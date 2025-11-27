//
//  SettingsExporter.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 04/11/25.
//

import Foundation

/// Protocol for exporting settings to a file
protocol SettingsExporterProtocol: Sendable {
    /// Exports settings to a file URL
    /// - Parameters:
    ///   - url: The destination file URL
    ///   - options: Export options specifying what to include
    /// - Throws: ZeroDevCleanerError if export fails
    func exportSettings(to url: URL, options: ExportOptions) async throws
}

/// Service for exporting app settings to a JSON file
@MainActor
final class SettingsExporter: SettingsExporterProtocol {
    /// Exports settings to a file URL
    /// - Parameters:
    ///   - url: The destination file URL (should have .zdcsettings extension)
    ///   - options: Export options specifying what to include
    /// - Throws: ZeroDevCleanerError if export fails
    func exportSettings(to url: URL, options: ExportOptions) async throws {
        // Validate that at least one option is selected
        guard options.hasAtLeastOneOption else {
            throw ZeroDevCleanerError.noSettingsToExport
        }

        // Gather settings from preferences
        let scanLocations = options.includeScanLocations ? (Preferences.scanLocations ?? []) : []
        let customCaches = options.includeCustomCaches ? (Preferences.customCacheLocations ?? []) : []

        // Get build folder configuration if requested
        var buildFolderConfig: BuildFolderConfiguration?
        if options.includeBuildFolderConfiguration {
            do {
                buildFolderConfig = try await ConfigurationManager.shared.loadConfiguration()
            } catch {
                // Log error but continue with export (config is optional)
                SuperLog.w("Failed to load build folder configuration for export: \(error)")
            }
        }

        // Validate that there are settings to export
        guard !scanLocations.isEmpty || !customCaches.isEmpty || buildFolderConfig != nil else {
            throw ZeroDevCleanerError.noSettingsToExport
        }

        // Create export object
        let export = SettingsExport(
            scanLocations: scanLocations,
            customCacheLocations: customCaches,
            buildFolderConfiguration: buildFolderConfig
        )

        do {
            // Encode to JSON with pretty printing
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(export)

            // Write to file
            try data.write(to: url, options: .atomic)
        } catch {
            throw ZeroDevCleanerError.exportFailed(error)
        }
    }

    /// Returns a preview of what will be exported without actually saving
    /// - Parameter options: Export options specifying what to include
    /// - Returns: SettingsExport object or nil if nothing to export
    func previewExport(options: ExportOptions) async -> SettingsExport? {
        let scanLocations = options.includeScanLocations ? (Preferences.scanLocations ?? []) : []
        let customCaches = options.includeCustomCaches ? (Preferences.customCacheLocations ?? []) : []

        var buildFolderConfig: BuildFolderConfiguration?
        if options.includeBuildFolderConfiguration {
            buildFolderConfig = try? await ConfigurationManager.shared.loadConfiguration()
        }

        guard !scanLocations.isEmpty || !customCaches.isEmpty || buildFolderConfig != nil else {
            return nil
        }

        return SettingsExport(
            scanLocations: scanLocations,
            customCacheLocations: customCaches,
            buildFolderConfiguration: buildFolderConfig
        )
    }
}
