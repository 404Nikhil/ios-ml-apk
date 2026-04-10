import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    var recommendedItems: [RecommendationItem]? = nil
    var isBundle: Bool = false
}

struct ChatAPIResponse: Codable {
    let response: String
    let items: [RecommendationItem]
    let isBundle: Bool?
}

struct ChatRequestAPI: Codable {
    let message: String
    let context_items: [String]
}
