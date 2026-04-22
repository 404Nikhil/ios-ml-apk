

import Foundation
import Combine
import SwiftUI

@MainActor
class WSTabBarViewModel: ObservableObject {
    
    @Published var selectedTab: TabItem = .home
    @Published var cartItemCount: Int = 0
    @Published var registryPath: [RegistryRoute] = []
    
    private var cancellable: AnyCancellable?
    
    var tabs: [TabItem] {
        TabItem.allCases
    }
    
    /// Call once from the root view to keep the cart badge in sync.
    func bind(cartRepository: CartRepository) {
        // Update immediately
        cartItemCount = cartRepository.totalItems
        
        // Subscribe to future changes
        cancellable = cartRepository.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.cartItemCount = items.reduce(0) { $0 + $1.quantity }
            }
    }
    
    func selectTab(_ tab: TabItem) {
        selectedTab = tab
    }
    
    func goToRegistrySuccess() {
        registryPath.append(.success)
    }
    
    func resetRegistryFlow() {
        registryPath.removeAll()
    }
}
