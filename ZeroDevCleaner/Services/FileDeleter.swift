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
        var failedDeletions: [URL] = []

        for (index, folder) in folders.enumerated() {
            do {
                try await deleteSingleFolder(folder)
            } catch {
                // Collect failures but continue with other deletions
                failedDeletions.append(folder.path)
            }

            await MainActor.run {
                progressHandler?(index + 1, folders.count)
            }
        }

        // If some deletions failed, throw partial failure error
        if !failedDeletions.isEmpty {
            throw ZeroDevCleanerError.partialDeletionFailure(failedDeletions)
        }
    }

    private nonisolated func deleteSingleFolder(_ folder: BuildFolder) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task.detached {
                do {
                    try self.fileManager.trashItem(at: folder.path, resultingItemURL: nil)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: ZeroDevCleanerError.deletionFailed(folder.path, error))
                }
            }
        }
    }
}
