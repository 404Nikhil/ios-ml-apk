//
//  SearchOverlayView.swift
//  WSHackathonApp
//

import SwiftUI

struct SearchOverlayView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var searchVM = SearchViewModel()
    
    // Inject dependencies from HomeView
    let allProducts: [ProductItem]
    let trendingProducts: [ProductItem]
    
    @FocusState private var isSearchFocused: Bool
    @State private var showFilterSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.wsIvory.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    searchHeader
                        .padding(.bottom, 8)
                    
                    if searchVM.hasSearched {
                        SearchResultsContentView(
                            viewModel: searchVM,
                            showFilterSheet: $showFilterSheet
                        )
                    } else {
                        SearchDiscoveryView(viewModel: searchVM)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                searchVM.allProducts = allProducts
                searchVM.trendingProducts = trendingProducts
                if !searchVM.hasSearched {
                    isSearchFocused = true
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            ProductFilterSheet(
                filterState: $searchVM.filterState,
                availableTypes: searchVM.availableProductTypes,
                priceBounds: searchVM.priceBounds,
                onApply: { /* Filters applied via binding */ }
            )
            .presentationDetents([.large])
        }
    }
    
    private var searchHeader: some View {
        HStack(spacing: 12) {
            // Search Input
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(.systemGray2))
                
                TextField("Search products...", text: $searchVM.searchText)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        searchVM.performSearch(searchVM.searchText)
                    }
                
                if !searchVM.searchText.isEmpty {
                    Button {
                        searchVM.clearSearch()
                        isSearchFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(.systemGray3))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
            
            // Cancel Button
            Button("Cancel") {
                dismiss()
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.wsDark)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

struct SearchDiscoveryView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                if !viewModel.searchHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("RECENT SEARCHES")
                                .font(.system(size: 12, weight: .bold))
                                .kerning(1.2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Clear") {
                                viewModel.clearHistory()
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.wsGold)
                        }
                        .padding(.horizontal, 16)
                        
                        ForEach(viewModel.searchHistory, id: \.self) { term in
                            Button {
                                viewModel.performSearch(term)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "clock")
                                        .foregroundColor(Color(.systemGray3))
                                    Text(term)
                                        .font(.system(size: 15))
                                        .foregroundColor(.wsDark)
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .foregroundColor(Color(.systemGray4))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                            Divider().padding(.leading, 42)
                        }
                    }
                    .padding(.top, 16)
                }
                
                // Trending Section inside Discovery
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.wsGold)
                            .frame(width: 3, height: 18)
                        
                        Text("TRENDING SEARCHES")
                            .font(.system(size: 13, weight: .bold))
                            .kerning(1.5)
                            .foregroundColor(.wsDark)
                    }
                    .padding(.horizontal, 16)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(viewModel.trendingProducts) { product in
                                NavigationLink(destination: ProductDetailView(
                                    product: product,
                                    allProducts: viewModel.allProducts
                                )) {
                                    TrendingProductCard(product: product)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, viewModel.searchHistory.isEmpty ? 24 : 0)
            }
            .padding(.bottom, 30)
        }
    }
}
