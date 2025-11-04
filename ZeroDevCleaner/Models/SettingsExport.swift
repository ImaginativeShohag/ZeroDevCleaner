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

    /// Current version of the settings export format
    static let currentVersion = "1.0"

    init(
        version: String = currentVersion,
        exportDate: Date = Date(),
        scanLocations: [ScanLocation],
        customCacheLocations: [CustomCacheLocation]
    ) {
        self.version = version
        self.exportDate = exportDate
        self.scanLocations = scanLocations
        self.customCacheLocations = customCacheLocations
    }

    /// Total number of items being exported
    var totalItems: Int {
        scanLocations.count + customCacheLocations.count
    }

    /// Validates the export format version
    var isVersionSupported: Bool {
        // Currently only version 1.0 is supported
        // In future, add version migration logic here
        version == Self.currentVersion
    }
}

/// Options for what to include in the export
struct ExportOptions {
    var includeScanLocations: Bool
    var includeCustomCaches: Bool

    static let all = ExportOptions(
        includeScanLocations: true,
        includeCustomCaches: true
    )

    var hasAtLeastOneOption: Bool {
        includeScanLocations || includeCustomCaches
    }
}

/// Options for how to import settings
enum ImportMode {
    /// Add imported items to existing settings (keep both)
    case merge

    /// Replace existing settings with imported ones (remove existing)
    case replace
}
