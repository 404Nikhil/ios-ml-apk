//
//  MockSmartCartService.swift
//  WSHackathonApp
//

import Foundation

class MockSmartCartService {
    static let shared = MockSmartCartService()
    
    // Simulates the FastAPI ML endpoint
    func fetchFrequentlyBoughtTogether() async throws -> [ProductItem] {
        // Simulate network/ML inference latency (1.5 seconds)
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Mock JSON response
        return [
            ProductItem(id: "101", title: "Wireless Charging Pad", price: 29.99, path: nil),
            ProductItem(id: "102", title: "Premium Screen Protector", price: 14.99, path: nil),
            ProductItem(id: "103", title: "Noise Cancelling Earbuds", price: 89.99, path: nil)
        ]
    }
    
    // Simulates fetching trending items for the empty state
    func fetchTrendingItems() async throws -> [ProductItem] {
        try await Task.sleep(nanoseconds: 800_000_000)
        return [
            ProductItem(id: "201", title: "Smart Watch Series X", price: 199.99, path: nil),
            ProductItem(id: "202", title: "Ergonomic Mouse", price: 45.00, path: nil)
        ]
    }
}
