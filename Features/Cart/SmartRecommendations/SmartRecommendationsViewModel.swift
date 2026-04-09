//
//  SmartRecommendationsViewModel.swift
//  WSHackathonApp
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SmartRecommendationsViewModel: ObservableObject {
    @Published var sections: [RecommendationSection] = []
    @Published var isLoading = false
    @Published var hasError = false
    
    private var cancellables = Set<AnyCancellable>()
    private let cartUpdateSubject = PassthroughSubject<[(id: String, title: String)], Never>()
    
    init() {
        setupDebounce()
    }
    
    // MARK: - API flow
    
    /// Called by the View when cart items change.
    func cartDidUpdate(_ items: [(id: String, title: String)]) {
        // If it's the very first load or cart became empty, handle immediately
        if sections.isEmpty || items.isEmpty {
            performUpdate(items)
        } else {
            // Otherwise, queue for debounced refresh
            cartUpdateSubject.send(items)
        }
    }
    
    private func setupDebounce() {
        cartUpdateSubject
            .debounce(for: .milliseconds(600), scheduler: RunLoop.main)
            .sink { [weak self] items in
                self?.performUpdate(items)
            }
            .store(in: &cancellables)
    }
    
    private func performUpdate(_ items: [(id: String, title: String)]) {
        Task {
            await loadRecommendations(cartItems: items)
        }
    }
    
    private func loadRecommendations(cartItems: [(id: String, title: String)]) async {
        guard !cartItems.isEmpty else {
            withAnimation {
                sections = []
                isLoading = false
            }
            return
        }
        
        // ONLY show loading shimmer if we don't have any content yet.
        // This is the key to 'Seamless' updates.
        if sections.isEmpty {
            isLoading = true
        }
        
        hasError = false
        
        let intcartIds = RecommendationService.shared.resolvedIntcartIds(from: cartItems)
        
        do {
            let response = try await RecommendationService.shared.fetchRecommendations(for: intcartIds)
            
            withAnimation(.easeInOut(duration: 0.4)) {
                self.sections = response.sections
                self.isLoading = false
            }
        } catch {
            print("⚠️ Recommendations silent refresh failed:", error.localizedDescription)
            // If we already have sections, don't show error state, just keep what we have.
            if sections.isEmpty {
                withAnimation {
                    self.isLoading = false
                    self.hasError = true
                }
            }
        }
    }
}
