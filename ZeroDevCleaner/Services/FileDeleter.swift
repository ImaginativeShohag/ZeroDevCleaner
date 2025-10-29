//
//  FileDeleter.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation
import AppKit
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
                try await deleteSingleItem(at: url)
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

    private nonisolated func deleteSingleItem(at url: URL) async throws {
        // Create a local logger for nonisolated context
        let deletionLogger = Logger(subsystem: "com.shohag.ZeroDevCleaner", category: "deletion")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            // Must use MainActor for NSWorkspace
            Task { @MainActor in
                // Verify item exists before attempting deletion
                guard self.fileManager.fileExists(atPath: url.path) else {
                    deletionLogger.error("Item does not exist: \(url.path, privacy: .public)")
                    continuation.resume(throwing: ZeroDevCleanerError.fileNotFound(url))
                    return
                }

                // Check if we can read the item
                guard self.fileManager.isReadableFile(atPath: url.path) else {
                    deletionLogger.error("Item is not readable: \(url.path, privacy: .public)")
                    continuation.resume(throwing: ZeroDevCleanerError.permissionDenied(url))
                    return
                }

                deletionLogger.debug("Attempting to recycle using NSWorkspace: \(url.path, privacy: .public)")

                // Use NSWorkspace.recycle which is better for user-facing deletion
                // This properly handles permissions and shows the item in Trash
                NSWorkspace.shared.recycle([url]) { trashedItems, error in
                    if let error = error {
                        deletionLogger.error("NSWorkspace.recycle failed for \(url.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
                        continuation.resume(throwing: ZeroDevCleanerError.deletionFailed(url, error))
                    } else if let trashedURL = trashedItems[url] {
                        deletionLogger.debug("Successfully recycled to: \(trashedURL.path, privacy: .public)")
                        continuation.resume()
                    } else {
                        deletionLogger.error("Recycle succeeded but no trashed URL returned for \(url.path, privacy: .public)")
                        continuation.resume(throwing: ZeroDevCleanerError.deletionFailed(url, NSError(domain: "ZeroDevCleaner", code: -1, userInfo: [NSLocalizedDescriptionKey: "No trashed URL returned"])))
                    }
                }
            }
        }
    }
}
