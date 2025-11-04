//
//  ModelTests.swift
//  ZeroDevCleanerTests
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import XCTest
@testable import ZeroDevCleaner

@MainActor
final class ModelTests: XCTestCase {

    // MARK: - ProjectType Tests

    func test_projectType_displayName_returnsCorrectNames() {
        XCTAssertEqual(ProjectType.android.displayName, "Android")
        XCTAssertEqual(ProjectType.iOS.displayName, "iOS/Xcode")
        XCTAssertEqual(ProjectType.swiftPackage.displayName, "Swift Package")
    }

    func test_projectType_iconName_returnsValidSFSymbols() {
        XCTAssertFalse(ProjectType.android.iconName.isEmpty)
        XCTAssertFalse(ProjectType.iOS.iconName.isEmpty)
        XCTAssertFalse(ProjectType.swiftPackage.iconName.isEmpty)
    }

    func test_projectType_buildFolderName_returnsCorrectPatterns() {
        XCTAssertEqual(ProjectType.android.buildFolderName, "build")
        XCTAssertEqual(ProjectType.iOS.buildFolderName, ".build")
        XCTAssertEqual(ProjectType.swiftPackage.buildFolderName, ".build")
    }

    func test_projectType_codable_encodesAndDecodes() throws {
        let type = ProjectType.android
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(type)
        let decoded = try decoder.decode(ProjectType.self, from: data)

        XCTAssertEqual(decoded, type)
    }

    // MARK: - BuildFolder Tests

    func test_buildFolder_initialization_setsAllProperties() {
        let url = URL(fileURLWithPath: "/test/path/build")
        let date = Date()
        let folder = BuildFolder(
            path: url,
            projectType: .android,
            size: 1024 * 1024 * 100, // 100 MB
            projectName: "TestProject",
            lastModified: date,
            isSelected: true
        )

        XCTAssertEqual(folder.path, url)
        XCTAssertEqual(folder.projectType, .android)
        XCTAssertEqual(folder.size, 1024 * 1024 * 100)
        XCTAssertEqual(folder.projectName, "TestProject")
        XCTAssertEqual(folder.lastModified, date)
        XCTAssertTrue(folder.isSelected)
    }

    func test_buildFolder_formattedSize_returnsHumanReadable() {
        let folder = BuildFolder(
            path: URL(fileURLWithPath: "/test"),
            projectType: .iOS,
            size: 1024 * 1024 * 100, // 100 MB
            projectName: "Test",
            lastModified: Date(),
            isSelected: false
        )

        XCTAssertFalse(folder.formattedSize.isEmpty)
        XCTAssertTrue(folder.formattedSize.contains("MB") || folder.formattedSize.contains("GB"))
    }

    func test_buildFolder_relativePath_removesRootPath() {
        let root = URL(fileURLWithPath: "/Users/test")
        let folder = BuildFolder(
            path: URL(fileURLWithPath: "/Users/test/project/build"),
            projectType: .android,
            size: 1024,
            projectName: "Test",
            lastModified: Date(),
            isSelected: false
        )

        let relative = folder.relativePath(from: root)
        XCTAssertEqual(relative, "project/build")
    }

    func test_buildFolder_hashable_worksInSet() {
        let folder1 = BuildFolder(
            id: UUID(),
            path: URL(fileURLWithPath: "/test1"),
            projectType: .android,
            size: 1024,
            projectName: "Test1",
            lastModified: Date(),
            isSelected: false
        )
        let folder2 = BuildFolder(
            id: UUID(),
            path: URL(fileURLWithPath: "/test2"),
            projectType: .iOS,
            size: 2048,
            projectName: "Test2",
            lastModified: Date(),
            isSelected: false
        )

        let set: Set<BuildFolder> = [folder1, folder2]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - ScanResult Tests

    func test_scanResult_totalSize_sumsAllFolders() {
        let folders = [
            BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                       size: 1024, projectName: "Test1", lastModified: Date()),
            BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                       size: 2048, projectName: "Test2", lastModified: Date()),
            BuildFolder(path: URL(fileURLWithPath: "/test3"), projectType: .swiftPackage,
                       size: 512, projectName: "Test3", lastModified: Date())
        ]

        let result = ScanResult(
            rootPath: URL(fileURLWithPath: "/root"),
            scanDate: Date(),
            buildFolders: folders,
            scanDuration: 10.5
        )

        XCTAssertEqual(result.totalSize, 1024 + 2048 + 512)
    }

    func test_scanResult_selectedSize_sumsOnlySelected() {
        let folders = [
            BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                       size: 1024, projectName: "Test1", lastModified: Date(), isSelected: true),
            BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                       size: 2048, projectName: "Test2", lastModified: Date(), isSelected: false),
            BuildFolder(path: URL(fileURLWithPath: "/test3"), projectType: .swiftPackage,
                       size: 512, projectName: "Test3", lastModified: Date(), isSelected: true)
        ]

        let result = ScanResult(
            rootPath: URL(fileURLWithPath: "/root"),
            scanDate: Date(),
            buildFolders: folders,
            scanDuration: 10.5
        )

        XCTAssertEqual(result.selectedSize, 1024 + 512)
        XCTAssertEqual(result.selectedCount, 2)
    }

    func test_scanResult_formattedScanDuration_isReadable() {
        let result = ScanResult(
            rootPath: URL(fileURLWithPath: "/root"),
            scanDate: Date(),
            buildFolders: [],
            scanDuration: 125.7
        )

        XCTAssertFalse(result.formattedScanDuration.isEmpty)
    }

    // MARK: - Error Tests

    func test_error_errorDescription_providesMessage() {
        let error = ZeroDevCleanerError.scanCancelled
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func test_error_recoverySuggestion_providesGuidance() {
        let error = ZeroDevCleanerError.permissionDenied(URL(fileURLWithPath: "/test"))
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("Full Disk Access"))
    }
}
