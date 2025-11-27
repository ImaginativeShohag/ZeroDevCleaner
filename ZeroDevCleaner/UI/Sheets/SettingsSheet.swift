//
//  SettingsSheet.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import SwiftUI

struct SettingsSheet: View {
    @Bindable var locationManager: ScanLocationManager
    @State private var customCacheManager = CustomCacheManager.shared
    @State private var projectTypesViewModel = ProjectTypesSettingsViewModel()
    @State private var isDropTargeted = false
    @State private var selectedTab: SettingsTab = .scanLocations
    @State private var locationToRemove: ScanLocation?
    @State private var cacheToRemove: CustomCacheLocation?
    @State private var showExportSheet = false
    @State private var showImportSheet = false
    @Environment(\.dismiss) private var dismiss

    enum SettingsTab: String, CaseIterable {
        case scanLocations = "Scan Locations"
        case customCaches = "Custom Caches"
        case projectTypes = "Project Types"

        var icon: String {
            switch self {
            case .scanLocations: return "folder.fill"
            case .customCaches: return "folder.badge.gearshape"
            case .projectTypes: return "hammer.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with Tabs
            VStack(spacing: 0) {
                HStack {
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()

                // Tab Picker
                Picker("Settings Tab", selection: $selectedTab) {
                    ForEach(SettingsTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal)
                .padding(.bottom, 12)
            }

            Divider()

            // Tab Content
            Group {
                switch selectedTab {
                case .scanLocations:
                    scanLocationsView
                case .customCaches:
                    customCachesView
                case .projectTypes:
                    projectTypesView
                }
            }

            Divider()

            // Footer with action buttons
            HStack {
                // Export/Import buttons
                HStack(spacing: 8) {
                    Button {
                        showExportSheet = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut("e", modifiers: .command)
                    .help("Export settings (⌘E)")
                    .buttonHoverEffect()

                    Button {
                        showImportSheet = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut("i", modifiers: .command)
                    .help("Import settings (⌘I)")
                    .buttonHoverEffect()
                }

                Spacer()

                Text(footerText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .buttonHoverEffect()
            }
            .padding()
        }
        .frame(width: 950, height: 650)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(isDropTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color.clear,
                    style: StrokeStyle(lineWidth: 3, dash: [8, 4])
                )
                .padding(2)
        )
        .dropDestination(for: URL.self) { items, _ in
            // Handle multiple folder drops
            var addedCount = 0
            for url in items {
                // Verify it's a directory
                var isDirectory: ObjCBool = false
                guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                      isDirectory.boolValue
                else {
                    continue
                }

                if selectedTab == .scanLocations {
                    // Check if already exists
                    if locationManager.locations.contains(where: { $0.path == url }) {
                        continue
                    }

                    let scanLocation = ScanLocation(
                        name: url.lastPathComponent,
                        path: url
                    )
                    locationManager.addLocation(scanLocation)
                    addedCount += 1
                } else {
                    // Add to custom caches
                    let customCache = CustomCacheLocation(
                        name: url.lastPathComponent,
                        path: url
                    )
                    customCacheManager.addLocation(customCache)
                    addedCount += 1
                }
            }

            return addedCount > 0
        } isTargeted: { isTargeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                isDropTargeted = isTargeted
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSettingsSheet()
        }
        .sheet(isPresented: $showImportSheet) {
            ImportSettingsSheet()
        }
    }

    // MARK: - Scan Locations Tab

    private var scanLocationsView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Project Folders")
                    .font(.headline)
                Spacer()
                Button("Add Location") {
                    openFolderPicker()
                }
                .buttonStyle(.bordered)
                .buttonHoverEffect()
            }
            .padding()

            // Locations List
            if locationManager.locations.isEmpty {
                ContentUnavailableView {
                    Label("No Scan Locations", systemImage: "folder.badge.plus")
                } description: {
                    Text("Add folders to scan automatically\n\nDrag & drop folders here or click Add Location")
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(locationManager.locations) { location in
                        LocationRow(
                            location: location,
                            onToggle: { locationManager.toggleEnabled(for: location) },
                            onRemove: { locationToRemove = location }
                        )
                    }
                }
            }
        }
        .confirmationDialog(
            "Remove Scan Location",
            isPresented: Binding(
                get: { locationToRemove != nil },
                set: { if !$0 { locationToRemove = nil } }
            ),
            presenting: locationToRemove
        ) { location in
            Button("Remove", role: .destructive) {
                locationManager.removeLocation(location)
                locationToRemove = nil
            }
            Button("Cancel", role: .cancel) {
                locationToRemove = nil
            }
        } message: { location in
            Text("Are you sure you want to remove '\(location.name)'?\n\nPath: \(location.path.path)")
        }
    }

    // MARK: - Custom Caches Tab

    @State private var showAddCustomCache = false
    @State private var editingCustomCache: CustomCacheLocation?

    private var customCachesView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Custom Cache Directories")
                    .font(.headline)
                Spacer()
                Button("Add Custom Cache") {
                    showAddCustomCache = true
                }
                .buttonStyle(.bordered)
                .buttonHoverEffect()
            }
            .padding()

