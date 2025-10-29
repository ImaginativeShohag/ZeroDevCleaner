//
//  RecentFoldersManagerTests.swift
//  ZeroDevCleanerTests
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import XCTest
@testable import ZeroDevCleaner

@MainActor
final class RecentFoldersManagerTests: XCTestCase {
    var sut: RecentFoldersManager!
    let testUserDefaultsKey = "test_recent_folders"
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        // Create a temporary directory for testing
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Use a test-specific key to avoid polluting real user defaults
        sut = RecentFoldersManager()
        // Clear any existing test data
        UserDefaults.standard.removeObject(forKey: "recent_folders")
    }

    override func tearDown() {
        // Clean up test data
        UserDefaults.standard.removeObject(forKey: "recent_folders")
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        sut = nil
        super.tearDown()
    }

    // MARK: - Add Folder Tests

    func test_addFolder_addsToRecentList() {
        // Given
        let folder = tempDir.appendingPathComponent("folder1")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        // When
        sut.addFolder(folder)

        // Then
        XCTAssertEqual(sut.recentFolders.count, 1)
        XCTAssertEqual(sut.recentFolders.first, folder)
    }

    func test_addFolder_movesExistingFolderToTop() {
        // Given
        let folder1 = tempDir.appendingPathComponent("folder1")
        let folder2 = tempDir.appendingPathComponent("folder2")
        try? FileManager.default.createDirectory(at: folder1, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: folder2, withIntermediateDirectories: true)

        // When
        sut.addFolder(folder1)
        sut.addFolder(folder2)
        sut.addFolder(folder1) // Add folder1 again

        // Then
        XCTAssertEqual(sut.recentFolders.count, 2)
        XCTAssertEqual(sut.recentFolders.first, folder1) // Should be at top
    }

    func test_addFolder_limitsToFiveEntries() {
        // Given
        let folders = (1...7).map { num -> URL in
            let folder = tempDir.appendingPathComponent("folder\(num)")
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            return folder
        }

        // When
        for folder in folders {
            sut.addFolder(folder)
        }

        // Then
        XCTAssertEqual(sut.recentFolders.count, 5)
        XCTAssertEqual(sut.recentFolders.first, folders[6]) // Most recent
        XCTAssertEqual(sut.recentFolders.last, folders[2]) // Oldest kept
    }

    func test_addFolder_removesNonExistentPaths() {
        // Given
        let existingFolder = FileManager.default.temporaryDirectory
        let nonExistentFolder = URL(fileURLWithPath: "/nonexistent/folder/that/should/not/exist")

        // When
        sut.addFolder(nonExistentFolder)
        sut.addFolder(existingFolder)

        // Then
        // Non-existent folder should be filtered out
        XCTAssertTrue(sut.recentFolders.contains(existingFolder))
        // The count should be 1 (only the existing folder)
        XCTAssertEqual(sut.recentFolders.count, 1)
    }

    // MARK: - Clear Tests

    func test_clearAll_removesAllFolders() {
        // Given
        let folder1 = tempDir.appendingPathComponent("folder1")
        let folder2 = tempDir.appendingPathComponent("folder2")
        try? FileManager.default.createDirectory(at: folder1, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: folder2, withIntermediateDirectories: true)

        sut.addFolder(folder1)
        sut.addFolder(folder2)

        // When
        sut.clearAll()

        // Then
        XCTAssertTrue(sut.recentFolders.isEmpty)
    }

    // MARK: - Persistence Tests

    func test_recentFolders_persistsAcrossInstances() {
        // Given
        let folder = tempDir.appendingPathComponent("folder1")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        sut.addFolder(folder)

        // When
        let newManager = RecentFoldersManager()

        // Then
        // The folder should persist
        XCTAssertTrue(newManager.recentFolders.contains(folder))
    }
}
