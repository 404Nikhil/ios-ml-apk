//
//  ProductFilterState.swift
//  WSHackathonApp
//
//  Pure-value type representing the active filter criteria.
//  Intentionally decoupled from any UI or ViewModel dependency.
//

import Foundation

// MARK: - Sort Options

enum SortOption: String, CaseIterable, Identifiable {
    case relevance       = "Relevance"
    case priceLowToHigh  = "Price: Low → High"
    case priceHighToLow  = "Price: High → Low"
    case nameAZ          = "Name: A → Z"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .relevance:      return "sparkles"
        case .priceLowToHigh: return "arrow.up"
        case .priceHighToLow: return "arrow.down"
        case .nameAZ:         return "textformat.abc"
        }
    }
}

// MARK: - Filter State

struct ProductFilterState: Equatable {
    var sortOption: SortOption = .relevance
    var minPrice: Double = 0
    var maxPrice: Double = 5000
    var selectedTypes: Set<String> = []
    
    /// Whether all values are at their defaults (no active filters).
    var isDefault: Bool {
        sortOption == .relevance &&
        minPrice == 0 &&
        maxPrice == 5000 &&
        selectedTypes.isEmpty
    }
    
    /// The number of actively applied filter dimensions (for badge count).
    var activeFilterCount: Int {
        var count = 0
        if sortOption != .relevance { count += 1 }
        if minPrice > 0 || maxPrice < 5000 { count += 1 }
        if !selectedTypes.isEmpty { count += 1 }
        return count
    }
    
    /// Resets all filter criteria to their default values.
    mutating func reset() {
        sortOption = .relevance
        minPrice = 0
        maxPrice = 5000
        selectedTypes = []
    }
}
