//
//  CustomAsyncImage.swift
//  WSHackathonApp
//

import SwiftUI

struct CustomAsyncImage: View {    
    let url: URL?
    @StateObject private var loader = CustomImageLoader()
    
    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if loader.hasFailed || url == nil {
                // Show a clean placeholder on error or missing URL
                ZStack {
                    Color(.systemGray5)
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(Color(.systemGray3))
                }
            } else {
                ZStack {
                    Color(.systemGray5)
                    ProgressView()
                }
            }
        }
        .onAppear {
            loader.load(url: url)
        }
    }
}
