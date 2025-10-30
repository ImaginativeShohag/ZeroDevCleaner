//
//  StaticLocationScanner.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import Foundation
import OSLog

protocol StaticLocationScannerProtocol: Sendable {
    func scanStaticLocations(
        types: [StaticLocationType],
        progressHandler: (@Sendable (String, Int) -> Void)?
    ) async throws -> [StaticLocation]
}

final class StaticLocationScanner: StaticLocationScannerProtocol, Sendable {
    private let sizeCalculator: FileSizeCalculatorProtocol
    nonisolated(unsafe) private let fileManager: FileManager

    init(
        sizeCalculator: FileSizeCalculatorProtocol = FileSizeCalculator(),
        fileManager: FileManager = .default
    ) {
        self.sizeCalculator = sizeCalculator
        self.fileManager = fileManager
    }

    func scanStaticLocations(
        types: [StaticLocationType],
        progressHandler: (@Sendable (String, Int) -> Void)?
    ) async throws -> [StaticLocation] {
        Logger.scanning.info("Starting static location scan for \(types.count) types")

        var results: [StaticLocation] = []

        for (index, type) in types.enumerated() {
            let path = type.defaultPath

            progressHandler?(path.path, index + 1)

            // Check if directory exists
            var isDirectory: ObjCBool = false
            let exists = fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory)

            guard exists && isDirectory.boolValue else {
                Logger.scanning.debug("Static location does not exist: \(path.path, privacy: .public)")
                // Still add it but mark as not existing with zero size
                let location = StaticLocation(
                    type: type,
                    path: path,
                    size: 0,
                    lastModified: Date(),
                    exists: false
                )
                results.append(location)
                continue
            }

            // Calculate size
            let size = try await sizeCalculator.calculateSize(of: path)

            // Get last modified date
            let attributes = try fileManager.attributesOfItem(atPath: path.path)
            let lastModified = attributes[.modificationDate] as? Date ?? Date()

            // Scan subfolders if supported (e.g., DerivedData, Archives, Device Support)
            var subItems: [StaticLocationSubItem] = []
            if type.supportsSubItems {
                subItems = try await scanSubItems(at: path, type: type)
            }

            let location = StaticLocation(
                type: type,
                path: path,
                size: size,
                lastModified: lastModified,
                exists: true,
                subItems: subItems
            )

            results.append(location)
            Logger.scanning.debug("Found static location: \(type.displayName, privacy: .public) - \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file), privacy: .public)")
        }

