//
//  DeletionConfirmationView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import SwiftUI

struct DeletionConfirmationView: View {
    let foldersToDelete: [BuildFolder]
    let staticLocationsToDelete: [StaticLocation]
    let subItemsToDelete: [(location: StaticLocation, subItem: StaticLocationSubItem)]
    let totalSize: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    private var totalItemCount: Int {
        foldersToDelete.count + staticLocationsToDelete.count + subItemsToDelete.count
    }

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

                Text("\(totalItemCount) item\(totalItemCount == 1 ? "" : "s") will be moved to Trash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Item list
            VStack(alignment: .leading, spacing: 12) {
                Text("Items to delete:")
                    .font(.headline)

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        // Static locations first
                        ForEach(Array(staticLocationsToDelete.prefix(5))) { location in
                            HStack {
                                Image(systemName: location.iconName)
                                    .foregroundStyle(location.color)
                                Text(location.displayName)
                                    .font(.callout)
                                Spacer()
                                Text(location.formattedSize)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Then sub-items (e.g., individual DerivedData folders)
                        let remainingSlots = 10 - min(5, staticLocationsToDelete.count)
                        let subItemsToShow = Array(subItemsToDelete.prefix(remainingSlots))
                        ForEach(subItemsToShow.indices, id: \.self) { index in
                            let item = subItemsToShow[index]
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(.blue)
                                Text(item.subItem.name)
                                    .font(.callout)
                                Spacer()
                                Text(item.subItem.formattedSize)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Then build folders
                        let subItemsShown = min(remainingSlots, subItemsToDelete.count)
                        let buildFoldersToShow = remainingSlots - subItemsShown
                        ForEach(Array(foldersToDelete.prefix(buildFoldersToShow))) { folder in
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

                        if totalItemCount > 10 {
                            Text("...and \(totalItemCount - 10) more")
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
                .buttonHoverEffect()

                Button("Move to Trash") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
                .buttonHoverEffect()
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
        staticLocationsToDelete: [],
        subItemsToDelete: [],
        totalSize: "80 MB",
        onConfirm: {},
        onCancel: {}
    )
}
