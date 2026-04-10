//
//  FilterChipsView.swift
//  WSHackathonApp
//

import SwiftUI

struct FilterChipsView: View {
    let suggestedFilters: [FilterOption]
    @Binding var selectedFilters: Set<FilterOption>
    var onSelect: (FilterOption) -> Void
    var onDeselect: (FilterOption) -> Void
    
    var body: some View {
        if suggestedFilters.isEmpty && selectedFilters.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    let sortedFilters = suggestedFilters.sorted { (f1, f2) -> Bool in
                        let s1 = selectedFilters.contains(f1)
                        let s2 = selectedFilters.contains(f2)
                        // Selected items go first
                        if s1 && !s2 { return true }
                        if !s1 && s2 { return false }
                        // Then sort alphabetically
                        return f1.title < f2.title
                    }
                    
                    ForEach(sortedFilters) { filter in
                        let isSelected = selectedFilters.contains(filter)
                        FilterChip(
                            filter: filter,
                            isSelected: isSelected,
                            onTap: {
                                if isSelected {
                                    onDeselect(filter)
                                } else {
                                    onSelect(filter)
                                }
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 36)
            .animation(.easeInOut(duration: 0.2), value: selectedFilters)
        }
    }
}

struct FilterChip: View {
    let filter: FilterOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onTap()
            }
        }) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
                
                Text(filter.title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Color(red: 0.133, green: 0.110, blue: 0.090)) // wsDark
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color(red: 0.133, green: 0.110, blue: 0.090) : Color.white)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
