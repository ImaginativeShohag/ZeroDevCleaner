//
//  ProjectType.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation
import SwiftUI

/// Represents the type of development project
/// Dynamically loaded from configuration file
struct ProjectType: Codable, Identifiable, Hashable, Sendable {
    /// Unique identifier for this project type
    let id: String

    /// Human-readable display name (e.g., "iOS/Xcode", "Node.js")
    let displayName: String

    /// SF Symbol icon name for UI display
    let iconName: String

    /// Hex color code (e.g., "#3DDC84" for Android green)
    private let colorHex: String

    /// Folder name that this type is detected by (for display purposes only)
    let buildFolderName: String

    /// Validation rules for detecting this project type
    let validation: ValidationRules

    init(
        id: String,
        displayName: String,
        iconName: String,
        colorHex: String,
        buildFolderName: String,
        validation: ValidationRules
    ) {
        self.id = id
        self.displayName = displayName
        self.iconName = iconName
        self.colorHex = colorHex
        self.buildFolderName = buildFolderName
        self.validation = validation
    }

    /// Color for the project type icon
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }

    // MARK: - Convenience Initializer from Config

    /// Create ProjectType from configuration
    init(from config: ProjectTypeConfig) {
        self.id = config.id
        self.displayName = config.displayName
        self.iconName = config.iconName
        self.colorHex = config.color
        self.buildFolderName = config.folderNames.first ?? "build"
        self.validation = config.validation
    }
}

// MARK: - Preview Helpers

extension ProjectType {
    /// Mock Android project type for previews
    static let android = ProjectType(
        id: "android",
        displayName: "Android",
        iconName: "app.badge.fill",
        colorHex: "#3DDC84",
        buildFolderName: "build",
        validation: ValidationRules(mode: .parentHierarchy, maxSearchDepth: 5, requiredFiles: FileRequirement(anyOf: ["build.gradle"], allOf: nil), requiredDirectories: nil, fileExtensions: nil)
    )

    /// Mock iOS project type for previews
    static let iOS = ProjectType(
        id: "iOS",
        displayName: "iOS/Xcode",
        iconName: "apple.logo",
        colorHex: "#007AFF",
        buildFolderName: "build",
        validation: ValidationRules(mode: .directoryEnumeration, maxSearchDepth: nil, requiredFiles: nil, requiredDirectories: nil, fileExtensions: ["xcodeproj", "xcworkspace"])
    )
}
