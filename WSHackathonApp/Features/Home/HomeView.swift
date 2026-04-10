//
//  HomeView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

// MARK: - Williams-Sonoma Color Palette
private extension Color {
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
    @State private var showFilterSheet = false
    
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
                            
                            // MARK: - Smart Filters
                            if !viewModel.suggestedFilters.isEmpty || !viewModel.selectedFilters.isEmpty {
                                FilterChipsView(
                                    suggestedFilters: viewModel.suggestedFilters,
                                    selectedFilters: $viewModel.selectedFilters,
                                    onSelect: { viewModel.applyFilter($0) },
                                    onDeselect: { viewModel.removeFilter($0) }
                                )
                                .padding(.top, 16)
                            }
                            
                            // MARK: - Hero Banner
                            heroBannerSection
                                .padding(.top, 16)
                            
                            // MARK: - Category Pills
                            categoryPillsSection
                                .padding(.top, 20)
                            
                            // MARK: - Trending Now
                            if viewModel.selectedCategory == nil && viewModel.searchText.isEmpty {
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
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBarSection: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(.systemGray2))
                
                TextField(AppStrings.Home.searchPlaceHolder, text: $viewModel.searchText)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
            
            // Filter Button
            Button {
                showFilterSheet = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.wsDark)
                        .frame(width: 42, height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        )
                    
                    // Active filter badge
                    if viewModel.filterState.activeFilterCount > 0 {
                        Text("\(viewModel.filterState.activeFilterCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(Color.wsGold))
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .sheet(isPresented: $showFilterSheet) {
            ProductFilterSheet(
                filterState: $viewModel.filterState,
                availableTypes: viewModel.availableProductTypes,
                priceBounds: viewModel.priceBounds,
                onApply: { /* filters applied via binding */ }
            )
            .presentationDetents([.large])
        }
    }
    
    // MARK: - Hero Banner
    
    private var heroBannerSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.wsDark, Color.wsDark.opacity(0.85)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 170)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(.wsGold)
                    Text("AI-POWERED SHOPPING")
                        .font(.system(size: 10, weight: .bold))
                        .kerning(1.5)
                        .foregroundColor(.wsGold)
                }
                
                Text("Smart Cart\nRecommendations")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineSpacing(2)
                
                Text("Personalized picks just for you")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(20)
            
            // Decorative circles
            Circle()
                .fill(Color.wsGold.opacity(0.1))
                .frame(width: 120, height: 120)
                .offset(x: 260, y: -80)
            
            Circle()
                .fill(Color.wsGold.opacity(0.06))
                .frame(width: 80, height: 80)
                .offset(x: 300, y: -20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: showContent)
    }
    
    // MARK: - Category Pills
    
    private var categoryPillsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HomeViewModel.categories) { category in
                    let isSelected: Bool = {
                        if !viewModel.debouncedSearchText.isEmpty {
                            // While searching, 'All' is the only active selection (keywords are empty)
                            return category.keywords.isEmpty
                        } else {
                            // Standard category selection logic
                            return (viewModel.selectedCategory == nil && category.keywords.isEmpty)
                                || (viewModel.selectedCategory?.name == category.name)
                        }
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
                    
                    if viewModel.filterState.activeFilterCount > 0 {
                        Text("• \(viewModel.filterState.activeFilterCount) filter\(viewModel.filterState.activeFilterCount > 1 ? "s" : "")")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.wsGold)
                    }
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
                                registryQuantity: viewModel.registryQuantity(for: product),
                                onAdd: { viewModel.addToCart(product) },
                                onRemove: { viewModel.removeFromCart(product) },
                                onAddToRegistry: {
                                    if viewModel.canAddToRegistry(product) {
                                        viewModel.addToRegistry(product)
                                    } else {
                                        tabBarVM.selectTab(.registry)
                                    }
                                },
                                onRemoveFromRegistry: { viewModel.removeFromRegistry(product) }
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
