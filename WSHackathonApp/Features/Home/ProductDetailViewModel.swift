//
//  ProductDetailViewModel.swift
//  WSHackathonApp
//
//  ViewModel for the Product Detail Page.
//  Fetches ML-powered recommendations (Similar, FBT, Complete Your Set)
//  using the /recommend endpoint with the current product as the cart context.
//

import Foundation
import Combine

@MainActor
final class ProductDetailViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published var similarItems: [ProductItem] = []
    @Published var allProducts: [ProductItem] = []
    @Published var isLoading = false
    @Published var recommendationSections: [RecommendationSection] = []
    @Published var isRecommendationsLoading = false
    
    private var cartRepository: CartRepository?
    private var registryRepository: RegistryRepository?
    
    // MARK: - Bind Repositories
    func bind(cartRepository: CartRepository, registryRepository: RegistryRepository) {
        self.cartRepository = cartRepository
        self.registryRepository = registryRepository
    }
    
    // MARK: - Cart Actions
    func addToCart(_ product: ProductItem) {
        cartRepository?.add(product: product)
    }
    
    func removeFromCart(_ product: ProductItem) {
        cartRepository?.remove(productId: product.id)
    }
    
    func quantity(for product: ProductItem) -> Int {
        cartRepository?.items.first(where: { $0.id == product.id })?.quantity ?? 0
    }
    
    // MARK: - Registry Actions
    func addToRegistry(_ product: ProductItem) {
        registryRepository?.addProduct(product)
    }
    
    func canAddToRegistry(_ product: ProductItem) -> Bool {
        if let registryRepository, registryRepository.isActiveRegistry {
            return true
        }
        return false
    }
    
    func removeFromRegistry(_ product: ProductItem) {
        registryRepository?.removeItem(product.id)
    }
    
    func registryQuantity(for product: ProductItem) -> Int {
        registryRepository?.currentRegistry?.items.first(where: { $0.id == product.id })?.quantity ?? 0
    }
    
    // MARK: - Fetch All Products (for Similar Items)
    func fetchAllProducts(currentProduct: ProductItem) async {
        isLoading = true
        do {
            let dtos: [ProductItemDTO] = try await APIClient.shared.request(Endpoint.products())
            let all = dtos.map { ProductItem(from: $0) }
            self.allProducts = all
            
            // Filter similar items: same product type prefix (e.g. SKU-PAN matches SKU-PAN)
            // but exclude the current product
            let currentPrefix = String(currentProduct.id.prefix(7)) // e.g. "SKU-PAN"
            self.similarItems = all.filter { item in
                item.id != currentProduct.id && item.id.hasPrefix(currentPrefix)
            }
            
            // If we didn't find enough similar items by prefix, broaden the search
            if similarItems.count < 2 {
                // Take other products that aren't the current one
                self.similarItems = Array(all.filter { $0.id != currentProduct.id }.prefix(6))
            }
        } catch {
            print("⚠️ Failed to fetch products: \(error)")
        }
        isLoading = false
    }
    
    // MARK: - Fetch Recommendations via /recommend API
    func fetchRecommendations(for product: ProductItem) async {
        isRecommendationsLoading = true
        
        // Use the same RecommendationService that cart uses to map product titles → intcart IDs
        let intcartIds = RecommendationService.shared.resolvedIntcartIds(
            from: [(id: product.id, title: product.title)]
        )
        
        do {
            let response = try await RecommendationService.shared.fetchRecommendations(for: intcartIds)
            // Filter out "Similar items" — we already show that section from the product catalog
            self.recommendationSections = response.sections.filter {
                !$0.items.isEmpty && !$0.title.localizedCaseInsensitiveContains("similar")
            }
        } catch {
            print("⚠️ Failed to fetch recommendations: \(error)")
            self.recommendationSections = []
        }
        
        isRecommendationsLoading = false
    }
}
