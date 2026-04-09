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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                if viewModel.isEmptyCart {
                    // --- THE EMPTY STATE (TRENDING ITEMS) ---
                    ScrollView {
                        VStack(spacing: 20) {
                            Image(systemName: "cart")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                            
                            Text(AppStrings.Cart.emptyMessage)
                                .font(.title2).fontWeight(.bold)
                            
                            Text("Check out what's trending right now:")
                                .foregroundColor(.secondary)
                            
                            // Reusing ProductCardView
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(viewModel.trendingItems) { item in
                                    ProductCardView(
                                        product: item,
                                        quantity: viewModel.quantity(for: item),
                                        registryQuantity: 0,
                                        onAdd: { viewModel.addToCart(item) },
                                        onRemove: { viewModel.removeFromCart(item) },
                                        onAddToRegistry: { },
                                        onRemoveFromRegistry: { }
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    // --- THE SMART CART STATE ---
                    VStack(spacing: 0) {
                        List {
                            // 1. The Main Cart Items
                            Section {
                                ForEach(viewModel.items) { cartItem in
                                    CartItemRow(
                                        item: cartItem,
                                        onAdd: { viewModel.add(cartItem) },
                                        onRemove: { viewModel.removeItem(cartItem) }
                                    )
                                    // NATIVE SWIPE TO DELETE
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation { viewModel.removeItem(cartItem) }
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            
                            // 2. Smart ML Recommendations (dynamic sections from backend)
                            Section {
                                SmartRecommendationsView(
                                    cartItems: viewModel.items.map { (id: $0.id, title: $0.title) },
                                    onAdd: { recItem in
                                        withAnimation(.spring()) {
                                            viewModel.addToCart(recItem.asProductItem())
                                        }
                                    }
                                )
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
        }
        .onAppear {
            Task {
                viewModel.bind(repository: cartRepository)
                viewModel.fetchInitialData()
            }
        }
    }
}
