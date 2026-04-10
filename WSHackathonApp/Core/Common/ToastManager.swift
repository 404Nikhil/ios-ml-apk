//
//  ToastManager.swift
//  WSHackathonApp
//

import Foundation
import SwiftUI
import Combine

class ToastManager: ObservableObject {
    @Published var isShowing: Bool = false
    @Published var message: String = ""
    
    private var dismissTask: Task<Void, Never>?
    
    func show(message: String) {
        // Cancel any pending dismiss task
        dismissTask?.cancel()
        
        self.message = message
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            self.isShowing = true
        }
        
        // Auto-dismiss after 2 seconds
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.3)) {
                    self.isShowing = false
                }
            }
        }
    }
}
