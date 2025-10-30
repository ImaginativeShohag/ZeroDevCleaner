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
    case gradleCache = "Gradle Cache"
    case cocoapodsCache = "CocoaPods Cache"
    case npmCache = "npm Cache"
    case yarnCache = "Yarn Cache"
    case carthageCache = "Carthage Cache"

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .derivedData:
            return "Xcode build artifacts and indexes"
        case .xcodeArchives:
            return "Xcode app archives from builds"
        case .deviceSupport:
            return "iOS device support files"
        case .gradleCache:
            return "Gradle dependencies and build cache"
        case .cocoapodsCache:
            return "CocoaPods specs and pods cache"
        case .npmCache:
            return "npm package cache"
        case .yarnCache:
            return "Yarn package cache"
        case .carthageCache:
            return "Carthage build cache"
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
        case .gradleCache:
            return "cube.fill"
        case .cocoapodsCache:
            return "shippingbox.fill"
        case .npmCache:
            return "n.square.fill"
        case .yarnCache:
            return "y.square.fill"
        case .carthageCache:
            return "archivebox.fill"
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
        case .gradleCache:
            return .green
        case .cocoapodsCache:
            return .red
        case .npmCache:
            return .orange
        case .yarnCache:
            return .cyan
        case .carthageCache:
            return .purple
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
        case .gradleCache:
            return home.appendingPathComponent(".gradle/caches")
        case .cocoapodsCache:
            return home.appendingPathComponent("Library/Caches/CocoaPods")
        case .npmCache:
            return home.appendingPathComponent(".npm")
        case .yarnCache:
            return home.appendingPathComponent("Library/Caches/Yarn")
        case .carthageCache:
            return home.appendingPathComponent("Library/Caches/org.carthage.CarthageKit")
        }
    }

    /// Whether this location type should show subfolders
    var supportsSubItems: Bool {
        switch self {
        case .derivedData, .xcodeArchives, .deviceSupport:
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

    var displayName: String {
        type.displayName
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedLastModified: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastModified, relativeTo: Date())
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
