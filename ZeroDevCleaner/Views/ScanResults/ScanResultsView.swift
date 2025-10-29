//
//  ScanResultsView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI

struct ScanResultsView: View {
    let results: [BuildFolder]
    let onToggleSelection: (BuildFolder) -> Void
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void
    let onDelete: () -> Void
    let selectedSize: String

    var body: some View {
        VStack(spacing: 0) {
            // Summary Card
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(results.count) build folders found")
                        .font(.headline)
                    Text("Selected: \(selectedCount) (\(selectedSize))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button("Select All", action: onSelectAll)
                        .buttonStyle(.bordered)

                    Button("Deselect All", action: onDeselectAll)
                        .buttonStyle(.bordered)

                    Button("Remove Selected", action: onDelete)
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedCount == 0)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Results Table
            Table(results) {
                TableColumn("") { folder in
                    Toggle("", isOn: Binding(
                        get: { folder.isSelected },
                        set: { _ in onToggleSelection(folder) }
                    ))
                    .toggleStyle(.checkbox)
                }
                .width(40)

                TableColumn("Project", value: \.projectName)

                TableColumn("Type") { folder in
                    Label(folder.projectType.displayName, systemImage: folder.projectType.iconName)
                }

                TableColumn("Size", value: \.formattedSize)

                TableColumn("Last Modified", value: \.formattedLastModified)

                TableColumn("Path") { folder in
                    Text(folder.path.path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(folder.path.path)
                }
            }
        }
    }

    private var selectedCount: Int {
        results.filter(\.isSelected).count
    }
}

#Preview {
    ScanResultsView(
        results: [
            BuildFolder(
                path: URL(fileURLWithPath: "/test/build"),
                projectType: .android,
                size: 1024 * 1024 * 100,
                projectName: "TestApp",
                lastModified: Date(),
                isSelected: true
            )
        ],
        onToggleSelection: { _ in },
        onSelectAll: {},
        onDeselectAll: {},
        onDelete: {},
        selectedSize: "100 MB"
    )
}
