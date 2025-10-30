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

    /// Parses device support name to show iOS version and device model
    private func parseDeviceSupportName(from deviceSupportURL: URL) -> String? {
        let folderName = deviceSupportURL.lastPathComponent

        // Try to find device information in the folder
        var deviceModel: String?

        // Look for .plist files that might contain device info
        if let contents = try? fileManager.contentsOfDirectory(at: deviceSupportURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
            for fileURL in contents {
                // Check for device info in plist files
                if fileURL.pathExtension == "plist" {
                    if let plistData = try? Data(contentsOf: fileURL),
                       let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {

                        // Look for device name or model
                        if let productType = plist["ProductType"] as? String {
                            deviceModel = mapDeviceIdentifierToName(productType)
                        } else if let deviceName = plist["DeviceName"] as? String {
                            deviceModel = deviceName
                        }

                        if deviceModel != nil { break }
                    }
                }
            }
        }

        // Format: "iOS 15.0 (19A346) (iPhone 13 Pro Max)" or just "iOS 15.0 (19A346)"
        if let deviceModel = deviceModel {
            return "iOS \(folderName) (\(deviceModel))"
        } else {
            return "iOS \(folderName)"
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
