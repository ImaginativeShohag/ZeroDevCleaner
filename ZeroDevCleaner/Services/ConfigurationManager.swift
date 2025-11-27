//
//  ConfigurationManager.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 28/11/25.
//

import Foundation

/// Manages build folder type configuration
/// - User config is single source of truth
/// - Bundled config only used for initialization and reset
@MainActor
final class ConfigurationManager {
    static let shared = ConfigurationManager()

    // MARK: - File Paths

    /// Path to bundled default configuration (read-only)
    private let bundledConfigPath: URL = {
        guard let path = Bundle.main.url(forResource: "DefaultBuildFolderTypes", withExtension: "json") else {
            fatalError("DefaultBuildFolderTypes.json not found in bundle")
        }
        return path
    }()

    /// Path to user configuration (Application Support)
    private let userConfigPath: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appFolder = appSupport.appendingPathComponent("ZeroDevCleaner", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        return appFolder.appendingPathComponent("BuildFolderTypes.json", isDirectory: false)
    }()

    // MARK: - Initialization

    private init() {}

    /// Initialize configuration on first launch
    /// Copies bundled config to user location if user config doesn't exist
    func initialize() async throws {
        guard !FileManager.default.fileExists(atPath: userConfigPath.path) else {
            SuperLog.i("User config already exists at \(userConfigPath.path)")
            return
        }

        SuperLog.i("First launch - initializing user config from bundled defaults")
        try await Task.detached {
            try self.copyBundledToUser()
        }.value
    }

    // MARK: - Configuration Loading

    /// Load active configuration from user config file
    /// - Returns: Current build folder configuration
    /// - Throws: ConfigurationError if loading or parsing fails
    func loadConfiguration() throws -> BuildFolderConfiguration {
        SuperLog.d("Loading configuration from \(userConfigPath.path)")

        guard FileManager.default.fileExists(atPath: userConfigPath.path) else {
            SuperLog.e("User config not found at \(userConfigPath.path)")
            throw ConfigurationError.userConfigNotFound
        }

        do {
            let data = try Data(contentsOf: userConfigPath)
            let decoder = JSONDecoder()
            let config = try decoder.decode(BuildFolderConfiguration.self, from: data)

            SuperLog.i("Loaded configuration with \(config.projectTypes.count) project types")
            return config
        } catch let error as DecodingError {
            SuperLog.e("Failed to decode user config: \(error)")
            throw ConfigurationError.invalidFormat(error)
        } catch {
            SuperLog.e("Failed to load user config: \(error)")
            throw ConfigurationError.loadFailed(error)
        }
    }

    /// Load bundled default configuration (for reset/comparison)
    /// - Returns: Bundled default configuration
    /// - Throws: ConfigurationError if bundled config is missing or invalid
    func loadBundledConfiguration() throws -> BuildFolderConfiguration {
        SuperLog.d("Loading bundled configuration from \(bundledConfigPath.path)")

        do {
            let data = try Data(contentsOf: bundledConfigPath)
            let decoder = JSONDecoder()
            let config = try decoder.decode(BuildFolderConfiguration.self, from: data)

            SuperLog.i("Loaded bundled config with \(config.projectTypes.count) project types")
            return config
        } catch let error as DecodingError {
            SuperLog.e("Failed to decode bundled config: \(error)")
            throw ConfigurationError.bundledConfigCorrupted(error)
        } catch {
            SuperLog.e("Failed to load bundled config: \(error)")
            throw ConfigurationError.bundledConfigMissing
        }
    }

    // MARK: - Configuration Saving

    /// Save configuration to user config file
    /// - Parameter config: Configuration to save
    /// - Throws: ConfigurationError if saving fails
    func saveConfiguration(_ config: BuildFolderConfiguration) throws {
        SuperLog.i("Saving configuration with \(config.projectTypes.count) project types")

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: userConfigPath, options: .atomic)

