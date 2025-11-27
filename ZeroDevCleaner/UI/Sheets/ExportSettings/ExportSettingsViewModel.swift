//
//  ExportSettingsViewModel.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 5/11/25.
//

import SwiftUI
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class ExportSettingsViewModel {
    var includeScanLocations = true
    var includeCustomCaches = true
    var includeBuildFolderConfiguration = true
    var isExporting = false
    var errorMessage: String?
    var showSuccessAlert = false

    private let exporter: SettingsExporterProtocol

    init(exporter: SettingsExporterProtocol = SettingsExporter()) {
        self.exporter = exporter
    }

    var exportOptions: ExportOptions {
        ExportOptions(
            includeScanLocations: includeScanLocations,
            includeCustomCaches: includeCustomCaches,
            includeBuildFolderConfiguration: includeBuildFolderConfiguration
        )
    }

    var hasAtLeastOneOption: Bool {
        includeScanLocations || includeCustomCaches || includeBuildFolderConfiguration
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

        // Generate filename with datetime
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_hh-mm-ss-a"
        let dateString = dateFormatter.string(from: Date())
        let filename = "ZeroDevCleaner-Settings_\(dateString)"

        // Open save panel
        let panel = NSSavePanel()
        panel.title = "Export Settings"
        panel.message = "Choose where to save your settings"
        panel.nameFieldLabel = "Save as:"
        panel.nameFieldStringValue = filename
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
            showSuccessAlert = true
        } catch let error as ZeroDevCleanerError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to export settings: \(error.localizedDescription)"
        }

        isExporting = false
    }
}
