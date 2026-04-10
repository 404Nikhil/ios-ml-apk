//
//  SearchViewModel.swift
//  WSHackathonApp
//

import SwiftUI
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var debouncedSearchText: String = ""
    @Published var hasSearched: Bool = false
    
    // Core Data
    @Published var allProducts: [ProductItem] = []
    @Published var trendingProducts: [ProductItem] = []
    
    // Filters
    @Published var filterState = ProductFilterState()
    @Published var suggestedFilters: [FilterOption] = []
    @Published var selectedFilters: Set<FilterOption> = []
    
    // History
    @AppStorage("ws_search_history") private var savedHistoryData: Data = Data()
    @Published var searchHistory: [String] = [] {
        didSet { saveHistory() }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadHistory()
        
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.debouncedSearchText = query
                // Don't auto-fetch smart filters if the user clears the search
                if !query.isEmpty {
                    Task { await self?.fetchSmartFilters(query: query) }
                } else {
                    self?.suggestedFilters = []
                    self?.selectedFilters.removeAll()
                }
            }
            .store(in: &cancellables)
    }
    
    func performSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            searchText = trimmed
            hasSearched = true
            addToHistory(trimmed)
        }
    }
    
    func clearSearch() {
        searchText = ""
        debouncedSearchText = ""
        hasSearched = false
    }
    
    // MARK: - History
    private func loadHistory() {
        if let decoded = try? JSONDecoder().decode([String].self, from: savedHistoryData) {
            searchHistory = decoded
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(searchHistory) {
            savedHistoryData = encoded
        }
    }
    
    private func addToHistory(_ query: String) {
        var current = searchHistory
        current.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
        current.insert(query, at: 0)
        if current.count > 10 {
            current = Array(current.prefix(10))
        }
        searchHistory = current
    }
    
    func clearHistory() {
        searchHistory.removeAll()
    }
    
    // MARK: - Filter UI Metadata
    var availableProductTypes: [String] {
        ProductFilterEngine.extractAvailableTypes(from: allProducts)
    }
    
    var priceBounds: ClosedRange<Double> {
        ProductFilterEngine.priceExtent(of: allProducts)
    }
    
    // MARK: - Filter Logic
    var filteredProducts: [ProductItem] {
        var result: [ProductItem]
        
        // 1. Search Query
        if !debouncedSearchText.isEmpty {
            let search = debouncedSearchText.lowercased()
            let matchingCategories = HomeViewModel.categories.filter { $0.name.localizedCaseInsensitiveContains(search) }
            
            result = allProducts.filter { product in
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
            result = [] // if not searched, return empty for results screen
        }
        
        // 2. Filter Engine (price, type, sort)
        result = ProductFilterEngine.apply(filterState, to: result)
        
        // 3. Smart Filters Selection
        for filter in selectedFilters {
            switch filter.type {
            case .category:
                result = result.filter { 
                    $0.productType?.localizedCaseInsensitiveContains(filter.title) == true || 
                    $0.title.localizedCaseInsensitiveContains(filter.title)
                }
            case .attribute:
                result = result.filter { $0.title.localizedCaseInsensitiveContains(filter.title) }
            case .price:
                if let maxPriceStr = filter.title.components(separatedBy: "$").last, let max = Double(maxPriceStr) {
                    result = result.filter { ($0.price ?? 0) <= max }
                } else if filter.title.contains("Premium") {
                     result = result.filter { ($0.price ?? 0) > 200 }
                }
            }
        }
        
        return result
    }
    
    @MainActor
    func fetchSmartFilters(query: String) async {
        guard !query.isEmpty else { return }
        do {
            let response: SmartFilterResponse = try await APIClient.shared.request(Endpoint.smartFilters(query: query))
            self.suggestedFilters = response.suggestedFilters
            let newSuggestedSet = Set(response.suggestedFilters)
            self.selectedFilters.formIntersection(newSuggestedSet)
        } catch {
            print("⚠️ Smart Filters Error: \(error)")
        }
    }
    
    func applyFilter(_ filter: FilterOption) {
        selectedFilters.insert(filter)
    }
    
    func removeFilter(_ filter: FilterOption) {
        selectedFilters.remove(filter)
    }
}
