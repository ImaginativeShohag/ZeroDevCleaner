//
//  FilterManager.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 05/11/25.
//

import Foundation
import Observation

@Observable
@MainActor
final class FilterManager {
    // MARK: - Filter Types

    enum FilterType: String, CaseIterable, Sendable {
        case all = "All"
        case android = "Android"
        case iOS = "iOS"
        case swiftPackage = "Swift Package"
        case flutter = "Flutter"
        case nodeJS = "Node.js"
        case rust = "Rust"
        case python = "Python"
        case go = "Go"
        case javaMaven = "Java/Maven"
        case ruby = "Ruby"
        case dotNet = ".NET"
        case unity = "Unity"

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .android: return "cube.fill"
            case .iOS: return "apple.logo"
            case .swiftPackage: return "shippingbox.fill"
            case .flutter: return "wind"
            case .nodeJS: return "atom"
            case .rust: return "gearshape.2.fill"
            case .python: return "chevron.left.forwardslash.chevron.right"
            case .go: return "g.square.fill"
            case .javaMaven: return "cup.and.saucer.fill"
            case .ruby: return "diamond.fill"
            case .dotNet: return "number.square.fill"
            case .unity: return "cube.transparent.fill"
            }
        }
    }

    enum ComparisonOperator: String, CaseIterable, Sendable {
        case equal = "="
        case lessThan = "<"
        case lessThanOrEqual = "<="
        case greaterThan = ">"
        case greaterThanOrEqual = ">="

        var displayName: String {
            rawValue
        }

        func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> Bool {
            switch self {
            case .equal:
                return lhs == rhs
            case .lessThan:
                return lhs < rhs
            case .lessThanOrEqual:
                return lhs <= rhs
            case .greaterThan:
                return lhs > rhs
            case .greaterThanOrEqual:
                return lhs >= rhs
            }
        }
    }

    // MARK: - State Properties

    /// Current filter type
    var currentFilter: FilterType = .all

    /// Current quick filter preset
    var currentPreset: FilterPreset = .all

    /// Comprehensive filter: size value in bytes (nil = no filter)
    var sizeFilterValue: Int64? = nil

    /// Comprehensive filter: size comparison operator
    var sizeFilterOperator: ComparisonOperator = .greaterThanOrEqual

    /// Comprehensive filter: days old value (nil = no filter)
    var daysOldFilterValue: Int? = nil

    /// Comprehensive filter: days old comparison operator
    var daysOldFilterOperator: ComparisonOperator = .greaterThanOrEqual

    /// Whether to show comprehensive filters
    var showComprehensiveFilters: Bool = false

    // MARK: - Filtering Logic

    /// Filter and apply all filter criteria to build folders
    func filteredResults(from buildFolders: [BuildFolder]) -> [BuildFolder] {

        // First apply project type filter
        var results: [BuildFolder]
        if currentFilter == .all {
            results = buildFolders
        } else {
            results = buildFolders.filter { folder in
                switch currentFilter {
                case .all:
                    return true
                case .android:
                    return folder.projectType.id == "android"
                case .iOS:
                    return folder.projectType.id == "iOS"
                case .swiftPackage:
                    return folder.projectType.id == "swiftPackage"
                case .flutter:
                    return folder.projectType.id == "flutter"
                case .nodeJS:
                    return folder.projectType.id == "nodeJS"
                case .rust:
                    return folder.projectType.id == "rust"
                case .python:
                    return folder.projectType.id == "python"
                case .go:
                    return folder.projectType.id == "go"
                case .javaMaven:
                    return folder.projectType.id == "javaMaven"
                case .ruby:
                    return folder.projectType.id == "ruby"
                case .dotNet:
                    return folder.projectType.id == "dotNet"
                case .unity:
                    return folder.projectType.id == "unity"
                }
            }
        }

        // Then apply preset filter
        if currentPreset != .all {
            results = results.filter { currentPreset.matches($0) }
        }

        // Apply comprehensive size filter
        if let sizeValue = sizeFilterValue {
            results = results.filter { folder in
                sizeFilterOperator.compare(folder.size, sizeValue)
            }
        }

        // Apply comprehensive days old filter
        if let daysValue = daysOldFilterValue {
            results = results.filter { folder in
                let daysSinceModified = Calendar.current.dateComponents([.day], from: folder.lastModified, to: Date()).day ?? 0
                return daysOldFilterOperator.compare(daysSinceModified, daysValue)
            }
        }

        return results
    }

    /// Filter static locations based on current filters
    func filteredStaticLocations(from staticLocations: [StaticLocation]) -> [StaticLocation] {
        var results: [StaticLocation]

        if currentPreset == .all {
            results = staticLocations
        } else {
            results = staticLocations.filter { currentPreset.matches($0) }
        }

        // Apply comprehensive size filter
        if let sizeValue = sizeFilterValue {
            results = results.filter { location in
                sizeFilterOperator.compare(location.size, sizeValue)
            }
        }

        // Apply comprehensive days old filter
        if let daysValue = daysOldFilterValue {
            results = results.filter { location in
                let daysSinceModified = Calendar.current.dateComponents([.day], from: location.lastModified, to: Date()).day ?? 0
                return daysOldFilterOperator.compare(daysSinceModified, daysValue)
            }
        }

        // Sort: existing items first, then empty items at the bottom
        return results.sorted { lhs, rhs in
            if lhs.exists && !rhs.exists {
                return true // existing comes before empty
            } else if !lhs.exists && rhs.exists {
                return false // empty comes after existing
            } else {
                // Both have same exists status, maintain original order by comparing sizes
                return lhs.size > rhs.size
            }
        }
    }

    /// Get count for a specific filter type
    func count(for filter: FilterType, in buildFolders: [BuildFolder]) -> Int {
        if filter == .all {
            return buildFolders.count
        }

        return buildFolders.filter { folder in
            switch filter {
            case .all:
                return true
            case .android:
                return folder.projectType.id == "android"
            case .iOS:
                return folder.projectType.id == "iOS"
            case .swiftPackage:
                return folder.projectType.id == "swiftPackage"
            case .flutter:
                return folder.projectType.id == "flutter"
            case .nodeJS:
                return folder.projectType.id == "nodeJS"
            case .rust:
                return folder.projectType.id == "rust"
            case .python:
                return folder.projectType.id == "python"
            case .go:
                return folder.projectType.id == "go"
            case .javaMaven:
                return folder.projectType.id == "javaMaven"
            case .ruby:
                return folder.projectType.id == "ruby"
            case .dotNet:
                return folder.projectType.id == "dotNet"
            case .unity:
                return folder.projectType.id == "unity"
            }
        }.count
    }

    /// Filter types sorted by count (descending)
    func sortedFilterTypes(for buildFolders: [BuildFolder]) -> [FilterType] {
        return FilterType.allCases.sorted { count(for: $0, in: buildFolders) > count(for: $1, in: buildFolders) }
    }
}
