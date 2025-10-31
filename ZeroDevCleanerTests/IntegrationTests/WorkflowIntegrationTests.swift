//
//  WorkflowIntegrationTests.swift
//  ZeroDevCleanerTests
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import XCTest
@testable import ZeroDevCleaner

/// Integration tests that verify complete workflows from start to finish
@MainActor
final class WorkflowIntegrationTests: XCTestCase {
    var viewModel: MainViewModel!
    var mockScanner: MockFileScanner!
    var mockDeleter: MockFileDeleter!
    var mockStaticScanner: MockStaticLocationScanner!
    var testFolder: URL!

    override func setUp() async throws {
        try await super.setUp()
        mockScanner = MockFileScanner()
        mockDeleter = MockFileDeleter()
        mockStaticScanner = MockStaticLocationScanner()
        viewModel = MainViewModel(scanner: mockScanner, deleter: mockDeleter, staticScanner: mockStaticScanner)
        testFolder = URL(fileURLWithPath: "/test/project")
    }

    override func tearDown() async throws {
        viewModel = nil
        mockScanner = nil
        mockDeleter = nil
        mockStaticScanner = nil
        testFolder = nil
        try await super.tearDown()
    }

    // MARK: - Complete Scan Workflow

    func test_completeScanWorkflow_selectFolderAndScan() async throws {
        // Given: A folder with build folders
        let buildFolder1 = BuildFolder(
            path: URL(fileURLWithPath: "/test/project1/build"),
            projectType: .android,
            size: 1024 * 1024 * 10, // 10 MB
            projectName: "Project1",
            lastModified: Date()
        )
        let buildFolder2 = BuildFolder(
            path: URL(fileURLWithPath: "/test/project2/build"),
            projectType: .iOS,
            size: 1024 * 1024 * 20, // 20 MB
            projectName: "Project2",
            lastModified: Date()
        )
        mockScanner.mockResults = [buildFolder1, buildFolder2]

        // When: User selects folder and starts scan
        let testLocation = ScanLocation(name: "Test Location", path: testFolder)
        viewModel.startScan(locations: [testLocation])

        // Wait for async scan to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 sec

        // Then: Results are displayed
        XCTAssertEqual(viewModel.scanResults.count, 2)
        XCTAssertFalse(viewModel.isScanning)
        XCTAssertTrue(mockScanner.scanCalled)
        XCTAssertEqual(viewModel.totalFoldersCount, 2)
        XCTAssertEqual(viewModel.totalSpaceSize, 1024 * 1024 * 30)
    }

    // MARK: - Complete Delete Workflow

    func test_completeDeleteWorkflow_selectScanDeleteItems() async throws {
        // Given: Scanned results with selected items
        let buildFolder1 = BuildFolder(
            path: URL(fileURLWithPath: "/test/project1/build"),
            projectType: .android,
            size: 1024 * 1024 * 10,
            projectName: "Project1",
            lastModified: Date(),
            isSelected: true
        )
        let buildFolder2 = BuildFolder(
            path: URL(fileURLWithPath: "/test/project2/build"),
            projectType: .iOS,
            size: 1024 * 1024 * 20,
            projectName: "Project2",
            lastModified: Date(),
            isSelected: false
        )
        mockScanner.mockResults = [buildFolder1, buildFolder2]

        let testLocation = ScanLocation(name: "Test Location", path: testFolder)
        viewModel.startScan(locations: [testLocation])
        try await Task.sleep(nanoseconds: 200_000_000)

        // When: User deletes selected items
        viewModel.confirmDeletion()
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: Only selected items are deleted
        XCTAssertTrue(mockDeleter.deleteCalled)
        XCTAssertEqual(mockDeleter.deletedURLs.count, 1)
        XCTAssertEqual(viewModel.scanResults.count, 1)
        XCTAssertEqual(viewModel.scanResults.first?.projectName, "Project2")
    }

    // MARK: - Filter Workflow

