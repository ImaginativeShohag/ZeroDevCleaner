//
//  FilterPreset.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 31/10/25.
//

import Foundation

/// Represents quick filter presets for build folders
enum FilterPreset: String, Codable, CaseIterable, Sendable {
    case all
    case large       // > 1 GB
    case veryLarge   // > 5 GB
    case old         // > 30 days
    case recent      // < 7 days

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .all:
            return "All Items"
        case .large:
            return "Large (>1GB)"
        case .veryLarge:
            return "Huge (>5GB)"
        case .old:
            return "Old (>30 days)"
        case .recent:
            return "Recent (<7 days)"
        }
    }

    /// SF Symbol icon name for the filter preset
    var iconName: String {
        switch self {
        case .all:
            return "list.bullet"
        case .large:
            return "externaldrive.fill"
        case .veryLarge:
            return "externaldrive.fill.badge.exclamationmark"
        case .old:
            return "clock.fill"
        case .recent:
            return "clock.badge.checkmark"
        }
    }

    /// Description of the filter criteria
    var description: String {
        switch self {
        case .all:
            return "Show all build folders and caches"
        case .large:
            return "Show items larger than 1 GB"
        case .veryLarge:
            return "Show items larger than 5 GB"
        case .old:
            return "Show items not modified in 30+ days"
        case .recent:
            return "Show items modified in the last 7 days"
        }
    }

    /// Filter logic for build folders
    func matches(_ buildFolder: BuildFolder) -> Bool {
        switch self {
        case .all:
            return true
        case .large:
            return buildFolder.size >= 1_000_000_000 // 1 GB in bytes
        case .veryLarge:
            return buildFolder.size >= 5_000_000_000 // 5 GB in bytes
        case .old:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            return buildFolder.lastModified < thirtyDaysAgo
        case .recent:
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return buildFolder.lastModified > sevenDaysAgo
        }
    }

    /// Filter logic for static locations
    func matches(_ staticLocation: StaticLocation) -> Bool {
        switch self {
        case .all:
            return true
        case .large:
            return staticLocation.size >= 1_000_000_000 // 1 GB in bytes
        case .veryLarge:
            return staticLocation.size >= 5_000_000_000 // 5 GB in bytes
        case .old:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            return staticLocation.lastModified < thirtyDaysAgo
        case .recent:
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return staticLocation.lastModified > sevenDaysAgo
        }
    }
}
