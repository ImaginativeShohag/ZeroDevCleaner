//
//  ExportSettingsSheet.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 04/11/25.
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
final class ExportSettingsViewModel {
    var includeScanLocations = true
    var includeCustomCaches = true
    var isExporting = false
    var errorMessage: String?

    private let exporter: SettingsExporterProtocol

    init(exporter: SettingsExporterProtocol = SettingsExporter()) {
        self.exporter = exporter
    }

    var exportOptions: ExportOptions {
        ExportOptions(
            includeScanLocations: includeScanLocations,
            includeCustomCaches: includeCustomCaches
        )
    }

    var hasAtLeastOneOption: Bool {
        includeScanLocations || includeCustomCaches
    }

    var previewText: String {
        let scanCount = includeScanLocations ? (Preferences.scanLocations?.count ?? 0) : 0
        let cacheCount = includeCustomCaches ? (Preferences.customCacheLocations?.count ?? 0) : 0
        let total = scanCount + cacheCount

        guard total > 0 else {
            return "No items to export"
        }

        var parts: [String] = []
        if scanCount > 0 {
            parts.append("\(scanCount) scan location\(scanCount == 1 ? "" : "s")")
        }
        if cacheCount > 0 {
            parts.append("\(cacheCount) custom cache\(cacheCount == 1 ? "" : "s")")
        }

        return "Export \(parts.joined(separator: " and "))"
    }

    func exportSettings() {
        guard hasAtLeastOneOption else {
            errorMessage = "Please select at least one option to export"
            return
        }

        // Open save panel
        let panel = NSSavePanel()
        panel.title = "Export Settings"
        panel.message = "Choose where to save your settings"
        panel.nameFieldLabel = "Save as:"
        panel.nameFieldStringValue = "ZeroDevCleaner-Settings.zdcsettings"
        panel.allowedContentTypes = [.init(filenameExtension: "zdcsettings")!]
        panel.canCreateDirectories = true

        panel.begin { [weak self] response in
            guard let self = self else { return }
            guard response == .OK, let url = panel.url else { return }

            Task { @MainActor in
                await self.performExport(to: url)
            }
        }
    }

    private func performExport(to url: URL) async {
        isExporting = true
        errorMessage = nil

        do {
            try await exporter.exportSettings(to: url, options: exportOptions)
        } catch let error as ZeroDevCleanerError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to export settings: \(error.localizedDescription)"
        }

        isExporting = false
    }
}

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
                Toggle(isOn: $viewModel.includeScanLocations) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Scan Locations")
                                .font(.headline)
                            Text("\(Preferences.scanLocations?.count ?? 0) location(s)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .toggleStyle(.checkbox)

                Toggle(isOn: $viewModel.includeCustomCaches) {
                    HStack {
                        Image(systemName: "folder.badge.gearshape")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Custom Cache Locations")
                                .font(.headline)
                            Text("\(Preferences.customCacheLocations?.count ?? 0) cache(s)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .toggleStyle(.checkbox)
            }

            // Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Summary")
                    .font(.headline)

                HStack {
                    Image(systemName: viewModel.hasAtLeastOneOption ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(viewModel.hasAtLeastOneOption ? .green : .orange)
                    Text(viewModel.previewText)
                        .font(.subheadline)
                        .foregroundStyle(viewModel.hasAtLeastOneOption ? .primary : .secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
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
