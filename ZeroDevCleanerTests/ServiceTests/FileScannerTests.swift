//
//  FileScannerTests.swift
//  ZeroDevCleanerTests
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import XCTest
@testable import ZeroDevCleaner

@MainActor
final class FileScannerTests: XCTestCase {
    var sut: FileScanner!
    var mockValidator: ProjectValidator!
    var mockSizeCalculator: MockFileSizeCalculator!
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()
        mockValidator = ProjectValidator()
        mockSizeCalculator = MockFileSizeCalculator()
        sut = FileScanner(
            validator: mockValidator,
            sizeCalculator: mockSizeCalculator,
            maxDepth: 5
        )
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        sut = nil
        mockValidator = nil
        mockSizeCalculator = nil
        try await super.tearDown()
    }

    // MARK: - .build Folder Detection Tests

    func test_scanDirectory_findsHiddenDotBuildFolder() async throws {
        // Given: Swift Package with .build folder (hidden)
        let packageDir = tempDirectory.appendingPathComponent("MyPackage")
        let buildDir = packageDir.appendingPathComponent(".build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let packageSwift = packageDir.appendingPathComponent("Package.swift")
        try "// Package.swift".write(to: packageSwift, atomically: true, encoding: .utf8)

        mockSizeCalculator.mockSize = 1024 * 1024 * 50 // 50 MB

        // When
        let results = try await sut.scanDirectory(at: tempDirectory, progressHandler: nil)

        // Then
        XCTAssertEqual(results.count, 1, "Should find the .build folder")
        XCTAssertEqual(results.first?.projectType, .swiftPackage)
        XCTAssertEqual(results.first?.path.lastPathComponent, ".build")
    }

    func test_scanDirectory_findsiOSDotBuildFolder() async throws {
        // Given: iOS project with .build folder for SPM dependencies
        let projectDir = tempDirectory.appendingPathComponent("MyiOSApp")
        let buildDir = projectDir.appendingPathComponent(".build")
        let xcodeProjDir = projectDir.appendingPathComponent("MyiOSApp.xcodeproj")

        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: xcodeProjDir, withIntermediateDirectories: true)

        mockSizeCalculator.mockSize = 1024 * 1024 * 100 // 100 MB

        // When
        let results = try await sut.scanDirectory(at: tempDirectory, progressHandler: nil)

        // Then
        XCTAssertEqual(results.count, 1, "Should find the .build folder for iOS project")
        XCTAssertEqual(results.first?.projectType, .iOS)
        XCTAssertEqual(results.first?.path.lastPathComponent, ".build")
    }

    func test_scanDirectory_findsiOSBuildFolder() async throws {
        // Given: iOS project with build folder (legacy/in-place build)
        let projectDir = tempDirectory.appendingPathComponent("MyiOSApp")
        let buildDir = projectDir.appendingPathComponent("build")
        let xcodeProjDir = projectDir.appendingPathComponent("MyiOSApp.xcodeproj")

        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: xcodeProjDir, withIntermediateDirectories: true)

        mockSizeCalculator.mockSize = 1024 * 1024 * 200 // 200 MB

        // When
        let results = try await sut.scanDirectory(at: tempDirectory, progressHandler: nil)

        // Then
        XCTAssertEqual(results.count, 1, "Should find the build folder for iOS project")
        XCTAssertEqual(results.first?.projectType, .iOS)
        XCTAssertEqual(results.first?.path.lastPathComponent, "build")
    }

    // MARK: - Hidden Folder Skipping Tests

    func test_scanDirectory_skipsGitFolder() async throws {
        // Given: Project with .git folder (should be skipped)
        let projectDir = tempDirectory.appendingPathComponent("MyProject")
        let gitDir = projectDir.appendingPathComponent(".git")
        let buildDir = projectDir.appendingPathComponent("build")

        try FileManager.default.createDirectory(at: gitDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let buildGradle = projectDir.appendingPathComponent("build.gradle")
        try "".write(to: buildGradle, atomically: true, encoding: .utf8)

        mockSizeCalculator.mockSize = 1024 * 1024 * 10

        // When
        let results = try await sut.scanDirectory(at: tempDirectory, progressHandler: nil)

        // Then
        XCTAssertEqual(results.count, 1, "Should find build folder but skip .git")
        XCTAssertFalse(results.contains(where: { $0.path.lastPathComponent == ".git" }))
    }

    func test_scanDirectory_skipsOtherHiddenFolders() async throws {
        // Given: Project with various hidden folders
        let projectDir = tempDirectory.appendingPathComponent("MyProject")
        let svnDir = projectDir.appendingPathComponent(".svn")
        let ideaDir = projectDir.appendingPathComponent(".idea")
        let buildDir = projectDir.appendingPathComponent("build")

        try FileManager.default.createDirectory(at: svnDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: ideaDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let buildGradle = projectDir.appendingPathComponent("build.gradle")
        try "".write(to: buildGradle, atomically: true, encoding: .utf8)

        mockSizeCalculator.mockSize = 1024 * 1024 * 10

        // When
        let results = try await sut.scanDirectory(at: tempDirectory, progressHandler: nil)

        // Then
        XCTAssertEqual(results.count, 1, "Should only find the build folder")
        XCTAssertEqual(results.first?.path.lastPathComponent, "build")
        XCTAssertFalse(results.contains(where: { $0.path.lastPathComponent.hasPrefix(".") && $0.path.lastPathComponent != ".build" }))
    }

    // MARK: - Multiple Project Types Tests

    func test_scanDirectory_findsMultipleProjectTypes() async throws {
        // Given: Directory with Android, iOS, and Swift Package projects
        // Android
        let androidDir = tempDirectory.appendingPathComponent("AndroidApp")
        let androidBuildDir = androidDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: androidBuildDir, withIntermediateDirectories: true)
        let buildGradle = androidDir.appendingPathComponent("build.gradle")
        try "".write(to: buildGradle, atomically: true, encoding: .utf8)

        // iOS
        let iosDir = tempDirectory.appendingPathComponent("iOSApp")
        let iosBuildDir = iosDir.appendingPathComponent(".build")
        let xcodeProjDir = iosDir.appendingPathComponent("iOSApp.xcodeproj")
        try FileManager.default.createDirectory(at: iosBuildDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: xcodeProjDir, withIntermediateDirectories: true)

        // Swift Package
        let packageDir = tempDirectory.appendingPathComponent("MyPackage")
        let packageBuildDir = packageDir.appendingPathComponent(".build")
        try FileManager.default.createDirectory(at: packageBuildDir, withIntermediateDirectories: true)
        let packageSwift = packageDir.appendingPathComponent("Package.swift")
        try "".write(to: packageSwift, atomically: true, encoding: .utf8)

        mockSizeCalculator.mockSize = 1024 * 1024 * 10

        // When
        let results = try await sut.scanDirectory(at: tempDirectory, progressHandler: nil)

        // Then
        XCTAssertEqual(results.count, 3, "Should find all three project types")
        XCTAssertTrue(results.contains(where: { $0.projectType == .android }))
        XCTAssertTrue(results.contains(where: { $0.projectType == .iOS }))
        XCTAssertTrue(results.contains(where: { $0.projectType == .swiftPackage }))
    }

    // MARK: - Nested Project Tests

    func test_scanDirectory_findsNestedProjects() async throws {
        // Given: Nested project structure
        let workspaceDir = tempDirectory.appendingPathComponent("Workspace")
        let project1Dir = workspaceDir.appendingPathComponent("Project1")
        let project2Dir = workspaceDir.appendingPathComponent("SubFolder").appendingPathComponent("Project2")

        // Project 1
        let build1Dir = project1Dir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: build1Dir, withIntermediateDirectories: true)
        let gradle1 = project1Dir.appendingPathComponent("build.gradle")
        try "".write(to: gradle1, atomically: true, encoding: .utf8)

        // Project 2
        let build2Dir = project2Dir.appendingPathComponent(".build")
        try FileManager.default.createDirectory(at: build2Dir, withIntermediateDirectories: true)
        let package2 = project2Dir.appendingPathComponent("Package.swift")
        try "".write(to: package2, atomically: true, encoding: .utf8)

        mockSizeCalculator.mockSize = 1024 * 1024 * 10

        // When
        let results = try await sut.scanDirectory(at: tempDirectory, progressHandler: nil)

        // Then
        XCTAssertEqual(results.count, 2, "Should find both nested projects")
    }

    // MARK: - Progress Handler Tests

    func test_scanDirectory_callsProgressHandler() async throws {
        // Given
        let projectDir = tempDirectory.appendingPathComponent("MyPackage")
        let buildDir = projectDir.appendingPathComponent(".build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        let packageSwift = projectDir.appendingPathComponent("Package.swift")
        try "".write(to: packageSwift, atomically: true, encoding: .utf8)

        mockSizeCalculator.mockSize = 1024 * 1024 * 10

        let progressCalls = ActorBox<(String, Int)>()

        // When
        _ = try await sut.scanDirectory(at: tempDirectory) { path, count in
            Task {
                await progressCalls.append((path, count))
            }
        }

        // Then
        let calls = await progressCalls.value
        XCTAssertGreaterThan(calls.count, 0, "Progress handler should be called")
        XCTAssertNotNil(calls.last?.0)
        XCTAssertNotNil(calls.last?.1)
    }
}

// MARK: - Mock FileSizeCalculator

final class MockFileSizeCalculator: FileSizeCalculatorProtocol, Sendable {
    nonisolated(unsafe) var mockSize: Int64 = 0

    func calculateSize(of directory: URL) async throws -> Int64 {
        return mockSize
    }
}

// MARK: - Actor Box for Thread-Safe State

actor ActorBox<T> {
    private var items: [T] = []

    func append(_ item: T) {
        items.append(item)
    }

    var value: [T] {
        items
    }
}
