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

            let location = StaticLocation(
                type: type,
                path: path,
                size: size,
                lastModified: lastModified,
                exists: true
            )

            results.append(location)
            Logger.scanning.debug("Found static location: \(type.displayName, privacy: .public) - \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file), privacy: .public)")
        }

        Logger.scanning.info("Static location scan complete. Found \(results.filter(\.exists).count) of \(types.count) locations")
        return results
    }
}
