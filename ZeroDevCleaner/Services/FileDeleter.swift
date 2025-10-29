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
        var failedDeletions: [(url: URL, error: Error)] = []

        logger.info("Starting deletion of \(folders.count) folder(s)")

        for (index, folder) in folders.enumerated() {
            logger.info("Deleting folder \(index + 1)/\(folders.count): \(folder.path.path, privacy: .public)")

            do {
                try await deleteSingleFolder(folder)
                logger.info("Successfully deleted: \(folder.path.path, privacy: .public)")
            } catch {
                // Log the actual error
                logger.error("Failed to delete \(folder.path.path, privacy: .public): \(error.localizedDescription, privacy: .public)")

                // Log additional details for NSError
                if let nsError = error as NSError? {
                    logger.error("Error domain: \(nsError.domain, privacy: .public), code: \(nsError.code)")
                    logger.error("Error details: \(String(describing: nsError.userInfo), privacy: .public)")
                }

                // Collect failures but continue with other deletions
                failedDeletions.append((url: folder.path, error: error))
            }

            await MainActor.run {
                progressHandler?(index + 1, folders.count)
            }
        }

        // If some deletions failed, throw partial failure error
        if !failedDeletions.isEmpty {
            logger.warning("Deletion completed with \(failedDeletions.count) failure(s) out of \(folders.count) total")
            for (index, failure) in failedDeletions.enumerated() {
                logger.warning("Failure \(index + 1): \(failure.url.path, privacy: .public) - \(failure.error.localizedDescription, privacy: .public)")
            }

            throw ZeroDevCleanerError.partialDeletionFailure(failedDeletions.map { $0.url })
        }

        logger.info("All \(folders.count) folder(s) deleted successfully")
    }

    private nonisolated func deleteSingleFolder(_ folder: BuildFolder) async throws {
        // Create a local logger for nonisolated context
        let deletionLogger = Logger(subsystem: "com.shohag.ZeroDevCleaner", category: "deletion")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task.detached {
                do {
                    // Verify folder exists before attempting deletion
                    guard self.fileManager.fileExists(atPath: folder.path.path) else {
                        deletionLogger.error("Folder does not exist: \(folder.path.path, privacy: .public)")
                        continuation.resume(throwing: ZeroDevCleanerError.fileNotFound(folder.path))
                        return
                    }

                    deletionLogger.debug("Attempting to trash: \(folder.path.path, privacy: .public)")
                    try self.fileManager.trashItem(at: folder.path, resultingItemURL: nil)
                    deletionLogger.debug("Successfully trashed: \(folder.path.path, privacy: .public)")
                    continuation.resume()
                } catch {
                    deletionLogger.error("trashItem failed for \(folder.path.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    continuation.resume(throwing: ZeroDevCleanerError.deletionFailed(folder.path, error))
                }
            }
        }
    }
}
