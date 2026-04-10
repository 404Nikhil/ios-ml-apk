//
//  CartRepository.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Foundation
import Combine

@MainActor
final class CartRepository: ObservableObject {
    
    private let storageKey = "ws_hackathon_cart_items"
    
    @Published private(set) var items: [CartItem] = [] {
        didSet {
            saveCart()
        }
    }
    
    var toastManager: ToastManager?
    
    init() {
        loadCart()
    }
    
    private func saveCart() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save cart: \(error)")
        }
    }
    
    private func loadCart() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let savedItems = try JSONDecoder().decode([CartItem].self, from: data)
            self.items = savedItems
        } catch {
            print("Failed to load cart: \(error)")
        }
    }
    
    // MARK: - Add Item
    func add(product: ProductItem, quantity: Int = 1) {
        guard let priceValue = product.price else { return }
        
        if let index = items.firstIndex(where: { $0.id == product.id }) {
            items[index].quantity += 1
        } else {
            let newItem = CartItem(
                id: product.id,
                title: product.title,
                price: priceValue,
                path: product.path,
                quantity: quantity
            )
            items.append(newItem)
        }
        
        // Trigger Toast
        toastManager?.show(message: "Added to Cart")
    }
    
    // MARK: - Remove Item
    func remove(productId: String) {
        guard let index = items.firstIndex(where: { $0.id == productId }) else { return }
        if items[index].quantity > 1 {
            items[index].quantity -= 1
        } else {
            items.remove(at: index)
        }
    }
    
    func deleteEntirely(productId: String) {
        items.removeAll(where: { $0.id == productId })
    }
    
    // MARK: - Clear Entire Cart
    func clearAll() {
        items.removeAll()
    }
    
    // MARK: - Total Price
    var totalPrice: Double {
        items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    // MARK: - Total Count
    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    func increaseQuantity(productId: String) {
        guard let index = items.firstIndex(where: { $0.id == productId }) else { return }
        items[index].quantity += 1
    }
}