            SuperLog.i("Configuration saved successfully to \(userConfigPath.path)")
        } catch {
            SuperLog.e("Failed to save configuration: \(error)")
            throw ConfigurationError.saveFailed(error)
        }
    }

    // MARK: - Reset

    /// Reset user configuration to bundled defaults
    /// - Throws: ConfigurationError if reset fails
    func resetToDefaults() async throws {
        SuperLog.i("Resetting user config to bundled defaults")

        // Validate bundled config first
        _ = try loadBundledConfiguration()

        // Copy bundled to user location
        try await Task.detached {
            try self.copyBundledToUser()
        }.value

        SuperLog.i("User config reset to defaults successfully")
    }

    // MARK: - Export/Import

    /// Export current user configuration as JSON data
    /// - Returns: JSON data for user config
    /// - Throws: ConfigurationError if export fails
    func exportConfiguration() throws -> Data {
        SuperLog.i("Exporting user configuration")

        let config = try loadConfiguration()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(config)
            SuperLog.i("Configuration exported successfully")
            return data
        } catch {
            SuperLog.e("Failed to export configuration: \(error)")
            throw ConfigurationError.exportFailed(error)
        }
    }

    /// Import configuration from JSON data
    /// - Parameter data: JSON data to import
    /// - Throws: ConfigurationError if import fails or data is invalid
    func importConfiguration(from data: Data) throws {
        SuperLog.i("Importing configuration")

        // Validate data first
        let decoder = JSONDecoder()
        do {
            let config = try decoder.decode(BuildFolderConfiguration.self, from: data)

            // Validate minimum requirements
            guard !config.projectTypes.isEmpty else {
                throw ConfigurationError.invalidImport("Configuration has no project types")
            }

            // Save imported config
            try saveConfiguration(config)

            SuperLog.i("Configuration imported successfully with \(config.projectTypes.count) project types")
        } catch let error as DecodingError {
            SuperLog.e("Failed to decode imported config: \(error)")
            throw ConfigurationError.invalidImport("Invalid JSON format")
        } catch let error as ConfigurationError {
            throw error
        } catch {
            SuperLog.e("Failed to import configuration: \(error)")
            throw ConfigurationError.importFailed(error)
        }
    }

    // MARK: - Validation

    /// Validate configuration for correctness
    /// - Parameter config: Configuration to validate
    /// - Returns: Array of validation warnings (empty if valid)
    func validateConfiguration(_ config: BuildFolderConfiguration) -> [String] {
        var warnings: [String] = []

        // Check for duplicate IDs
        let ids = config.projectTypes.map { $0.id }
        let uniqueIds = Set(ids)
        if ids.count != uniqueIds.count {
            warnings.append("Duplicate project type IDs found")
        }

        // Check for empty folder names
        for type in config.projectTypes {
            if type.folderNames.isEmpty {
                warnings.append("Project type '\(type.displayName)' has no folder names")
            }
        }

        // Check validation rules consistency
        for type in config.projectTypes {
            switch type.validation.mode {
            case .parentHierarchy:
                if type.validation.maxSearchDepth == nil {
                    warnings.append("Project type '\(type.displayName)' uses parentHierarchy but has no maxSearchDepth")
                }
            case .directoryEnumeration:
                if type.validation.fileExtensions == nil || type.validation.fileExtensions?.isEmpty == true {
                    warnings.append("Project type '\(type.displayName)' uses directoryEnumeration but has no fileExtensions")
                }
            case .parentDirectory:
                if type.validation.requiredFiles == nil && type.validation.requiredDirectories == nil {
                    warnings.append("Project type '\(type.displayName)' uses parentDirectory but has no requirements")
                }
            case .alwaysValid:
                break
            }
        }

        return warnings
    }

    // MARK: - Private Helpers

    /// Copy bundled config to user location
    nonisolated private func copyBundledToUser() throws {
        do {
            // Remove existing user config if present
            if FileManager.default.fileExists(atPath: userConfigPath.path) {
                try FileManager.default.removeItem(at: userConfigPath)
            }

            // Copy bundled to user location
            try FileManager.default.copyItem(at: bundledConfigPath, to: userConfigPath)

            SuperLog.i("Copied bundled config to user location")
        } catch {
            SuperLog.e("Failed to copy bundled config: \(error)")
            throw ConfigurationError.resetFailed(error)
        }
    }
}

// MARK: - Configuration Error

enum ConfigurationError: Error, LocalizedError {
    case userConfigNotFound
    case bundledConfigMissing
    case bundledConfigCorrupted(Error)
    case invalidFormat(Error)
    case loadFailed(Error)
    case saveFailed(Error)
    case exportFailed(Error)
    case importFailed(Error)
    case invalidImport(String)
    case resetFailed(Error)

    var errorDescription: String? {
        switch self {
        case .userConfigNotFound:
            return "User configuration file not found. Please reset to defaults."
        case .bundledConfigMissing:
            return "Default configuration file is missing from the app bundle."
        case .bundledConfigCorrupted(let error):
            return "Default configuration file is corrupted: \(error.localizedDescription)"
        case .invalidFormat(let error):
            return "Configuration file has invalid format: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load configuration: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save configuration: \(error.localizedDescription)"
        case .exportFailed(let error):
            return "Failed to export configuration: \(error.localizedDescription)"
        case .importFailed(let error):
            return "Failed to import configuration: \(error.localizedDescription)"
        case .invalidImport(let reason):
            return "Invalid configuration import: \(reason)"
        case .resetFailed(let error):
            return "Failed to reset to defaults: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .userConfigNotFound, .invalidFormat, .loadFailed:
            return "Try resetting to default configuration in Settings."
        case .bundledConfigMissing, .bundledConfigCorrupted:
            return "Please reinstall the application."
        case .saveFailed, .exportFailed, .importFailed:
            return "Check file permissions and disk space."
        case .invalidImport:
            return "Make sure you're importing a valid ZeroDevCleaner configuration file."
        case .resetFailed:
            return "Try restarting the application or check file permissions."
        }
    }
}
