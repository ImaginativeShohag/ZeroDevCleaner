//
//  StaticLocation.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import Foundation
import SwiftUI

enum StaticLocationType: String, Codable, CaseIterable, Sendable {
    case derivedData = "DerivedData"
    case xcodeArchives = "Xcode Archives"
    case deviceSupport = "Device Support"
    case xcodeDocumentationCache = "Xcode Documentation Cache"
    case gradleCache = "Gradle Cache"
    case cocoapodsCache = "CocoaPods Cache"
    case npmCache = "npm Cache"
    case yarnCache = "Yarn Cache"
    case bunCache = "Bun Cache"
    case carthageCache = "Carthage Cache"
    case phpCache = "PHP Cache"
    case composerCache = "Composer Cache"
    case dockerCache = "Docker Cache"
    case systemCache = "System Cache"
    case custom = "Custom Cache"

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .derivedData:
            return "Xcode build artifacts and indexes"
        case .xcodeArchives:
            return "Xcode app archives from builds"
        case .deviceSupport:
            return "iOS device support files"
        case .xcodeDocumentationCache:
            return "Xcode documentation and symbol cache"
        case .gradleCache:
            return "Gradle dependencies and build cache"
        case .cocoapodsCache:
            return "CocoaPods specs and pods cache"
        case .npmCache:
            return "npm package cache"
        case .yarnCache:
            return "Yarn package cache"
        case .bunCache:
            return "Bun package cache"
        case .carthageCache:
            return "Carthage build cache"
        case .phpCache:
            return "PHP OPcache and session files"
        case .composerCache:
            return "Composer package cache"
        case .dockerCache:
            return "Docker images, containers, and build cache"
        case .systemCache:
            return "macOS system caches and temporary files"
        case .custom:
            return "User-defined custom cache location"
        }
    }

    var iconName: String {
        switch self {
        case .derivedData:
            return "hammer.fill"
        case .xcodeArchives:
            return "archivebox.fill"
        case .deviceSupport:
            return "iphone.gen3"
        case .xcodeDocumentationCache:
            return "doc.text.fill"
        case .gradleCache:
            return "cube.fill"
        case .cocoapodsCache:
            return "shippingbox.fill"
        case .npmCache:
            return "n.square.fill"
        case .yarnCache:
            return "y.square.fill"
        case .bunCache:
            return "b.square.fill"
        case .carthageCache:
            return "archivebox.fill"
        case .phpCache:
            return "p.square.fill"
        case .composerCache:
            return "music.note.list"
        case .dockerCache:
            return "cube.transparent.fill"
        case .systemCache:
            return "gearshape.2.fill"
        case .custom:
            return "folder.badge.gearshape" // Default, will be overridden by custom icon
        }
    }

    var color: Color {
        switch self {
        case .derivedData:
            return .blue
        case .xcodeArchives:
            return .indigo
        case .deviceSupport:
            return .pink
        case .xcodeDocumentationCache:
            return .teal
        case .gradleCache:
            return .green
        case .cocoapodsCache:
            return .red
        case .npmCache:
            return .orange
        case .yarnCache:
            return .cyan
        case .bunCache:
            return .yellow
        case .carthageCache:
            return .purple
        case .phpCache:
            return .indigo
        case .composerCache:
            return .brown
        case .dockerCache:
            return .blue
        case .systemCache:
            return .gray
        case .custom:
            return .gray // Default, will be overridden by custom color
        }
    }

    var defaultPath: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        switch self {
        case .derivedData:
            return home.appendingPathComponent("Library/Developer/Xcode/DerivedData")
        case .xcodeArchives:
            return home.appendingPathComponent("Library/Developer/Xcode/Archives")
        case .deviceSupport:
            return home.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport")
        case .xcodeDocumentationCache:
            return home.appendingPathComponent("Library/Developer/Xcode/DocumentationCache")
        case .gradleCache:
            return home.appendingPathComponent(".gradle/caches")
        case .cocoapodsCache:
            return home.appendingPathComponent("Library/Caches/CocoaPods")
        case .npmCache:
            return home.appendingPathComponent(".npm")
        case .yarnCache:
            return home.appendingPathComponent("Library/Caches/Yarn")
        case .bunCache:
            return home.appendingPathComponent(".bun/install/cache")
        case .carthageCache:
            return home.appendingPathComponent("Library/Caches/org.carthage.CarthageKit")
        case .phpCache:
            return home.appendingPathComponent("Library/Caches/php")
        case .composerCache:
            return home.appendingPathComponent(".composer/cache")
        case .dockerCache:
            return home.appendingPathComponent("Library/Containers/com.docker.docker/Data")
        case .systemCache:
            return home.appendingPathComponent("Library/Caches")
        case .custom:
            return home // Not used for custom types
        }
    }

    /// Whether this location type should show subfolders
    var supportsSubItems: Bool {
        switch self {
        case .derivedData, .xcodeArchives, .deviceSupport, .xcodeDocumentationCache, .dockerCache, .systemCache, .custom:
            return true
        default:
            return false
        }
    }
}

/// Represents a subfolder within a static location (e.g., individual project folders in DerivedData)
struct StaticLocationSubItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: URL
    let size: Int64
    let lastModified: Date
    var isSelected: Bool = false
    var subItems: [StaticLocationSubItem] = []  // For nested items (e.g., app versions in archives)

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedLastModified: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastModified, relativeTo: Date())
    }

    /// Icon name based on whether the item is a file or directory
    var iconName: String {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: path.path, isDirectory: &isDirectory)
        return isDirectory.boolValue ? "folder.fill" : "doc.fill"
    }

    /// Whether this sub-item is old (not modified in 30+ days)
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

    /// Returns selected sub-items
    var selectedSubItems: [StaticLocationSubItem] {
        subItems.filter(\.isSelected)
    }

    /// Returns true if all sub-items are selected
    var allSubItemsSelected: Bool {
        !subItems.isEmpty && subItems.allSatisfy(\.isSelected)
    }

    /// Returns true if some (but not all) sub-items are selected
    var someSubItemsSelected: Bool {
        let selectedCount = selectedSubItems.count
        return selectedCount > 0 && selectedCount < subItems.count
    }
}

struct StaticLocation: Identifiable, Hashable {
    let id = UUID()
    let type: StaticLocationType
    let path: URL
    var size: Int64
    var lastModified: Date
    var exists: Bool
    var isSelected: Bool = false
    var subItems: [StaticLocationSubItem] = []

    // Custom cache metadata (only used when type == .custom)
    var customName: String?
    var customIconName: String?
    var customColorHex: String?

    var displayName: String {
        if type == .custom, let customName = customName {
            return customName
        }
        return type.displayName
    }

    var iconName: String {
        if type == .custom, let customIconName = customIconName {
            return customIconName
        }
        return type.iconName
    }

    var color: Color {
        if type == .custom, let customColorHex = customColorHex, let color = Color(hex: customColorHex) {
            return color
        }
        return type.color
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedLastModified: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastModified, relativeTo: Date())
    }

    /// Whether this location is old (not modified in 30+ days)
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

    /// Returns selected sub-items
    var selectedSubItems: [StaticLocationSubItem] {
        subItems.filter(\.isSelected)
    }

    /// Returns true if all sub-items are selected
    var allSubItemsSelected: Bool {
        !subItems.isEmpty && subItems.allSatisfy(\.isSelected)
    }

    /// Returns true if some (but not all) sub-items are selected
    var someSubItemsSelected: Bool {
        let selectedCount = selectedSubItems.count
        return selectedCount > 0 && selectedCount < subItems.count
    }
}
