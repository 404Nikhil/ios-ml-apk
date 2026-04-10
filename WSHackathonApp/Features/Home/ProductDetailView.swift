//
//  ProductDetailView.swift
//  WSHackathonApp
//


import SwiftUI

struct ProductDetailView: View {
    
    let product: ProductItem
    let allProducts: [ProductItem]
    
    @StateObject private var viewModel = ProductDetailViewModel()
    
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var registryRepository: RegistryRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    @Namespace private var heroAnimation
    @State private var imageScale: CGFloat = 1.0
    @State private var showContent = false

    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                
                heroImageSection
                
                productInfoSection
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // MARK: - Action Buttons
                actionButtonsSection
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                // MARK: - Product Details Accordion
                productDetailsSection
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                
                Divider()
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // MARK: - Bundle Offer
                if let bundle = viewModel.bundleOffer {
                    BundleOfferView(
                        bundle: bundle,
                        onAddBundle: { items in
                            viewModel.addBundleToCart(items)
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // MARK: - Similar Items
                if !viewModel.similarItems.isEmpty {
                    similarItemsSection
                        .padding(.top, 20)
                }
                
                // MARK: - ML Recommendation Sections (FBT, Complete Your Set)
                if !viewModel.recommendationSections.isEmpty {
                    recommendationsSections
                        .padding(.top, 8)
                }
                
                // Loading state for recommendations
                if viewModel.isRecommendationsLoading {
                    recommendationsSkeletonSection
                        .padding(.top, 8)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGray6))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.bind(cartRepository: cartRepository, registryRepository: registryRepository)
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
            
            Task {
                await viewModel.fetchAllProducts(currentProduct: product)
                await viewModel.fetchRecommendations(for: product)
            }
        }
    }
    
    // MARK: - Hero Image Section
    private var heroImageSection: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let isScrollingUp = minY > 0
            
