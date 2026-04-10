//
//  ProductFilterSheet.swift
//  WSHackathonApp
//
//  A premium bottom-sheet filter UI matching the Williams-Sonoma
//  editorial design language (wsIvory, wsDark, wsGold).
//

import SwiftUI

// Removed duplicate color extension since it's now internal to the app module.

struct ProductFilterSheet: View {
    
    @Binding var filterState: ProductFilterState
    let availableTypes: [String]
    let priceBounds: ClosedRange<Double>
    var onApply: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // Local working copy so user can cancel without side-effects
    @State private var workingState: ProductFilterState
    
    init(filterState: Binding<ProductFilterState>,
         availableTypes: [String],
         priceBounds: ClosedRange<Double>,
         onApply: @escaping () -> Void) {
        self._filterState = filterState
        self.availableTypes = availableTypes
        self.priceBounds = priceBounds
        self.onApply = onApply
        self._workingState = State(initialValue: filterState.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    
                    // MARK: - Sort By
                    sortSection
                    
                    divider
                    
                    // MARK: - Price Range
                    priceRangeSection
                    
                    divider
                    
                    // MARK: - Product Type
                    productTypeSection
                    
                    Spacer(minLength: 80)
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
            }
            .background(Color.wsIvory.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("FILTERS")
                            .font(.system(size: 14, weight: .bold))
                            .kerning(2)
                            .foregroundColor(.wsDark)
                        Rectangle()
                            .fill(Color.wsGold)
                            .frame(width: 24, height: 1.5)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                footerButtons
            }
        }
    }
    
    // MARK: - Sort Section
    
    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "SORT BY", icon: "arrow.up.arrow.down")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SortOption.allCases) { option in
                        let isActive = workingState.sortOption == option
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                workingState.sortOption = option
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: option.icon)
                                    .font(.system(size: 11, weight: .semibold))
                                Text(option.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(isActive ? .white : .wsDark)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(isActive ? Color.wsDark : Color.white)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isActive ? Color.clear : Color(.systemGray4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Price Range Section
    
    private var priceRangeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "PRICE RANGE", icon: "dollarsign.circle")
            
            VStack(spacing: 16) {
                // Price labels
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MIN")
                            .font(.system(size: 9, weight: .bold))
                            .kerning(1)
                            .foregroundColor(.secondary)
                        Text("$\(Int(workingState.minPrice))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.wsDark)
                    }
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 30, height: 1)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("MAX")
                            .font(.system(size: 9, weight: .bold))
                            .kerning(1)
                            .foregroundColor(.secondary)
                        Text("$\(Int(workingState.maxPrice))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.wsDark)
                    }
                }
                
                // Sliders
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text("$\(Int(priceBounds.lowerBound))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Slider(
                            value: $workingState.minPrice,
                            in: priceBounds.lowerBound...workingState.maxPrice,
                            step: 50
                        )
                        .tint(Color.wsGold)
                        
                        Text("$\(Int(workingState.maxPrice))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Text("$\(Int(workingState.minPrice))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Slider(
                            value: $workingState.maxPrice,
                            in: workingState.minPrice...priceBounds.upperBound,
                            step: 50
                        )
                        .tint(Color.wsGold)
                        
                        Text("$\(Int(priceBounds.upperBound))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Product Type Section
    
    private var productTypeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "PRODUCT TYPE", icon: "tag")
            
            if availableTypes.isEmpty {
                Text("No types available")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(availableTypes, id: \.self) { type in
                        let isActive = workingState.selectedTypes.contains(type)
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if isActive {
                                    workingState.selectedTypes.remove(type)
                                } else {
                                    workingState.selectedTypes.insert(type)
                                }
                            }
                        } label: {
                            HStack(spacing: 5) {
                                if isActive {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                Text(type)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(isActive ? .white : .wsDark)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(isActive ? Color.wsDark : Color.white)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isActive ? Color.clear : Color(.systemGray4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Footer Buttons
    
    private var footerButtons: some View {
        HStack(spacing: 12) {
            // Reset
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    workingState.reset()
                }
            } label: {
                Text("Reset All")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.wsDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
            
            // Apply
            Button {
                filterState = workingState
                onApply()
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 14))
                    Text("Apply Filters")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wsDark)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color.wsIvory
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: -3)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Shared Components
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.wsGold)
                .frame(width: 3, height: 16)
            
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.wsGold)
            
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .kerning(1.5)
                .foregroundColor(.wsDark)
        }
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 1)
    }
}

// MARK: - Flow Layout (wrapping HStack for chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layoutSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layoutSubviews(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            guard index < result.positions.count else { continue }
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x,
                                       y: bounds.minY + position.y),
                          proposal: .unspecified)
        }
    }
    
    private func layoutSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}
