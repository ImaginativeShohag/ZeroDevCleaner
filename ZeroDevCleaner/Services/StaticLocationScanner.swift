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

            // Calculate size
            let size = try await sizeCalculator.calculateSize(of: path)

            // Get last modified date
            let attributes = try fileManager.attributesOfItem(atPath: path.path)
            let lastModified = attributes[.modificationDate] as? Date ?? Date()

            // Scan subfolders if supported (e.g., DerivedData, Archives, Device Support)
            var subItems: [StaticLocationSubItem] = []
            if type.supportsSubItems {
                // Special handling for Docker - use Docker CLI if available
                if type == .dockerCache {
                    subItems = try await scanDockerItems()
                } else {
                    subItems = try await scanSubItems(at: path, type: type)
                }
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
                let resourceValues = try versionFolder.resourceValues(forKeys: [.isDirectoryKey])
                guard resourceValues.isDirectory == true else { continue }

                // Scan for NSOperatingSystemVersion folders inside this version folder
                let osVersionFolders = try fileManager.contentsOfDirectory(
                    at: versionFolder,
                    includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
                    options: [.skipsHiddenFiles]
                )

                for osVersionURL in osVersionFolders {
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

    /// Scans Docker resources using Docker CLI
    private func scanDockerItems() async throws -> [StaticLocationSubItem] {
        SuperLog.i("Scanning Docker resources using Docker CLI")
        var subItems: [StaticLocationSubItem] = []

        // Check if Docker CLI is available
        guard isDockerAvailable() else {
            SuperLog.w("Docker CLI not available, falling back to directory scan")
            return []
        }

        // Get Docker images (including dangling)
        if let imagesItem = try? await scanDockerImages() {
            subItems.append(imagesItem)
        }

        // Get Docker build cache
        if let buildCacheItem = try? await scanDockerBuildCache() {
            subItems.append(buildCacheItem)
        }

        // Get Docker volumes
        if let volumesItem = try? await scanDockerVolumes() {
            subItems.append(volumesItem)
        }

        // Get Docker containers (stopped)
        if let containersItem = try? await scanDockerContainers() {
            subItems.append(containersItem)
        }

        SuperLog.i("Docker scan complete: found \(subItems.count) resource types")
        return subItems
    }

    /// Check if Docker CLI is available and running
    private func isDockerAvailable() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["docker", "info"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            SuperLog.w("Docker not available: \(error.localizedDescription)")
            return false
        }
    }

    /// Scan Docker images
    private func scanDockerImages() async throws -> StaticLocationSubItem? {
        let output = try await runDockerCommand(["images", "--format", "{{.Size}}"])
        guard !output.isEmpty else { return nil }

        // Parse sizes and calculate total
        let sizes = output.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { parseSizeString($0) }

        let totalSize = sizes.reduce(0, +)
        guard totalSize > 0 else { return nil }

        let count = sizes.count

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
        let output = try await runDockerCommand(["system", "df", "-v", "--format", "{{.Type}}\t{{.Size}}"])
        guard !output.isEmpty else { return nil }

        // Find the build cache line
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            let parts = line.components(separatedBy: "\t")
            if parts.count == 2 && parts[0].contains("Build Cache") {
                if let size = parseSizeString(parts[1]), size > 0 {
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

        return nil
    }

    /// Scan Docker volumes
    private func scanDockerVolumes() async throws -> StaticLocationSubItem? {
        let output = try await runDockerCommand(["volume", "ls", "-q"])
        guard !output.isEmpty else { return nil }

        let volumes = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard !volumes.isEmpty else { return nil }

        // Get total size of all volumes
        var totalSize: Int64 = 0
        for _ in volumes {
            if let sizeOutput = try? await runDockerCommand(["system", "df", "-v", "--format", "{{.Size}}"]) {
                if let size = parseSizeString(sizeOutput) {
                    totalSize += size
                }
            }
        }

        return StaticLocationSubItem(
            name: "Docker Volumes (\(volumes.count) volume\(volumes.count == 1 ? "" : "s"))",
            path: URL(fileURLWithPath: "/var/lib/docker/volumes"), // Placeholder
            size: totalSize,
            lastModified: Date(),
            isSelected: false,
            subItems: []
        )
    }

    /// Scan Docker containers (stopped)
    private func scanDockerContainers() async throws -> StaticLocationSubItem? {
        let output = try await runDockerCommand(["ps", "-a", "--filter", "status=exited", "-q"])
        guard !output.isEmpty else { return nil }

        let containers = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard !containers.isEmpty else { return nil }

        // Estimate size (containers don't have direct size, use a rough estimate)
        let estimatedSize: Int64 = Int64(containers.count) * 100_000_000 // ~100MB per container

        return StaticLocationSubItem(
            name: "Stopped Containers (\(containers.count) container\(containers.count == 1 ? "" : "s"))",
            path: URL(fileURLWithPath: "/var/lib/docker/containers"), // Placeholder
            size: estimatedSize,
            lastModified: Date(),
            isSelected: false,
            subItems: []
        )
    }

    /// Run Docker command and return output
    private func runDockerCommand(_ arguments: [String]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["docker"] + arguments

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: NSError(domain: "DockerError", code: Int(process.terminationStatus)))
                }
            } catch {
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
}
