//
//  QuickFiltersBar.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 31/10/25.
//

import SwiftUI

struct QuickFiltersBar: View {
    @Binding var currentPreset: FilterPreset

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
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview("All Selected") {
    @Previewable @State var currentPreset: FilterPreset = .all
    QuickFiltersBar(currentPreset: $currentPreset)
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(width: 800)
}

#Preview("Large Selected") {
    @Previewable @State var currentPreset: FilterPreset = .large
    QuickFiltersBar(currentPreset: $currentPreset)
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(width: 800)
}

#Preview("Old Selected") {
    @Previewable @State var currentPreset: FilterPreset = .old
    QuickFiltersBar(currentPreset: $currentPreset)
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(width: 800)
}
