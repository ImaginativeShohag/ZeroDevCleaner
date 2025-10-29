//
//  EmptyStateView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct EmptyStateView: View {
    let selectedFolder: URL?
    let onSelectFolder: () -> Void
    let onFolderDropped: (URL) -> Void
    let onStartScan: () -> Void

    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 24) {
            if let folder = selectedFolder {
                // Folder selected - ready to scan
                Image(systemName: "folder.fill.badge.checkmark")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)

                VStack(spacing: 8) {
                    Text("Folder Selected")
                        .font(.title)
                        .fontWeight(.semibold)

                    Text(folder.lastPathComponent)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(folder.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                HStack(spacing: 12) {
                    Button(action: onSelectFolder) {
                        Label("Change Folder", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)

                    Button(action: onStartScan) {
                        Label("Start Scan", systemImage: "play.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            } else {
                // No folder selected - initial state
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
        selectedFolder: nil,
        onSelectFolder: {},
        onFolderDropped: { _ in },
        onStartScan: {}
    )
}
