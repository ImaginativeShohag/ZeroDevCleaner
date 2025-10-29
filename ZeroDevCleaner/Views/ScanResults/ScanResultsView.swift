//
//  ScanResultsView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI

struct ScanResultsView: View {
    @Bindable var viewModel: MainViewModel
    let onShowInFinder: (BuildFolder) -> Void

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
                            Text("\(viewModel.totalFoldersCount) folders")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text(viewModel.formattedTotalSize)
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
                            Text(viewModel.formattedSelectedSize)
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
                    Button("Select All", action: viewModel.selectAll)
                        .buttonStyle(.bordered)

                    Button("Deselect All", action: viewModel.deselectAll)
                        .buttonStyle(.bordered)
                }

                Spacer()

                Button("Remove Selected", action: viewModel.showDeleteConfirmation)
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

                Picker("Filter", selection: $viewModel.currentFilter) {
                    ForEach(MainViewModel.FilterType.allCases, id: \.self) { filter in
                        Label(filter.rawValue, systemImage: filter.icon)
                            .tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 400)

                Spacer()

                Text("\(viewModel.filteredResults.count) of \(viewModel.totalFoldersCount) shown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Results Table
            Table(viewModel.sortedAndFilteredResults) {
                TableColumn("") { folder in
                    Toggle("", isOn: Binding(
                        get: { folder.isSelected },
                        set: { _ in viewModel.toggleSelection(for: folder) }
                    ))
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                }
                .width(40)

                TableColumn("Project") { folder in
                    HStack {
                        Image(systemName: folder.projectType.iconName)
                            .foregroundStyle(folder.projectType.color)
                        Text(folder.projectName)
                    }
                }
                .width(min: 150, ideal: 200, max: 300)
                .customizationID("project")

                TableColumn("Type") { folder in
                    Text(folder.projectType.displayName)
                }
                .width(min: 100, ideal: 120)
                .customizationID("type")

                TableColumn("Size") { folder in
                    Text(folder.formattedSize)
                        .monospacedDigit()
                }
                .width(min: 80, ideal: 100)
                .customizationID("size")

                TableColumn("Last Modified") { folder in
                    Text(folder.formattedLastModified)
                }
                .width(min: 120, ideal: 150)
                .customizationID("lastModified")

                TableColumn("Path") { folder in
                    Text(folder.path.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .width(min: 200)
            }
            .contextMenu(forSelectionType: BuildFolder.ID.self) { items in
                if let itemId = items.first,
                   let folder = viewModel.sortedAndFilteredResults.first(where: { $0.id == itemId }) {
                    Button("Show in Finder") {
                        onShowInFinder(folder)
                    }

                    Button("Copy Path") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(folder.path.path, forType: .string)
                    }
                }
            } primaryAction: { items in
                // Double-click action
                if let itemId = items.first,
                   let folder = viewModel.sortedAndFilteredResults.first(where: { $0.id == itemId }) {
                    onShowInFinder(folder)
                }
            }

            // Sort Controls
            HStack {
                Text("Sort by:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Sort Column", selection: $viewModel.sortColumn) {
                    ForEach(MainViewModel.SortColumn.allCases, id: \.self) { column in
                        Text(column.rawValue).tag(column)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 150)

                Button {
                    viewModel.sortOrder.toggle()
                } label: {
                    Image(systemName: viewModel.sortOrder == .ascending ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                }
                .buttonStyle(.plain)
                .help(viewModel.sortOrder == .ascending ? "Ascending" : "Descending")

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var selectedCount: Int {
        viewModel.selectedFolders.count
    }
}

#Preview {
    @Previewable @State var viewModel = MainViewModel()

    viewModel.scanResults = [
        BuildFolder(
            path: URL(fileURLWithPath: "/test/build"),
            projectType: .android,
            size: 1024 * 1024 * 100,
            projectName: "TestApp",
            lastModified: Date(),
            isSelected: true
        )
    ]

    return ScanResultsView(
        viewModel: viewModel,
        onShowInFinder: { _ in }
    )
}
