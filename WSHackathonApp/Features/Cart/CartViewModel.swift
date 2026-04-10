//
//  CartViewModel.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//

import Foundation
import Combine

@MainActor
final class CartViewModel: ObservableObject {

    @Published private(set) var items: [CartItem] = []
    
    // --- Smart Cart State ---
    @Published var recommendations: [ProductItem] = []
    @Published var isRecommendationsLoading = false
    @Published var trendingItems: [ProductItem] = []
    @Published var isTrendingLoading = false
    @Published var bundleOffer: BundleOffer?

    private var cancellable: AnyCancellable?
    private var repository: CartRepository?
    // Prevents buildBundleFromCart() from re-surfacing the bundle immediately
    // after the user has already added & dismissed it.
    private var isBundleDismissed = false
    
    func bind(repository: CartRepository) {
        self.repository = repository
        self.items = repository.items
        
        cancellable = repository.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedItems in
                self?.items = updatedItems
            }
    }
    
    var isEmptyCart: Bool {
        items.isEmpty
    }
    
    var totalPriceText: String {
        String(format: "$%.2f", repository?.totalPrice ?? 0)
    }
    
    var totalPrice: Double {
        repository?.totalPrice ?? 0
    }
    
    func removeItem(_ item: CartItem) {
        repository?.remove(productId: item.id)
    }
    
    func deleteItem(_ item: CartItem) {
        repository?.deleteEntirely(productId: item.id)
    }
    
    func clearCart() {
        repository?.clearAll()
        bundleOffer = nil
        isBundleDismissed = false  // allow a fresh bundle next session
    }
    
    func add(_ item: CartItem) {
        repository?.increaseQuantity(productId: item.id)
    }
    
    // --- Smart Cart Methods ---
    func addToCart(_ item: ProductItem) {
        repository?.add(product: item)
    }
    
    func addBundleToCart(_ items: [BundleItem]) {
        guard let cartRepo = repository else { return }
        for item in items {
            let product = item.asProductItem()
            if !cartRepo.items.contains(where: { $0.id == product.id }) {
                cartRepo.add(product: product)
            }
        }
        // Dismiss the bundle card and prevent it from reappearing
        isBundleDismissed = true
        self.bundleOffer = nil
    }
    
    func fetchInitialData() {
        Task {
            isTrendingLoading = true
            do {
                // Fetch real available products as 'trending' items
                let dtos: [ProductItemDTO] = try await APIClient.shared.request(Endpoint.products())
                self.trendingItems = dtos.map { ProductItem(from: $0) }
            } catch {
                print("⚠️ Failed to fetch trending items:", error)
                self.trendingItems = []
            }
            isTrendingLoading = false
        }
    }
    
    // Build a bundle offer from current cart items + complementary product using ML recommendations
    func buildBundleFromCart() {
        guard !items.isEmpty, !isBundleDismissed else {
            bundleOffer = nil
            return
        }
        
        Task {
            let intcartIds = RecommendationService.shared.resolvedIntcartIds(
                from: items.map { (id: $0.id, title: $0.title) }
            )
            
            do {
                let response = try await RecommendationService.shared.fetchRecommendations(for: intcartIds)
                
                await MainActor.run {
                    var bundleItems: [BundleItem] = []
                    var usedIds = Set<String>()
                    
                    // Add current cart items (up to 2)
                    for cartItem in items.prefix(2) {
                        bundleItems.append(BundleItem(
                            id: cartItem.id,
                            title: self.shortTitle(cartItem.title),
                            price: cartItem.price,
                            imageURL: cartItem.imageURL
                        ))
                        usedIds.insert(cartItem.id)
                    }
                    
                    // Add items from FBT section first
                    let fbtSections = response.sections.filter { $0.title.localizedCaseInsensitiveContains("frequently") }
                    let otherSections = response.sections.filter { !$0.title.localizedCaseInsensitiveContains("frequently") && !$0.title.localizedCaseInsensitiveContains("similar") }
                    
                    let allSections = fbtSections + otherSections
                    
                    for section in allSections {
                        for item in section.items {
                            if !usedIds.contains(item.id) && bundleItems.count < 3 {
                                bundleItems.append(BundleItem(
                                    id: item.id,
                                    title: item.name.replacingOccurrences(of: "_", with: " ").capitalized,
                                    price: Double(item.price),
                                    imageURL: item.imageURL
                                ))
                                usedIds.insert(item.id)
                            }
                        }
                    }
                    
                    guard bundleItems.count >= 3 else {
                        self.bundleOffer = nil
                        return
                    }
                    
                    self.bundleOffer = BundleOffer(
                        title: "Bundle & save on your picks",
                        items: bundleItems,
                        discountPercent: 15
                    )
                }
            } catch {
                print("⚠️ Failed to fetch recommendations for bundle: \(error)")
                await MainActor.run { self.bundleOffer = nil }
            }
        }
    }
    
    private func shortTitle(_ title: String) -> String {
        let words = title.components(separatedBy: " ")
        if words.count > 3 {
            return words.prefix(3).joined(separator: " ")
        }
        return title
    }
    
    // Pass-through functions for ProductCardView (used in trending)
    func removeFromCart(_ product: ProductItem) {
        repository?.remove(productId: product.id)
    }
    
    func quantity(for product: ProductItem) -> Int {
        items.first(where: { $0.id == product.id })?.quantity ?? 0
    }
}
