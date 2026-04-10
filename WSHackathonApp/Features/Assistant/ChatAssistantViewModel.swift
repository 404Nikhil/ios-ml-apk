import Foundation
import Combine
import SwiftUI

@MainActor
class ChatAssistantViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    
    func fetchInitialGreeting() {
        guard messages.isEmpty else { return }
        messages.append(ChatMessage(text: "Hi! I'm Milo. Ask me about cookware, furniture, or anything in our catalog!", isUser: false))
    }
    
    func removeItemFromMessage(messageId: UUID, itemId: String) {
        if let idx = messages.firstIndex(where: { $0.id == messageId }) {
            messages[idx].recommendedItems?.removeAll { $0.id == itemId }
        }
    }

    func sendMessage(_ text: String) {
        var contextIds: [String] = []
        if let lastBundleMsg = messages.last(where: { $0.isBundle == true && $0.recommendedItems != nil }),
           let items = lastBundleMsg.recommendedItems {
            contextIds = items.map { $0.id }
        }

        messages.append(ChatMessage(text: text, isUser: true))
        isTyping = true
        
        Task {
            do {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                guard let url = URL(string: AppConstants.RecommendAPI.baseURL + "/chat") else { return }
                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.addValue("application/json", forHTTPHeaderField: "Content-Type")
                let payload = ChatRequestAPI(message: text, context_items: contextIds)
                req.httpBody = try JSONEncoder().encode(payload)
                
                let (data, _) = try await URLSession.shared.data(for: req)
                let response = try JSONDecoder().decode(ChatAPIResponse.self, from: data)
                
                await MainActor.run {
                    self.isTyping = false
                    let bundleFlag = response.isBundle ?? false
                    self.messages.append(ChatMessage(text: response.response, isUser: false, recommendedItems: response.items, isBundle: bundleFlag))
                }
            } catch {
                await MainActor.run {
                    self.isTyping = false
                    self.messages.append(ChatMessage(text: "Sorry, I am having trouble connecting right now.", isUser: false))
                    print("Chat error: \(error)")
                }
            }
        }
    }
}
