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
    @State private var expandedStaticLocations: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            // Static Locations Section
            if !viewModel.staticLocations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "externaldrive.fill")
                            .foregroundStyle(.purple)
                        Text("System Cache Locations")
                            .font(.headline)

                        Spacer()

                        if viewModel.isScanningStatic {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.trailing, 4)
                        }
                    }

                    // Static locations mini table
                    if !viewModel.staticLocations.isEmpty {
                        VStack(spacing: 4) {
                            ForEach(viewModel.staticLocations) { location in
                                VStack(spacing: 0) {
                                    // Main location row
                                    HStack(spacing: 12) {
                                        Toggle("", isOn: Binding(
                                            get: { location.isSelected },
                                            set: { _ in viewModel.toggleStaticLocationSelection(for: location) }
                                        ))
                                        .toggleStyle(.checkbox)
                                        .labelsHidden()
                                        .disabled(!location.exists)

                                        // Disclosure button for expandable items (with clickable row)
                                        HStack(spacing: 8) {
                                            if location.type.supportsSubItems && !location.subItems.isEmpty {
                                                Image(systemName: expandedStaticLocations.contains(location.id) ? "chevron.down" : "chevron.right")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }

                                            Image(systemName: location.type.iconName)
                                                .foregroundStyle(location.type.color)
                                                .frame(width: 20)

                                            VStack(alignment: .leading, spacing: 2) {
                                                HStack(spacing: 4) {
                                                    Text(location.displayName)
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                    if !location.subItems.isEmpty {
                                                        Text("(\(location.subItems.count) items)")
                                                            .font(.caption2)
                                                            .foregroundStyle(.tertiary)
                                                    }
                                                }
                                                Text(location.type.description)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if location.type.supportsSubItems && !location.subItems.isEmpty {
                                                toggleExpansion(for: location.id)
                                            }
                                        }

                                        Spacer()

                                        if location.exists {
                                            HStack(spacing: 8) {
                                                Text(location.formattedSize)
                                                    .font(.subheadline)
                                                    .monospacedDigit()
                                                    .foregroundStyle(.secondary)

                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.green)
                                                    .font(.caption)

                                                Button {
                                                    NSWorkspace.shared.selectFile(
                                                        location.path.path,
                                                        inFileViewerRootedAtPath: location.path.deletingLastPathComponent().path
                                                    )
                                                } label: {
                                                    Image(systemName: "arrow.up.forward.app")
                                                        .foregroundStyle(.blue)
                                                }
                                                .buttonStyle(.plain)
                                                .help("Show in Finder")
                                                .hoverEffect(scale: 1.1, brightness: 0.1)
                                            }
                                        } else {
                                            Text("Not found")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(location.exists ? Color(nsColor: .controlBackgroundColor) : Color.clear)
                                    .cornerRadius(6)
                                    .opacity(location.exists ? 1.0 : 0.5)
                                    .rowHoverEffect()
                                    .contextMenu {
                                        if location.exists {
                                            Button("Show in Finder") {
                                                NSWorkspace.shared.selectFile(
                                                    location.path.path,
                                                    inFileViewerRootedAtPath: location.path.deletingLastPathComponent().path
                                                )
                                            }

                                            Button("Copy Path") {
                                                NSPasteboard.general.clearContents()
                                                NSPasteboard.general.setString(location.path.path, forType: .string)
                                            }
                                        }
                                    }

                                    // Sub-items (if expanded)
                                    if expandedStaticLocations.contains(location.id) && !location.subItems.isEmpty {
                                        VStack(spacing: 2) {
                                            ForEach(location.subItems) { subItem in
                                                HStack(spacing: 12) {
                                                    Spacer()
                                                        .frame(width: 20)

                                                    Toggle("", isOn: Binding(
                                                        get: { subItem.isSelected },
                                                        set: { _ in viewModel.toggleSubItemSelection(for: location, subItemId: subItem.id) }
                                                    ))
                                                    .toggleStyle(.checkbox)
                                                    .labelsHidden()

                                                    Image(systemName: "folder.fill")
                                                        .foregroundStyle(.secondary)
                                                        .font(.caption)
                                                        .frame(width: 16)

                                                    Text(subItem.name)
                                                        .font(.caption)
                                                        .lineLimit(1)
                                                        .truncationMode(.middle)

                                                    Spacer()

                                                    Text(subItem.formattedSize)
                                                        .font(.caption)
                                                        .monospacedDigit()
                                                        .foregroundStyle(.tertiary)

                                                    Text(subItem.formattedLastModified)
                                                        .font(.caption2)
                                                        .foregroundStyle(.quaternary)
                                                        .frame(width: 80, alignment: .trailing)

                                                    Button {
                                                        NSWorkspace.shared.selectFile(
                                                            subItem.path.path,
                                                            inFileViewerRootedAtPath: subItem.path.deletingLastPathComponent().path
                                                        )
                                                    } label: {
                                                        Image(systemName: "arrow.up.forward.app")
                                                            .foregroundStyle(.blue)
                                                            .font(.caption)
                                                    }
                                                    .buttonStyle(.plain)
                                                    .help("Show in Finder")
                                                    .hoverEffect(scale: 1.1, brightness: 0.1)
                                                }
                                                .padding(.vertical, 4)
                                                .padding(.horizontal, 8)
                                                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                                                .cornerRadius(4)
                                                .rowHoverEffect()
                                                .contextMenu {
                                                    Button("Show in Finder") {
                                                        NSWorkspace.shared.selectFile(
                                                            subItem.path.path,
                                                            inFileViewerRootedAtPath: subItem.path.deletingLastPathComponent().path
                                                        )
                                                    }

                                                    Button("Copy Path") {
                                                        NSPasteboard.general.clearContents()
                                                        NSPasteboard.general.setString(subItem.path.path, forType: .string)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.leading, 20)
                                        .padding(.top, 4)
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 8)

                Divider()
                    .padding(.vertical, 8)
            }

            // Enhanced Summary Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.blue)
                    Text("Project Build Folders")
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
            .cardStyle()
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Action Buttons
            HStack {
                HStack(spacing: 12) {
                    Button("Select All", action: viewModel.selectAll)
                        .buttonStyle(.bordered)
                        .buttonHoverEffect()

                    Button("Deselect All", action: viewModel.deselectAll)
                        .buttonStyle(.bordered)
                        .buttonHoverEffect()
                }

                Spacer()

                Button("Remove Selected", action: viewModel.showDeleteConfirmation)
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedCount == 0)
                    .buttonHoverEffect()
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
                .frame(minWidth: 200, idealWidth: 300, maxWidth: 350)

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
                .hoverEffect(scale: 1.1, brightness: 0.1)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var selectedCount: Int {
        viewModel.selectedFolders.count
    }

    private func toggleExpansion(for locationId: UUID) {
        if expandedStaticLocations.contains(locationId) {
            expandedStaticLocations.remove(locationId)
        } else {
            expandedStaticLocations.insert(locationId)
        }
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
