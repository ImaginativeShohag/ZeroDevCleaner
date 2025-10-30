//
//  EmptyStateView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI

struct EmptyStateView: View {
    let hasConfiguredLocations: Bool
    let onStartScan: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            if hasConfiguredLocations {
                // Has configured locations - ready to scan
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)

                VStack(spacing: 8) {
                    Text("Ready to Scan")
                        .font(.title)
                        .fontWeight(.semibold)

                    Text("Click Scan to find cache files")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Text("System caches and configured locations will be scanned")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Button(action: onStartScan) {
                    Label("Scan", systemImage: "play.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.return, modifiers: .command)
            } else {
                // No locations configured - prompt to add
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    Text("No Scan Locations")
                        .font(.title)
                        .fontWeight(.semibold)

                    Text("Add your projects path in settings")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Text("System caches will be scanned automatically")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Button(action: onOpenSettings) {
                    Label("Open Settings", systemImage: "gear")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("No Locations") {
    EmptyStateView(
        hasConfiguredLocations: false,
        onStartScan: {},
        onOpenSettings: {}
    )
}

#Preview("Has Locations") {
    EmptyStateView(
        hasConfiguredLocations: true,
        onStartScan: {},
        onOpenSettings: {}
    )
}
