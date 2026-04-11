//
//  ProductCardView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation
import SwiftUI

struct ProductCardView: View {
    @EnvironmentObject var favoritesRepo: FavoritesRepository
    
    let product: ProductItem
    let quantity: Int
    var registryQuantity: Int = 0
    let onAdd: () -> Void
    let onRemove: () -> Void
    var onAddToRegistry: () -> Void = {}
    var onRemoveFromRegistry: () -> Void = {}
    
    @State private var isPressed = false
    
    private var brandName: String? {
        let brands = ["GreenPan", "All-Clad", "Le Creuset", "Staub", "Wüsthof", "Shun", "Zwilling",
                       "Williams Sonoma", "OXO", "KitchenAid", "Cuisinart", "Breville", "Miyabi", "John Boos"]
        for brand in brands {
            if product.title.localizedCaseInsensitiveContains(brand) {
                return brand.uppercased()
            }
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Product Image
            ZStack(alignment: .topTrailing) {
                GeometryReader { geo in
                    CustomAsyncImage(url: product.imageURL)
                        .frame(width: geo.size.width, height: 180)
                        .clipped()
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Wishlist Button
                Button(action: {
                    withAnimation { favoritesRepo.toggleFavorite(product) }
                }) {
                    Image(systemName: favoritesRepo.isFavorite(product) ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(favoritesRepo.isFavorite(product) ? .red : .gray)
                        .padding(8)
                }
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // MARK: - Brand Tag
                if let brand = brandName {
                    Text(brand)
                        .font(.system(size: 9, weight: .bold))
                        .kerning(1.2)
                        .foregroundColor(Color(.systemGray))
                        .padding(.top, 10)
                }
                
                // MARK: - Product Title
                Text(product.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, brandName == nil ? 10 : 0)
                
                // MARK: - Price
                Text(product.price?.formatted(.currency(code: "USD")) ?? "")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer(minLength: 4)
                
                // MARK: - Add To Cart Button
                if !product.isAvailable {
                    Text("Unavailable")
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.gray)
                        .clipShape(Capsule())
                } else if quantity == 0 {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                            isPressed = true
                        }
                        onAdd()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation { isPressed = false }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 12, weight: .semibold))
                            Text(AppStrings.Home.addToCartButton)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                    .scaleEffect(isPressed ? 0.92 : 1.0)
                } else {
                    HStack {
                        Button(action: onRemove) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22))
                        }
                        
                        Spacer()
                        
                        Text("\(quantity)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        
                        Spacer()
                        
                        Button(action: onAdd) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                        }
                    }
                    .foregroundColor(.black)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 4)
                }
                
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        .frame(maxWidth: .infinity)
    }
}
