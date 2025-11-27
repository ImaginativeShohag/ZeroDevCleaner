//
//  StaticLocationScanner.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import Foundation

protocol StaticLocationScannerProtocol: Sendable {
    func scanStaticLocations(
        types: [StaticLocationType],
        progressHandler: (@Sendable (String, Int) -> Void)?
    ) async throws -> [StaticLocation]

    func scanCustomCacheLocation(_ customLocation: CustomCacheLocation) async throws -> StaticLocation?
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
        SuperLog.i("Starting static location scan for \(types.count) types")

        var results: [StaticLocation] = []

        for (index, type) in types.enumerated() {
            // Check for cancellation at the start of each iteration
            try Task.checkCancellation()

            let path = type.defaultPath

            progressHandler?(path.path, index + 1)

            // Check if directory exists
            var isDirectory: ObjCBool = false
            let exists = fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory)

            guard exists && isDirectory.boolValue else {
                SuperLog.d("Static location does not exist: \(path.path)")
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

            // Check for cancellation before expensive operations
            try Task.checkCancellation()

            // Scan subfolders if supported (e.g., DerivedData, Archives, Device Support)
            var subItems: [StaticLocationSubItem] = []
            if type.supportsSubItems {
                // Special handling for Docker - use Docker CLI if available
                if type == .dockerCache {
                    subItems = try await scanDockerItems()

                    // If no Docker sub-items found (Docker not installed), skip this location entirely
                    if subItems.isEmpty {
                        SuperLog.d("Docker not installed or no Docker resources found, skipping Docker Cache location")
                        continue
                    }
                } else {
                    subItems = try await scanSubItems(at: path, type: type)
                }
            }

            // Check for cancellation before size calculation
            try Task.checkCancellation()

            // Calculate size (but skip for Docker since we get it from sub-items)
            let size: Int64
            if type == .dockerCache {
                // For Docker, size is sum of sub-items (from CLI)
                size = subItems.reduce(0) { $0 + $1.size }
            } else {
                // For other types, calculate from file system
                size = try await sizeCalculator.calculateSize(of: path)
            }

            // Get last modified date
            let attributes = try fileManager.attributesOfItem(atPath: path.path)
            let lastModified = attributes[.modificationDate] as? Date ?? Date()

            let location = StaticLocation(
                type: type,
                path: path,
                size: size,
                lastModified: lastModified,
                exists: true,
                subItems: subItems
            )

            results.append(location)
            SuperLog.d("Found static location: \(type.displayName) (\(type.defaultPath)) - \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
        }

        SuperLog.i("Static location scan complete. Found \(results.filter(\.exists).count) of \(types.count) locations")
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
                // Check for cancellation in outer loop
                try Task.checkCancellation()

                let resourceValues = try dateFolder.resourceValues(forKeys: [.isDirectoryKey])
                guard resourceValues.isDirectory == true else { continue }

                // Scan for .xcarchive files inside this date folder
                let archives = try fileManager.contentsOfDirectory(
                    at: dateFolder,
                    includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
                    options: [.skipsHiddenFiles]
                )

                for archiveURL in archives {
                    // Check for cancellation in inner loop
                    try Task.checkCancellation()

                    guard archiveURL.pathExtension == "xcarchive" else { continue }

                    let archiveResourceValues = try archiveURL.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey])
                    guard archiveResourceValues.isDirectory == true else { continue }

                    let size = try await sizeCalculator.calculateSize(of: archiveURL)
                    let lastModified = archiveResourceValues.contentModificationDate ?? Date()

