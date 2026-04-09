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
    
    func fetchInitialData() {
        Task {
            isRecommendationsLoading = true
            do {
                recommendations = try await MockSmartCartService.shared.fetchFrequentlyBoughtTogether()
                trendingItems = try await MockSmartCartService.shared.fetchTrendingItems()
            } catch {
                print("Failed to fetch smart cart data")
            }
            isRecommendationsLoading = false
        }
    }
    
    // Pass-through functions for ProductCardView (used in trending)
    func removeFromCart(_ product: ProductItem) {
        repository?.remove(productId: product.id)
    }
    
    func quantity(for product: ProductItem) -> Int {
        items.first(where: { $0.id == product.id })?.quantity ?? 0
    }
}
