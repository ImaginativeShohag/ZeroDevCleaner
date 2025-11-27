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

    /// Nested sub-folders (recursive hierarchy support)
    var subItems: [BuildFolder]

    /// Initializer with all properties
    init(
        id: UUID = UUID(),
        path: URL,
        projectType: ProjectType,
        size: Int64,
        projectName: String,
        lastModified: Date,
        isSelected: Bool = false,
        subItems: [BuildFolder] = []
    ) {
        self.id = id
        self.path = path
        self.projectType = projectType
        self.size = size
        self.projectName = projectName
        self.lastModified = lastModified
        self.isSelected = isSelected
        self.subItems = subItems
    }

    /// Human-readable size (e.g., "125.5 MB")
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// Human-readable last modified time (e.g., "5 days ago")
    var formattedLastModified: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastModified, relativeTo: Date())
    }

    /// Whether this folder is old (not modified in 30+ days)
    var isOld: Bool {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return lastModified < thirtyDaysAgo
    }

    /// Days since last modification
    var daysSinceModification: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastModified, to: Date())
        return components.day ?? 0
    }

    /// Returns relative path from a given root directory
    func relativePath(from root: URL) -> String {
        let pathComponents = path.pathComponents
        let rootComponents = root.pathComponents

        guard pathComponents.starts(with: rootComponents) else {
            return path.path
        }

        let relativeComponents = pathComponents.dropFirst(rootComponents.count)
        return relativeComponents.joined(separator: "/")
    }

    /// Total count including all nested sub-items recursively
    var totalCount: Int {
        1 + subItems.reduce(0) { $0 + $1.totalCount }
    }

    /// Total size including all nested sub-items (should already be included in parent size, but kept for clarity)
    var totalSizeIncludingSubItems: Int64 {
        size + subItems.reduce(0) { $0 + $1.size }
    }

    /// Count of selected items recursively
    var selectedCount: Int {
        let selfCount = isSelected ? 1 : 0
        let childCount = subItems.reduce(0) { $0 + $1.selectedCount }
        return selfCount + childCount
    }

    /// Whether this folder has any sub-items
    var hasSubItems: Bool {
        !subItems.isEmpty
    }

    /// All folder IDs in the hierarchy (for expansion state)
    var allFolderIds: [UUID] {
        [id] + subItems.flatMap { $0.allFolderIds }
    }
}
