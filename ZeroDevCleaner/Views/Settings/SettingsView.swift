//
//  SettingsView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable var locationManager: ScanLocationManager
    @State private var showingFolderPicker = false
    @State private var isDropTargeted = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Scan Locations")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Add Location") {
                    showingFolderPicker = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

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
                            onRemove: { locationManager.removeLocation(location) }
                        )
                    }
                }
            }

            Divider()

            // Footer with close button
            HStack {
                Text("Drag & drop folders to add")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 600, height: 400)
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
        .dropDestination(for: URL.self) { items, location in
            // Handle multiple folder drops
            var addedCount = 0
            for url in items {
                // Verify it's a directory
                var isDirectory: ObjCBool = false
                guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                      isDirectory.boolValue else {
                    continue
                }

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
            }

            return addedCount > 0
        } isTargeted: { isTargeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                isDropTargeted = isTargeted
            }
        }
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
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
    }
}

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
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
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
    return SettingsView(locationManager: manager)
}
