//
//  CustomImageLoader.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import SwiftUI
import Combine

final class CustomImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var hasFailed = false
    
    private var hasLoaded = false
    
    func load(url: URL?) {
        guard !hasLoaded else { return }
        guard let url else {
            hasFailed = true
            return
        }
        hasLoaded = true
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let img = UIImage(data: data) {
                    await MainActor.run {
                        self.image = img
                    }
                } else {
                    await MainActor.run {
                        self.hasFailed = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.hasFailed = true
                }
            }
        }
    }
}
