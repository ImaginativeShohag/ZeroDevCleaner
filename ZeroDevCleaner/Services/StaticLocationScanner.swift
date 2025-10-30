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
        let contents = try fileManager.contentsOfDirectory(
            at: parentPath,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        var subItems: [StaticLocationSubItem] = []

        for itemURL in contents {
            let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey])

            // Only include directories
            guard resourceValues.isDirectory == true else { continue }

            let size = try await sizeCalculator.calculateSize(of: itemURL)
            let lastModified = resourceValues.contentModificationDate ?? Date()

            // Format name based on type
            let displayName: String
            switch type {
            case .xcodeArchives:
                // Try to parse archive info to get app name and version
                displayName = parseArchiveName(from: itemURL) ?? itemURL.lastPathComponent
            case .deviceSupport:
                // Device Support folders are already well-named (e.g., "15.0 (19A346)")
                displayName = itemURL.lastPathComponent
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

        // Sort by last modified date (newest first) for archives, size for others
        if type == .xcodeArchives {
            return subItems.sorted { $0.lastModified > $1.lastModified }
        } else {
            return subItems.sorted { $0.size > $1.size }
        }
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
}
