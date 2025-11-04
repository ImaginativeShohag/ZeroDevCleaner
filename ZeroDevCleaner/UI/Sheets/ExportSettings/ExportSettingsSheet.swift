//
//  ExportSettingsSheet.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 04/11/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportSettingsSheet: View {
    @State private var viewModel = ExportSettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text("Export Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()
            }

            // Description
            Text("Choose which settings to export. The exported file can be imported on this or another Mac.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Options
            VStack(spacing: 16) {
                // Scan Locations
                Button(action: {
                    viewModel.includeScanLocations.toggle()
                }) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: viewModel.includeScanLocations ? "checkmark.square.fill" : "square")
                            .font(.system(size: 18))
                            .foregroundStyle(viewModel.includeScanLocations ? .blue : .secondary)

                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 20, height: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Scan Locations")
                                .font(.headline)
                            Text("\(Preferences.scanLocations?.count ?? 0) location(s)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(6)

                // Custom Cache Locations
                Button(action: {
                    viewModel.includeCustomCaches.toggle()
                }) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: viewModel.includeCustomCaches ? "checkmark.square.fill" : "square")
                            .font(.system(size: 18))
                            .foregroundStyle(viewModel.includeCustomCaches ? .blue : .secondary)

                        Image(systemName: "folder.badge.gearshape")
                            .foregroundStyle(.orange)
                            .frame(width: 20, height: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Custom Cache Locations")
                                .font(.headline)
                            Text("\(Preferences.customCacheLocations?.count ?? 0) cache(s)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(6)
            }

            // Preview
            VStack(alignment: .leading, spacing: 12) {
                Text("Preview")
                    .font(.headline)

                if !viewModel.hasAtLeastOneOption {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Please select at least one option to export")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            // Scan Locations
                            if viewModel.includeScanLocations, let locations = Preferences.scanLocations, !locations.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .foregroundStyle(.blue)
                                            .font(.caption)
                                        Text("Scan Locations (\(locations.count))")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }

                                    ForEach(locations) { location in
                                        HStack(spacing: 8) {
                                            Image(systemName: "circle.fill")
                                                .font(.system(size: 4))
                                                .foregroundStyle(.secondary)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(location.name)
                                                    .font(.caption)
                                                Text(location.path.path)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding(.leading, 8)
                                    }
                                }
                            }

                            // Custom Caches
                            if viewModel.includeCustomCaches, let caches = Preferences.customCacheLocations, !caches.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "folder.badge.gearshape")
                                            .foregroundStyle(.orange)
                                            .font(.caption)
                                        Text("Custom Cache Locations (\(caches.count))")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }

                                    ForEach(caches) { cache in
                                        HStack(spacing: 8) {
                                            Image(systemName: "circle.fill")
                                                .font(.system(size: 4))
                                                .foregroundStyle(.secondary)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(cache.name)
                                                    .font(.caption)
                                                Text(cache.path.path)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                                if let pattern = cache.pattern, !pattern.isEmpty {
                                                    Text("Pattern: \(pattern)")
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                        .padding(.leading, 8)
                                    }
                                }
                            }

                            // Empty state
                            if (viewModel.includeScanLocations && (Preferences.scanLocations?.isEmpty ?? true)) ||
                               (viewModel.includeCustomCaches && (Preferences.customCacheLocations?.isEmpty ?? true)) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundStyle(.blue)
                                    Text("No items to export")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(12)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(maxHeight: 200)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            // Error message
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }

            Spacer()

            Divider()

            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonHoverEffect()

                Spacer()

                Button("Export...") {
                    viewModel.exportSettings()
                }
                .disabled(!viewModel.hasAtLeastOneOption || viewModel.isExporting)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .buttonHoverEffect()
            }
        }
        .padding(20)
        .frame(width: 500)
        .alert("Export Successful", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your settings have been exported successfully.")
        }
    }
}

#Preview("With Settings") {
    Preferences.scanLocations = [
        ScanLocation(name: "Projects", path: URL(fileURLWithPath: "/Users/test/Projects")),
        ScanLocation(name: "Documents", path: URL(fileURLWithPath: "/Users/test/Documents"))
    ]
    Preferences.customCacheLocations = [
        CustomCacheLocation(name: "Build Cache", path: URL(fileURLWithPath: "/tmp/cache"))
    ]
    return ExportSettingsSheet()
}

#Preview("Empty Settings") {
    Preferences.scanLocations = nil
    Preferences.customCacheLocations = nil
    return ExportSettingsSheet()
}
