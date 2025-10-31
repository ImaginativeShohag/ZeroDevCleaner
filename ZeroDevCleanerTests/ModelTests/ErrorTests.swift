//
//  ErrorTests.swift
//  ZeroDevCleanerTests
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import XCTest
@testable import ZeroDevCleaner

final class ErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func test_permissionDenied_hasCorrectDescription() {
        // Given
        let url = URL(fileURLWithPath: "/test/folder")
        let error = ZeroDevCleanerError.permissionDenied(url)

        // Then
        XCTAssertEqual(error.errorDescription, "Permission Denied")
        XCTAssertTrue(error.recoverySuggestion?.contains("Full Disk Access") ?? false)
    }

    func test_fileNotFound_hasCorrectDescription() {
        // Given
        let url = URL(fileURLWithPath: "/test/folder")
        let error = ZeroDevCleanerError.fileNotFound(url)

        // Then
        XCTAssertEqual(error.errorDescription, "Folder Not Found")
        XCTAssertTrue(error.recoverySuggestion?.contains("no longer exists") ?? false)
    }

    func test_deletionFailed_hasCorrectDescription() {
        // Given
        let url = URL(fileURLWithPath: "/test/build")
        let underlyingError = NSError(domain: "test", code: 1, userInfo: nil)
        let error = ZeroDevCleanerError.deletionFailed(url, underlyingError)

        // Then
        XCTAssertTrue(error.errorDescription?.contains("build") ?? false)
        XCTAssertTrue(error.recoverySuggestion?.contains("in use") ?? false)
    }

    func test_scanCancelled_hasCorrectDescription() {
        // Given
        let error = ZeroDevCleanerError.scanCancelled

        // Then
        XCTAssertEqual(error.errorDescription, "Scan Cancelled")
        XCTAssertTrue(error.recoverySuggestion?.contains("new scan") ?? false)
    }

    func test_noResultsFound_hasCorrectDescription() {
        // Given
        let url = URL(fileURLWithPath: "/test/folder")
        let error = ZeroDevCleanerError.noResultsFound(url)

        // Then
        XCTAssertEqual(error.errorDescription, "No Build Folders Found")
        XCTAssertTrue(error.recoverySuggestion?.contains("No build folders were found") ?? false)
    }

    func test_partialDeletionFailure_hasCorrectDescription() {
        // Given
        let urls = [
            URL(fileURLWithPath: "/test/build1"),
            URL(fileURLWithPath: "/test/build2"),
            URL(fileURLWithPath: "/test/build3"),
            URL(fileURLWithPath: "/test/build4")
        ]
        let error = ZeroDevCleanerError.partialDeletionFailure(urls)

        // Then
        XCTAssertEqual(error.errorDescription, "Some Items Could Not Be Deleted")
        XCTAssertTrue(error.recoverySuggestion?.contains("4 item") ?? false)
        XCTAssertTrue(error.recoverySuggestion?.contains("and 1 more") ?? false)
    }

    func test_outOfDiskSpace_hasCorrectDescription() {
        // Given
        let error = ZeroDevCleanerError.outOfDiskSpace

        // Then
        XCTAssertEqual(error.errorDescription, "Out of Disk Space")
        XCTAssertTrue(error.recoverySuggestion?.contains("Free up some space") ?? false)
    }

    func test_folderInUse_hasCorrectDescription() {
        // Given
        let url = URL(fileURLWithPath: "/test/build")
        let error = ZeroDevCleanerError.folderInUse(url)

        // Then
        XCTAssertEqual(error.errorDescription, "Folder In Use")
        XCTAssertTrue(error.recoverySuggestion?.contains("Close any applications") ?? false)
    }

    func test_networkDriveNotSupported_hasCorrectDescription() {
        // Given
        let url = URL(fileURLWithPath: "/Volumes/Network")
        let error = ZeroDevCleanerError.networkDriveNotSupported(url)

        // Then
        XCTAssertEqual(error.errorDescription, "Network Drive Not Supported")
        XCTAssertTrue(error.recoverySuggestion?.contains("network drive") ?? false)
    }

    func test_unknownError_hasCorrectDescription() {
        // Given
        let underlyingError = NSError(domain: "test", code: 999, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error = ZeroDevCleanerError.unknownError(underlyingError)

        // Then
        XCTAssertEqual(error.errorDescription, "An Unexpected Error Occurred")
        XCTAssertTrue(error.recoverySuggestion?.contains("Test error") ?? false)
    }

    // MARK: - Recovery Suggestion Tests

    func test_allErrors_haveRecoverySuggestions() {
        // Given
        let url = URL(fileURLWithPath: "/test")
        let underlyingError = NSError(domain: "test", code: 1, userInfo: nil)

        let errors: [ZeroDevCleanerError] = [
            .permissionDenied(url),
            .fileNotFound(url),
            .deletionFailed(url, underlyingError),
            .scanCancelled,
            .invalidPath(url),
            .calculationFailed(url, underlyingError),
            .outOfDiskSpace,
            .folderInUse(url),
            .networkDriveNotSupported(url),
            .noResultsFound(url),
            .partialDeletionFailure([url]),
            .unknownError(underlyingError)
        ]

        // Then
        for error in errors {
            XCTAssertNotNil(error.recoverySuggestion, "Error \(error.errorDescription ?? "") should have recovery suggestion")
            XCTAssertFalse(error.recoverySuggestion?.isEmpty ?? true, "Recovery suggestion should not be empty")
        }
    }
}
