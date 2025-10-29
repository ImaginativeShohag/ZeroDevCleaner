//
//  EmptyStateView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI

struct EmptyStateView: View {
    let onSelectFolder: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Folder Selected")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Select a folder to scan for build artifacts")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Button(action: onSelectFolder) {
                Label("Select Folder", systemImage: "folder")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(onSelectFolder: {})
}
