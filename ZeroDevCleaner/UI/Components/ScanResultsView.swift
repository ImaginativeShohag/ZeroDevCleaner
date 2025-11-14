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
    let onDone: () -> Void
    @State private var expandedStaticLocations: Set<UUID> = []
    @State private var expandedSubItems: Set<UUID> = [] // For nested items like archive app groups

    var body: some View {
        VStack(spacing: 0) {
            // Header with Done button
            HStack {
                Text("Scan Results")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    onDone()
                } label: {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .buttonHoverEffect()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            // Custom Tab Bar
            HStack(spacing: 0) {
                ForEach(MainViewModel.ResultsTab.allCases, id: \.self) { tab in
                    Button {
                        viewModel.currentTab = tab
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14))
                            Text(tab.rawValue)
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(viewModel.currentTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                        .foregroundStyle(viewModel.currentTab == tab ? Color.accentColor : Color.primary)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
            )
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            // Content based on selected tab
            if viewModel.currentTab == .buildFolders {
                buildFoldersView
            } else {
                systemCachesView
            }
        }
    }

    // MARK: - Build Folders Tab

    private var buildFoldersView: some View {
        VStack(spacing: 0) {
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
                            Text("\(selectedBuildFoldersCount) folders")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text(formattedSelectedBuildFoldersSize)
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

                Picker("Filter Project", selection: $viewModel.currentFilter) {
                    ForEach(viewModel.sortedFilterTypes, id: \.self) { filter in
                        Label {
                            Text("\(filter.rawValue) (\(viewModel.count(for: filter)))")
                        } icon: {
                            Image(systemName: filter.icon)
                        }
                        .tag(filter)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Spacer()

                Text("\(viewModel.filteredResults.count) of \(viewModel.totalFoldersCount) shown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Quick Filters
            QuickFiltersBar(
                currentPreset: $viewModel.currentPreset,
                showComprehensiveFilters: $viewModel.showComprehensiveFilters,
                hasActiveFilters: viewModel.sizeFilterValue != nil || viewModel.daysOldFilterValue != nil
            )

            // Comprehensive Filters
            if viewModel.showComprehensiveFilters {
                ComprehensiveFiltersView(
                    sizeFilterValue: $viewModel.sizeFilterValue,
                    sizeFilterOperator: $viewModel.sizeFilterOperator,
                    daysOldFilterValue: $viewModel.daysOldFilterValue,
                    daysOldFilterOperator: $viewModel.daysOldFilterOperator,
                    onClear: {
                        viewModel.sizeFilterValue = nil
                        viewModel.daysOldFilterValue = nil
                    }
                )
                .padding(.top, 8)
                .padding([.horizontal, .bottom])
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                ))
            }

            Divider()

            // Results Table
            Table(viewModel.sortedAndFilteredResults) {
                TableColumn("") { folder in
                    Button {
                        viewModel.toggleSelection(for: folder)
                    } label: {
                        Image(systemName: folder.isSelected ? "checkmark.square.fill" : "square")
                            .foregroundStyle(.primary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
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
                    HStack(spacing: 4) {
                        Text(folder.projectType.displayName)
                        Text("(\(folder.projectType.buildFolderName))")
                            .foregroundStyle(.secondary)
                    }
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
                    HStack(spacing: 4) {
                        if folder.isOld {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                                .help("Not modified in \(folder.daysSinceModification) days")
                        }
                        Text(folder.formattedLastModified)
                    }
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
                   let folder = viewModel.sortedAndFilteredResults.first(where: { $0.id == itemId })
                {
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
                   let folder = viewModel.sortedAndFilteredResults.first(where: { $0.id == itemId })
                {
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
                .labelsHidden()
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
        .animation(.default, value: viewModel.showComprehensiveFilters)
    }

    // MARK: - System Caches Tab

    private var systemCachesView: some View {
        VStack(spacing: 0) {
            // Summary Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "externaldrive.fill")
                        .foregroundStyle(.purple)
                    Text("System Cache Locations")
                        .font(.headline)
                    Spacer()

                    if viewModel.isScanningStatic {
                        ProgressView()
                            .controlSize(.small)
                    }
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
                            Text("\(viewModel.staticLocations.filter(\.exists).count) locations")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text(formattedTotalStaticSize)
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
                            Text("\(selectedStaticLocationsCount) items")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text(formattedSelectedStaticSize)
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
                    Button("Select All", action: selectAllStatic)
                        .buttonStyle(.bordered)
                        .buttonHoverEffect()

                    Button("Deselect All", action: deselectAllStatic)
                        .buttonStyle(.bordered)
                        .buttonHoverEffect()
                }

                Spacer()

                Button("Remove Selected", action: viewModel.showDeleteConfirmation)
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedStaticLocationsCount == 0)
                    .buttonHoverEffect()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Quick Filters
            QuickFiltersBar(
                currentPreset: $viewModel.currentPreset,
                showComprehensiveFilters: $viewModel.showComprehensiveFilters,
                hasActiveFilters: viewModel.sizeFilterValue != nil || viewModel.daysOldFilterValue != nil
            )

            // Comprehensive Filters
            if viewModel.showComprehensiveFilters {
                ComprehensiveFiltersView(
                    sizeFilterValue: $viewModel.sizeFilterValue,
                    sizeFilterOperator: $viewModel.sizeFilterOperator,
                    daysOldFilterValue: $viewModel.daysOldFilterValue,
                    daysOldFilterOperator: $viewModel.daysOldFilterOperator,
                    onClear: {
                        viewModel.sizeFilterValue = nil
                        viewModel.daysOldFilterValue = nil
                    }
                )
                .padding()
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                ))
            }

            Divider()

            // Static Locations List
            ScrollView {
                if !viewModel.filteredStaticLocations.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(viewModel.filteredStaticLocations) { location in
                            VStack(spacing: 0) {
                                // Main location row
                                // Parent checkbox with partial selection support
                                HStack(spacing: 12) {
                                    Button {
                                        if location.exists {
                                            viewModel.toggleStaticLocationSelection(for: location)
                                        }
                                    } label: {
                                        Image(systemName: getCheckboxIcon(for: location))
                                            .foregroundStyle(location.exists ? .primary : .tertiary)
                                            .font(.system(size: 14))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!location.exists)

                                    // Disclosure button for expandable items (with clickable row)
                                    HStack(spacing: 8) {
                                        if location.type.supportsSubItems && !location.subItems.isEmpty {
                                            Image(systemName: expandedStaticLocations.contains(location.id) ? "chevron.down" : "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Image(systemName: location.iconName)
                                            .foregroundStyle(location.color)
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
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(location.exists ? Color(nsColor: .controlBackgroundColor) : Color.clear)
                                .cornerRadius(8)
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
                                    VStack(spacing: 4) {
                                        ForEach(location.subItems) { subItem in
                                            // Check if this sub-item has its own sub-items (e.g., archive app groups)
                                            if !subItem.subItems.isEmpty {
                                                // Nested disclosure group for app groups
                                                VStack(spacing: 0) {
                                                    // App group header
                                                    HStack(spacing: 12) {
                                                        Spacer()
                                                            .frame(width: 20)

                                                        // App group checkbox with partial selection support
                                                        Button {
                                                            viewModel.toggleSubItemSelection(for: location, subItemId: subItem.id)
                                                        } label: {
                                                            Image(systemName: getCheckboxIconForSubItem(subItem))
                                                                .foregroundStyle(.primary)
                                                                .font(.system(size: 12))
                                                        }
                                                        .buttonStyle(.plain)

                                                        // Chevron for expand/collapse
                                                        Image(systemName: expandedSubItems.contains(subItem.id) ? "chevron.down" : "chevron.right")
                                                            .font(.caption2)
                                                            .foregroundStyle(.secondary)
                                                            .frame(width: 12)
                                                            .onTapGesture {
                                                                toggleSubItemExpansion(for: subItem.id)
                                                            }

                                                        Image(systemName: "folder.fill.badge.gearshape")
                                                            .foregroundStyle(.secondary)
                                                            .font(.caption)
                                                            .frame(width: 16)

                                                        Text(subItem.name)
                                                            .font(.caption)
                                                            .fontWeight(.medium)
                                                            .lineLimit(1)
                                                            .truncationMode(.middle)

                                                        Spacer()

                                                        Text(subItem.formattedSize)
                                                            .font(.caption2)
                                                            .monospacedDigit()
                                                            .foregroundStyle(.tertiary)

                                                        Text("\(subItem.subItems.count) versions")
                                                            .font(.caption2)
                                                            .foregroundStyle(.quaternary)
                                                            .frame(width: 80, alignment: .trailing)
                                                    }
                                                    .padding(.vertical, 6)
                                                    .padding(.horizontal, 12)
                                                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                                                    .cornerRadius(6)
                                                    .rowHoverEffect()
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        toggleSubItemExpansion(for: subItem.id)
                                                    }

                                                    // Nested version items (if expanded)
                                                    if expandedSubItems.contains(subItem.id) {
                                                        VStack(spacing: 4) {
                                                            ForEach(subItem.subItems) { versionItem in
                                                                HStack(spacing: 12) {
                                                                    Spacer()
                                                                        .frame(width: 52) // Extra indent for nested items

                                                                    Button {
                                                                        viewModel.toggleNestedSubItemSelection(for: location, subItemId: subItem.id, nestedItemId: versionItem.id)
                                                                    } label: {
                                                                        Image(systemName: versionItem.isSelected ? "checkmark.square.fill" : "square")
                                                                            .foregroundStyle(.primary)
                                                                            .font(.system(size: 11))
                                                                    }
                                                                    .buttonStyle(.plain)

                                                                    Image(systemName: "archivebox")
                                                                        .foregroundStyle(.tertiary)
                                                                        .font(.caption2)
                                                                        .frame(width: 14)

                                                                    Text(versionItem.name)
                                                                        .font(.caption2)
                                                                        .lineLimit(1)
                                                                        .truncationMode(.middle)

                                                                    Spacer()

                                                                    Text(versionItem.formattedSize)
                                                                        .font(.caption2)
                                                                        .monospacedDigit()
                                                                        .foregroundStyle(.tertiary)

                                                                    HStack(spacing: 2) {
                                                                        if versionItem.isOld {
                                                                            Image(systemName: "exclamationmark.triangle.fill")
                                                                                .foregroundStyle(.orange)
                                                                                .font(.system(size: 8))
                                                                        }
                                                                        Text(versionItem.formattedLastModified)
                                                                            .font(.caption2)
                                                                            .foregroundStyle(.quaternary)
                                                                    }
                                                                    .frame(width: 80, alignment: .trailing)
                                                                    .help(versionItem.isOld ? "Not modified in \(versionItem.daysSinceModification) days" : "")

                                                                    Button {
                                                                        NSWorkspace.shared.selectFile(
                                                                            versionItem.path.path,
                                                                            inFileViewerRootedAtPath: versionItem.path.deletingLastPathComponent().path
                                                                        )
                                                                    } label: {
                                                                        Image(systemName: "arrow.up.forward.app")
                                                                            .foregroundStyle(.blue)
                                                                            .font(.caption2)
                                                                    }
                                                                    .buttonStyle(.plain)
                                                                    .help("Show in Finder")
                                                                    .hoverEffect(scale: 1.1, brightness: 0.1)
                                                                }
                                                                .padding(.vertical, 5)
                                                                .padding(.horizontal, 12)
                                                                .background(Color(nsColor: .controlBackgroundColor).opacity(0.2))
                                                                .cornerRadius(4)
                                                                .rowHoverEffect()
                                                                .contextMenu {
                                                                    Button("Show in Finder") {
                                                                        NSWorkspace.shared.selectFile(
                                                                            versionItem.path.path,
                                                                            inFileViewerRootedAtPath: versionItem.path.deletingLastPathComponent().path
                                                                        )
                                                                    }

                                                                    Button("Copy Path") {
                                                                        NSPasteboard.general.clearContents()
                                                                        NSPasteboard.general.setString(versionItem.path.path, forType: .string)
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        .padding(.leading, 24)
                                                        .padding(.top, 4)
                                                        .padding(.bottom, 4)
                                                    }
                                                }
                                            } else {
                                                // Regular sub-item (no nesting)
                                                HStack(spacing: 12) {
                                                    Spacer()
                                                        .frame(width: 20)

                                                    Button {
                                                        viewModel.toggleSubItemSelection(for: location, subItemId: subItem.id)
                                                    } label: {
                                                        Image(systemName: subItem.isSelected ? "checkmark.square.fill" : "square")
                                                            .foregroundStyle(.primary)
                                                            .font(.system(size: 12))
                                                    }
                                                    .buttonStyle(.plain)

                                                    Image(systemName: subItem.iconName)
                                                        .foregroundStyle(.secondary)
                                                        .font(.caption)
                                                        .frame(width: 16)

                                                    Text(subItem.name)
                                                        .font(.caption)
                                                        .lineLimit(1)
                                                        .truncationMode(.middle)

                                                    Spacer()

                                                    // Hint message badge (e.g., "Running")
                                                    if let hint = subItem.hintMessage {
                                                        HStack(spacing: 2) {
                                                            Image(systemName: "info.circle.fill")
                                                                .foregroundStyle(.green)
                                                                .font(.system(size: 9))
                                                            Text(hint)
                                                                .font(.caption2)
                                                                .foregroundStyle(.green)
                                                        }
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.green.opacity(0.1))
                                                        .cornerRadius(4)
                                                    }

                                                    // Warning message badge (e.g., "Dangling image")
                                                    if let warning = subItem.warningMessage {
                                                        HStack(spacing: 2) {
                                                            Image(systemName: "exclamationmark.triangle.fill")
                                                                .foregroundStyle(.orange)
                                                                .font(.system(size: 9))
                                                            Text(warning)
                                                                .font(.caption2)
                                                                .foregroundStyle(.orange)
                                                        }
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.orange.opacity(0.1))
                                                        .cornerRadius(4)
                                                    }

                                                    Text(subItem.formattedSize)
                                                        .font(.caption)
                                                        .monospacedDigit()
                                                        .foregroundStyle(.tertiary)

                                                    HStack(spacing: 2) {
                                                        if subItem.isOld {
                                                            Image(systemName: "exclamationmark.triangle.fill")
                                                                .foregroundStyle(.orange)
                                                                .font(.system(size: 9))
                                                        }
                                                        Text(subItem.formattedLastModified)
                                                            .font(.caption2)
                                                            .foregroundStyle(.quaternary)
                                                    }
                                                    .frame(width: 80, alignment: .trailing)
                                                    .help(subItem.isOld ? "Not modified in \(subItem.daysSinceModification) days" : "")

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
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 12)
                                                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                                                .cornerRadius(6)
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
                                    }
                                    .padding(.leading, 24)
                                    .padding(.top, 4)
                                    .padding(.bottom, 8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
        .animation(.default, value: viewModel.showComprehensiveFilters)
    }

    // MARK: - Helper Properties & Methods

    // Build Folders Tab
    private var selectedBuildFoldersCount: Int {
        viewModel.selectedFolders.count
    }

    private var formattedSelectedBuildFoldersSize: String {
        let size = viewModel.selectedFolders.reduce(0) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    // System Caches Tab
    private var selectedStaticLocationsCount: Int {
        viewModel.selectedStaticLocations.count + viewModel.selectedSubItems.count
    }

    private var formattedTotalStaticSize: String {
        let size = viewModel.staticLocations.filter(\.exists).reduce(0) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    private var formattedSelectedStaticSize: String {
        let staticSize = viewModel.selectedStaticLocations.reduce(0) { $0 + $1.size }
        let subItemsSize = viewModel.selectedSubItems.reduce(0) { $0 + $1.subItem.size }
        return ByteCountFormatter.string(fromByteCount: staticSize + subItemsSize, countStyle: .file)
    }

    private func selectAllStatic() {
        for index in viewModel.staticLocations.indices where viewModel.staticLocations[index].exists {
            viewModel.staticLocations[index].isSelected = true
            // Also select all sub-items
            for subIndex in viewModel.staticLocations[index].subItems.indices {
                viewModel.staticLocations[index].subItems[subIndex].isSelected = true
                // Also select nested sub-items (archive versions)
                for nestedIndex in viewModel.staticLocations[index].subItems[subIndex].subItems.indices {
                    viewModel.staticLocations[index].subItems[subIndex].subItems[nestedIndex].isSelected = true
                }
            }
        }
    }

    private func deselectAllStatic() {
        for index in viewModel.staticLocations.indices {
            viewModel.staticLocations[index].isSelected = false
            // Also deselect all sub-items
            for subIndex in viewModel.staticLocations[index].subItems.indices {
                viewModel.staticLocations[index].subItems[subIndex].isSelected = false
                // Also deselect nested sub-items (archive versions)
                for nestedIndex in viewModel.staticLocations[index].subItems[subIndex].subItems.indices {
                    viewModel.staticLocations[index].subItems[subIndex].subItems[nestedIndex].isSelected = false
                }
            }
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

    private func toggleSubItemExpansion(for subItemId: UUID) {
        if expandedSubItems.contains(subItemId) {
            expandedSubItems.remove(subItemId)
        } else {
            expandedSubItems.insert(subItemId)
        }
    }

    // Helper to determine checkbox icon for parent location
    private func getCheckboxIcon(for location: StaticLocation) -> String {
        if location.isSelected {
            return "checkmark.square.fill"
        } else if location.someSubItemsSelected {
            return "minus.square.fill" // Partial selection
        } else {
            return "square"
        }
    }

    // Helper to determine checkbox icon for sub-item (app group)
    private func getCheckboxIconForSubItem(_ subItem: StaticLocationSubItem) -> String {
        if subItem.isSelected {
            return "checkmark.square.fill"
        } else if subItem.someSubItemsSelected {
            return "minus.square.fill" // Partial selection
        } else {
            return "square"
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
        onShowInFinder: { _ in },
        onDone: {}
    )
}
