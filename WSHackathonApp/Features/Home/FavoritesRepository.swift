//
//  FavoritesRepository.swift
//  WSHackathonApp
//

import Foundation
import Combine
import SwiftUI

class FavoritesRepository: ObservableObject {
    @Published var favoriteItems: [ProductItem] = []

    func toggleFavorite(_ item: ProductItem) {
        if let index = favoriteItems.firstIndex(where: { $0.id == item.id }) {
            favoriteItems.remove(at: index)
        } else {
            favoriteItems.append(item)
        }
    }

    func isFavorite(_ item: ProductItem) -> Bool {
        return favoriteItems.contains(where: { $0.id == item.id })
    }
}
