//
//  ImportSettingsViewModel.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 5/11/25.
//

import SwiftUI
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class ImportSettingsViewModel {
    var importMode: ImportMode = .merge
    var isLoading = false
    var isImporting = false
    var errorMessage: String?
    var loadedExport: SettingsExport?
    var showSuccessAlert = false

    private let importer: SettingsImporterProtocol

    init(importer: SettingsImporterProtocol = SettingsImporter()) {
        self.importer = importer
    }

    var canImport: Bool {
        loadedExport != nil && !isImporting
    }

    var previewText: String {
        guard let export = loadedExport else {
            return "No file selected"
        }

        let scanCount = export.scanLocations.count
        let cacheCount = export.customCacheLocations.count
        let total = scanCount + cacheCount

        guard total > 0 else {
            return "File contains no settings"
        }

        var parts: [String] = []
        if scanCount > 0 {
            parts.append("\(scanCount) scan location\(scanCount == 1 ? "" : "s")")
        }
        if cacheCount > 0 {
            parts.append("\(cacheCount) custom cache\(cacheCount == 1 ? "" : "s")")
        }

        return "Importing \(parts.joined(separator: " and "))"
    }

    func selectFile() {
        let panel = NSOpenPanel()
        panel.title = "Import Settings"
        panel.message = "Choose a settings file to import"
        panel.prompt = "Import"
        panel.allowedContentTypes = [.init(filenameExtension: "zdcsettings")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        panel.begin { [weak self] response in
            guard let self = self else { return }
            guard response == .OK, let url = panel.url else { return }

            Task { @MainActor in
                await self.loadSettings(from: url)
            }
        }
    }

    private func loadSettings(from url: URL) async {
        isLoading = true
        errorMessage = nil
        loadedExport = nil

        do {
            let export = try await importer.loadSettings(from: url)
            loadedExport = export
        } catch let error as ZeroDevCleanerError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load settings: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func performImport() async {
        guard let export = loadedExport else { return }

        isImporting = true
        errorMessage = nil

        await importer.applySettings(export, mode: importMode)

        isImporting = false
        showSuccessAlert = true
    }
}
