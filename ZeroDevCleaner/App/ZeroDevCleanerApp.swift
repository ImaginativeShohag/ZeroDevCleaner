//
//  ZeroDevCleanerApp.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI

@main
struct ZeroDevCleanerApp: App {
    var body: some Scene {
        WindowGroup {
            // Placeholder - will be replaced with MainView in Phase 4
            PlaceholderView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

// Temporary placeholder view
struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("ZeroDevCleaner")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Foundation phase complete")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Ready for Phase 2: Core Services")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PlaceholderView()
}
