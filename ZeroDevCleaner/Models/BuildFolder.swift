//
//  BuildFolder.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation

/// Represents a build folder found during scanning
struct BuildFolder: Identifiable, Hashable, Codable, Sendable {
    /// Unique identifier
    let id: UUID

    /// Full path to the build folder
    let path: URL

    /// Type of project this build folder belongs to
    let projectType: ProjectType

    /// Size of the build folder in bytes
    let size: Int64

    /// Name of the parent project
    let projectName: String

    /// Last modified date of the build folder
    let lastModified: Date

    /// Whether this folder is selected for deletion
    var isSelected: Bool

    /// Initializer with all properties
    init(
        id: UUID = UUID(),
        path: URL,
        projectType: ProjectType,
        size: Int64,
        projectName: String,
        lastModified: Date,
        isSelected: Bool = false
    ) {
        self.id = id
        self.path = path
        self.projectType = projectType
        self.size = size
        self.projectName = projectName
        self.lastModified = lastModified
        self.isSelected = isSelected
    }

    /// Human-readable size (e.g., "125.5 MB")
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// Relative path from a given root (computed when needed)
    func relativePath(from root: URL) -> String {
        path.path.replacingOccurrences(of: root.path, with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    /// Human-readable last modified time (e.g., "5 days ago")
    var formattedLastModified: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastModified, relativeTo: Date())
    }
}