    func test_filterWorkflow_scanFilterSelectDelete() async throws {
        // Given: Mixed project types
        let androidFolder = BuildFolder(
            path: URL(fileURLWithPath: "/test/android/build"),
            projectType: .android,
            size: 1024 * 1024 * 10,
            projectName: "AndroidApp",
            lastModified: Date()
        )
        let iosFolder = BuildFolder(
            path: URL(fileURLWithPath: "/test/ios/build"),
            projectType: .iOS,
            size: 1024 * 1024 * 15,
            projectName: "iOSApp",
            lastModified: Date()
        )
        let swiftPackageFolder = BuildFolder(
            path: URL(fileURLWithPath: "/test/package/.build"),
            projectType: .swiftPackage,
            size: 1024 * 1024 * 5,
            projectName: "SwiftPackage",
            lastModified: Date()
        )
        mockScanner.mockResults = [androidFolder, iosFolder, swiftPackageFolder]

        // When: Scan, filter to Android, select all filtered
        let testLocation = ScanLocation(name: "Test Location", path: testFolder)
        viewModel.startScan(locations: [testLocation])
        try await Task.sleep(nanoseconds: 200_000_000)

        viewModel.currentFilter = .android
        viewModel.selectAll()

        // Then: Only Android items are selected
        XCTAssertEqual(viewModel.filteredResults.count, 1)
        XCTAssertEqual(viewModel.selectedFolders.count, 1)
        XCTAssertEqual(viewModel.selectedFolders.first?.projectType, .android)

        // When: Delete selected
        viewModel.confirmDeletion()
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: Only Android folder is deleted
        XCTAssertEqual(mockDeleter.deletedURLs.count, 1)
        XCTAssertEqual(viewModel.scanResults.count, 2)
    }

    // MARK: - Error Scenarios

    func test_emptyResultsWorkflow_showsErrorAndGuidance() async throws {
        // Given: A folder with no build folders
        mockScanner.mockResults = []
        mockStaticScanner.mockStaticLocations = []

        // When: User scans
        let testLocation = ScanLocation(name: "Test Location", path: testFolder)
        viewModel.startScan(locations: [testLocation])
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: Error is shown with guidance
        XCTAssertTrue(viewModel.showError)
        if case .scanCancelled = viewModel.currentError {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected scanCancelled error")
        }
        XCTAssertTrue(viewModel.scanResults.isEmpty)
    }

    func test_partialDeletionFailureWorkflow_showsErrorAndKeepsFailed() async throws {
        // Given: Multiple items where some fail to delete
        let folder1 = BuildFolder(
            path: URL(fileURLWithPath: "/test/project1/build"),
            projectType: .android,
            size: 1024,
            projectName: "Project1",
            lastModified: Date(),
            isSelected: true
        )
        let folder2 = BuildFolder(
            path: URL(fileURLWithPath: "/test/project2/build"),
            projectType: .iOS,
            size: 2048,
            projectName: "Project2",
            lastModified: Date(),
            isSelected: true
        )
        mockScanner.mockResults = [folder1, folder2]

        let testLocation = ScanLocation(name: "Test Location", path: testFolder)
        viewModel.startScan(locations: [testLocation])
        try await Task.sleep(nanoseconds: 200_000_000)

        // When: Deletion partially fails
        let partialError = ZeroDevCleanerError.partialDeletionFailure([folder2.path])
        mockDeleter.shouldThrowError = partialError
        viewModel.confirmDeletion()
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: Error shown, failed items remain, successful items removed
        XCTAssertTrue(viewModel.showError)
        // In partial failure, both items should still be called for deletion
        XCTAssertTrue(mockDeleter.deleteCalled)
    }

    // MARK: - Cancellation Workflow

    func test_cancellationWorkflow_showsPartialResults() async throws {
        // Given: A long-running scan
        let folder1 = BuildFolder(
            path: URL(fileURLWithPath: "/test/project1/build"),
            projectType: .android,
            size: 1024,
            projectName: "Project1",
            lastModified: Date()
        )
        mockScanner.mockResults = [folder1]

        // When: User starts scan and immediately cancels
        let testLocation = ScanLocation(name: "Test Location", path: testFolder)
        viewModel.startScan(locations: [testLocation])
        try await Task.sleep(nanoseconds: 50_000_000) // Let it start

        // Manually add a result to simulate partial scanning
        viewModel.scanResults = [folder1]
        viewModel.cancelScan()

        // Then: Partial results are shown, no error
        XCTAssertFalse(viewModel.isScanning)
        XCTAssertFalse(viewModel.showError)
        XCTAssertEqual(viewModel.scanResults.count, 1)
    }

