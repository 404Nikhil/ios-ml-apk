//
//  WSTabView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

struct WSTabView: View {    
    @EnvironmentObject var viewModel: WSTabBarViewModel
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var registryRepository: RegistryRepository
    
    init() {
        // Override the default red badge to match the black & white theme
        let badgeAppearance = UITabBarItemAppearance()
        badgeAppearance.normal.badgeBackgroundColor = .black
        badgeAppearance.normal.badgeTextAttributes = [.foregroundColor: UIColor.white]
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.stackedLayoutAppearance = badgeAppearance
        tabBarAppearance.inlineLayoutAppearance = badgeAppearance
        tabBarAppearance.compactInlineLayoutAppearance = badgeAppearance
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            ForEach(viewModel.tabs, id: \.rawValue) { tab in
                view(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
                    .badge(tab == .cart ? (viewModel.cartItemCount > 0 ? viewModel.cartItemCount : 0) : 0)
            }
        }
        .tint(.black)
    }
    
    @ViewBuilder
    private func view(for tab: TabItem) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .registry:
            RegistryView()
        case .cart:
            CartView()
        }
    }
}

#Preview {
    WSTabView()
}
