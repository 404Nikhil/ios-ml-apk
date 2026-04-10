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
    @Published var bundleOffer: BundleOffer?
    
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
    
    func addBundleToCart(_ items: [BundleItem]) {
        guard let cartRepo = cartRepository else { return }
        for item in items {
            let product = item.asProductItem()
            if !cartRepo.items.contains(where: { $0.id == product.id }) {
                cartRepo.add(product: product)
            }
        }
        // Hide the bundle card once added — adding the same bundle twice makes no sense
        self.bundleOffer = nil
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
            
            // Build bundle offer from recommendation data
            buildBundleOffer(for: product, from: response.sections)
        } catch {
            print("⚠️ Failed to fetch recommendations: \(error)")
            self.recommendationSections = []
        }
        
        isRecommendationsLoading = false
    }
    
    // MARK: - Build Bundle Offer
    private func buildBundleOffer(for product: ProductItem, from sections: [RecommendationSection]) {
        // Collect items from FBT + Complete sections for the bundle
        var bundleItems: [BundleItem] = []
        var usedIds = Set<String>()
        
        // Always include the current product first
        bundleItems.append(BundleItem(
            id: product.id,
            title: shortTitle(product.title),
            price: product.price ?? 0,
            imageURL: product.imageURL
        ))
        usedIds.insert(product.id)
        
        // Add items from FBT section first, then from other sections
        let fbtSections = sections.filter { $0.title.localizedCaseInsensitiveContains("frequently") }
        let otherSections = sections.filter { !$0.title.localizedCaseInsensitiveContains("frequently") && !$0.title.localizedCaseInsensitiveContains("similar") }
        
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
        
        // Need at least 3 items for a meaningful bundle
        guard bundleItems.count >= 3 else {
            self.bundleOffer = nil
            return
        }
        
        // Determine bundle title based on what's in it
        let title = determineBundleTitle(for: product)
        
        self.bundleOffer = BundleOffer(
            title: title,
            items: bundleItems,
            discountPercent: 15
        )
    }
    
    private func determineBundleTitle(for product: ProductItem) -> String {
        let titleLower = product.title.lowercased()
        if titleLower.contains("pan") || titleLower.contains("skillet") || titleLower.contains("pot") || titleLower.contains("dutch") {
            return "Complete your cookware setup"
        } else if titleLower.contains("knife") || titleLower.contains("cutting") || titleLower.contains("board") {
            return "Complete your prep station"
        } else if titleLower.contains("spatula") || titleLower.contains("turner") {
            return "Complete your kitchen tools"
        } else if titleLower.contains("chair") || titleLower.contains("table") || titleLower.contains("sofa") {
            return "Complete your living space"
        } else {
            return "Complete your collection"
        }
    }
    
    private func shortTitle(_ title: String) -> String {
        // Truncate long product titles for the bundle view
        let words = title.components(separatedBy: " ")
        if words.count > 3 {
            return words.prefix(3).joined(separator: " ")
        }
        return title
    }
}
