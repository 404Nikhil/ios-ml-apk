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
                    // Combine selected plus remaining suggested
                    let active = Array(selectedFilters).sorted(by: { $0.title < $1.title })
                    let remaining = suggestedFilters.filter { !selectedFilters.contains($0) }
                    
                    ForEach(active) { filter in
                        FilterChip(
                            filter: filter,
                            isSelected: true,
                            onTap: { onDeselect(filter) }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    ForEach(remaining) { filter in
                        FilterChip(
                            filter: filter,
                            isSelected: false,
                            onTap: { onSelect(filter) }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 36)
            .animation(.easeInOut(duration: 0.2), value: selectedFilters)
            .animation(.easeInOut(duration: 0.2), value: suggestedFilters)
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
            HStack(spacing: 4) {
                Text(filter.title)
                    .font(.system(size: 13, weight: .medium))
                
                if isSelected {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                }
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
