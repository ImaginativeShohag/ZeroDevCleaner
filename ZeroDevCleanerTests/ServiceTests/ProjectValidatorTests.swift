//
//  ProjectValidatorTests.swift
//  ZeroDevCleanerTests
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import XCTest
@testable import ZeroDevCleaner

@MainActor
final class ProjectValidatorTests: XCTestCase {
    var sut: ProjectValidator!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        sut = ProjectValidator()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Android Tests

    func test_isValidAndroidProject_withBuildGradle_returnsTrue() throws {
        // Given: Android project with build.gradle
        let projectDir = tempDirectory.appendingPathComponent("AndroidProject")
        let buildDir = projectDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let buildGradle = projectDir.appendingPathComponent("build.gradle")
        try "// build file".write(to: buildGradle, atomically: true, encoding: .utf8)

        // When
        let result = sut.isValidAndroidProject(buildFolder: buildDir)

        // Then
        XCTAssertTrue(result)
    }

    func test_isValidAndroidProject_withoutGradleFile_returnsFalse() throws {
        // Given: Random build folder
        let buildDir = tempDirectory.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        // When
        let result = sut.isValidAndroidProject(buildFolder: buildDir)

        // Then
        XCTAssertFalse(result)
    }

    func test_isValidAndroidProject_withSettingsGradle_returnsTrue() throws {
        // Given: Android project with settings.gradle
        let projectDir = tempDirectory.appendingPathComponent("AndroidProject2")
        let buildDir = projectDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let settingsGradle = projectDir.appendingPathComponent("settings.gradle")
        try "// settings file".write(to: settingsGradle, atomically: true, encoding: .utf8)

        // When
        let result = sut.isValidAndroidProject(buildFolder: buildDir)

        // Then
        XCTAssertTrue(result)
    }

    func test_isValidAndroidProject_withWrongFolderName_returnsFalse() throws {
        // Given: Folder not named "build"
        let projectDir = tempDirectory.appendingPathComponent("AndroidProject3")
        let buildDir = projectDir.appendingPathComponent("output")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let buildGradle = projectDir.appendingPathComponent("build.gradle")
        try "// build file".write(to: buildGradle, atomically: true, encoding: .utf8)

        // When
        let result = sut.isValidAndroidProject(buildFolder: buildDir)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - iOS Tests

    func test_isValidiOSProject_withXcodeProj_returnsTrue() throws {
        // Given: iOS project with .xcodeproj
        let projectDir = tempDirectory.appendingPathComponent("iOSProject")
        let buildDir = projectDir.appendingPathComponent(".build")
        let xcodeProjDir = projectDir.appendingPathComponent("App.xcodeproj")

        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: xcodeProjDir, withIntermediateDirectories: true)

        // When
        let result = sut.isValidiOSProject(buildFolder: buildDir)

        // Then
        XCTAssertTrue(result)
    }

    func test_isValidiOSProject_withXcodeWorkspace_returnsTrue() throws {
        // Given: iOS project with .xcworkspace
        let projectDir = tempDirectory.appendingPathComponent("iOSProject2")
        let buildDir = projectDir.appendingPathComponent(".build")
        let workspaceDir = projectDir.appendingPathComponent("App.xcworkspace")

        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: workspaceDir, withIntermediateDirectories: true)

        // When
        let result = sut.isValidiOSProject(buildFolder: buildDir)

