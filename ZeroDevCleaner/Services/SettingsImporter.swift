//
//  SettingsImporter.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 04/11/25.
//

import Foundation

/// Protocol for importing settings from a file
protocol SettingsImporterProtocol: Sendable {
    /// Loads and validates settings from a file without applying them
    /// - Parameter url: The source file URL
    /// - Returns: The loaded SettingsExport object
    /// - Throws: ZeroDevCleanerError if import fails or file is invalid
    func loadSettings(from url: URL) async throws -> SettingsExport

    /// Imports settings from a previously loaded export
    /// - Parameters:
    ///   - export: The settings export to import
    ///   - mode: Whether to merge with or replace existing settings
    func applySettings(_ export: SettingsExport, mode: ImportMode) async
}

/// Service for importing app settings from a JSON file
@MainActor
final class SettingsImporter: SettingsImporterProtocol {
    /// Loads and validates settings from a file without applying them
    /// - Parameter url: The source file URL
    /// - Returns: The loaded SettingsExport object
    /// - Throws: ZeroDevCleanerError if import fails or file is invalid
    func loadSettings(from url: URL) async throws -> SettingsExport {
        do {
            // Read file data
            let data = try Data(contentsOf: url)

            // Decode JSON
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let export = try decoder.decode(SettingsExport.self, from: data)

            // Validate version
            guard export.isVersionSupported else {
                throw ZeroDevCleanerError.unsupportedVersion(export.version)
            }

            return export
        } catch let error as ZeroDevCleanerError {
            throw error
        } catch {
            throw ZeroDevCleanerError.importFailed(error)
        }
    }

    /// Imports settings from a previously loaded export
    /// - Parameters:
    ///   - export: The settings export to import
    ///   - mode: Whether to merge with or replace existing settings
    func applySettings(_ export: SettingsExport, mode: ImportMode) async {
        switch mode {
        case .merge:
            mergeScanLocations(export.scanLocations)
            mergeCustomCacheLocations(export.customCacheLocations)
            await mergeBuildFolderConfiguration(export.buildFolderConfiguration)

        case .replace:
            replaceScanLocations(export.scanLocations)
            replaceCustomCacheLocations(export.customCacheLocations)
            await replaceBuildFolderConfiguration(export.buildFolderConfiguration)
        }
    }

    // MARK: - Private Helpers

    /// Merges imported scan locations with existing ones, avoiding duplicates
    private func mergeScanLocations(_ imported: [ScanLocation]) {
        var existing = Preferences.scanLocations ?? []

        for location in imported {
            // Check if a location with the same path already exists
            if !existing.contains(where: { $0.path == location.path }) {
                existing.append(location)
            }
        }

        Preferences.scanLocations = existing
    }

    /// Replaces all existing scan locations with imported ones
    private func replaceScanLocations(_ imported: [ScanLocation]) {
        Preferences.scanLocations = imported.isEmpty ? nil : imported
    }

    /// Merges imported custom cache locations with existing ones, avoiding duplicates
    private func mergeCustomCacheLocations(_ imported: [CustomCacheLocation]) {
        var existing = Preferences.customCacheLocations ?? []

        for location in imported {
            // Check if a location with the same path already exists
            if !existing.contains(where: { $0.path == location.path }) {
                existing.append(location)
            }
        }

        Preferences.customCacheLocations = existing
    }

    /// Replaces all existing custom cache locations with imported ones
    private func replaceCustomCacheLocations(_ imported: [CustomCacheLocation]) {
        Preferences.customCacheLocations = imported.isEmpty ? nil : imported
    }

    /// Merges imported build folder configuration with existing one
    /// For configuration, merge means keeping existing and ignoring import (user config is authoritative)
    private func mergeBuildFolderConfiguration(_ imported: BuildFolderConfiguration?) async {
        guard let imported else { return }

        // In merge mode, we keep the existing user configuration
        // This prevents accidental overwrites of user customizations
        SuperLog.i("Merge mode: Keeping existing build folder configuration")

        // Optionally, we could add imported project types that don't exist in current config
        // But for simplicity, we just skip the import in merge mode
    }

    /// Replaces existing build folder configuration with imported one
    private func replaceBuildFolderConfiguration(_ imported: BuildFolderConfiguration?) async {
        guard let imported else { return }

        do {
            try await ConfigurationManager.shared.saveConfiguration(imported)
            SuperLog.i("Build folder configuration replaced with imported config")
        } catch {
            SuperLog.e("Failed to import build folder configuration: \(error)")
        }
    }
}
