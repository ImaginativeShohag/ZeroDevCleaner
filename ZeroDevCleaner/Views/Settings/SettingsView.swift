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
                ContentUnavailableView(
                    "No Scan Locations",
                    systemImage: "folder.badge.plus",
                    description: Text("Add folders to scan automatically")
                )
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
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
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
