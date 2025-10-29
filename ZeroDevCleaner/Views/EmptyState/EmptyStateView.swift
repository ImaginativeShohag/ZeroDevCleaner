//
//  EmptyStateView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct EmptyStateView: View {
    let onSelectFolder: () -> Void
    let onFolderDropped: (URL) -> Void

    @State private var isDropTargeted = false

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

                Text("or drag & drop a folder here")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Button(action: onSelectFolder) {
                Label("Select Folder", systemImage: "folder")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDropTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color.clear,
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .padding(20)
        )
        .dropDestination(for: URL.self) { items, location in
            guard let url = items.first else { return false }

            // Verify it's a directory
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                return false
            }

            onFolderDropped(url)
            return true
        } isTargeted: { isTargeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                isDropTargeted = isTargeted
            }
        }
    }
}

#Preview {
    EmptyStateView(
        onSelectFolder: {},
        onFolderDropped: { _ in }
    )
}
