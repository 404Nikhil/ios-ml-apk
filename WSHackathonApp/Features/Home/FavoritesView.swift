//
//  FavoritesView.swift
//  WSHackathonApp
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favoritesRepo: FavoritesRepository
    @EnvironmentObject var cartRepo: CartRepository

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(favoritesRepo.favoriteItems) { item in
                    ProductCardView(
                        product: item,
                        quantity: cartRepo.items.first(where: { $0.id == item.id })?.quantity ?? 0,
                        onAdd: { cartRepo.add(product: item) },
                        onRemove: { cartRepo.remove(productId: item.id) }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Your Favourites")
        .overlay {
            if favoritesRepo.favoriteItems.isEmpty {
                Text("No favourites yet!")
                    .foregroundColor(.secondary)
            }
        }
    }
}
