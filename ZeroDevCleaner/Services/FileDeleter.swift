//
//  FileDeleter.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation

final class FileDeleter: FileDeleterProtocol {
    nonisolated(unsafe) private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func delete(
        folders: [BuildFolder],
        progressHandler: DeletionProgressHandler?
    ) async throws {
        let urls = folders.map { $0.path }
        try await delete(urls: urls, progressHandler: progressHandler)
    }

    func delete(
        urls: [URL],
        progressHandler: DeletionProgressHandler?
    ) async throws {
        var failedDeletions: [(url: URL, error: Error)] = []

        SuperLog.i("Starting deletion of \(urls.count) item(s)")

        for (index, url) in urls.enumerated() {
            SuperLog.i("Deleting item \(index + 1)/\(urls.count): \(url.path)")

            do {
                try deleteSingleItem(at: url)
                SuperLog.i("Successfully deleted: \(url.path)")
            } catch {
                // Log the actual error
                SuperLog.e("Failed to delete \(url.path): \(error.localizedDescription)")

                // Log additional details for NSError
                if let nsError = error as NSError? {
                    SuperLog.e("Error domain: \(nsError.domain), code: \(nsError.code)")
                    SuperLog.e("Error details: \(String(describing: nsError.userInfo))")
                }

                // Collect failures but continue with other deletions
                failedDeletions.append((url: url, error: error))
            }

            await MainActor.run {
                progressHandler?(index + 1, urls.count)
            }
        }

        // If some deletions failed, throw partial failure error
        if !failedDeletions.isEmpty {
            SuperLog.w("Deletion completed with \(failedDeletions.count) failure(s) out of \(urls.count) total")
            for (index, failure) in failedDeletions.enumerated() {
                SuperLog.w("Failure \(index + 1): \(failure.url.path) - \(failure.error.localizedDescription)")
            }

            throw ZeroDevCleanerError.partialDeletionFailure(failedDeletions.map { $0.url })
        }

        SuperLog.i("All \(urls.count) item(s) deleted successfully")
    }

    func delete(
        staticItems: [StaticLocationSubItem],
        progressHandler: DeletionProgressHandler?
    ) async throws {
        var failedDeletions: [(name: String, error: Error)] = []

        SuperLog.i("Starting deletion of \(staticItems.count) static item(s)")

        for (index, item) in staticItems.enumerated() {
            SuperLog.i("Deleting item \(index + 1)/\(staticItems.count): \(item.name)")

            do {
                // Check if this is a Docker CLI resource
                if item.requiresDockerCli {
                    try await deleteDockerResource(item)
                } else {
                    // Regular file system deletion
                    try deleteSingleItem(at: item.path)
                }
                SuperLog.i("Successfully deleted: \(item.name)")
            } catch {
                SuperLog.e("Failed to delete \(item.name): \(error.localizedDescription)")

                if let nsError = error as NSError? {
                    SuperLog.e("Error domain: \(nsError.domain), code: \(nsError.code)")
                    SuperLog.e("Error details: \(String(describing: nsError.userInfo))")
                }

                failedDeletions.append((name: item.name, error: error))
            }

            await MainActor.run {
                progressHandler?(index + 1, staticItems.count)
            }
        }

        if !failedDeletions.isEmpty {
            SuperLog.w("Deletion completed with \(failedDeletions.count) failure(s) out of \(staticItems.count) total")
            for (index, failure) in failedDeletions.enumerated() {
                SuperLog.w("Failure \(index + 1): \(failure.name) - \(failure.error.localizedDescription)")
            }

            // Create URLs for error reporting (use paths)
            let failedURLs = staticItems.filter { item in
                failedDeletions.contains(where: { $0.name == item.name })
            }.map { $0.path }

            throw ZeroDevCleanerError.partialDeletionFailure(failedURLs)
        }

        SuperLog.i("All \(staticItems.count) static item(s) deleted successfully")
    }

    // MARK: - Docker CLI Deletion

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

    private func deleteDockerResource(_ item: StaticLocationSubItem) async throws {
        guard let resourceId = item.dockerResourceId,
              let resourceType = item.dockerResourceType else {
            SuperLog.e("Docker resource missing ID or type: \(item.name)")
            throw ZeroDevCleanerError.deletionFailed(
                item.path,
                NSError(domain: "DockerDeletionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Docker resource metadata"])
            )
        }