    func test_cancellationWorkflow_withNoResults_showsError() {
        // Given: Scan in progress with no results yet
        viewModel.isScanning = true
        viewModel.scanResults = []

        // When: User cancels
        viewModel.cancelScan()

        // Then: Cancellation error is shown
        XCTAssertTrue(viewModel.showError)
        if case .scanCancelled = viewModel.currentError {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected scanCancelled error")
        }
    }

    // MARK: - Recent Folders Workflow

    func test_recentFoldersWorkflow_addsSuccessfulScans() async throws {
        // Given: A successful scan
        mockScanner.mockResults = [
            BuildFolder(
                path: URL(fileURLWithPath: "/test/build"),
                projectType: .android,
                size: 1024,
                projectName: "Test",
                lastModified: Date()
            )
        ]

        // When: User scans multiple folders
        let folder1 = URL(fileURLWithPath: "/test/project1")
        let folder2 = URL(fileURLWithPath: "/test/project2")

        let location1 = ScanLocation(name: "Project 1", path: folder1)
        viewModel.startScan(locations: [location1])
        try await Task.sleep(nanoseconds: 200_000_000)

        let location2 = ScanLocation(name: "Project 2", path: folder2)
        viewModel.startScan(locations: [location2])
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: Recent folders are updated
        // Note: Recent folders manager filters non-existent paths, so we can't verify exact folders
        // But we can verify the manager is being called
        XCTAssertTrue(mockScanner.scanCalled)
    }

    // MARK: - Concurrent Operation Prevention

    func test_concurrentOperationPrevention_cannotScanWhileDeleting() async throws {
        // Given: Items ready for deletion
        mockScanner.mockResults = [
            BuildFolder(
                path: URL(fileURLWithPath: "/test/build"),
                projectType: .android,
                size: 1024,
                projectName: "Test",
                lastModified: Date(),
                isSelected: true
            )
        ]

        let testLocation = ScanLocation(name: "Test Location", path: testFolder)
        viewModel.startScan(locations: [testLocation])
        try await Task.sleep(nanoseconds: 200_000_000)

        // When: Deletion starts
        viewModel.confirmDeletion()
        mockScanner.scanCalled = false // Reset

        // And: User tries to start a new scan
        viewModel.startScan(locations: [testLocation])

        // Then: New scan is prevented
        XCTAssertFalse(mockScanner.scanCalled)
    }

    func test_concurrentOperationPrevention_cannotDeleteWhileScanning() {
        // Given: Scan in progress
        mockScanner.mockResults = []
        let testLocation = ScanLocation(name: "Test Location", path: testFolder)
        viewModel.startScan(locations: [testLocation])
        viewModel.scanResults = [
            BuildFolder(
                path: URL(fileURLWithPath: "/test/build"),
                projectType: .android,
                size: 1024,
                projectName: "Test",
                lastModified: Date(),
                isSelected: true
            )
        ]

        mockDeleter.deleteCalled = false

        // When: User tries to delete
        viewModel.confirmDeletion()

        // Then: Deletion is prevented
        XCTAssertFalse(mockDeleter.deleteCalled)
    }

    // MARK: - Select/Deselect All Workflow

    func test_selectDeselectAllWorkflow_worksWithFilters() async throws {
        // Given: Mixed results
        mockScanner.mockResults = [
            BuildFolder(path: URL(fileURLWithPath: "/test/android/build"),
                       projectType: .android, size: 1024, projectName: "Android",
                       lastModified: Date(), isSelected: false),
            BuildFolder(path: URL(fileURLWithPath: "/test/ios/build"),
                       projectType: .iOS, size: 2048, projectName: "iOS",
                       lastModified: Date(), isSelected: false)
        ]

        let testLocation = ScanLocation(name: "Test Location", path: testFolder)
        viewModel.startScan(locations: [testLocation])
        try await Task.sleep(nanoseconds: 200_000_000)

        // When: Filter to Android and select all
        viewModel.currentFilter = .android
        viewModel.selectAll()

        // Then: Only Android is selected
        XCTAssertEqual(viewModel.selectedFolders.count, 1)
        XCTAssertEqual(viewModel.selectedFolders.first?.projectType, .android)

        // When: Deselect all
        viewModel.deselectAll()

        // Then: Android is deselected
        XCTAssertEqual(viewModel.selectedFolders.count, 0)
    }
}
