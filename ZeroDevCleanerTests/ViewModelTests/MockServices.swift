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
    var deletedURLs: [URL] = []
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

    func delete(
        urls: [URL],
        progressHandler: DeletionProgressHandler?
    ) async throws {
        deleteCalled = true
        deletedURLs = urls

        if let error = shouldThrowError {
            throw error
        }

        // Simulate progress
        for i in 0..<urls.count {
            progressHandler?(i + 1, urls.count)
        }
    }
}

final class MockStaticLocationScanner: StaticLocationScannerProtocol, @unchecked Sendable {
    var mockStaticLocations: [StaticLocation] = []
    var shouldThrowError: Error?
    var scanCalled: Bool = false

    func scanStaticLocations(
        types: [StaticLocationType],
        progressHandler: ((String, Int) -> Void)?
    ) async throws -> [StaticLocation] {
        scanCalled = true

        if let error = shouldThrowError {
            throw error
        }

        // Simulate progress
        for (index, _) in types.enumerated() {
            progressHandler?("Scanning", index + 1)
        }

        return mockStaticLocations
    }

    func scanCustomCacheLocation(_ customLocation: CustomCacheLocation) async throws -> StaticLocation? {
        if let error = shouldThrowError {
            throw error
        }

        // Return a mock static location for the custom cache
        return StaticLocation(
            type: .custom,
            path: customLocation.path,
            size: 1_000_000,
            lastModified: Date(),
            exists: true,
            subItems: [],
            customName: customLocation.name,
            customIconName: customLocation.iconName,
            customColorHex: customLocation.colorHex
        )
    }
}
