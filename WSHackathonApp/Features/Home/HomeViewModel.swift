//
//  HomeViewModel.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 04/04/26.
//

import Foundation
import Combine

struct ProductCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let keywords: [String]
}

class HomeViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var products: [ProductItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedCategory: ProductCategory? = nil
    
    private var hasLoaded = false
    private var cartRepository: CartRepository?
    private var registryRepository: RegistryRepository?

    // MARK: - Category Data
    static let categories: [ProductCategory] = [
        ProductCategory(name: "All", icon: "square.grid.2x2", keywords: []),
        ProductCategory(name: "Cookware", icon: "frying.pan", keywords: ["pan", "skillet", "pot", "dutch oven", "saucepan", "braiser", "wok", "stockpot", "cookware", "fry"]),
        ProductCategory(name: "Cutlery", icon: "fork.knife", keywords: ["knife", "knives", "cutlery", "shears", "steel", "block", "blade"]),
        ProductCategory(name: "Bakeware", icon: "birthday.cake", keywords: ["bake", "baking", "sheet", "muffin", "cake", "loaf", "pie", "cookie"]),
        ProductCategory(name: "Tabletop", icon: "cup.and.saucer", keywords: ["plate", "bowl", "glass", "mug", "cup", "dinnerware", "flatware", "napkin"]),
        ProductCategory(name: "Food", icon: "leaf", keywords: ["food", "coffee", "tea", "chocolate", "olive", "spice", "sauce", "jam", "honey"]),
        ProductCategory(name: "Tools", icon: "wrench.and.screwdriver", keywords: ["spatula", "tong", "whisk", "peeler", "grater", "ladle", "turner", "tool", "utensil"]),
        ProductCategory(name: "Electrics", icon: "bolt", keywords: ["blender", "mixer", "processor", "toaster", "espresso", "machine", "electric"]),
    ]

    func bind(cartRepository: CartRepository,
              registryRepository: RegistryRepository) {
        self.cartRepository = cartRepository
        self.registryRepository = registryRepository
    }
    
    // Cart
    func addToCart(_ product: ProductItem) {
        cartRepository?.add(product: product)
    }
    
    func removeFromCart(_ product: ProductItem) {
        cartRepository?.remove(productId: product.id)
    }
    
    // Registry
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
    
    func quantity(for product: ProductItem) -> Int {
        cartRepository?.items.first(where: { $0.id == product.id })?.quantity ?? 0
    }
    
    func registryQuantity(for product: ProductItem) -> Int {
        registryRepository?.currentRegistry?.items.first(where: { $0.id == product.id })?.quantity ?? 0
    }
    
    // MARK: - Filtering

    var filteredProducts: [ProductItem] {
        var result = products
        
        // Category filter
        if let cat = selectedCategory, !cat.keywords.isEmpty {
            result = result.filter { product in
                let title = product.title.lowercased()
                return cat.keywords.contains(where: { title.contains($0) })
            }
        }
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        return result
    }
    
    /// First 6 products for the "Trending Now" carousel
    var trendingProducts: [ProductItem] {
        Array(products.prefix(6))
    }
    
    func selectCategory(_ category: ProductCategory) {
        if category.keywords.isEmpty {
            // "All" category
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
    }
    
    func fetchProducts() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        
        isLoading = true
        errorMessage = nil
        
        do {
            let dtos: [ProductItemDTO] = try await APIClient.shared.request(Endpoint.products())
            self.products = dtos.map { ProductItem(from: $0) }
        } catch {
            print(error)
            errorMessage = "Failed to load products"
        }
        
        isLoading = false
    }
    
    func refreshProducts() async {
        hasLoaded = false
        await fetchProducts()
    }
}   
