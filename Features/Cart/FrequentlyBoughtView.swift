//
//  FrequentlyBoughtView.swift
//  WSHackathonApp
//

import SwiftUI

struct FrequentlyBoughtView: View {
    let items: [ProductItem]
    let isLoading: Bool
    var onAdd: (ProductItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frequently Bought Together")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if isLoading {
                        // Skeleton State
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                                .frame(width: 140, height: 180)
                                .shimmering()
                        }
                    } else {
                        // Loaded State
                        ForEach(items, id: \.id) { item in
                            CompactUpsellCard(item: item, onAdd: onAdd)
                                // THE MAGIC: Makes the item draggable
                                .draggable(item) {
                                    // Custom preview while dragging
                            CompactUpsellCard(item: item, onAdd: { _ in })
                                        .frame(width: 120, height: 160)
                                        .opacity(0.8)
                                }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 10)
    }
}

// A smaller card designed specifically for the horizontal carousel
struct CompactUpsellCard: View {
    let item: ProductItem
    var onAdd: (ProductItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            // Re-using CustomAsyncImage
            CustomAsyncImage(url: item.imageURL)
                .frame(width: 124, height: 100)
                .cornerRadius(8)
                .clipped()
            
            Text(item.title)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            HStack {
                Text(item.price?.formatted(.currency(code: "USD")) ?? "")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { onAdd(item) }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.black)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 140)
        .padding(8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}