        SuperLog.i("Deleting Docker \(resourceType): \(resourceId)")

        switch resourceType {
        case "image":
            try await deleteDockerImage(imageId: resourceId)
        case "container":
            try await deleteDockerContainer(containerId: resourceId)
        case "volume":
            try await deleteDockerVolume(volumeName: resourceId)
        case "buildCache":
            try await deleteDockerBuildCache(cacheId: resourceId)
        default:
            SuperLog.e("Unknown Docker resource type: \(resourceType)")
            throw ZeroDevCleanerError.deletionFailed(
                item.path,
                NSError(domain: "DockerDeletionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown resource type: \(resourceType)"])
            )
        }
    }

    private func deleteDockerImage(imageId: String) async throws {
        SuperLog.d("Executing: docker rmi \(imageId)")
        try await runDockerCommand(["rmi", imageId])
        SuperLog.i("Successfully deleted Docker image: \(imageId)")
    }

    private func deleteDockerContainer(containerId: String) async throws {
        SuperLog.d("Executing: docker rm \(containerId)")
        try await runDockerCommand(["rm", containerId])
        SuperLog.i("Successfully deleted Docker container: \(containerId)")
    }

    private func deleteDockerVolume(volumeName: String) async throws {
        SuperLog.d("Executing: docker volume rm \(volumeName)")
        try await runDockerCommand(["volume", "rm", volumeName])
        SuperLog.i("Successfully deleted Docker volume: \(volumeName)")
    }

    private func deleteDockerBuildCache(cacheId: String) async throws {
        SuperLog.d("Executing: docker builder prune --filter id=\(cacheId) --force")
        try await runDockerCommand(["builder", "prune", "--filter", "id=\(cacheId)", "--force"])
        SuperLog.i("Successfully deleted Docker build cache: \(cacheId)")
    }

    /// Run Docker command and handle errors
    private func runDockerCommand(_ arguments: [String]) async throws {
        let commandString = "docker " + arguments.joined(separator: " ")

        guard let dockerPath = findDockerPath() else {
            SuperLog.e("Docker CLI not found, cannot execute command: \(commandString)")
            throw NSError(
                domain: "DockerDeletionError",
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

                if process.terminationStatus == 0 {
                    SuperLog.d("Docker command succeeded: \(commandString)")
                    continuation.resume()
                } else {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    SuperLog.e("Docker command failed: \(commandString) - \(errorOutput)")

                    let error = NSError(
                        domain: "DockerDeletionError",
                        code: Int(process.terminationStatus),
                        userInfo: [NSLocalizedDescriptionKey: "Docker command failed: \(errorOutput)"]
                    )
                    continuation.resume(throwing: error)
                }
            } catch {
                SuperLog.e("Failed to execute Docker command: \(commandString) - \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - File System Deletion

    private nonisolated func deleteSingleItem(at url: URL) throws {
        // Verify item exists before attempting deletion
        guard fileManager.fileExists(atPath: url.path) else {
            SuperLog.e("Item does not exist: \(url.path)")
            throw ZeroDevCleanerError.fileNotFound(url)
        }

        // Check if we can read the item
        guard fileManager.isReadableFile(atPath: url.path) else {
            SuperLog.e("Item is not readable: \(url.path)")
            throw ZeroDevCleanerError.permissionDenied(url)
        }

        SuperLog.d("Attempting to trash item using FileManager: \(url.path)")

        // Use FileManager.trashItem which is the modern API for moving items to trash
        var trashedURL: NSURL?
        do {
            try fileManager.trashItem(at: url, resultingItemURL: &trashedURL)

            if let trashedPath = trashedURL?.path {
                SuperLog.d("Successfully moved to trash: \(trashedPath)")
            } else {
                SuperLog.d("Successfully moved to trash: \(url.path)")
            }
        } catch {
            SuperLog.e("FileManager.trashItem failed for \(url.path): \(error.localizedDescription)")
            throw ZeroDevCleanerError.deletionFailed(url, error)
        }
    }
}