            // Custom Caches List
            if customCacheManager.locations.isEmpty {
                ContentUnavailableView {
                    Label("No Custom Caches", systemImage: "folder.badge.gearshape")
                } description: {
                    Text("Add custom cache directories to scan\n\nDrag & drop folders or click Add Custom Cache")
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(customCacheManager.locations) { cache in
                        CustomCacheRow(
                            cache: cache,
                            onToggle: { customCacheManager.toggleEnabled(id: cache.id) },
                            onEdit: { editingCustomCache = cache },
                            onRemove: { cacheToRemove = cache }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showAddCustomCache) {
            AddCustomCacheSheet(customCacheManager: customCacheManager)
        }
        .sheet(item: $editingCustomCache) { cache in
            EditCustomCacheSheet(cache: cache, customCacheManager: customCacheManager)
        }
        .confirmationDialog(
            "Remove Custom Cache",
            isPresented: Binding(
                get: { cacheToRemove != nil },
                set: { if !$0 { cacheToRemove = nil } }
            ),
            presenting: cacheToRemove
        ) { cache in
            Button("Remove", role: .destructive) {
                customCacheManager.removeLocation(id: cache.id)
                cacheToRemove = nil
            }
            Button("Cancel", role: .cancel) {
                cacheToRemove = nil
            }
        } message: { cache in
            Text("Are you sure you want to remove '\(cache.name)'?\n\nPath: \(cache.path.path)")
        }
    }

    // MARK: - Folder Picker

    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.title = "Choose a folder to scan"
        panel.message = "Select a folder containing your projects"
        panel.prompt = "Select"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            // Check if already exists
            guard !locationManager.locations.contains(where: { $0.path == url }) else {
                return
            }

            let location = ScanLocation(
                name: url.lastPathComponent,
                path: url
            )
            locationManager.addLocation(location)
        }
    }

    // MARK: - Project Types View

    private var projectTypesView: some View {
        ProjectTypesSettingsSheet(viewModel: projectTypesViewModel)
    }

    // MARK: - Helpers

    private var footerText: String {
        switch selectedTab {
        case .scanLocations:
            return "Drag & drop folders to add"
        case .customCaches:
            return "Add custom cache directories"
        case .projectTypes:
            return "Configure build folder detection rules"
        }
    }
}

// MARK: - Location Row

struct LocationRow: View {
    let location: ScanLocation
    let onToggle: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onToggle()
            } label: {
                Image(systemName: location.isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(location.isEnabled ? .blue : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .hoverEffect(scale: 1.1, brightness: 0.1)

            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)
                Text(location.path.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("Last scanned: \(location.formattedLastScanned)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button(role: .destructive) {
                onRemove()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .help("Remove this location")
            .hoverEffect(scale: 1.1, brightness: 0.1)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .rowHoverEffect()
    }
}

// MARK: - Custom Cache Row

struct CustomCacheRow: View {
    let cache: CustomCacheLocation
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onToggle()
            } label: {
                Image(systemName: cache.isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(cache.isEnabled ? cache.color : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .hoverEffect(scale: 1.1, brightness: 0.1)

            Image(systemName: cache.iconName)
                .foregroundStyle(cache.color)

            VStack(alignment: .leading, spacing: 4) {
                Text(cache.name)
                    .font(.headline)
                Text(cache.path.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let pattern = cache.pattern, !pattern.isEmpty {
                    Text("Pattern: \(pattern)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text("Last scanned: \(cache.formattedLastScanned)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .help("Edit this cache location")
            .hoverEffect(scale: 1.1, brightness: 0.1)

            Button(role: .destructive) {
                onRemove()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .help("Remove this cache location")
            .hoverEffect(scale: 1.1, brightness: 0.1)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .rowHoverEffect()
    }
}

#Preview {
    @Previewable @State var manager = ScanLocationManager()
    manager.locations = [
        ScanLocation(
            name: "Projects",
            path: URL(fileURLWithPath: "/Users/test/Projects"),
            isEnabled: true,
            lastScanned: Date()
        ),
        ScanLocation(
            name: "Documents",
            path: URL(fileURLWithPath: "/Users/test/Documents"),
            isEnabled: false,
            lastScanned: nil
        )
    ]
    return SettingsSheet(locationManager: manager)
}
