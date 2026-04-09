//
//  ProductItem.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

// 1. Define a custom UTType for your app's products
extension UTType {
    static var smartCartProduct: UTType {
        UTType(exportedAs: "com.wigglevig.aithon.productitem")
    }
}

// 2. Make the model Transferable using DataRepresentation (Sendable-safe)
extension ProductItem: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .smartCartProduct) { item in
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
