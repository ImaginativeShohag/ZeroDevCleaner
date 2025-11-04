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
        SuperLog.i("Starting scan of parent folder: \(url.path)")

        // Get the canonical root path to ensure we stay within bounds
        let rootPath = url.resolvingSymlinksInPath().path
        SuperLog.d("Canonical root path: \(rootPath)")

        var buildFolders: [BuildFolder] = []

        try await withThrowingTaskGroup(of: BuildFolder?.self) { group in
            try await scanRecursively(
                url: url,
                rootPath: rootPath,
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

        SuperLog.i("Completed scan of \(url.path) - Found \(buildFolders.count) build folder(s)")
        return buildFolders
    }

    private func scanRecursively(
        url: URL,
        rootPath: String,
        currentDepth: Int,
        foundFolders: inout [BuildFolder],
        group: inout ThrowingTaskGroup<BuildFolder?, Error>,
        progressHandler: ScanProgressHandler?
    ) async throws {
        guard currentDepth < maxDepth else { return }

        // Security check: Ensure we're still within the root directory
        let currentPath = url.resolvingSymlinksInPath().path
        if !currentPath.hasPrefix(rootPath) {
            SuperLog.w("Attempted to scan outside root directory: \(currentPath)")
            return
        }

        // Get directory contents WITHOUT skipping hidden files
        // We need to see .build folders!
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: []
        )

        for itemURL in contents {
            let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])

            // CRITICAL: Skip symlinks FIRST before checking if it's a directory
            // This prevents following symlinks that might point outside the root
            if let isSymlink = resourceValues.isSymbolicLink, isSymlink {
                SuperLog.d("Skipping symlink: \(itemURL.path)")
                continue
            }

            // Skip if not a directory
            guard resourceValues.isDirectory == true else { continue }

            let folderName = itemURL.lastPathComponent

            // Skip system/version control hidden folders (but allow .build and .venv/.env)
            if folderName.hasPrefix(".") && folderName != ".build" && folderName != ".venv" && folderName != ".env" {
                // Skip .git, .svn, .DS_Store, etc.
                continue
            }

            // Check if this is a build/cache folder
            if folderName == "build" ||
               folderName == ".build" ||
               folderName == "node_modules" ||
               folderName == "target" ||
               folderName == "__pycache__" ||
               folderName == "venv" ||
               folderName == ".venv" ||
               folderName == "env" ||
               folderName == ".env" ||
               folderName == "vendor" ||
               folderName == "bin" ||
               folderName == "obj" ||
               folderName == "Library" ||
               folderName == "Temp" {
                if let projectType = validator.detectProjectType(buildFolder: itemURL) {
                    group.addTask {
                        await self.createBuildFolder(url: itemURL, projectType: projectType)
                    }
                    await MainActor.run {
                        progressHandler?(itemURL.path, foundFolders.count + 1)
                    }
                }

                // Continue scanning inside detected build folders to find nested artifacts
                // (e.g., Android build inside node_modules)
                try await scanRecursively(
                    url: itemURL,
                    rootPath: rootPath,
                    currentDepth: currentDepth + 1,
                    foundFolders: &foundFolders,
                    group: &group,
                    progressHandler: progressHandler
                )
            } else {
                // Recursively scan subdirectories
                try await scanRecursively(
                    url: itemURL,
                    rootPath: rootPath,
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
