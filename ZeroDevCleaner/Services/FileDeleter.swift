//
//  FileDeleter.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation
import OSLog

final class FileDeleter: FileDeleterProtocol {
    nonisolated(unsafe) private let fileManager: FileManager
    private let logger = Logger.deletion

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

        logger.info("Starting deletion of \(urls.count) item(s)")

        for (index, url) in urls.enumerated() {
            logger.info("Deleting item \(index + 1)/\(urls.count): \(url.path, privacy: .public)")

            do {
                try deleteSingleItem(at: url)
                logger.info("Successfully deleted: \(url.path, privacy: .public)")
            } catch {
                // Log the actual error
                logger.error("Failed to delete \(url.path, privacy: .public): \(error.localizedDescription, privacy: .public)")

                // Log additional details for NSError
                if let nsError = error as NSError? {
                    logger.error("Error domain: \(nsError.domain, privacy: .public), code: \(nsError.code)")
                    logger.error("Error details: \(String(describing: nsError.userInfo), privacy: .public)")
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
            logger.warning("Deletion completed with \(failedDeletions.count) failure(s) out of \(urls.count) total")
            for (index, failure) in failedDeletions.enumerated() {
                logger.warning("Failure \(index + 1): \(failure.url.path, privacy: .public) - \(failure.error.localizedDescription, privacy: .public)")
            }

            throw ZeroDevCleanerError.partialDeletionFailure(failedDeletions.map { $0.url })
        }

        logger.info("All \(urls.count) item(s) deleted successfully")
    }

    private nonisolated func deleteSingleItem(at url: URL) throws {
        // Create a local logger for nonisolated context
        let deletionLogger = Logger(subsystem: "com.shohag.ZeroDevCleaner", category: "deletion")

        // Verify item exists before attempting deletion
        guard fileManager.fileExists(atPath: url.path) else {
            deletionLogger.error("Item does not exist: \(url.path, privacy: .public)")
            throw ZeroDevCleanerError.fileNotFound(url)
        }

        // Check if we can read the item
        guard fileManager.isReadableFile(atPath: url.path) else {
            deletionLogger.error("Item is not readable: \(url.path, privacy: .public)")
            throw ZeroDevCleanerError.permissionDenied(url)
        }

        deletionLogger.debug("Attempting to trash item using FileManager: \(url.path, privacy: .public)")

        // Use FileManager.trashItem which is the modern API for moving items to trash
        var trashedURL: NSURL?
        do {
            try fileManager.trashItem(at: url, resultingItemURL: &trashedURL)

            if let trashedPath = trashedURL?.path {
                deletionLogger.debug("Successfully moved to trash: \(trashedPath, privacy: .public)")
            } else {
                deletionLogger.debug("Successfully moved to trash: \(url.path, privacy: .public)")
            }
        } catch {
            deletionLogger.error("FileManager.trashItem failed for \(url.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw ZeroDevCleanerError.deletionFailed(url, error)
        }
    }
}
