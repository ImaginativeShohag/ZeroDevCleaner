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

    /// Folders that have been claimed by a project type (claim-once logic)
    private var claimedFolders: Set<String> = []

    /// Project type configurations loaded from ConfigurationManager
    private var projectTypeConfigs: [ProjectTypeConfig] = []

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

        // Load project type configuration
        do {
            let config = try await ConfigurationManager.shared.loadConfiguration()
            self.projectTypeConfigs = config.projectTypes
            SuperLog.i("Loaded \(self.projectTypeConfigs.count) project type configurations")
        } catch {
            SuperLog.e("Failed to load build folder configuration: \(error)")
            throw ZeroDevCleanerError.configurationLoadFailed(error)
        }

        // Reset claimed folders for this scan
        claimedFolders.removeAll()

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

        // Structure into hierarchy
        let hierarchicalFolders = structureHierarchy(from: buildFolders)

        SuperLog.i("Completed scan of \(url.path) - Found \(hierarchicalFolders.count) top-level folders with nested structure")
        return hierarchicalFolders
    }

    private func scanRecursively(
        url: URL,
        rootPath: String,
        currentDepth: Int,
        foundFolders: inout [BuildFolder],
        group: inout ThrowingTaskGroup<BuildFolder?, Error>,
        progressHandler: ScanProgressHandler?
    ) async throws {
        // Check for cancellation at the start of each recursive call
        try Task.checkCancellation()

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
            // Check for cancellation in the loop
            try Task.checkCancellation()

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

            // CLAIM-ONCE LOGIC: Skip if this folder has already been claimed
            let folderPath = itemURL.path
            if claimedFolders.contains(folderPath) {
                SuperLog.d("Skipping already-claimed folder: \(folderPath)")
                continue
            }

            // Check if this folder matches any configured build folder names
            let matchingConfigs = projectTypeConfigs.filter { $0.folderNames.contains(folderName) }

            if !matchingConfigs.isEmpty {
                // Try to detect project type using sequential validation
                if let projectType = validator.detectProjectType(buildFolder: itemURL, projectTypes: projectTypeConfigs) {
                    // Claim this folder so it won't be detected again
                    claimedFolders.insert(folderPath)

                    group.addTask {
                        await self.createBuildFolder(url: itemURL, projectType: projectType)
                    }
                    await MainActor.run {
                        progressHandler?(itemURL.path, foundFolders.count + 1)
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
                    // Folder name matches but validation failed - continue scanning inside
                    try await scanRecursively(
                        url: itemURL,
                        rootPath: rootPath,
                        currentDepth: currentDepth + 1,
                        foundFolders: &foundFolders,
                        group: &group,
                        progressHandler: progressHandler
                    )
                }
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

    /// Structures flat list of build folders into multi-level hierarchy
    /// Folders are nested if their path is a subfolder of another folder's path
    private func structureHierarchy(from folders: [BuildFolder]) -> [BuildFolder] {
        SuperLog.i("Structuring \(folders.count) folders into hierarchy")

        // Sort by path components count (shallowest first) to build from top down
        let sortedFolders = folders.sorted { $0.path.pathComponents.count < $1.path.pathComponents.count }

        // Track which folders have been added as children
        var childPaths = Set<String>()

        // Recursively build hierarchy
        func buildChildren(for parentPath: String) -> [BuildFolder] {
            var children: [BuildFolder] = []

            for folder in sortedFolders {
                let folderPath = folder.path.path

                // Skip if already used as a child elsewhere
                guard !childPaths.contains(folderPath) else { continue }

                // Check if this folder is a direct or nested child of parent
                guard folderPath != parentPath && folderPath.hasPrefix(parentPath + "/") else { continue }

                // Mark as used
                childPaths.insert(folderPath)

                // Recursively build this folder's children
                var childFolder = folder
                childFolder.subItems = buildChildren(for: folderPath)

                children.append(childFolder)
            }

            // Sort children: by path depth first (shallowest first), then alphabetically
            return children.sorted { lhs, rhs in
                let lhsDepth = lhs.path.pathComponents.count
                let rhsDepth = rhs.path.pathComponents.count
                if lhsDepth != rhsDepth {
                    return lhsDepth < rhsDepth
                }
                return lhs.path.path < rhs.path.path
            }
        }

        // Find top-level folders (not children of any other folder)
        var topLevel: [BuildFolder] = []

        for folder in sortedFolders {
            let folderPath = folder.path.path

            // Skip if already used as a child
            guard !childPaths.contains(folderPath) else { continue }

            // Check if this folder is a child of any other folder
            let isChild = sortedFolders.contains { otherFolder in
                let otherPath = otherFolder.path.path
                return folderPath != otherPath && folderPath.hasPrefix(otherPath + "/")
            }

            if !isChild {
                // This is a top-level folder
                var topFolder = folder
                topFolder.subItems = buildChildren(for: folderPath)
                topLevel.append(topFolder)
            }
        }

        // Sort top-level folders alphabetically by project name
        let result = topLevel.sorted { $0.projectName < $1.projectName }

        SuperLog.i("Structured into \(result.count) top-level folders")
        return result
    }
}
