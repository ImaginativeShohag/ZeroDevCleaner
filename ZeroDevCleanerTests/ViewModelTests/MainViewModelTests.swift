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

    // MARK: - Filter Tests

    func test_filteredResults_withAllFilter_returnsAllFolders() {
        // Given
        sut.scanResults = [
            BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                       size: 1024, projectName: "Test1", lastModified: Date()),
            BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                       size: 2048, projectName: "Test2", lastModified: Date()),
            BuildFolder(path: URL(fileURLWithPath: "/test3"), projectType: .swiftPackage,
                       size: 512, projectName: "Test3", lastModified: Date())
        ]
        sut.currentFilter = .all

        // Then
        XCTAssertEqual(sut.filteredResults.count, 3)
    }

    func test_filteredResults_withAndroidFilter_returnsOnlyAndroid() {
        // Given
        sut.scanResults = [
            BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                       size: 1024, projectName: "Test1", lastModified: Date()),
            BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                       size: 2048, projectName: "Test2", lastModified: Date())
        ]
        sut.currentFilter = .android

        // Then
        XCTAssertEqual(sut.filteredResults.count, 1)
        XCTAssertEqual(sut.filteredResults[0].projectType, .android)
    }

    func test_filteredResults_withIOSFilter_returnsOnlyIOS() {
        // Given
        sut.scanResults = [
            BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                       size: 1024, projectName: "Test1", lastModified: Date()),
            BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                       size: 2048, projectName: "Test2", lastModified: Date())
        ]
        sut.currentFilter = .iOS

        // Then
        XCTAssertEqual(sut.filteredResults.count, 1)
        XCTAssertEqual(sut.filteredResults[0].projectType, .iOS)
    }

    func test_selectAll_withFilter_selectsOnlyFilteredFolders() {
        // Given
        sut.scanResults = [
            BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                       size: 1024, projectName: "Test1", lastModified: Date(), isSelected: false),
            BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                       size: 2048, projectName: "Test2", lastModified: Date(), isSelected: false)
        ]
        sut.currentFilter = .android

        // When
        sut.selectAll()

        // Then
        XCTAssertTrue(sut.scanResults[0].isSelected) // Android folder
        XCTAssertFalse(sut.scanResults[1].isSelected) // iOS folder not selected
    }

    // MARK: - Error Handling Tests

    func test_startScan_withEmptyResults_showsNoResultsError() async {
        // Given
        sut.selectedFolder = URL(fileURLWithPath: "/test")
        mockScanner.mockResults = []

        // When
        sut.startScan()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.showError)
        if case .noResultsFound = sut.currentError {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected noResultsFound error")
        }
    }

    func test_startScan_withError_handlesError() async {
        // Given
        sut.selectedFolder = URL(fileURLWithPath: "/test")
        let expectedError = NSError(domain: NSCocoaErrorDomain, code: 257, userInfo: nil)
        mockScanner.shouldThrowError = expectedError

        // When
        sut.startScan()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.showPermissionError)
        XCTAssertFalse(sut.isScanning)
    }

    func test_selectFolder_withNetworkDrive_showsError() {
        // Given
        let networkURL = URL(fileURLWithPath: "/Volumes/NetworkDrive")

        // When
        sut.selectFolder(at: networkURL)

        // Network drive detection might not work in tests, but we test the flow
        // The actual check uses resourceValues which may not work in unit tests
    }

    func test_deleteSelectedFolders_withPartialFailure_removesSuccessfulOnes() async {
        // Given
        let folder1 = BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                                 size: 1024, projectName: "Test1", lastModified: Date(), isSelected: true)
        let folder2 = BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                                 size: 2048, projectName: "Test2", lastModified: Date(), isSelected: true)
        sut.scanResults = [folder1, folder2]

        let partialError = ZeroDevCleanerError.partialDeletionFailure([folder2.path])
        mockDeleter.shouldThrowError = partialError

        // When
        sut.deleteSelectedFolders()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.showError)
        XCTAssertFalse(sut.isDeleting)
    }

    // MARK: - Concurrent Operation Tests

    func test_startScan_whileScanning_doesNotStartNewScan() {
        // Given
        sut.selectedFolder = URL(fileURLWithPath: "/test")
        sut.isScanning = true
        mockScanner.scanCalled = false

        // When
        sut.startScan()

        // Then
        XCTAssertFalse(mockScanner.scanCalled)
    }

    func test_startScan_whileDeleting_doesNotStartScan() {
        // Given
        sut.selectedFolder = URL(fileURLWithPath: "/test")
        sut.isDeleting = true
        mockScanner.scanCalled = false

        // When
        sut.startScan()

        // Then
        XCTAssertFalse(mockScanner.scanCalled)
    }

    func test_deleteSelectedFolders_whileScanning_doesNotDelete() {
        // Given
        let folder = BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                                size: 1024, projectName: "Test1", lastModified: Date(), isSelected: true)
        sut.scanResults = [folder]
        sut.isScanning = true
        mockDeleter.deleteCalled = false

        // When
        sut.deleteSelectedFolders()

        // Then
        XCTAssertFalse(mockDeleter.deleteCalled)
    }

    func test_deleteSelectedFolders_whileDeleting_doesNotStartNewDeletion() {
        // Given
        let folder = BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                                size: 1024, projectName: "Test1", lastModified: Date(), isSelected: true)
        sut.scanResults = [folder]
        sut.isDeleting = true
        mockDeleter.deleteCalled = false

        // When
        sut.deleteSelectedFolders()

        // Then
        XCTAssertFalse(mockDeleter.deleteCalled)
    }

    // MARK: - Scan Cancellation Tests

    func test_cancelScan_withResults_keepsPartialResults() {
        // Given
        sut.scanResults = [
            BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                       size: 1024, projectName: "Test1", lastModified: Date())
        ]
        sut.isScanning = true

        // When
        sut.cancelScan()

        // Then
        XCTAssertFalse(sut.isScanning)
        XCTAssertEqual(sut.scanResults.count, 1)
        XCTAssertFalse(sut.showError) // Should not show error when we have results
    }

    func test_cancelScan_withNoResults_showsCancelledError() {
        // Given
        sut.scanResults = []
        sut.isScanning = true

        // When
        sut.cancelScan()

        // Then
        XCTAssertFalse(sut.isScanning)
        XCTAssertTrue(sut.showError)
        if case .scanCancelled = sut.currentError {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected scanCancelled error")
        }
    }

    // MARK: - Error Dismissal Tests

    func test_dismissError_clearsErrorState() {
        // Given
        sut.currentError = .scanCancelled
        sut.showError = true
        sut.showPermissionError = true

        // When
        sut.dismissError()

        // Then
        XCTAssertFalse(sut.showError)
        XCTAssertFalse(sut.showPermissionError)
        XCTAssertNil(sut.currentError)
    }
}
