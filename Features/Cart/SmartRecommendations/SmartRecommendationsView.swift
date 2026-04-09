//
//  SmartRecommendationsView.swift
//  WSHackathonApp
//
//  Dynamically renders ALL recommendation sections returned by the ML API.
//  Each section title and items come directly from the server — nothing is hardcoded.
//

import SwiftUI

// MARK: - Main Smart Recommendations View

/// Drop this anywhere in your cart UI. Pass cartItems (id + title) and onAdd closure.
struct SmartRecommendationsView: View {
    /// Full cart items — titles are used to keyword-map to intcart product types.
    let cartItems: [(id: String, title: String)]
    var onAdd: (RecommendationItem) -> Void

    @State private var sections: [RecommendationSection] = []
    @State private var isLoading = true
    @State private var hasError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoading {
                // Show skeleton for each typical section (3 sections, 3 cards each)
                ForEach(0..<3, id: \.self) { _ in
                    RecommendationSkeletonSection()
                }
            } else if hasError {
                // Graceful error — don't crash the cart UI
                EmptyView()
            } else {
                ForEach(sections) { section in
                    if !section.items.isEmpty {
                        RecommendationSectionView(section: section, onAdd: onAdd)
                    }
                }
            }
        }
        .task(id: cartItems.map(\.id).joined()) {
            await loadRecommendations()
        }
    }

    private func loadRecommendations() async {
        guard !cartItems.isEmpty else {
            isLoading = false
            return
        }
        isLoading = true
        hasError = false
        let intcartIds = RecommendationService.shared.resolvedIntcartIds(from: cartItems)
        do {
            let response = try await RecommendationService.shared.fetchRecommendations(for: intcartIds)
            withAnimation(.easeInOut(duration: 0.4)) {
                sections = response.sections
                isLoading = false
            }
        } catch {
            print("⚠️ Recommendations failed:", error.localizedDescription)
            withAnimation {
                isLoading = false
                hasError = true
            }
        }
    }
}

// MARK: - Single Section View

private struct RecommendationSectionView: View {
    let section: RecommendationSection
    var onAdd: (RecommendationItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Section header with decorative accent
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black)
                    .frame(width: 3, height: 16)

                Text(section.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)

            // Horizontal scroll of product cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(section.items) { item in
                        RecommendationProductCard(item: item, onAdd: onAdd)
                            // Drag-and-drop support
                            .draggable(item) {
                                RecommendationProductCard(item: item, onAdd: { _ in })
                                    .frame(width: 130, height: 170)
                                    .opacity(0.85)
                                    .scaleEffect(0.95)
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }
}

// MARK: - Product Card

private struct RecommendationProductCard: View {
    let item: RecommendationItem
    var onAdd: (RecommendationItem) -> Void

    @State private var addedToCart = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Image area
            RecommendationImageView(url: item.imageURL)
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Name + Price + Add button
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(alignment: .center) {
                    Text(item.priceText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    // + Add button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            addedToCart = true
                            onAdd(item)
                        }
                        // Reset checkmark after 1.5s
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { addedToCart = false }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(addedToCart ? Color.green : Color.black)
                                .frame(width: 26, height: 26)

                            Image(systemName: addedToCart ? "checkmark" : "plus")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.borderless)
                    .scaleEffect(addedToCart ? 1.15 : 1.0)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(width: 148)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Image with shimmer fallback

private struct RecommendationImageView: View {
    let url: URL?

    @StateObject private var loader = CustomImageLoader()
    @State private var loadFailed = false

    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity.animation(.easeIn(duration: 0.3)))
            } else if loader.hasFailed || url == nil {
                // Shimmer placeholder for failed/missing images
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 22))
                            .foregroundColor(Color(.systemGray3))
                    )
                    .shimmering()
            } else {
                // Loading state — shimmering grey
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .shimmering()
            }
        }
        .onAppear { loader.load(url: url) }
    }
}

// MARK: - Skeleton Section (Loading State)

private struct RecommendationSkeletonSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Skeleton header
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray5))
                    .frame(width: 3, height: 16)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(width: 180, height: 14)
                    .shimmering()
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)

            // 3 skeleton cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonProductCard()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }
}

private struct SkeletonProductCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray5))
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .shimmering()

            VStack(alignment: .leading, spacing: 6) {
                // Name placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 90, height: 10)
                    .shimmering()

                // Price placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 50, height: 10)
                    .shimmering()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }
        .frame(width: 148)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
