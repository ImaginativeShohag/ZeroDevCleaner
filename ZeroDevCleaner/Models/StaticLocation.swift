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
        case .derivedData:
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

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedLastModified: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastModified, relativeTo: Date())
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
}
