//
//  ProductCardView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation
import SwiftUI

struct ProductCardView: View {
    let product: ProductItem
    let quantity: Int
    let registryQuantity: Int
    let onAdd: () -> Void
    let onRemove: () -> Void
    let onAddToRegistry: () -> Void
    let onRemoveFromRegistry: () -> Void
    
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
                
                // Free Shipping badge
                HStack(spacing: 3) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 8))
                    Text("FREE SHIP")
                        .font(.system(size: 8, weight: .bold))
                        .kerning(0.5)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.75))
                .clipShape(Capsule())
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
                if quantity == 0 {
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
                
                // MARK: - Add To Registry Button
                if registryQuantity == 0 {
                    Button(action: onAddToRegistry) {
                        HStack(spacing: 5) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 10))
                            Text(AppStrings.Home.addToRegistry)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.clear)
                        .foregroundColor(.black)
                        .overlay(
                            Capsule()
                                .stroke(Color.black.opacity(0.5), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                    }
                } else {
                    HStack {
                        Button(action: onRemoveFromRegistry) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 20))
                        }
                        
                        Text(AppStrings.Registry.title)
                            .font(.system(size: 11, weight: .semibold))
                        
                        Spacer()
                        
                        Text("\(registryQuantity)")
                            .font(.system(size: 14, weight: .bold))
                        
                        Spacer()
                        
                        Button(action: onAddToRegistry) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                        }
                    }
                    .foregroundColor(.black)
                    .padding(.vertical, 4)
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