            CustomAsyncImage(url: product.imageURL)
                .frame(width: geo.size.width, height: isScrollingUp ? 380 + minY : 380)
                .clipped()
                .offset(y: isScrollingUp ? -minY : 0)
                .scaleEffect(isScrollingUp ? 1 + minY / 1000 : 1)
        }
        .frame(height: 380)
    }
    
    // MARK: - Product Info Section
    private var productInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Brand tag
            if let brand = extractBrand() {
                Text(brand.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .kerning(1.5)
                    .foregroundColor(.secondary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: showContent)
            }
            
            // Title
            Text(product.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)
                .animation(.easeOut(duration: 0.4).delay(0.15), value: showContent)
            
            // Price
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(product.price?.formatted(.currency(code: "USD")) ?? "")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                // Free Shipping badge
                HStack(spacing: 4) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 10))
                    Text("Free Shipping")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 15)
            .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
            
            // Availability
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("In Stock")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.green)
            }
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.25), value: showContent)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 10) {
            let qty = viewModel.quantity(for: product)
            
            // Add to Cart
            if qty == 0 {
                Button(action: {
                    viewModel.addToCart(product)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text(AppStrings.Home.addToCartButton)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: showContent)
            } else {
                // Stepper — same pattern as home ProductCardView
                HStack {
                    Text(AppStrings.Cart.title)
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 50, alignment: .leading)
                    
                    Spacer()
                    
                    Button(action: { viewModel.removeFromCart(product) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                    }
                    
                    Text("\(qty)")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 40)
                    
                    Button(action: { viewModel.addToCart(product) }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                .foregroundColor(.black)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color(.systemGray5))
                .cornerRadius(12)
            }
            
            // Add to Registry
            let regQty = viewModel.registryQuantity(for: product)
            
            if regQty == 0 {
                Button(action: {
                    if viewModel.canAddToRegistry(product) {
                        viewModel.addToRegistry(product)
                    } else {
                        tabBarVM.selectTab(.registry)
                        dismiss()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 14, weight: .semibold))
                        Text(AppStrings.Home.addToRegistry)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 1.5)
                    )
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.35), value: showContent)
            } else {
                HStack {
                    Text(AppStrings.Registry.title)
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 70, alignment: .leading)
                    
                    Spacer()
                    
                    Button(action: { viewModel.removeFromRegistry(product) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                    }
                    
                    Text("\(regQty)")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 40)
                    
                    Button(action: { viewModel.addToRegistry(product) }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                .foregroundColor(.black)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color(.systemGray5))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Product Details Section
    private var productDetailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section Header
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black)
                    .frame(width: 3, height: 16)
                
                Text("PRODUCT DETAILS")
                    .font(.system(size: 13, weight: .bold))
                    .kerning(1.2)
                    .foregroundColor(.primary)
            }
            
            // Details grid
            VStack(spacing: 0) {
                if let brand = extractBrand() {
                    detailRow(label: "Brand", value: brand.capitalized)
                }
                if let material = extractMaterial() {
                    detailRow(label: "Material", value: material.replacingOccurrences(of: "-", with: " ").capitalized)
                }
                if let productType = extractProductType() {
                    detailRow(label: "Type", value: productType.replacingOccurrences(of: "-", with: " ").capitalized)
                }
                detailRow(label: "Availability", value: "In Stock")
                detailRow(label: "Shipping", value: "Free Standard Shipping")
                detailRow(label: "Gift Wrap", value: "Available")
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .opacity(showContent ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(
            Divider(), alignment: .bottom
        )
    }
    
    // MARK: - Similar Items Section
    private var similarItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black)
                    .frame(width: 3, height: 16)
                
                Text("SIMILAR ITEMS")
                    .font(.system(size: 13, weight: .bold))
                    .kerning(1.2)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.similarItems) { item in
                        NavigationLink(destination: ProductDetailView(product: item, allProducts: allProducts)) {
                            SimilarItemCard(
                                item: item,
                                quantity: viewModel.quantity(for: item),
                                onAdd: { viewModel.addToCart(item) },
                                onRemove: { viewModel.removeFromCart(item) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - ML Recommendation Sections
    private var recommendationsSections: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel.recommendationSections) { section in
                VStack(alignment: .leading, spacing: 10) {
                    // Section header
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.black)
                            .frame(width: 3, height: 16)
                        
                        Text(section.title.uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .kerning(1.2)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(section.items) { recItem in
                                let productItem = recItem.asProductItem()
                                RecommendationCardForDetail(
                                    item: recItem,
                                    quantity: viewModel.quantity(for: productItem),
                                    onAdd: { viewModel.addToCart(productItem) },
                                    onRemove: { viewModel.removeFromCart(productItem) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
    }
    
    // MARK: - Recommendations Skeleton
    private var recommendationsSkeletonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<2, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray5))
                            .frame(width: 3, height: 16)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(width: 160, height: 12)
                            .shimmering()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 148, height: 160)
                                    .shimmering()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func extractBrand() -> String? {
        // Try to extract brand from the product title
        let brands = ["GreenPan", "All-Clad", "Le Creuset", "Staub", "Wüsthof", "Shun", "Zwilling", "Miyabi",
                       "Williams Sonoma", "Sur La Table", "OXO", "John Boos", "KitchenAid", "Cuisinart"]
        for brand in brands {
            if product.title.localizedCaseInsensitiveContains(brand) {
                return brand
            }
        }
        return nil
    }
    
    private func extractMaterial() -> String? {
        let materials = ["ceramic-nonstick", "hard-anodized", "cast-iron", "stainless-steel", "nonstick",
                          "silicone", "wood", "acacia", "walnut", "maple", "carbon-steel"]
        let titleLower = product.title.lowercased()
        for material in materials {
            if titleLower.contains(material.replacingOccurrences(of: "-", with: " ")) ||
               titleLower.contains(material.replacingOccurrences(of: "-", with: "")) {
                return material
            }
        }
        return nil
    }
    
    private func extractProductType() -> String? {
        let types = ["fry-pan", "skillet", "dutch-oven", "stockpot", "saucepan", "braiser",
                      "knife", "cutting-board", "spatula", "turner", "plate", "bowl",
                      "coffee-table", "sofa", "chair", "table"]
        let titleLower = product.title.lowercased()
        for type in types {
            if titleLower.contains(type.replacingOccurrences(of: "-", with: " ")) {
                return type
            }
        }
        return nil
    }
}

// MARK: - Similar Item Card

struct SimilarItemCard: View {
    let item: ProductItem
    let quantity: Int
    var onAdd: () -> Void
    var onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CustomAsyncImage(url: item.imageURL)
                .frame(width: 155, height: 110)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(height: 32, alignment: .topLeading)
                
                if quantity == 0 {
                    HStack(alignment: .center) {
                        Text(item.price?.formatted(.currency(code: "USD")) ?? "")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: onAdd) {
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 26, height: 26)
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                } else {
                    HStack(spacing: 6) {
                        Button(action: onRemove) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 20))
                        }
                        
                        Text("\(quantity)")
                            .font(.system(size: 14, weight: .bold))
                            .frame(minWidth: 20)
                        
                        Button(action: onAdd) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                        }
                        
                        Spacer()
                    }
                    .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(width: 155)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Recommendation Card For Detail Page

struct RecommendationCardForDetail: View {
    let item: RecommendationItem
    let quantity: Int
    var onAdd: () -> Void
    var onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            CustomAsyncImage(url: item.imageURL)
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if quantity == 0 {
                    HStack(alignment: .center) {
                        Text(item.priceText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: onAdd) {
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 26, height: 26)
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                } else {
                    HStack(spacing: 6) {
                        Button(action: onRemove) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 20))
                        }
                        
                        Text("\(quantity)")
                            .font(.system(size: 14, weight: .bold))
                            .frame(minWidth: 20)
                        
                        Button(action: onAdd) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                        }
                        
                        Spacer()
                    }
                    .foregroundColor(.black)
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
