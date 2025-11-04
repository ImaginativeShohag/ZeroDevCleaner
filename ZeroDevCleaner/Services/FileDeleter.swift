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
