//
//  RecommendationModels.swift
//  WSHackathonApp
//
//  Data models matching the /recommend API response exactly.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

// MARK: - API Response Models

struct RecommendationResponse: Codable {
    let sections: [RecommendationSection]
}

struct RecommendationSection: Codable, Identifiable {
    // API doesn't give us an id, so synthesize one from the title
    var id: String { title }
    let title: String
    let items: [RecommendationItem]
}

struct RecommendationItem: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let type: String
    let category: String
    let price: Double
    let image: String   // relative path e.g. "/images/pan_1.jpg"

    /// Fully-qualified image URL using the recommendation server base.
    var imageURL: URL? {
        URL(string: AppConstants.RecommendAPI.baseURL + image)
    }

    /// Formatted price string. Backend returns price in currency units.
    var priceText: String { String(format: "$%.2f", price) }
}

// MARK: - Transferable (drag-and-drop)

extension RecommendationItem: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .json) { item in
            try JSONEncoder().encode(item)
        } importing: { data in
            try JSONDecoder().decode(RecommendationItem.self, from: data)
        }
    }
}

// MARK: - Bridge to ProductItem (for CartRepository)

extension RecommendationItem {
    /// Converts to the app's canonical ProductItem so it can flow through CartRepository.
    func asProductItem() -> ProductItem {
        // The image path from the API is relative e.g. "/images/pan_1.jpg"
        // We store it as-is and use imageURL on RecommendationItem for display.
        // ProductItem.imageURL will correctly prepend the Base URL itself.
        ProductItem(id: id, title: name.replacingOccurrences(of: "_", with: " ").capitalized, price: Double(price), path: image, brand: nil, productType: category)
    }
}
