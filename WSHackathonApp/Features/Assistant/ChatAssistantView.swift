import SwiftUI

struct ChatAssistantView: View {
    @StateObject private var viewModel = ChatAssistantViewModel()
    @State private var inputText = ""
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(viewModel.messages) { msg in
                                ChatMessageRow(
                                    message: msg,
                                    onAdd: { item in
                                        withAnimation { cartRepository.add(product: item.asProductItem()) }
                                    },
                                    onRemoveLocal: { removedId in
                                        viewModel.removeItemFromMessage(messageId: msg.id, itemId: removedId)
                                    }
                                )
                                .id(msg.id)
                            }
                            if viewModel.isTyping {
                                HStack {
                                    Text("Milo is thinking...")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 12)
                                    Spacer()
                                }
                                .id("typing")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation { proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom) }
                    }
                    .onChange(of: viewModel.isTyping) { typing in
                        if typing { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
                    }
                }
                
                // Input area
                VStack(spacing: 0) {
                    Divider()
                        .background(Color(.systemGray4))
                    HStack {
                        TextField("Ask Milo...", text: $inputText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        Button {
                            let msg = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !msg.isEmpty else { return }
                            viewModel.sendMessage(msg)
                            inputText = ""
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(inputText.isEmpty ? .gray : .black)
                        }
                        .disabled(inputText.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Milo")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.fetchInitialGreeting() }
        }
    }
}

struct ChatMessageRow: View {
    let message: ChatMessage
    var onAdd: (RecommendationItem) -> Void
    var onRemoveLocal: ((String) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 12) {
            HStack {
                if message.isUser { Spacer(minLength: 40) }
                
                Text(message.text)
                    .font(.system(size: 15, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(message.isUser ? Color.black : Color(.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                if !message.isUser { Spacer(minLength: 40) }
            }
            
            if let items = message.recommendedItems, !items.isEmpty {
                if message.isBundle {
                    BundleOfferView(
                        bundle: BundleOffer(
                            title: "Custom Bundle",
                            items: items.map { BundleItem(id: $0.id, title: $0.name.replacingOccurrences(of: "_", with: " ").capitalized, price: $0.price, imageURL: $0.imageURL) },
                            discountPercent: 12
                        ),
                        onAddBundle: { bundleItems in
                            for item in bundleItems {
                                onAdd(RecommendationItem(id: item.id, name: item.title, type: "bundle", category: "bundle", price: item.price, image: item.imageURL?.absoluteString ?? ""))
                            }
                        },
                        onRemoveItem: onRemoveLocal
                    )
                    .padding(.vertical, 8)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(items) { item in
                                NavigationLink(destination: ProductDetailView(product: item.asProductItem(), allProducts: [])) {
                                    RecommendationProductCard(item: item, onAdd: onAdd)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
    }
}
