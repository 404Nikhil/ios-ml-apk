//
//  CartView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

struct CartView: View {
    @StateObject private var viewModel = CartViewModel()
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    @State private var showClearConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                if viewModel.isEmptyCart {
                    // --- PREMIUM EMPTY STATE ---
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            
                            // 1. Stylized Empty State Illustration
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 100, height: 100)
                                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                                    
                                    Image(systemName: "bag.badge.plus")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                }
                                .padding(.top, 40)
                                
                                Text(AppStrings.Cart.emptyMessage)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.center)
                                
                                Text("Your cart is waiting to be filled with great products.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }

                            // 2. Trending Header (Consistent with Smart Recommendations)
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.black)
                                    .frame(width: 3, height: 16)
                                
                                Text("TRENDING NOW")
                                    .font(.system(size: 14, weight: .bold))
                                    .kerning(1.2)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            // 3. Trending Items Grid
                            if viewModel.isTrendingLoading {
                                // Skeletal Loading Grid
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                    ForEach(0..<4, id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray5))
                                            .frame(height: 220)
                                            .shimmering()
                                    }
                                }
                                .padding(.horizontal)
                            } else {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                    ForEach(viewModel.trendingItems.prefix(10)) { item in
                                        NavigationLink(destination: ProductDetailView(
                                            product: item,
                                            allProducts: viewModel.trendingItems
                                        )) {
                                            ProductCardView(
                                                product: item,
                                                quantity: viewModel.quantity(for: item),
                                                registryQuantity: 0,
                                                onAdd: { 
                                                    withAnimation(.spring()) {
                                                        viewModel.addToCart(item) 
                                                    }
                                                },
                                                onRemove: { viewModel.removeFromCart(item) },
                                                onAddToRegistry: { },
                                                onRemoveFromRegistry: { }
                                            )
                                            .transition(.scale.combined(with: .opacity))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            Spacer(minLength: 40)
                        }
                    }
                } else {
                    // --- THE SMART CART STATE ---
                    VStack(spacing: 0) {
                        List {
                            // 1. The Main Cart Items
                            Section {
                                ForEach(viewModel.items) { cartItem in
                                    NavigationLink(destination: ProductDetailView(
                                        product: ProductItem(id: cartItem.id, title: cartItem.title, price: cartItem.price, path: cartItem.imageURL?.absoluteString, brand: nil, productType: nil),
                                        allProducts: viewModel.trendingItems
                                    )) {
                                        CartItemRow(
                                            item: cartItem,
                                            onAdd: { viewModel.add(cartItem) },
                                            onRemove: { viewModel.removeItem(cartItem) },
                                            onDelete: {
                                                withAnimation { viewModel.deleteItem(cartItem) }
                                            }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation { viewModel.deleteItem(cartItem) }
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            
                            // 2. Bundle Offer
                            if let bundle = viewModel.bundleOffer {
                                Section {
                                    CompactBundleOfferView(
                                        bundle: bundle,
                                        onAddBundle: { items in
                                            withAnimation(.spring()) {
                                                viewModel.addBundleToCart(items)
                                            }
                                        }
                                    )
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            
                            // 3. Smart ML Recommendations (dynamic sections from backend)
                            Section {
                                SmartRecommendationsView(
                                    cartItems: viewModel.items.map { (id: $0.id, title: $0.title) },
                                    onAdd: { recItem in
                                        withAnimation(.spring()) {
                                            viewModel.addToCart(recItem.asProductItem())
                                        }
                                    }
                                )
                                .id("ML_Recommendations")
                                .listRowInsets(EdgeInsets())
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        // THE MAGIC: Drop destination for the dragged items
                        .dropDestination(for: ProductItem.self) { droppedItems, _ in
                            for item in droppedItems {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    viewModel.addToCart(item)
                                }
                            }
                            return true
                        }
                        .dropDestination(for: RecommendationItem.self) { droppedItems, _ in
                            for item in droppedItems {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    viewModel.addToCart(item.asProductItem())
                                }
                            }
                            return true
                        }
                        
                        // 3. Floating Bottom Total View
                        VStack(spacing: 12) {
                            HStack {
                                Text(AppStrings.Cart.total)
                                    .font(.headline)
                                Spacer()
                                Text(viewModel.totalPriceText)
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            
                            Button(action: {
                                // TODO: - Implement checkout flow
                            }) {
                                Text(AppStrings.Cart.checkoutButton)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16.0)
                        .padding(.horizontal)
                        .padding(.bottom)
                        .shadow(color: Color(.black).opacity(0.1), radius: 10, x: 0, y: -5)
                    }
                }
            }
            .navigationTitle(AppStrings.Cart.title)
            .toolbar {
                if !viewModel.isEmptyCart {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            Label("Empty Cart", systemImage: "trash")
                                .labelStyle(.iconOnly)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .confirmationDialog(
                "Empty your cart?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove All Items", role: .destructive) {
                    viewModel.clearCart()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove all \(viewModel.items.count) item\(viewModel.items.count == 1 ? "" : "s") from your cart.")
            }
        }
        .onAppear {
            Task {
                viewModel.bind(repository: cartRepository)
                viewModel.fetchInitialData()
            }
        }
        .onChange(of: viewModel.items.count) { _, _ in
            viewModel.buildBundleFromCart()
        }
        .onChange(of: viewModel.isTrendingLoading) { _, isLoading in
            if !isLoading {
                viewModel.buildBundleFromCart()
            }
        }
    }
}