        // Then
        XCTAssertTrue(result)
    }

    func test_isValidiOSProject_withoutXcodeFiles_returnsFalse() throws {
        // Given: .build folder without .xcodeproj or .xcworkspace
        let projectDir = tempDirectory.appendingPathComponent("NotAnIOSProject")
        let buildDir = projectDir.appendingPathComponent(".build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        // When
        let result = sut.isValidiOSProject(buildFolder: buildDir)

        // Then
        XCTAssertFalse(result)
    }

    func test_isValidiOSProject_withBuildFolder_returnsTrue() throws {
        // Given: iOS project with "build" folder (legacy/in-place build)
        let projectDir = tempDirectory.appendingPathComponent("iOSProject3")
        let buildDir = projectDir.appendingPathComponent("build")
        let xcodeProjDir = projectDir.appendingPathComponent("App.xcodeproj")

        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: xcodeProjDir, withIntermediateDirectories: true)

        // When
        let result = sut.isValidiOSProject(buildFolder: buildDir)

        // Then
        XCTAssertTrue(result, "iOS projects can have 'build' folders for legacy/in-place builds")
    }

    func test_isValidiOSProject_withDotBuildFolder_returnsTrue() throws {
        // Given: iOS project with ".build" folder (SPM dependencies)
        let projectDir = tempDirectory.appendingPathComponent("iOSProject4")
        let buildDir = projectDir.appendingPathComponent(".build")
        let xcodeProjDir = projectDir.appendingPathComponent("App.xcodeproj")

        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: xcodeProjDir, withIntermediateDirectories: true)

        // When
        let result = sut.isValidiOSProject(buildFolder: buildDir)

        // Then
        XCTAssertTrue(result, "iOS projects can have '.build' folders for SPM dependencies")
    }

    // MARK: - Swift Package Tests

    func test_isValidSwiftPackage_withPackageSwift_returnsTrue() throws {
        // Given: Swift package
        let packageDir = tempDirectory.appendingPathComponent("MyPackage")
        let buildDir = packageDir.appendingPathComponent(".build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let packageSwift = packageDir.appendingPathComponent("Package.swift")
        try "// Package.swift".write(to: packageSwift, atomically: true, encoding: .utf8)

        // When
        let result = sut.isValidSwiftPackage(buildFolder: buildDir)

        // Then
        XCTAssertTrue(result)
    }

    func test_isValidSwiftPackage_withoutPackageSwift_returnsFalse() throws {
        // Given: .build folder without Package.swift
        let packageDir = tempDirectory.appendingPathComponent("NotAPackage")
        let buildDir = packageDir.appendingPathComponent(".build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        // When
        let result = sut.isValidSwiftPackage(buildFolder: buildDir)

        // Then
        XCTAssertFalse(result)
    }

    func test_isValidSwiftPackage_withWrongFolderName_returnsFalse() throws {
        // Given: Folder not named ".build"
        let packageDir = tempDirectory.appendingPathComponent("MyPackage2")
        let buildDir = packageDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let packageSwift = packageDir.appendingPathComponent("Package.swift")
        try "// Package.swift".write(to: packageSwift, atomically: true, encoding: .utf8)

        // When
        let result = sut.isValidSwiftPackage(buildFolder: buildDir)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Detection Tests

    func test_detectProjectType_withAndroidProject_returnsAndroid() throws {
        // Given
        let projectDir = tempDirectory.appendingPathComponent("AndroidProject")
        let buildDir = projectDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        let buildGradle = projectDir.appendingPathComponent("build.gradle")
        try "".write(to: buildGradle, atomically: true, encoding: .utf8)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir)

        // Then
        XCTAssertEqual(result, .android)
    }

    func test_detectProjectType_withSwiftPackage_returnsSwiftPackage() throws {
        // Given
        let packageDir = tempDirectory.appendingPathComponent("MyPackage")
        let buildDir = packageDir.appendingPathComponent(".build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        let packageSwift = packageDir.appendingPathComponent("Package.swift")
        try "".write(to: packageSwift, atomically: true, encoding: .utf8)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir)

        // Then
        XCTAssertEqual(result, .swiftPackage)
    }

    func test_detectProjectType_withiOSProject_returnsiOS() throws {
        // Given
        let projectDir = tempDirectory.appendingPathComponent("iOSProject")
        let buildDir = projectDir.appendingPathComponent(".build")
        let xcodeProjDir = projectDir.appendingPathComponent("App.xcodeproj")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: xcodeProjDir, withIntermediateDirectories: true)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir)

        // Then
        XCTAssertEqual(result, .iOS)
    }

    func test_detectProjectType_withInvalidFolder_returnsNil() throws {
        // Given
        let buildDir = tempDirectory.appendingPathComponent("RandomFolder")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir)

        // Then
        XCTAssertNil(result)
    }
}
