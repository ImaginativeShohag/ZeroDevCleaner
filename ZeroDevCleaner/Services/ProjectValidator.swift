//
//  ProjectValidator.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation

final class ProjectValidator: ProjectValidatorProtocol, Sendable {
    nonisolated(unsafe) private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Detects project type from build folder path using configuration-driven validation
    /// - Parameter buildFolder: URL to the build folder
    /// - Parameter projectTypes: Array of project type configurations (in sequential order)
    /// - Returns: Matching ProjectType or nil if no match
    func detectProjectType(buildFolder: URL, projectTypes: [ProjectTypeConfig]) -> ProjectType? {
        let folderName = buildFolder.lastPathComponent

        // Iterate through project types in order (sequential detection)
        for config in projectTypes {
            // Check if folder name matches any of the configured folder names
            guard config.folderNames.contains(folderName) else {
                continue
            }

            // Validate using the configured validation rules
            if validateProjectType(buildFolder: buildFolder, config: config) {
                return ProjectType(from: config)
            }
        }

        return nil
    }

    // MARK: - Validation Logic

    /// Validates a project type using configuration rules
    private func validateProjectType(buildFolder: URL, config: ProjectTypeConfig) -> Bool {
        switch config.validation.mode {
        case .alwaysValid:
            // No validation needed - folder name match is sufficient
            return true

        case .parentDirectory:
            // Check immediate parent directory only
            return validateParentDirectory(buildFolder: buildFolder, rules: config.validation)

        case .parentHierarchy:
            // Search up parent hierarchy with max depth
            return validateParentHierarchy(buildFolder: buildFolder, rules: config.validation)

        case .directoryEnumeration:
            // Enumerate parent directory for specific file extensions
            return validateDirectoryEnumeration(buildFolder: buildFolder, rules: config.validation)
        }
    }

    /// Validate by checking immediate parent directory
    private func validateParentDirectory(buildFolder: URL, rules: ValidationRules) -> Bool {
        let parentURL = buildFolder.deletingLastPathComponent()

        // Check required files (anyOf or allOf)
        if let fileReq = rules.requiredFiles {
            if !validateFileRequirements(in: parentURL, requirements: fileReq) {
                return false
            }
        }

        // Check required directories (allOf)
        if let dirReq = rules.requiredDirectories {
            if !validateDirectoryRequirements(in: parentURL, requirements: dirReq) {
                return false
            }
        }

        return true
    }

    /// Validate by searching up parent hierarchy
    private func validateParentHierarchy(buildFolder: URL, rules: ValidationRules) -> Bool {
        let maxDepth = rules.maxSearchDepth ?? 5
        var currentURL = buildFolder.deletingLastPathComponent()
        var level = 0

        while level < maxDepth {
            // Check required files at this level
            if let fileReq = rules.requiredFiles {
                if validateFileRequirements(in: currentURL, requirements: fileReq) {
                    // Check directories if specified
                    if let dirReq = rules.requiredDirectories {
                        if validateDirectoryRequirements(in: currentURL, requirements: dirReq) {
                            return true
                        }
                    } else {
                        return true
                    }
                }
            }

            // Move up one level
            let parentURL = currentURL.deletingLastPathComponent()
            if parentURL == currentURL { break }
            currentURL = parentURL
            level += 1
        }

        return false
    }

    /// Validate by enumerating parent directory for file extensions
    private func validateDirectoryEnumeration(buildFolder: URL, rules: ValidationRules) -> Bool {
        guard let extensions = rules.fileExtensions, !extensions.isEmpty else {
            return false
        }

        let parentURL = buildFolder.deletingLastPathComponent()

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: parentURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )

            // Check if any file has one of the required extensions
            for url in contents {
                if extensions.contains(url.pathExtension) {
                    return true
                }
            }
        } catch {
            return false
        }

        return false
    }

    // MARK: - Requirement Validation

    /// Validate file requirements (anyOf or allOf logic)
    private func validateFileRequirements(in directory: URL, requirements: FileRequirement) -> Bool {
        // Check anyOf (OR logic) - at least one file must exist
        if let anyOf = requirements.anyOf, !anyOf.isEmpty {
            for fileName in anyOf {
                if directoryContainsFile(directory: directory, named: fileName) {
                    return true
                }
            }
            // If anyOf is specified but none found, fail
            return false
        }

        // Check allOf (AND logic) - all files must exist
        if let allOf = requirements.allOf, !allOf.isEmpty {
            for fileName in allOf {
                if !directoryContainsFile(directory: directory, named: fileName) {
                    return false
                }
            }
            return true
        }

        // No requirements specified
        return true
    }

    /// Validate directory requirements (allOf logic only)
    private func validateDirectoryRequirements(in directory: URL, requirements: DirectoryRequirement) -> Bool {
        // All directories must exist
        for dirName in requirements.allOf {
            let dirURL = directory.appendingPathComponent(dirName)
            var isDirectory: ObjCBool = false
            let exists = fileManager.fileExists(atPath: dirURL.path, isDirectory: &isDirectory)

            if !exists || !isDirectory.boolValue {
                return false
            }
        }

        return true
    }

    // MARK: - Helper Methods

    private func fileExists(at path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    private func directoryContainsFile(directory: URL, named: String) -> Bool {
        fileExists(at: directory.appendingPathComponent(named).path)
    }
}
