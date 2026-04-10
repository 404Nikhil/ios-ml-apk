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
    @Published var debouncedSearchText: String = ""
    @Published var products: [ProductItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedCategory: ProductCategory? = nil
    @Published var filterState = ProductFilterState()
    
    private var hasLoaded = false
    private var cartRepository: CartRepository?
    private var registryRepository: RegistryRepository?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .assign(to: \.debouncedSearchText, on: self)
            .store(in: &cancellables)
    }

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
    
    // MARK: - Filter Metadata
    
    /// Dynamically extracts available product types from the loaded catalog.
    var availableProductTypes: [String] {
        ProductFilterEngine.extractAvailableTypes(from: products)
    }
    
    /// Returns the min–max price extent of the loaded catalog.
    var priceBounds: ClosedRange<Double> {
        ProductFilterEngine.priceExtent(of: products)
    }

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
    
    // MARK: - Filtering Pipeline
    //
    // Order: Search → Category → Filter Engine (price, type, sort)

    var filteredProducts: [ProductItem] {
        var result: [ProductItem]
        
        // Step 1: Search (global, ignoring category)
        if !debouncedSearchText.isEmpty {
            let search = debouncedSearchText.lowercased()
            
            // Find if the search term matches any category names
            let matchingCategories = Self.categories.filter { $0.name.localizedCaseInsensitiveContains(search) }
            
            result = products.filter { product in
                let titleLower = product.title.lowercased()
                
                let matchesFields = titleLower.contains(search) ||
                    (product.brand?.localizedCaseInsensitiveContains(search) ?? false) ||
                    (product.productType?.localizedCaseInsensitiveContains(search) ?? false)
                
                let matchesCategory = matchingCategories.contains { category in
                    category.keywords.contains { keyword in
                        titleLower.contains(keyword)
                    }
                }
                
                return matchesFields || matchesCategory
            }
        } else {
            // Step 2: Category filter (when no search text)
            result = products
            if let cat = selectedCategory, !cat.keywords.isEmpty {
                result = result.filter { product in
                    let title = product.title.lowercased()
                    return cat.keywords.contains(where: { title.contains($0) })
                }
            }
        }
        
        // Step 3: Apply filter engine (price, type, sort)
        result = ProductFilterEngine.apply(filterState, to: result)
        
        return result
    }
    
    /// First 6 products for the "Trending Now" carousel
    var trendingProducts: [ProductItem] {
        Array(products.prefix(6))
    }
    
    func selectCategory(_ category: ProductCategory) {
        // Clear search when a category is explicitly selected
        searchText = ""
        debouncedSearchText = ""
        
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
