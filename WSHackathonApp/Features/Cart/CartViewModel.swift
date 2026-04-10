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
    
    func add(_ item: CartItem) {
        repository?.increaseQuantity(productId: item.id)
    }
    
    // --- Smart Cart Methods ---
    func addToCart(_ item: ProductItem) {
        repository?.add(product: item)
    }
    
    func addBundleToCart(_ items: [BundleItem]) {
        for item in items {
            let product = item.asProductItem()
            repository?.add(product: product)
        }
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
    
    // Build a bundle offer from current cart items + complementary product
    func buildBundleFromCart() {
        guard !items.isEmpty, !trendingItems.isEmpty else {
            bundleOffer = nil
            return
        }
        
        var bundleItems: [BundleItem] = []
        var usedIds = Set<String>()
        
        // Add current cart items (up to 2)
        for cartItem in items.prefix(2) {
            bundleItems.append(BundleItem(
                id: cartItem.id,
                title: shortTitle(cartItem.title),
                price: cartItem.price,
                imageURL: cartItem.imageURL
            ))
            usedIds.insert(cartItem.id)
        }
        
        // Add complementary items from trending that aren't already in cart
        let cartIds = Set(items.map(\.id))
        let complementary = trendingItems.filter { !cartIds.contains($0.id) && !usedIds.contains($0.id) }
        
        for item in complementary.prefix(2) {
            bundleItems.append(BundleItem(
                id: item.id,
                title: shortTitle(item.title),
                price: item.price ?? 0,
                imageURL: item.imageURL
            ))
            usedIds.insert(item.id)
        }
        
        guard bundleItems.count >= 3 else {
            bundleOffer = nil
            return
        }
        
        bundleOffer = BundleOffer(
            title: "Bundle & save on your picks",
            items: bundleItems,
            discountPercent: 15
        )
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
