//
//  FileScanner.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation

final class FileScanner: FileScannerProtocol {
    nonisolated(unsafe) private let fileManager: FileManager
    private let validator: ProjectValidatorProtocol
    private let sizeCalculator: FileSizeCalculatorProtocol
    private let maxDepth: Int

    init(
        fileManager: FileManager = .default,
        validator: ProjectValidatorProtocol,
        sizeCalculator: FileSizeCalculatorProtocol,
        maxDepth: Int = 10
    ) {
        self.fileManager = fileManager
        self.validator = validator
        self.sizeCalculator = sizeCalculator
        self.maxDepth = maxDepth
    }

    func scanDirectory(
        at url: URL,
        progressHandler: ScanProgressHandler?
    ) async throws -> [BuildFolder] {
        var buildFolders: [BuildFolder] = []

        try await withThrowingTaskGroup(of: BuildFolder?.self) { group in
            try await scanRecursively(
                url: url,
                currentDepth: 0,
                foundFolders: &buildFolders,
                group: &group,
                progressHandler: progressHandler
            )

            for try await folder in group {
                if let folder {
                    buildFolders.append(folder)
                }
            }
        }

        return buildFolders
    }

    private func scanRecursively(
        url: URL,
        currentDepth: Int,
        foundFolders: inout [BuildFolder],
        group: inout ThrowingTaskGroup<BuildFolder?, Error>,
        progressHandler: ScanProgressHandler?
    ) async throws {
        guard currentDepth < maxDepth else { return }

        // Get directory contents, skipping hidden files
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        )

        for itemURL in contents {
            let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])

            // Skip if not a directory
            guard resourceValues.isDirectory == true else { continue }

            // Skip symlinks for safety (prevents following links outside root, infinite loops)
            if let isSymlink = resourceValues.isSymbolicLink, isSymlink {
                continue
            }

            let folderName = itemURL.lastPathComponent

            // Check if this is a build folder
            if folderName == "build" || folderName == ".build" {
                if let projectType = validator.detectProjectType(buildFolder: itemURL) {
                    group.addTask {
                        await self.createBuildFolder(url: itemURL, projectType: projectType)
                    }
                    await MainActor.run {
                        progressHandler?(itemURL.path, foundFolders.count + 1)
                    }
                }
            } else {
                // Recursively scan subdirectories
                try await scanRecursively(
                    url: itemURL,
                    currentDepth: currentDepth + 1,
                    foundFolders: &foundFolders,
                    group: &group,
                    progressHandler: progressHandler
                )
            }
        }
    }

    private func createBuildFolder(url: URL, projectType: ProjectType) async -> BuildFolder? {
        do {
            let size = try await sizeCalculator.calculateSize(of: url)
            let resourceValues = try url.resourceValues(forKeys: [.contentModificationDateKey])
            let lastModified = resourceValues.contentModificationDate ?? Date()

            let projectName = url.deletingLastPathComponent().lastPathComponent

            return BuildFolder(
                path: url,
                projectType: projectType,
                size: size,
                projectName: projectName,
                lastModified: lastModified,
                isSelected: false
            )
        } catch {
            return nil
        }
    }
}
