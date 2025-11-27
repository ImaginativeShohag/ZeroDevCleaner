//
//  SettingsExport.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 04/11/25.
//

import Foundation

/// Represents the exported settings data structure
struct SettingsExport: Codable {
    /// Schema version for backwards compatibility
    let version: String

    /// Date when settings were exported
    let exportDate: Date

    /// User-configured scan locations
    let scanLocations: [ScanLocation]

    /// User-defined custom cache locations
    let customCacheLocations: [CustomCacheLocation]

    /// Build folder type configuration (optional for backwards compatibility)
    let buildFolderConfiguration: BuildFolderConfiguration?

    /// Current version of the settings export format
    static let currentVersion = "2.0"

    init(
        version: String = currentVersion,
        exportDate: Date = Date(),
        scanLocations: [ScanLocation],
        customCacheLocations: [CustomCacheLocation],
        buildFolderConfiguration: BuildFolderConfiguration? = nil
    ) {
        self.version = version
        self.exportDate = exportDate
        self.scanLocations = scanLocations
        self.customCacheLocations = customCacheLocations
        self.buildFolderConfiguration = buildFolderConfiguration
    }

    /// Total number of items being exported
    var totalItems: Int {
        let configCount = buildFolderConfiguration?.projectTypes.count ?? 0
        return scanLocations.count + customCacheLocations.count + configCount
    }

    /// Validates the export format version
    var isVersionSupported: Bool {
        // Support both 1.0 (legacy without config) and 2.0 (with config)
        version == "1.0" || version == Self.currentVersion
    }
}

/// Options for what to include in the export
struct ExportOptions: Sendable {
    var includeScanLocations: Bool
    var includeCustomCaches: Bool
    var includeBuildFolderConfiguration: Bool

    static let all = ExportOptions(
        includeScanLocations: true,
        includeCustomCaches: true,
        includeBuildFolderConfiguration: true
    )

    var hasAtLeastOneOption: Bool {
        includeScanLocations || includeCustomCaches || includeBuildFolderConfiguration
    }
}

/// Options for how to import settings
enum ImportMode {
    /// Add imported items to existing settings (keep both)
    case merge

    /// Replace existing settings with imported ones (remove existing)
    case replace
}
