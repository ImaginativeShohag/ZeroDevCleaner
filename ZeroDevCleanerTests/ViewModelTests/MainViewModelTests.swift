//
//  MainViewModelTests.swift
//  ZeroDevCleanerTests
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import XCTest
@testable import ZeroDevCleaner

@MainActor
final class MainViewModelTests: XCTestCase {
    var sut: MainViewModel!
    var mockScanner: MockFileScanner!
    var mockDeleter: MockFileDeleter!

    override func setUp() {
        super.setUp()
        mockScanner = MockFileScanner()
        mockDeleter = MockFileDeleter()
        sut = MainViewModel(scanner: mockScanner, deleter: mockDeleter)
    }

    override func tearDown() {
        sut = nil
        mockScanner = nil
        mockDeleter = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_initialization_setsDefaultValues() {
        XCTAssertNil(sut.selectedFolder)
        XCTAssertTrue(sut.scanResults.isEmpty)
        XCTAssertFalse(sut.isScanning)
        XCTAssertEqual(sut.scanProgress, 0.0)
        XCTAssertFalse(sut.isDeleting)
    }

    // MARK: - Scan Tests

    func test_startScan_withValidFolder_updatesResults() async {
        // Given
        sut.selectedFolder = URL(fileURLWithPath: "/test")
        let mockFolder = BuildFolder(
            path: URL(fileURLWithPath: "/test/build"),
            projectType: .android,
            size: 1024,
            projectName: "Test",
            lastModified: Date()
        )
        mockScanner.mockResults = [mockFolder]

        // When
        sut.startScan()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 sec

        // Then
        XCTAssertTrue(mockScanner.scanCalled)
        XCTAssertEqual(sut.scanResults.count, 1)
        XCTAssertFalse(sut.isScanning)
    }

    func test_cancelScan_stopsScanning() {
        // Given
        sut.selectedFolder = URL(fileURLWithPath: "/test")
        sut.isScanning = true

        // When
        sut.cancelScan()

        // Then
        XCTAssertFalse(sut.isScanning)
    }

    // MARK: - Selection Tests

    func test_selectAll_selectsAllFolders() {
        // Given
        sut.scanResults = [
            BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                       size: 1024, projectName: "Test1", lastModified: Date(), isSelected: false),
            BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                       size: 2048, projectName: "Test2", lastModified: Date(), isSelected: false)
        ]

        // When
        sut.selectAll()

        // Then
        XCTAssertTrue(sut.scanResults.allSatisfy(\.isSelected))
    }

    func test_deselectAll_deselectsAllFolders() {
        // Given
        sut.scanResults = [
            BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                       size: 1024, projectName: "Test1", lastModified: Date(), isSelected: true),
            BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                       size: 2048, projectName: "Test2", lastModified: Date(), isSelected: true)
        ]

        // When
        sut.deselectAll()

        // Then
        XCTAssertFalse(sut.scanResults.contains(where: \.isSelected))
    }

    func test_toggleSelection_togglesFolderSelection() {
        // Given
        let folder = BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                                size: 1024, projectName: "Test1", lastModified: Date(), isSelected: false)
        sut.scanResults = [folder]

        // When
        sut.toggleSelection(for: folder)

        // Then
        XCTAssertTrue(sut.scanResults[0].isSelected)
    }

    // MARK: - Deletion Tests

    func test_deleteSelectedFolders_deletesOnlySelected() async {
        // Given
        let folder1 = BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                                 size: 1024, projectName: "Test1", lastModified: Date(), isSelected: true)
        let folder2 = BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                                 size: 2048, projectName: "Test2", lastModified: Date(), isSelected: false)
        sut.scanResults = [folder1, folder2]

        // When
        sut.deleteSelectedFolders()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 sec

        // Then
        XCTAssertTrue(mockDeleter.deleteCalled)
        XCTAssertEqual(mockDeleter.deletedFolders.count, 1)
        XCTAssertEqual(sut.scanResults.count, 1)
    }

    // MARK: - Computed Property Tests

    func test_selectedSize_calculatesCorrectTotal() {
        // Given
        sut.scanResults = [
            BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                       size: 1024, projectName: "Test1", lastModified: Date(), isSelected: true),
            BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                       size: 2048, projectName: "Test2", lastModified: Date(), isSelected: true)
        ]

        // Then
        XCTAssertEqual(sut.selectedSize, 1024 + 2048)
    }

    func test_formattedSelectedSize_returnsFormattedString() {
        // Given
        sut.scanResults = [
            BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                       size: 1024 * 1024 * 100, projectName: "Test1", lastModified: Date(), isSelected: true)
        ]

        // Then
        XCTAssertFalse(sut.formattedSelectedSize.isEmpty)
    }
}
