//
//  ProductFilterEngine.swift
//  WSHackathonApp
//
//  Stateless utility that applies a ProductFilterState to a [ProductItem] array.
//  Pure functions — no side effects, no state, trivially testable.
//

import Foundation

enum ProductFilterEngine {
    
    // MARK: - Primary API
    
    /// Applies all active filters and sort order to a product array.
    /// - Parameters:
    ///   - state: The current filter configuration.
    ///   - products: The pre-filtered product array (after search/category).
    /// - Returns: A new array reflecting the applied filters and sort.
    static func apply(_ state: ProductFilterState, to products: [ProductItem]) -> [ProductItem] {
        var result = products
        
        // 1. Price range filter
        result = result.filter { product in
            guard let price = product.price else { return true }
            return price >= state.minPrice && price <= state.maxPrice
        }
        
        // 2. Product type filter
        if !state.selectedTypes.isEmpty {
            result = result.filter { product in
                let titleLower = product.title.lowercased()
                let typeLower = product.productType?.lowercased() ?? ""
                
                return state.selectedTypes.contains { type in
                    titleLower.contains(type.lowercased()) ||
                    typeLower.contains(type.lowercased())
                }
            }
        }
        
        // 3. Sort
        result = sorted(result, by: state.sortOption)
        
        return result
    }
    
    // MARK: - Metadata Extraction
    
    /// Extracts all unique product types from a catalog for the filter UI.
    static func extractAvailableTypes(from products: [ProductItem]) -> [String] {
        var types = Set<String>()
        
        for product in products {
            // Try the explicit productType field first
            if let productType = product.productType, !productType.isEmpty {
                types.insert(productType.capitalized)
            }
            
            // Also extract type from known keywords in the title
            let titleLower = product.title.lowercased()
            let knownTypes = [
                "pan", "pot", "spatula", "knife", "cutting board",
                "sofa", "chair", "coffee table", "table", "plate", "glass",
                "skillet", "dutch oven", "saucepan", "wok", "blender",
                "mixer", "toaster", "sheet", "muffin", "cake"
            ]
            for type in knownTypes {
                if titleLower.contains(type) {
                    types.insert(type.capitalized)
                }
            }
        }
        
        return types.sorted()
    }
    
    /// Returns the min–max price extent of a product catalog.
    static func priceExtent(of products: [ProductItem]) -> ClosedRange<Double> {
        let prices = products.compactMap { $0.price }.filter { $0 > 0 }
        guard let minPrice = prices.min(), let maxPrice = prices.max() else {
            return 0...5000
        }
        return floor(minPrice)...ceil(maxPrice)
    }
    
    // MARK: - Private Helpers
    
    private static func sorted(_ products: [ProductItem], by option: SortOption) -> [ProductItem] {
        switch option {
        case .relevance:
            return products // Original API order
        case .priceLowToHigh:
            return products.sorted { ($0.price ?? 0) < ($1.price ?? 0) }
        case .priceHighToLow:
            return products.sorted { ($0.price ?? 0) > ($1.price ?? 0) }
        case .nameAZ:
            return products.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
}
