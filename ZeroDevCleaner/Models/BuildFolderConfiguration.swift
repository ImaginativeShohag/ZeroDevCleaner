//
//  BuildFolderConfiguration.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 28/11/25.
//

import Foundation

/// Root configuration structure for build folder detection
struct BuildFolderConfiguration: Codable {
    /// Configuration file version
    let version: String

    /// List of project types (order matters - checked sequentially)
    let projectTypes: [ProjectTypeConfig]
}

/// Configuration for a single project type
struct ProjectTypeConfig: Codable, Identifiable, Hashable {
    /// Unique identifier for this project type
    let id: String

    /// Human-readable name (e.g., "iOS/Xcode", "Node.js")
    let displayName: String

    /// SF Symbol icon name for UI display
    let iconName: String

    /// Hex color code (e.g., "#3DDC84" for Android green)
    let color: String

    /// Folder names to search for (e.g., ["build", ".build"])
    let folderNames: [String]

    /// Validation rules to confirm project type
    let validation: ValidationRules
}

/// Validation rules for detecting project type
struct ValidationRules: Codable, Hashable {
    /// Validation mode determines how to check for project markers
    let mode: ValidationMode

    /// Maximum levels to search up directory tree (for parentHierarchy mode)
    let maxSearchDepth: Int?

    /// Required files to find in parent directories
    let requiredFiles: FileRequirement?

    /// Required directories to find in parent
    let requiredDirectories: DirectoryRequirement?

    /// File extensions to search for (for directoryEnumeration mode)
    let fileExtensions: [String]?
}

/// File requirement with AND/OR logic
struct FileRequirement: Codable, Hashable {
    /// Match ANY of these files (OR condition)
    let anyOf: [String]?

    /// Match ALL of these files (AND condition)
    let allOf: [String]?
}

/// Directory requirement (always AND logic)
struct DirectoryRequirement: Codable, Hashable {
    /// All of these directories must exist
    let allOf: [String]
}

/// Validation mode determines detection strategy
enum ValidationMode: String, Codable {
    /// No validation needed - folder name is sufficient (e.g., Python __pycache__)
    case alwaysValid

    /// Check immediate parent directory only
    case parentDirectory

    /// Search up parent hierarchy (use maxSearchDepth)
    case parentHierarchy

    /// Enumerate parent directory for file extensions (e.g., .xcodeproj)
    case directoryEnumeration
}

// MARK: - Sendable Conformance

extension BuildFolderConfiguration: @unchecked Sendable {}
extension ProjectTypeConfig: Sendable {}
extension ValidationRules: Sendable {}
extension FileRequirement: Sendable {}
extension DirectoryRequirement: Sendable {}
extension ValidationMode: Sendable {}
