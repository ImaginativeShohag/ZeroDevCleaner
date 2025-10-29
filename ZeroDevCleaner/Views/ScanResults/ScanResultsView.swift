//
//  ScanResultsView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI

struct ScanResultsView: View {
    let results: [BuildFolder]
    @Binding var currentFilter: MainViewModel.FilterType
    let onToggleSelection: (BuildFolder) -> Void
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void
    let onDelete: () -> Void
    let onShowInFinder: (BuildFolder) -> Void
    let selectedSize: String
    let totalCount: Int
    let totalSize: String

    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Summary Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.blue)
                    Text("Scan Results")
                        .font(.headline)
                    Spacer()
                }

                HStack(spacing: 24) {
                    // Total found
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Found")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            Image(systemName: "folder.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(totalCount) folders")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text(totalSize)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Selected
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text("\(selectedCount) folders")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text(selectedSize)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Action Buttons
            HStack {
                HStack(spacing: 12) {
                    Button("Select All", action: onSelectAll)
                        .buttonStyle(.bordered)

                    Button("Deselect All", action: onDeselectAll)
                        .buttonStyle(.bordered)
                }

                Spacer()

                Button("Remove Selected", action: onDelete)
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedCount == 0)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Filter Picker
            HStack {
                Text("Filter:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Filter", selection: $currentFilter) {
                    ForEach(MainViewModel.FilterType.allCases, id: \.self) { filter in
                        Label(filter.rawValue, systemImage: filter.icon)
                            .tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 400)

                Spacer()

                Text("\(results.count) of \(totalCount) shown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

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
            .contextMenu(forSelectionType: BuildFolder.ID.self) { items in
                if let itemId = items.first,
                   let folder = results.first(where: { $0.id == itemId }) {
                    Button("Show in Finder") {
                        onShowInFinder(folder)
                    }
                }
            } primaryAction: { items in
                // Double-click action
                if let itemId = items.first,
                   let folder = results.first(where: { $0.id == itemId }) {
                    onShowInFinder(folder)
                }
            }
        }
    }

    private var selectedCount: Int {
        results.filter(\.isSelected).count
    }
}

#Preview {
    @Previewable @State var filter = MainViewModel.FilterType.all

    return ScanResultsView(
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
        currentFilter: $filter,
        onToggleSelection: { _ in },
        onSelectAll: {},
        onDeselectAll: {},
        onDelete: {},
        onShowInFinder: { _ in },
        selectedSize: "100 MB",
        totalCount: 1,
        totalSize: "100 MB"
    )
}