                    // Parse archive metadata
                    if let archiveInfo = parseArchiveInfo(from: archiveURL, size: size, lastModified: lastModified) {
                        archivesByApp[archiveInfo.appName, default: []].append(archiveInfo)
                    } else {
                        // Fallback: Use folder name if Info.plist can't be read
                        SuperLog.w("Could not parse Info.plist for archive: \(archiveURL.lastPathComponent)")
                        let folderName = archiveURL.lastPathComponent.replacingOccurrences(of: ".xcarchive", with: "")
                        let fallbackInfo = ArchiveInfo(
                            appName: folderName,
                            version: "Unknown",
                            build: nil,
                            dateTime: "",
                            path: archiveURL,
                            size: size,
                            lastModified: lastModified
                        )
                        archivesByApp[fallbackInfo.appName, default: []].append(fallbackInfo)
                    }
                }
            }

            // Create grouped structure: App Name -> Versions
            SuperLog.d("Found \(archivesByApp.count) unique apps with archives")
            for (appName, archives) in archivesByApp {
                SuperLog.d("App '\(appName)' has \(archives.count) archive(s)")
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
                    size: totalSize,  // Total size of all versions
                    lastModified: mostRecentDate,
                    isSelected: false,
                    subItems: versionItems
                )

                subItems.append(appItem)
            }

            // Sort apps alphabetically
            let sortedApps = subItems.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            SuperLog.d("Returning \(sortedApps.count) app groups with total \(sortedApps.flatMap { $0.subItems }.count) archive versions")
            return sortedApps
        }

        // For Xcode Documentation Cache, scan through version folders
        // Structure: DocumentationCache/v289/NSOperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0)
        if type == .xcodeDocumentationCache {
            let versionFolders = try fileManager.contentsOfDirectory(
                at: parentPath,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            for versionFolder in versionFolders {
                // Check for cancellation in outer loop
                try Task.checkCancellation()

                let resourceValues = try versionFolder.resourceValues(forKeys: [.isDirectoryKey])
                guard resourceValues.isDirectory == true else { continue }

                // Scan for NSOperatingSystemVersion folders inside this version folder
                let osVersionFolders = try fileManager.contentsOfDirectory(
                    at: versionFolder,
                    includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
                    options: [.skipsHiddenFiles]
                )

                for osVersionURL in osVersionFolders {
                    // Check for cancellation in inner loop
                    try Task.checkCancellation()

                    let osResourceValues = try osVersionURL.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey])
                    guard osResourceValues.isDirectory == true else { continue }

                    let size = try await sizeCalculator.calculateSize(of: osVersionURL)
                    let lastModified = osResourceValues.contentModificationDate ?? Date()

                    // Parse version from folder name
                    if let displayName = parseDocumentationCacheVersion(from: osVersionURL) {
                        let subItem = StaticLocationSubItem(
                            name: displayName,
                            path: osVersionURL,
                            size: size,
                            lastModified: lastModified
                        )
                        subItems.append(subItem)
                    } else {
                        // Fallback: Use folder path
                        SuperLog.w("Could not parse version from documentation cache folder: \(osVersionURL.lastPathComponent)")
                        let displayName = "Cache from Xcode (Unknown version)"
                        let subItem = StaticLocationSubItem(
                            name: displayName,
                            path: osVersionURL,
                            size: size,
                            lastModified: lastModified
                        )
                        subItems.append(subItem)
                    }
                }
            }

            // Sort by version (newest first based on modification date)
            return subItems.sorted { $0.lastModified > $1.lastModified }
        }

        // For other types (DerivedData, Device Support), scan directly
        let contents = try fileManager.contentsOfDirectory(
            at: parentPath,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        for itemURL in contents {
            // Check for cancellation in loop
            try Task.checkCancellation()

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
              let appName = properties["CFBundleName"] as? String ?? properties["CFBundleDisplayName"] as? String ?? plist["Name"] as? String,
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

    /// Parses Xcode Documentation Cache version from folder name
    /// Folder format: "NSOperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0)"
    /// Returns: "Cache from Xcode 26.0.0"
    private func parseDocumentationCacheVersion(from url: URL) -> String? {
        let folderName = url.lastPathComponent

        // Use regex to extract version numbers
        // Pattern: majorVersion: (\d+), minorVersion: (\d+), patchVersion: (\d+)
        let pattern = #"majorVersion:\s*(\d+),\s*minorVersion:\s*(\d+),\s*patchVersion:\s*(\d+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: folderName, options: [], range: NSRange(folderName.startIndex..., in: folderName)),
              match.numberOfRanges == 4 else {
            return nil
        }

        // Extract version components
        guard let majorRange = Range(match.range(at: 1), in: folderName),
              let minorRange = Range(match.range(at: 2), in: folderName),
              let patchRange = Range(match.range(at: 3), in: folderName) else {
            return nil
        }

        let major = String(folderName[majorRange])
        let minor = String(folderName[minorRange])
        let patch = String(folderName[patchRange])

        return "Cache from Xcode \(major).\(minor).\(patch)"
    }

    // MARK: - Custom Cache Location Scanning

    /// Scans a custom cache location and returns a StaticLocation
    func scanCustomCacheLocation(_ customLocation: CustomCacheLocation) async throws -> StaticLocation? {
        SuperLog.i("Scanning custom cache location: '\(customLocation.name)' at path: \(customLocation.path.path)")

        let path = customLocation.path

        // Check if directory exists
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory)

        guard exists && isDirectory.boolValue else {
            SuperLog.w("Custom cache location does not exist or is not a directory: \(path.path)")
            // Return nil for non-existent custom locations (don't show them in UI)
            return nil
        }

        SuperLog.d("Calculating size for custom cache: \(customLocation.name)")
        // Calculate size
        let size = try await sizeCalculator.calculateSize(of: path)

        // Get last modified date
        let attributes = try fileManager.attributesOfItem(atPath: path.path)
        let lastModified = attributes[.modificationDate] as? Date ?? Date()

        // Scan subfolders if pattern is provided
        var subItems: [StaticLocationSubItem] = []
        if let pattern = customLocation.pattern, !pattern.isEmpty {
            SuperLog.d("Scanning custom cache '\(customLocation.name)' with pattern: '\(pattern)'")
            subItems = try await scanCustomSubItems(at: path, pattern: pattern)
            SuperLog.i("Found \(subItems.count) sub-item(s) matching pattern '\(pattern)' in '\(customLocation.name)'")
        }

        // If no pattern or no matches, scan immediate subdirectories
        if subItems.isEmpty {
            SuperLog.d("Scanning immediate subdirectories for custom cache: \(customLocation.name)")
            subItems = try await scanCustomSubItemsDefault(at: path)
            SuperLog.i("Found \(subItems.count) immediate subdirectory(ies) in '\(customLocation.name)'")
        }

        // Create StaticLocation with custom type and metadata
        let location = StaticLocation(
            type: .custom,
            path: path,
            size: size,
            lastModified: lastModified,
            exists: true,
            subItems: subItems,
            customName: customLocation.name,
            customIconName: customLocation.iconName,
            customColorHex: customLocation.colorHex
        )

        SuperLog.i("Completed scanning custom cache '\(customLocation.name)': \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)), \(subItems.count) sub-item(s)")
        return location
    }

    private func scanCustomSubItemsDefault(at parentPath: URL) async throws -> [StaticLocationSubItem] {
        SuperLog.d("Scanning immediate subdirectories at: \(parentPath.path)")
        var subItems: [StaticLocationSubItem] = []

        let contents = try fileManager.contentsOfDirectory(
            at: parentPath,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        SuperLog.d("Found \(contents.count) potential sub-item(s) to scan")

        for itemURL in contents {
            let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey])
            guard resourceValues.isDirectory == true else { continue }

            let size = try await sizeCalculator.calculateSize(of: itemURL)
            let lastModified = resourceValues.contentModificationDate ?? Date()

            let subItem = StaticLocationSubItem(
                name: itemURL.lastPathComponent,
                path: itemURL,
                size: size,
                lastModified: lastModified
            )

            subItems.append(subItem)
            SuperLog.d("  - Found sub-item: \(itemURL.lastPathComponent) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))")
        }

        return subItems.sorted { $0.size > $1.size } // Sort by size descending
    }

    private func scanCustomSubItems(at parentPath: URL, pattern: String) async throws -> [StaticLocationSubItem] {
        SuperLog.d("Scanning with pattern '\(pattern)' at: \(parentPath.path)")
        var subItems: [StaticLocationSubItem] = []

        let contents = try fileManager.contentsOfDirectory(
            at: parentPath,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        SuperLog.d("Checking \(contents.count) item(s) against pattern '\(pattern)'")

        for itemURL in contents {
            // Match pattern (simple wildcard matching for now)
            if matchesPattern(itemURL.lastPathComponent, pattern: pattern) {
                SuperLog.d("  - Matched: \(itemURL.lastPathComponent)")

                let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey])
                _ = resourceValues.isDirectory ?? false // Unused but kept for consistency

                let size = try await sizeCalculator.calculateSize(of: itemURL)
                let lastModified = resourceValues.contentModificationDate ?? Date()

                let subItem = StaticLocationSubItem(
                    name: itemURL.lastPathComponent,
                    path: itemURL,
                    size: size,
                    lastModified: lastModified
                )

                subItems.append(subItem)
            }
        }

        SuperLog.d("Pattern matching complete: \(subItems.count) match(es) found")
        return subItems.sorted { $0.size > $1.size }
    }

    private func matchesPattern(_ name: String, pattern: String) -> Bool {
        // Simple wildcard matching: * matches any characters
        let regexPattern = pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")

        guard let regex = try? NSRegularExpression(pattern: "^\(regexPattern)$", options: []) else {
            return false
        }

        let range = NSRange(name.startIndex..., in: name)
        return regex.firstMatch(in: name, options: [], range: range) != nil
    }

    // MARK: - Docker Scanning

    /// Common Docker CLI locations to check
    private let dockerPaths = [
        "/usr/local/bin/docker",           // Most common (Intel Macs, Homebrew)
        "/opt/homebrew/bin/docker",        // Apple Silicon Macs with Homebrew
        "/Applications/Docker.app/Contents/Resources/bin/docker", // Docker Desktop bundle
        "/usr/bin/docker"                  // Less common but possible
    ]

    /// Find Docker executable path
    private func findDockerPath() -> String? {
        for path in dockerPaths {
            if fileManager.fileExists(atPath: path) {
                SuperLog.d("Found Docker at: \(path)")
                return path
            }
        }
        SuperLog.w("Docker not found in any standard location: \(dockerPaths)")
        return nil
    }

    /// Scans Docker resources using Docker CLI
    private func scanDockerItems() async throws -> [StaticLocationSubItem] {
        SuperLog.i("Scanning Docker resources using Docker CLI")
        var subItems: [StaticLocationSubItem] = []

        // Check if Docker is installed first
        guard isDockerInstalled() else {
            SuperLog.i("Docker CLI not installed, skipping Docker cache entirely")
            return [] // Don't show Docker at all if not installed
        }

        // Check if Docker daemon is running
        let dockerAvailable = isDockerAvailable()

        if dockerAvailable {
            SuperLog.i("Docker daemon is running, scanning detailed resources...")

            // Get Docker images (with repository grouping)
            let images = try? await scanDockerImagesDetailed()
            if let images = images, !images.isEmpty {
                // Create a parent item for images
                let totalSize = images.reduce(0) { $0 + $1.size }
                let imagesParent = StaticLocationSubItem(
                    name: "Images (\(images.count) repositor\(images.count == 1 ? "y" : "ies"))",
                    path: URL(fileURLWithPath: "/var/lib/docker/images"),
                    size: totalSize,
                    lastModified: Date(),
                    isSelected: false,
                    subItems: images
                )
                subItems.append(imagesParent)
            }

            // Get Docker containers (ALL - running and stopped)
            let containers = try? await scanDockerContainersDetailed()
            if let containers = containers, !containers.isEmpty {
                // Create a parent item for containers
                let totalSize = containers.reduce(0) { $0 + $1.size }
                let containerParent = StaticLocationSubItem(
                    name: "Containers (\(containers.count))",
                    path: URL(fileURLWithPath: "/var/lib/docker/containers"),
                    size: totalSize,
                    lastModified: Date(),
                    isSelected: false,
                    subItems: containers
                )
                subItems.append(containerParent)
            }

            // Get Docker build cache (with detailed entries if available)
            let buildCacheItems = try? await scanDockerBuildCacheDetailed()
            if let buildCacheItems = buildCacheItems, !buildCacheItems.isEmpty {
                // Create a parent item for build cache
                let totalSize = buildCacheItems.reduce(0) { $0 + $1.size }
                let buildCacheParent = StaticLocationSubItem(
                    name: "Build Cache (\(buildCacheItems.count) entr\(buildCacheItems.count == 1 ? "y" : "ies"))",
                    path: URL(fileURLWithPath: "/var/lib/docker/buildkit"),
                    size: totalSize,
                    lastModified: Date(),
                    isSelected: false,
                    subItems: buildCacheItems
                )
                subItems.append(buildCacheParent)
            }

            // Get Docker volumes (with usage hints)
            let volumesItems = try? await scanDockerVolumesDetailed()
            if let volumesItems = volumesItems, !volumesItems.isEmpty {
                // Create a parent item for volumes
                let totalSize = volumesItems.reduce(0) { $0 + $1.size }
                let volumesParent = StaticLocationSubItem(
                    name: "Volumes (\(volumesItems.count))",
                    path: URL(fileURLWithPath: "/var/lib/docker/volumes"),
                    size: totalSize,
                    lastModified: Date(),
                    isSelected: false,
                    subItems: volumesItems
                )
                subItems.append(volumesParent)
            }
        } else {
            SuperLog.w("Docker daemon not running, showing only logs folder with warning")
        }

        // Always add log folder sub-item if Docker is installed and folder exists
        // This is safe to delete and accessible even when daemon is not running
        if let logItem = await scanDockerLogFolder(daemonRunning: dockerAvailable) {
            subItems.append(logItem)
        }

        SuperLog.i("Docker scan complete: found \(subItems.count) resource types")
        return subItems
    }

    /// Scan Docker log folder (always accessible, safe to delete)
    private func scanDockerLogFolder(daemonRunning: Bool) async -> StaticLocationSubItem? {
        SuperLog.d("Scanning Docker log folder...")
        let home = FileManager.default.homeDirectoryForCurrentUser
        let logPath = home.appendingPathComponent("Library/Containers/com.docker.docker/Data/log")

        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: logPath.path, isDirectory: &isDirectory)

        guard exists && isDirectory.boolValue else {
            SuperLog.d("Docker log folder does not exist at: \(logPath.path)")
            return nil
        }

        do {
            let size = try await sizeCalculator.calculateSize(of: logPath)
            let attributes = try fileManager.attributesOfItem(atPath: logPath.path)
            let lastModified = attributes[.modificationDate] as? Date ?? Date()

            SuperLog.i("Found Docker log folder with size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")

            // Add warning message if daemon is not running
            let warningMessage: String? = daemonRunning ? nil : "Docker is not running. Start Docker Desktop to see images, containers, volumes, and build cache."

            return StaticLocationSubItem(
                name: "Docker Logs",
                path: logPath,
                size: size,
                lastModified: lastModified,
                isSelected: false,
                subItems: [],
                warningMessage: warningMessage,
                hintMessage: nil,
                requiresDockerCli: false, // Logs can be deleted via file system
                dockerResourceId: nil,
                dockerResourceType: nil
            )
        } catch {
            SuperLog.w("Failed to scan Docker log folder: \(error.localizedDescription)")
            return nil
        }
    }

    /// Check if Docker CLI is installed (works without daemon)
    private func isDockerInstalled() -> Bool {
        SuperLog.d("Checking if Docker CLI is installed...")

        guard let dockerPath = findDockerPath() else {
            SuperLog.w("Docker CLI is not installed")
            return false
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: dockerPath)
        process.arguments = ["--version"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            let isInstalled = process.terminationStatus == 0
            SuperLog.d("Docker process exited with code: \(process.terminationStatus)")
            if isInstalled {
                let outputPipe = process.standardOutput as! Pipe
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let version = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown version"
                SuperLog.i("Docker CLI is installed at \(dockerPath): \(version)")
            } else {
                SuperLog.w("Docker CLI found but --version failed")
            }
            return isInstalled
        } catch {
            SuperLog.w("Docker CLI check failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Check if Docker CLI is available and running
    private func isDockerAvailable() -> Bool {
        SuperLog.d("Checking if Docker daemon is available...")

        guard let dockerPath = findDockerPath() else {
            SuperLog.w("Docker CLI not found, daemon cannot be checked")
            return false
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: dockerPath)
        process.arguments = ["info"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            let isAvailable = process.terminationStatus == 0
            if isAvailable {
                SuperLog.i("Docker daemon is available and running")
            } else {
                let errorPipe = process.standardError as! Pipe
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                SuperLog.w("Docker daemon not running - Exit code: \(process.terminationStatus), Error: \(errorOutput)")
            }
            return isAvailable
        } catch {
            SuperLog.w("Docker daemon check failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Scan Docker images
    private func scanDockerImages() async throws -> StaticLocationSubItem? {
        SuperLog.d("Scanning Docker images...")
        let output = try await runDockerCommand(["images", "--format", "{{.Size}}"])
        guard !output.isEmpty else {
            SuperLog.d("No Docker images found")
            return nil
        }

        // Parse sizes and calculate total
        let sizes = output.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { parseSizeString($0) }

        let totalSize = sizes.reduce(0, +)
        guard totalSize > 0 else {
            SuperLog.d("Docker images total size is 0")
            return nil
        }

        let count = sizes.count
        SuperLog.i("Found \(count) Docker image(s) with total size: \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")

        return StaticLocationSubItem(
            name: "Docker Images (\(count) image\(count == 1 ? "" : "s"))",
            path: URL(fileURLWithPath: "/var/lib/docker/images"), // Placeholder
            size: totalSize,
            lastModified: Date(),
            isSelected: false,
            subItems: []
        )
    }

    /// Scan Docker build cache
    private func scanDockerBuildCache() async throws -> StaticLocationSubItem? {
        SuperLog.d("Scanning Docker build cache...")
        let output = try await runDockerCommand(["system", "df", "-v", "--format", "{{.Type}}\t{{.Size}}"])
        guard !output.isEmpty else {
            SuperLog.d("No Docker build cache information found")
            return nil
        }

        // Find the build cache line
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            let parts = line.components(separatedBy: "\t")
            if parts.count == 2 && parts[0].contains("Build Cache") {
                if let size = parseSizeString(parts[1]), size > 0 {
                    SuperLog.i("Found Docker build cache with size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
                    return StaticLocationSubItem(
                        name: "Docker Build Cache",
                        path: URL(fileURLWithPath: "/var/lib/docker/buildkit"), // Placeholder
                        size: size,
                        lastModified: Date(),
                        isSelected: false,
                        subItems: []
                    )
                }
            }
        }

        SuperLog.d("No Docker build cache data found in output")
        return nil
    }

    /// Scan Docker volumes
    private func scanDockerVolumes() async throws -> StaticLocationSubItem? {
        SuperLog.d("Scanning Docker volumes...")
        let output = try await runDockerCommand(["volume", "ls", "-q"])
        guard !output.isEmpty else {
            SuperLog.d("No Docker volumes found")
            return nil
        }

        let volumes = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard !volumes.isEmpty else {
            SuperLog.d("No Docker volumes found after filtering")
            return nil
        }

        // Get total size of all volumes
        var totalSize: Int64 = 0
        for _ in volumes {
            if let sizeOutput = try? await runDockerCommand(["system", "df", "-v", "--format", "{{.Size}}"]) {
                if let size = parseSizeString(sizeOutput) {
                    totalSize += size
                }
            }
        }

        SuperLog.i("Found \(volumes.count) Docker volume(s) with total size: \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")

        return StaticLocationSubItem(
            name: "Docker Volumes (\(volumes.count) volume\(volumes.count == 1 ? "" : "s"))",
            path: URL(fileURLWithPath: "/var/lib/docker/volumes"), // Placeholder
            size: totalSize,
            lastModified: Date(),
            isSelected: false,
            subItems: []
        )
    }

    /// Scan Docker containers (ALL - running and stopped) with detailed information
    private func scanDockerContainersDetailed() async throws -> [StaticLocationSubItem] {
        SuperLog.d("Scanning all Docker containers (running and stopped)...")

        // Get all containers with JSON format for structured parsing
        let output = try await runDockerCommand(["ps", "-a", "--format", "{{json .}}"])
        guard !output.isEmpty else {
            SuperLog.d("No Docker containers found")
            return []
        }

        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard !lines.isEmpty else {
            SuperLog.d("No Docker containers found after filtering")
            return []
        }

        var containers: [StaticLocationSubItem] = []

        for line in lines {
            guard let jsonData = line.data(using: .utf8),
                  let container = try? JSONDecoder().decode(DockerContainer.self, from: jsonData) else {
                SuperLog.w("Failed to parse container JSON: \(line)")
                continue
            }

            // Parse size if available (format: "virtual size" or just size)
            let sizeBytes = parseSizeString(container.size) ?? 100_000_000 // Default 100MB estimate

            // Determine hint message based on state
            var hint: String?
            if container.state.lowercased() == "running" {
                hint = "Running"
            } else if container.state.lowercased() == "paused" {
                hint = "Paused"
            }

            // Create display name with image and status
            let displayName = "\(container.names) (\(container.image))"

            let subItem = StaticLocationSubItem(
                name: displayName,
                path: URL(fileURLWithPath: "/var/lib/docker/containers/\(container.id)"), // Placeholder path
                size: sizeBytes,
                lastModified: parseDockerDate(container.createdAt) ?? Date(),
                isSelected: false,
                subItems: [],
                warningMessage: nil,
                hintMessage: hint,
                requiresDockerCli: true,
                dockerResourceId: container.id,
                dockerResourceType: "container"
            )

            containers.append(subItem)
            SuperLog.d("  - Container: \(container.names) (\(container.state)) - \(container.status)")
        }

        // Sort: Running containers first, then by last modified
        containers.sort { lhs, rhs in
            if (lhs.hintMessage == "Running") != (rhs.hintMessage == "Running") {
                return lhs.hintMessage == "Running"
            }
            return lhs.lastModified > rhs.lastModified
        }

        SuperLog.i("Found \(containers.count) Docker container(s)")
        return containers
    }

    /// Scan Docker images with detailed information and repository grouping
    private func scanDockerImagesDetailed() async throws -> [StaticLocationSubItem] {
        SuperLog.d("Scanning Docker images with detailed information...")

        // Get all images with JSON format
        let output = try await runDockerCommand(["images", "--format", "{{json .}}"])
        guard !output.isEmpty else {
            SuperLog.d("No Docker images found")
            return []
        }

        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard !lines.isEmpty else {
            SuperLog.d("No Docker images found after filtering")
            return []
        }

        // Dictionary to group images by repository
        var imagesByRepository: [String: [DockerImage]] = [:]

        for line in lines {
            guard let jsonData = line.data(using: .utf8),
                  let image = try? JSONDecoder().decode(DockerImage.self, from: jsonData) else {
                SuperLog.w("Failed to parse image JSON: \(line)")
                continue
            }

            let repository = image.repository.isEmpty ? "<none>" : image.repository
            imagesByRepository[repository, default: []].append(image)
        }

        SuperLog.d("Found \(imagesByRepository.count) unique repository(ies)")

        var repositoryItems: [StaticLocationSubItem] = []

        for (repository, images) in imagesByRepository {
            // Sort images by creation date (newest first)
            let sortedImages = images.sorted { img1, img2 in
                if let date1 = parseDockerDate(img1.createdAt), let date2 = parseDockerDate(img2.createdAt) {
                    return date1 > date2
                }
                return false
            }

            // Create sub-items for each tag
            var tagItems: [StaticLocationSubItem] = []
            for image in sortedImages {
                let sizeBytes = parseSizeString(image.size) ?? 0
                let tag = image.tag.isEmpty ? "<none>" : image.tag
                let tagName = repository == "<none>" ? image.id : tag

                // For dangling images, add a warning
                let warning: String? = (repository == "<none>" && tag == "<none>") ? "Dangling image" : nil

                let tagItem = StaticLocationSubItem(
                    name: tagName,
                    path: URL(fileURLWithPath: "/var/lib/docker/images/\(image.id)"),
                    size: sizeBytes,
                    lastModified: parseDockerDate(image.createdAt) ?? Date(),
                    isSelected: false,
                    subItems: [],
                    warningMessage: warning,
                    hintMessage: nil,
                    requiresDockerCli: true,
                    dockerResourceId: image.id,
                    dockerResourceType: "image"
                )
                tagItems.append(tagItem)
            }

            // Calculate total size for this repository
            let totalSize = tagItems.reduce(0) { $0 + $1.size }

            // Create repository parent item
            let repositoryName = repository == "<none>" ? "<none> (Dangling)" : repository
            let repositoryItem = StaticLocationSubItem(
                name: "\(repositoryName) (\(tagItems.count) image\(tagItems.count == 1 ? "" : "s"))",
                path: URL(fileURLWithPath: "/var/lib/docker/images"),
                size: totalSize,
                lastModified: tagItems.first?.lastModified ?? Date(),
                isSelected: false,
                subItems: tagItems
            )

            repositoryItems.append(repositoryItem)
            SuperLog.d("  - Repository: \(repository) with \(tagItems.count) image(s), total size: \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
        }

        // Sort repositories alphabetically, but put dangling images at the end
        repositoryItems.sort { lhs, rhs in
            let lhsIsDangling = lhs.name.hasPrefix("<none>")
            let rhsIsDangling = rhs.name.hasPrefix("<none>")

            if lhsIsDangling != rhsIsDangling {
                return !lhsIsDangling // Non-dangling first
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }

        SuperLog.i("Found \(repositoryItems.count) Docker image repository(ies)")
        return repositoryItems
    }

    /// Scan Docker volumes with detailed information and usage hints
    private func scanDockerVolumesDetailed() async throws -> [StaticLocationSubItem] {
        SuperLog.d("Scanning Docker volumes with detailed information...")

        // Get all volumes with JSON format
        let output = try await runDockerCommand(["volume", "ls", "--format", "{{json .}}"])
        guard !output.isEmpty else {
            SuperLog.d("No Docker volumes found")
            return []
        }

        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard !lines.isEmpty else {
            SuperLog.d("No Docker volumes found after filtering")
            return []
        }

        var volumes: [StaticLocationSubItem] = []

        for line in lines {
            guard let jsonData = line.data(using: .utf8),
                  let volume = try? JSONDecoder().decode(DockerVolume.self, from: jsonData) else {
                SuperLog.w("Failed to parse volume JSON: \(line)")
                continue
            }

            // Try to get volume size by inspecting it
            // Note: Volume size is not directly available, we need to use inspect or system df
            let sizeBytes: Int64
            if let inspectOutput = try? await runDockerCommand(["volume", "inspect", volume.name, "--format", "{{.Mountpoint}}"]),
               !inspectOutput.isEmpty {
                let mountpoint = inspectOutput.trimmingCharacters(in: .whitespacesAndNewlines)
                // Try to calculate size from mountpoint (this may not work on macOS Docker Desktop)
                sizeBytes = 100_000_000 // Default 100MB estimate
                SuperLog.d("  - Volume \(volume.name) mountpoint: \(mountpoint)")
            } else {
                sizeBytes = 100_000_000 // Default 100MB estimate
            }

            // Check if volume is in use (Links > 0 means it's used by containers)
            // We'll need to get this info from docker system df -v
            let hintMessage: String? = nil // Will be set if we can determine usage
            let warningMessage: String? = nil // Will be set for unused volumes

            let volumeItem = StaticLocationSubItem(
                name: volume.name,
                path: URL(fileURLWithPath: "/var/lib/docker/volumes/\(volume.name)"),
                size: sizeBytes,
                lastModified: Date(), // Volumes don't have creation date in standard output
                isSelected: false,
                subItems: [],
                warningMessage: warningMessage,
                hintMessage: hintMessage,
                requiresDockerCli: true,
                dockerResourceId: volume.name,
                dockerResourceType: "volume"
            )

            volumes.append(volumeItem)
            SuperLog.d("  - Volume: \(volume.name) (driver: \(volume.driver))")
        }

        // Sort by name
        volumes.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        SuperLog.i("Found \(volumes.count) Docker volume(s)")
        return volumes
    }

    /// Scan Docker build cache with detailed information
    /// Note: Build cache scanning uses `docker buildx du` which may not be available on all systems
    /// Falls back to showing aggregate cache from `docker system df`
    private func scanDockerBuildCacheDetailed() async throws -> [StaticLocationSubItem] {
        SuperLog.d("Scanning Docker build cache...")

        // Try using buildx du for detailed cache information
        if let buildxOutput = try? await runDockerCommand(["buildx", "du", "--verbose"]) {
            return try parseBuildxDuOutput(buildxOutput)
        }

        SuperLog.d("buildx du not available, falling back to system df")

        // Fallback: use system df to get aggregate build cache size
        if let systemDfOutput = try? await runDockerCommand(["system", "df", "-v"]) {
            return try parseSystemDfBuildCache(systemDfOutput)
        }

        SuperLog.d("No build cache information available")
        return []
    }

    /// Parse buildx du output for detailed cache entries
    private func parseBuildxDuOutput(_ output: String) throws -> [StaticLocationSubItem] {
        SuperLog.d("Parsing buildx du output...")
        var cacheItems: [StaticLocationSubItem] = []

        let lines = output.components(separatedBy: "\n")

        // Skip header lines and parse data rows
        // Format: ID  RECLAIMABLE  SIZE  LAST ACCESSED  DESCRIPTION
        for line in lines.dropFirst(1) where !line.isEmpty {
            let components = line.split(separator: "\t").map { String($0).trimmingCharacters(in: .whitespaces) }
            guard components.count >= 3 else { continue }

            let cacheId = components[0]
            let sizeStr = components[2]
            let lastAccessed = components.count > 3 ? components[3] : "Unknown"

            guard let sizeBytes = parseSizeString(sizeStr) else { continue }

            // Truncate cache ID for display
            let displayId = String(cacheId.prefix(12))

            let cacheItem = StaticLocationSubItem(
                name: "Cache \(displayId)",
                path: URL(fileURLWithPath: "/var/lib/docker/buildkit/\(cacheId)"),
                size: sizeBytes,
                lastModified: Date(), // buildx doesn't provide exact date
                isSelected: false,
                subItems: [],
                warningMessage: nil,
                hintMessage: lastAccessed != "Unknown" ? "Last used: \(lastAccessed)" : nil,
                requiresDockerCli: true,
                dockerResourceId: cacheId,
                dockerResourceType: "buildCache"
            )

            cacheItems.append(cacheItem)
        }

        SuperLog.i("Found \(cacheItems.count) build cache entry(ies) via buildx du")
        return cacheItems
    }

    /// Parse system df output for aggregate build cache
    private func parseSystemDfBuildCache(_ output: String) throws -> [StaticLocationSubItem] {
        SuperLog.d("Parsing system df for build cache...")

        // Look for "Build Cache" line in output
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            if line.contains("Build Cache") {
                // Extract size from line (format varies)
                let components = line.split(separator: " ").map { String($0) }

                // Find size component (usually has KB, MB, GB)
                for component in components {
                    if let size = parseSizeString(component), size > 0 {
                        let cacheItem = StaticLocationSubItem(
                            name: "Build Cache (aggregate)",
                            path: URL(fileURLWithPath: "/var/lib/docker/buildkit"),
                            size: size,
                            lastModified: Date(),
                            isSelected: false,
                            subItems: [],
                            warningMessage: nil,
                            hintMessage: "Cannot show individual cache entries. Use 'docker builder prune' to clean.",
                            requiresDockerCli: false, // Can't delete individual items
                            dockerResourceId: nil,
                            dockerResourceType: nil
                        )

                        SuperLog.i("Found aggregate build cache: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
                        return [cacheItem]
                    }
                }
            }
        }

        SuperLog.d("No build cache found in system df output")
        return []
    }

    // MARK: - Docker JSON Structures

    /// Docker container JSON structure
    private struct DockerContainer: Decodable {
        let id: String              // Container ID (short)
        let names: String           // Container names
        let image: String           // Image name
        let state: String           // State: running, exited, paused, etc.
        let status: String          // Human-readable status (e.g., "Up 2 hours", "Exited (0) 3 days ago")
        let createdAt: String       // Creation timestamp
        let size: String            // Size information

        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case names = "Names"
            case image = "Image"
            case state = "State"
            case status = "Status"
            case createdAt = "CreatedAt"
            case size = "Size"
        }
    }

    /// Docker image JSON structure
    private struct DockerImage: Decodable {
        let repository: String      // Repository name
        let tag: String            // Image tag
        let id: String             // Image ID (short)
        let createdAt: String      // Creation timestamp
        let size: String           // Size (e.g., "1.2GB")

        enum CodingKeys: String, CodingKey {
            case repository = "Repository"
            case tag = "Tag"
            case id = "ID"
            case createdAt = "CreatedAt"
            case size = "Size"
        }
    }

    /// Docker volume JSON structure
    private struct DockerVolume: Decodable {
        let name: String           // Volume name
        let driver: String         // Volume driver (usually "local")

        enum CodingKeys: String, CodingKey {
            case name = "Name"
            case driver = "Driver"
        }
    }

    /// Run Docker command and return output
    private func runDockerCommand(_ arguments: [String]) async throws -> String {
        let commandString = "docker " + arguments.joined(separator: " ")
        SuperLog.d("Executing Docker command: \(commandString)")

        guard let dockerPath = findDockerPath() else {
            SuperLog.e("Docker CLI not found, cannot execute command: \(commandString)")
            throw NSError(
                domain: "DockerError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Docker CLI not found on this system"]
            )
        }

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: dockerPath)
            process.arguments = arguments

            let pipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = pipe
            process.standardError = errorPipe

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    SuperLog.d("Docker command succeeded: \(commandString) (output length: \(output.count) chars)")
                    continuation.resume(returning: output)
                } else {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    SuperLog.w("Docker command failed: \(commandString) - Exit code: \(process.terminationStatus), Error: \(errorOutput)")
                    continuation.resume(throwing: NSError(
                        domain: "DockerError",
                        code: Int(process.terminationStatus),
                        userInfo: [NSLocalizedDescriptionKey: "Docker command failed: \(errorOutput)"]
                    ))
                }
            } catch {
                SuperLog.e("Failed to execute Docker command: \(commandString) - \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }

    /// Parse Docker size string (e.g., "1.2GB", "500MB", "10KB") to bytes
    private func parseSizeString(_ sizeStr: String) -> Int64? {
        let trimmed = sizeStr.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Extract number and unit
        let pattern = #"([\d.]+)\s*([KMGT]?B)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(trimmed.startIndex..., in: trimmed)),
              match.numberOfRanges == 3 else {
            return nil
        }

        guard let numberRange = Range(match.range(at: 1), in: trimmed),
              let unitRange = Range(match.range(at: 2), in: trimmed),
              let value = Double(String(trimmed[numberRange])) else {
            return nil
        }

        let unit = String(trimmed[unitRange]).uppercased()
        let multiplier: Double
        switch unit {
        case "B":
            multiplier = 1
        case "KB":
            multiplier = 1024
        case "MB":
            multiplier = 1024 * 1024
        case "GB":
            multiplier = 1024 * 1024 * 1024
        case "TB":
            multiplier = 1024 * 1024 * 1024 * 1024
        default:
            return nil
        }

        return Int64(value * multiplier)
    }

    /// Parse Docker date string to Date
    /// Docker dates are in format: "2025-11-14 05:30:00 +0000 UTC"
    private func parseDockerDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z z"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        if let date = formatter.date(from: dateString) {
            return date
        }

        // Try alternative format without timezone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: dateString)
    }
}