        Logger.scanning.info("Static location scan complete. Found \(results.filter(\.exists).count) of \(types.count) locations")
        return results
    }

    private func scanSubItems(at parentPath: URL, type: StaticLocationType) async throws -> [StaticLocationSubItem] {
        var subItems: [StaticLocationSubItem] = []

        // For Xcode Archives, we need to scan through date-based subfolders and group by app name
        // Structure: Archives/2025-10-27/AppName 27-10-25, 5.12 PM.xcarchive
        if type == .xcodeArchives {
            // Dictionary to group archives by app name
            var archivesByApp: [String: [ArchiveInfo]] = [:]

            let dateFolders = try fileManager.contentsOfDirectory(
                at: parentPath,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            for dateFolder in dateFolders {
                let resourceValues = try dateFolder.resourceValues(forKeys: [.isDirectoryKey])
                guard resourceValues.isDirectory == true else { continue }

                // Scan for .xcarchive files inside this date folder
                let archives = try fileManager.contentsOfDirectory(
                    at: dateFolder,
                    includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
                    options: [.skipsHiddenFiles]
                )

                for archiveURL in archives {
                    guard archiveURL.pathExtension == "xcarchive" else { continue }

                    let archiveResourceValues = try archiveURL.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey])
                    guard archiveResourceValues.isDirectory == true else { continue }

                    let size = try await sizeCalculator.calculateSize(of: archiveURL)
                    let lastModified = archiveResourceValues.contentModificationDate ?? Date()

                    // Parse archive metadata
                    if let archiveInfo = parseArchiveInfo(from: archiveURL, size: size, lastModified: lastModified) {
                        archivesByApp[archiveInfo.appName, default: []].append(archiveInfo)
                    }
                }
            }

            // Create grouped structure: App Name -> Versions
            for (appName, archives) in archivesByApp {
                // Sort versions by date (newest first)
                let sortedArchives = archives.sorted { $0.lastModified > $1.lastModified }

                // Calculate total size for this app (all versions)
                let totalSize = sortedArchives.reduce(0) { $0 + $1.size }

                // Get the most recent modification date
                let mostRecentDate = sortedArchives.first?.lastModified ?? Date()

                // Create version sub-items
                let versionItems = sortedArchives.map { archive in
                    StaticLocationSubItem(
                        name: archive.versionDisplay,
                        path: archive.path,
                        size: archive.size,
                        lastModified: archive.lastModified,
                        isSelected: false,
                        subItems: []
                    )
                }

                // Create app group item with versions as sub-items
                let appItem = StaticLocationSubItem(
                    name: appName,
                    path: sortedArchives.first!.path.deletingLastPathComponent(), // Use date folder as path
                    size: totalSize,
                    lastModified: mostRecentDate,
                    isSelected: false,
                    subItems: versionItems
                )

                subItems.append(appItem)
            }

            // Sort apps alphabetically
            return subItems.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }

        // For other types (DerivedData, Device Support), scan directly
        let contents = try fileManager.contentsOfDirectory(
            at: parentPath,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        for itemURL in contents {
            let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey])

            // Only include directories
            guard resourceValues.isDirectory == true else { continue }

            let size = try await sizeCalculator.calculateSize(of: itemURL)
            let lastModified = resourceValues.contentModificationDate ?? Date()

            // Format name based on type
            let displayName: String
            switch type {
            case .deviceSupport:
                // Parse device support to show iOS version and device model
                displayName = parseDeviceSupportName(from: itemURL) ?? itemURL.lastPathComponent
            default:
                // DerivedData and others use folder name
                displayName = itemURL.lastPathComponent
            }

            let subItem = StaticLocationSubItem(
                name: displayName,
                path: itemURL,
                size: size,
                lastModified: lastModified
            )

            subItems.append(subItem)
        }

        // Sort by size (largest first) for non-archive types
        return subItems.sorted { $0.size > $1.size }
    }

    /// Archive information for grouping
    private struct ArchiveInfo {
        let appName: String
        let version: String
        let build: String?
        let dateTime: String
        let path: URL
        let size: Int64
        let lastModified: Date

        var versionDisplay: String {
            let versionPart = build.map { "\(version) (\($0))" } ?? version
            return "\(versionPart) \(dateTime)"
        }
    }

    /// Parses archive info including version and date/time from folder name
    private func parseArchiveInfo(from archiveURL: URL, size: Int64, lastModified: Date) -> ArchiveInfo? {
        // Read Info.plist for app name and version
        let infoPlistPath = archiveURL.appendingPathComponent("Info.plist")

        guard fileManager.fileExists(atPath: infoPlistPath.path),
              let plistData = try? Data(contentsOf: infoPlistPath),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
              let properties = plist["ApplicationProperties"] as? [String: Any],
              let appName = properties["CFBundleName"] as? String ?? properties["CFBundleDisplayName"] as? String,
              let version = properties["CFBundleShortVersionString"] as? String else {
            return nil
        }

        let build = properties["CFBundleVersion"] as? String

        // Extract date/time from folder name: "MacScreenShare 27-10-25, 5.12 PM.xcarchive"
        let folderName = archiveURL.lastPathComponent
        let dateTime = extractDateTime(from: folderName, appName: appName)

        return ArchiveInfo(
            appName: appName,
            version: version,
            build: build,
            dateTime: dateTime,
            path: archiveURL,
            size: size,
            lastModified: lastModified
        )
    }

    /// Extracts date and time from archive folder name
    /// Format: "AppName 27-10-25, 5.12 PM.xcarchive" -> "27/10/25, 5:12 PM"
    private func extractDateTime(from folderName: String, appName: String) -> String {
        // Remove .xcarchive extension
        let nameWithoutExtension = folderName.replacingOccurrences(of: ".xcarchive", with: "")

        // Remove app name from the beginning
        let dateTimePart = nameWithoutExtension.replacingOccurrences(of: appName, with: "").trimmingCharacters(in: .whitespaces)

        // Replace dashes with slashes and dots with colons for better readability
        // "27-10-25, 5.12 PM" -> "27/10/25, 5:12 PM"
        let formatted = dateTimePart
            .replacingOccurrences(of: "-", with: "/")
            .replacingOccurrences(of: ".", with: ":")

        return formatted
    }

    /// Parses archive name to extract app name and version
    private func parseArchiveName(from archiveURL: URL) -> String? {
        // Archives contain a date-based folder structure
        // Look for Info.plist in the archive to get app name and version
        let infoPlistPath = archiveURL.appendingPathComponent("Info.plist")

        guard fileManager.fileExists(atPath: infoPlistPath.path),
              let plistData = try? Data(contentsOf: infoPlistPath),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
              let properties = plist["ApplicationProperties"] as? [String: Any],
              let appName = properties["CFBundleName"] as? String ?? properties["CFBundleDisplayName"] as? String,
              let version = properties["CFBundleShortVersionString"] as? String else {
            return nil
        }

        let build = properties["CFBundleVersion"] as? String
        if let build = build {
            return "\(appName) \(version) (\(build))"
        } else {
            return "\(appName) \(version)"
        }
    }

    /// Parses device support name to show iOS version and device model
    /// Folder format: "iPhone14,3 26.0.1 (23A355)" or "iPad11,1 26.0.1 (23A355)"
    private func parseDeviceSupportName(from deviceSupportURL: URL) -> String? {
        let folderName = deviceSupportURL.lastPathComponent

        // Split by space to get components
        // Format: "iPhone14,3 26.0.1 (23A355)"
        let components = folderName.split(separator: " ")

        guard components.count >= 2 else {
            return "iOS \(folderName)"
        }

        let deviceIdentifier = String(components[0])
        let version = String(components[1])

        // Extract build number if present (in parentheses)
        var buildNumber: String?
        if let buildStart = folderName.firstIndex(of: "("),
           let buildEnd = folderName.firstIndex(of: ")") {
            buildNumber = String(folderName[folderName.index(after: buildStart)..<buildEnd])
        }

        // Map device identifier to human-readable name
        let deviceName = mapDeviceIdentifierToName(deviceIdentifier)

        // Format: "iOS 26.0.1 (23A355) (iPhone 13 Pro Max)"
        if let build = buildNumber {
            return "iOS \(version) (\(build)) (\(deviceName))"
        } else {
            return "iOS \(version) (\(deviceName))"
        }
    }

    /// Maps device identifier (e.g., "iPhone14,3") to human-readable name
    private func mapDeviceIdentifierToName(_ identifier: String) -> String {
        // Common device identifiers mapped to names
        let deviceMap: [String: String] = [
            // iPhone 15 series
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone15,4": "iPhone 15 Plus",
            "iPhone15,5": "iPhone 15",

            // iPhone 14 series
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone14,7": "iPhone 14",

            // iPhone 13 series
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,5": "iPhone 13",
            "iPhone14,4": "iPhone 13 mini",

            // iPhone 12 series
            "iPhone13,4": "iPhone 12 Pro Max",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,2": "iPhone 12",
            "iPhone13,1": "iPhone 12 mini",

            // iPhone 11 series
            "iPhone12,5": "iPhone 11 Pro Max",
            "iPhone12,3": "iPhone 11 Pro",
            "iPhone12,1": "iPhone 11",

            // iPhone XS/XR series
            "iPhone11,8": "iPhone XR",
            "iPhone11,6": "iPhone XS Max",
            "iPhone11,4": "iPhone XS Max",
            "iPhone11,2": "iPhone XS",

            // iPhone X/8 series
            "iPhone10,6": "iPhone X",
            "iPhone10,3": "iPhone X",
            "iPhone10,5": "iPhone 8 Plus",
            "iPhone10,4": "iPhone 8",
            "iPhone10,2": "iPhone 8 Plus",
            "iPhone10,1": "iPhone 8",

            // iPad Pro
            "iPad14,6": "iPad Pro 12.9-inch (6th gen)",
            "iPad14,5": "iPad Pro 11-inch (4th gen)",
            "iPad13,11": "iPad Pro 12.9-inch (5th gen)",
            "iPad13,10": "iPad Pro 11-inch (3rd gen)",
            "iPad8,12": "iPad Pro 12.9-inch (4th gen)",
            "iPad8,11": "iPad Pro 11-inch (2nd gen)",

            // iPad Air
            "iPad13,17": "iPad Air (5th gen)",
            "iPad13,2": "iPad Air (4th gen)",
            "iPad11,4": "iPad Air (3rd gen)",

            // iPad
            "iPad13,19": "iPad (10th gen)",
            "iPad12,2": "iPad (9th gen)",
            "iPad11,7": "iPad (8th gen)",
        ]

        return deviceMap[identifier] ?? identifier
    }
}
