//
//  MockServices.swift
//  ZeroDevCleanerTests
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation
@testable import ZeroDevCleaner

final class MockFileScanner: FileScannerProtocol, @unchecked Sendable {
    var mockResults: [BuildFolder] = []
    var shouldThrowError: Error?
    var scanCalled: Bool = false

    func scanDirectory(
        at url: URL,
        progressHandler: ScanProgressHandler?
    ) async throws -> [BuildFolder] {
        scanCalled = true

        if let error = shouldThrowError {
            throw error
        }

        // Simulate progress
        for i in 0..<mockResults.count {
            progressHandler?(mockResults[i].path.path, i + 1)
        }

        return mockResults
    }
}

final class MockFileDeleter: FileDeleterProtocol, @unchecked Sendable {
    var deleteCalled: Bool = false
    var deletedFolders: [BuildFolder] = []
    var shouldThrowError: Error?

    func delete(
        folders: [BuildFolder],
        progressHandler: DeletionProgressHandler?
    ) async throws {
        deleteCalled = true
        deletedFolders = folders

        if let error = shouldThrowError {
            throw error
        }

        // Simulate progress
        for i in 0..<folders.count {
            progressHandler?(i + 1, folders.count)
        }
    }
}
