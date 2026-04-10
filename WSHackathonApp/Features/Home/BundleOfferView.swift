//
//  BundleOfferView.swift
//  WSHackathonApp
//
//  A premium "Bundle Offer" card that shows the current product + recommended items
//  as a discounted bundle. Users can add the entire bundle to cart with one tap.
//  Design: black & white, minimal, classy — consistent with the app theme.
//

import SwiftUI

// MARK: - Bundle Data Model

struct BundleOffer: Identifiable {
    let id = UUID()
    let title: String
    let items: [BundleItem]
    let discountPercent: Int
    
    var originalTotal: Double {
        items.reduce(0) { $0 + $1.price }
    }
    
    var discountedTotal: Double {
        originalTotal * (1.0 - Double(discountPercent) / 100.0)
    }
    
    var savings: Double {
        originalTotal - discountedTotal
    }
}

struct BundleItem: Identifiable {
    let id: String
    let title: String
    let price: Double
    let imageURL: URL?
    
    /// Convert back to ProductItem for adding to cart
    func asProductItem() -> ProductItem {
        // Extract path from the imageURL (strip the base URL)
        let path: String?
        if let url = imageURL {
            let baseURL = AppConstants.API.imageBasePath
            let fullString = url.absoluteString
            if fullString.hasPrefix(baseURL) {
                path = String(fullString.dropFirst(baseURL.count))
            } else {
                path = fullString
            }
        } else {
            path = nil
        }
        return ProductItem(id: id, title: title, price: price, path: path, brand: nil, productType: nil)
    }
}

// MARK: - Bundle Offer View

struct BundleOfferView: View {
    let bundle: BundleOffer
    var onAddBundle: ([BundleItem]) -> Void
    
    @State private var bundleAdded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // MARK: Section Header
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black)
                    .frame(width: 3, height: 16)
                
                Text("BUNDLE OFFER")
                    .font(.system(size: 13, weight: .bold))
                    .kerning(1.2)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // MARK: Bundle Card
            VStack(spacing: 0) {
                
                // Top: Title + Savings Badge
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bundle.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("\(bundle.items.count) items • Buy together & save")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Savings badge
                    VStack(spacing: 2) {
                        Text("SAVE")
                            .font(.system(size: 9, weight: .heavy))
                            .kerning(1)
                        Text("$\(Int(bundle.savings))")
                            .font(.system(size: 18, weight: .black))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Middle: Product thumbnails with "+" between them
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(Array(bundle.items.enumerated()), id: \.element.id) { index, item in
                            BundleItemThumbnail(item: item)
                            
                            if index < bundle.items.count - 1 {
                                Text("+")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .frame(width: 28)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 14)
                
                // Divider
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 0.5)
                    .padding(.horizontal, 16)
                
                // Bottom: Price + Add Bundle Button
                HStack(spacing: 12) {
                    // Price information
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "$%.2f", bundle.originalTotal))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .strikethrough(true, color: .secondary)
                        
                        Text(String(format: "$%.2f", bundle.discountedTotal))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Add bundle button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            bundleAdded = true
                            onAddBundle(bundle.items)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { bundleAdded = false }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: bundleAdded ? "checkmark" : "cart.badge.plus")
                                .font(.system(size: 13, weight: .semibold))
                            Text(bundleAdded ? "Bundle Added!" : "Add Bundle")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(bundleAdded ? .black : .white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(bundleAdded ? Color(.systemGray5) : Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .scaleEffect(bundleAdded ? 1.05 : 1.0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        }
    }
}

// MARK: - Bundle Item Thumbnail

private struct BundleItemThumbnail: View {
    let item: BundleItem
    
    var body: some View {
        VStack(spacing: 6) {
            CustomAsyncImage(url: item.imageURL)
                .frame(width: 80, height: 70)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )
            
            Text(item.title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
                .frame(height: 26)
            
            Text(String(format: "$%.0f", item.price))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Compact Bundle Offer (for Cart page)

struct CompactBundleOfferView: View {
    let bundle: BundleOffer
    var onAddBundle: ([BundleItem]) -> Void
    
    @State private var bundleAdded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Header row
            HStack {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black)
                        .frame(width: 3, height: 16)
                    
                    Text("BUNDLE & SAVE")
                        .font(.system(size: 12, weight: .bold))
                        .kerning(1)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Savings pill
                Text("Save $\(Int(bundle.savings))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            // Items row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(bundle.items.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 4) {
                            CustomAsyncImage(url: item.imageURL)
                                .frame(width: 60, height: 50)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            Text(item.title)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .frame(width: 60)
                        }
                        
                        if index < bundle.items.count - 1 {
                            Text("+")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 10)
            
            // Divider
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5)
                .padding(.horizontal, 16)
            
            // Price + Button row
            HStack {
                HStack(spacing: 6) {
                    Text(String(format: "$%.0f", bundle.originalTotal))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .strikethrough()
                    
                    Text(String(format: "$%.0f", bundle.discountedTotal))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        bundleAdded = true
                        onAddBundle(bundle.items)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation { bundleAdded = false }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: bundleAdded ? "checkmark" : "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text(bundleAdded ? "Added" : "Add Bundle")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(bundleAdded ? .black : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(bundleAdded ? Color(.systemGray5) : Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
