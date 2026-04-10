//
//  HomeView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

// MARK: - Williams-Sonoma Color Palette
extension Color {
    static let wsIvory = Color(red: 0.976, green: 0.965, blue: 0.945)      // #F9F6F1
    static let wsGold  = Color(red: 0.745, green: 0.643, blue: 0.459)      // #BEA475
    static let wsDark  = Color(red: 0.133, green: 0.110, blue: 0.090)      // #221C17
}

struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var registryRepository: RegistryRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    @State private var showContent = false
    @State private var showSearch = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.wsIvory
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        if viewModel.isLoading {
                            loadingSkeletonView
                        } else {
                            // MARK: - Search Bar
                            searchBarSection
                                .padding(.top, 4)
                            

                            // MARK: - Category Pills
                            categoryPillsSection
                                .padding(.top, 20)
                            
                            // MARK: - Trending Now
                            if viewModel.selectedCategory == nil {
                                trendingSection
                                    .padding(.top, 24)
                            }
                            
                            // MARK: - Products Grid
                            productsGridSection
                                .padding(.top, 24)
                            
                            Spacer(minLength: 30)
                        }
                    }
                }
                .refreshable {
                    await viewModel.refreshProducts()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("WILLIAMS SONOMA")
                            .font(.system(size: 16, weight: .bold))
                            .kerning(2.5)
                            .foregroundColor(.wsDark)
                        
                        Rectangle()
                            .fill(Color.wsGold)
                            .frame(width: 40, height: 1.5)
                    }
                }
            }
            .onAppear {
                viewModel.bind(
                    cartRepository: cartRepository,
                    registryRepository: registryRepository
                )
                Task {
                    await viewModel.fetchProducts()
                    withAnimation(.easeOut(duration: 0.5)) {
                        showContent = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showSearch) {
                SearchOverlayView(
                    allProducts: viewModel.products,
                    trendingProducts: viewModel.trendingProducts
                )
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBarSection: some View {
        Button {
            showSearch = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(.systemGray2))
                
                Text(AppStrings.Home.searchPlaceHolder)
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray3))
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
    

    // MARK: - Category Pills
    
    private var categoryPillsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HomeViewModel.categories) { category in
                    let isSelected: Bool = {
                        // Standard category selection logic
                        return (viewModel.selectedCategory == nil && category.keywords.isEmpty)
                            || (viewModel.selectedCategory?.name == category.name)
                    }()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectCategory(category)
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12, weight: .medium))
                            Text(category.name)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(isSelected ? .white : .wsDark)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.wsDark : Color.white)
                        )
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .opacity(showContent ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
    }
    
    // MARK: - Trending Now Section
    
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section Header
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.wsGold)
                    .frame(width: 3, height: 18)
                
                Text("TRENDING NOW")
                    .font(.system(size: 13, weight: .bold))
                    .kerning(1.5)
                    .foregroundColor(.wsDark)
                
                Spacer()
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.wsGold)
            }
            .padding(.horizontal, 16)
            
            // Horizontal Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.trendingProducts) { product in
                        NavigationLink(destination: ProductDetailView(
                            product: product,
                            allProducts: viewModel.products
                        )) {
                            TrendingProductCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)
    }
    
    // MARK: - Products Grid
    
    private var productsGridSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section Header
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.wsGold)
                    .frame(width: 3, height: 18)
                
                Text(viewModel.selectedCategory?.name.uppercased() ?? "SHOP ALL")
                    .font(.system(size: 13, weight: .bold))
                    .kerning(1.5)
                    .foregroundColor(.wsDark)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Text("\(viewModel.filteredProducts.count) items")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.systemGray))
                }
            }
            .padding(.horizontal, 16)
            
            let columns = [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ]
            
            if viewModel.filteredProducts.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundColor(Color(.systemGray3))
                    Text("No products found")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(viewModel.filteredProducts) { product in
                        NavigationLink(destination: ProductDetailView(
                            product: product,
                            allProducts: viewModel.products
                        )) {
                            ProductCardView(
                                product: product,
                                quantity: viewModel.quantity(for: product),
                                onAdd: { viewModel.addToCart(product) },
                                onRemove: { viewModel.removeFromCart(product) }
                            )
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 16)
                .id("Grid-\(viewModel.selectedCategory?.name ?? "All")") // Stabilize layout across filters
            }
        }
        .opacity(showContent ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: viewModel.filteredProducts)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)
    }
    
    // MARK: - Loading Skeleton
    
    private var loadingSkeletonView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Search skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(height: 42)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            
            // Banner skeleton
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray5))
                .frame(height: 170)
                .padding(.horizontal, 16)
            
            // Category pills skeleton
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { _ in
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(width: 90, height: 34)
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Grid skeleton
            let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(height: 180)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(height: 14)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(width: 80, height: 14)
                    }
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Trending Product Card

struct TrendingProductCard: View {
    let product: ProductItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            CustomAsyncImage(url: product.imageURL)
                .frame(width: 150, height: 120)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(height: 32, alignment: .topLeading)
                
                Text(product.price?.formatted(.currency(code: "USD")) ?? "")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(width: 150)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}
