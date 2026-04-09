//
//  ProductItem.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

extension ProductItem: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .json) { item in
            try JSONEncoder().encode(item)
        } importing: { data in
            try JSONDecoder().decode(ProductItem.self, from: data)
        }
    }
}

struct ProductItem: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let price: Double?
    let path: String?
    
    var imageURL: URL? {
        if let imageUrl = path {
            return URL(string: AppConstants.API.imageBasePath + imageUrl)
        }
        return nil
    }
}

extension ProductItem {
    init(from dto: ProductItemDTO) {
        self.id = dto.id
        self.title = dto.name
        
        // Price formatting: use regularPrice if available
        if let priceValue = dto.price?.regularPrice {
            self.price = priceValue
        } else {
            self.price = 0.0
        }
        
        // Image: first ProductImage path if available
        if let firstImage = dto.media?.images?.first?.path {
            self.path = firstImage
        } else {
            self.path = nil
        }
    }
}
