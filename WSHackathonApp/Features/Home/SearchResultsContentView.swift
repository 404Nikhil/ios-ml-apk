//
//  SearchResultsContentView.swift
//  WSHackathonApp
//

import SwiftUI

struct SearchResultsContentView: View {
    @ObservedObject var viewModel: SearchViewModel
    @Binding var showFilterSheet: Bool
    
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var registryRepository: RegistryRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                
                // MARK: - Smart Filters
                if !viewModel.suggestedFilters.isEmpty || !viewModel.selectedFilters.isEmpty {
                    FilterChipsView(
                        suggestedFilters: viewModel.suggestedFilters,
                        selectedFilters: $viewModel.selectedFilters,
                        onSelect: { viewModel.applyFilter($0) },
                        onDeselect: { viewModel.removeFilter($0) }
                    )
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }
                
                // MARK: - Product Grid Header
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.wsGold)
                        .frame(width: 3, height: 18)
                    
                    Text("SEARCH RESULTS")
                        .font(.system(size: 13, weight: .bold))
                        .kerning(1.5)
                        .foregroundColor(.wsDark)
                    
                    Spacer()
                    
                    // Filter counts & button
                    HStack(spacing: 12) {
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
                        
                        Button {
                            showFilterSheet = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.wsDark)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 14)
                
                // MARK: - Grid
                let columns = [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ]
                
                if viewModel.filteredProducts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(Color(.systemGray3))
                        Text("No products found for \"\(viewModel.searchText)\"")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 80)
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(viewModel.filteredProducts) { product in
                            NavigationLink(destination: ProductDetailView(
                                product: product,
                                allProducts: viewModel.allProducts
                            )) {
                                ProductCardView(
                                    product: product,
                                    quantity: cartRepository.items.first(where: { $0.id == product.id })?.quantity ?? 0,
                                    onAdd: { cartRepository.add(product: product) },
                                    onRemove: { cartRepository.remove(productId: product.id) }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}
