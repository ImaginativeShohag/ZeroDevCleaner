//
//  QuickFiltersBar.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 31/10/25.
//

import SwiftUI

struct QuickFiltersBar: View {
    @Binding var currentPreset: FilterPreset
    @Binding var showComprehensiveFilters: Bool
    var hasActiveFilters: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text("Quick Filters:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(FilterPreset.allCases, id: \.self) { preset in
                    Button {
                        currentPreset = preset
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: preset.iconName)
                                .font(.system(size: 11))
                            Text(preset.displayName)
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(currentPreset == preset ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                        .foregroundStyle(currentPreset == preset ? Color.white : Color.primary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(currentPreset == preset ? Color.clear : Color(nsColor: .separatorColor), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .buttonHoverEffect()
                    .help(preset.description)
                }

                // Custom button
                Button {
                    showComprehensiveFilters.toggle()
                    // Deselect quick filters when Custom is enabled
                    if showComprehensiveFilters {
                        currentPreset = .all
                    }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        HStack(spacing: 4) {
                            Image(systemName: showComprehensiveFilters ? "slider.horizontal.3" : "slider.horizontal.2.square")
                                .font(.system(size: 11))
                            Text("Custom")
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(showComprehensiveFilters ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                        .foregroundStyle(showComprehensiveFilters ? Color.white : Color.primary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(showComprehensiveFilters ? Color.clear : Color(nsColor: .separatorColor), lineWidth: 0.5)
                        )

                        // Red indicator when filters are active
                        if hasActiveFilters {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: 0)
                        }
                    }
                }
                .buttonStyle(.plain)
                .buttonHoverEffect()
                .help("Show/hide custom size and age filters")
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview("All Selected") {
    @Previewable @State var currentPreset: FilterPreset = .all
    @Previewable @State var showComprehensive: Bool = false
    QuickFiltersBar(currentPreset: $currentPreset, showComprehensiveFilters: $showComprehensive, hasActiveFilters: false)
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(width: 800)
}

#Preview("Large Selected") {
    @Previewable @State var currentPreset: FilterPreset = .large
    @Previewable @State var showComprehensive: Bool = false
    QuickFiltersBar(currentPreset: $currentPreset, showComprehensiveFilters: $showComprehensive, hasActiveFilters: false)
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(width: 800)
}

#Preview("Old Selected") {
    @Previewable @State var currentPreset: FilterPreset = .old
    @Previewable @State var showComprehensive: Bool = false
    QuickFiltersBar(currentPreset: $currentPreset, showComprehensiveFilters: $showComprehensive, hasActiveFilters: true)
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(width: 800)
}
