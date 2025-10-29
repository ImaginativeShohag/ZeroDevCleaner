//
//  DeletionConfirmationView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import SwiftUI

struct DeletionConfirmationView: View {
    let foldersToDelete: [BuildFolder]
    let totalSize: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)

            // Title
            VStack(spacing: 8) {
                Text("Confirm Deletion")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("\(foldersToDelete.count) item\(foldersToDelete.count == 1 ? "" : "s") will be moved to Trash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Item list
            VStack(alignment: .leading, spacing: 12) {
                Text("Items to delete:")
                    .font(.headline)

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(foldersToDelete.prefix(10))) { folder in
                            HStack {
                                Image(systemName: folder.projectType.iconName)
                                    .foregroundStyle(folder.projectType.color)
                                Text(folder.projectName)
                                    .font(.callout)
                                Spacer()
                                Text(folder.formattedSize)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if foldersToDelete.count > 10 {
                            Text("...and \(foldersToDelete.count - 10) more")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    }
                }
                .frame(maxHeight: 200)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Total size
                HStack {
                    Text("Total size:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(totalSize)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Reassurance
            Text("These items will be moved to the Trash and can be restored if needed.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                .controlSize(.large)

                Button("Move to Trash") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            }
        }
        .padding(32)
        .frame(width: 480)
    }
}

#Preview {
    DeletionConfirmationView(
        foldersToDelete: [
            BuildFolder(
                path: URL(fileURLWithPath: "/test/build"),
                projectType: .android,
                size: 1024 * 1024 * 50,
                projectName: "AndroidApp",
                lastModified: Date()
            ),
            BuildFolder(
                path: URL(fileURLWithPath: "/test/.build"),
                projectType: .iOS,
                size: 1024 * 1024 * 30,
                projectName: "iOSApp",
                lastModified: Date()
            )
        ],
        totalSize: "80 MB",
        onConfirm: {},
        onCancel: {}
    )
}
