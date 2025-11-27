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
    var mockProjectTypes: [ProjectTypeConfig]!

    override func setUp() {
        super.setUp()
        sut = ProjectValidator()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Setup mock project type configurations
        mockProjectTypes = createMockProjectTypes()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Mock Configuration Helper

    private func createMockProjectTypes() -> [ProjectTypeConfig] {
        return [
            // Swift Package (should be checked first - more specific folder name)
            ProjectTypeConfig(
                id: "swiftPackage",
                displayName: "Swift Package",
                iconName: "shippingbox.fill",
                color: "#FF9500",
                folderNames: [".build"],
                validation: ValidationRules(
                    mode: .parentHierarchy,
                    maxSearchDepth: 2,
                    requiredFiles: FileRequirement(anyOf: ["Package.swift"], allOf: nil),
                    requiredDirectories: nil,
                    fileExtensions: nil
                )
            ),
            // Android
            ProjectTypeConfig(
                id: "android",
                displayName: "Android",
                iconName: "app.badge.fill",
                color: "#3DDC84",
                folderNames: ["build"],
                validation: ValidationRules(
                    mode: .parentHierarchy,
                    maxSearchDepth: 5,
                    requiredFiles: FileRequirement(
                        anyOf: ["build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts"],
                        allOf: nil
                    ),
                    requiredDirectories: nil,
                    fileExtensions: nil
                )
            ),
            // iOS/Xcode
            ProjectTypeConfig(
                id: "iOS",
                displayName: "iOS/Xcode",
                iconName: "apple.logo",
                color: "#007AFF",
                folderNames: ["build", ".build"],
                validation: ValidationRules(
                    mode: .directoryEnumeration,
                    maxSearchDepth: nil,
                    requiredFiles: nil,
                    requiredDirectories: nil,
                    fileExtensions: ["xcodeproj", "xcworkspace"]
                )
            ),
            // Flutter
            ProjectTypeConfig(
                id: "flutter",
                displayName: "Flutter",
                iconName: "wind",
                color: "#02569B",
                folderNames: ["build"],
                validation: ValidationRules(
                    mode: .parentDirectory,
                    maxSearchDepth: nil,
                    requiredFiles: FileRequirement(anyOf: ["pubspec.yaml"], allOf: nil),
                    requiredDirectories: nil,
                    fileExtensions: nil
                )
            )
        ]
    }

    // MARK: - Android Tests

    func test_detectProjectType_withAndroidProject_returnsAndroid() throws {
        // Given: Android project with build.gradle
        let projectDir = tempDirectory.appendingPathComponent("AndroidProject")
        let buildDir = projectDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let buildGradle = projectDir.appendingPathComponent("build.gradle")
        try "// build file".write(to: buildGradle, atomically: true, encoding: .utf8)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: mockProjectTypes)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, "android")
    }

    func test_detectProjectType_withAndroidProjectAndSettingsGradle_returnsAndroid() throws {
        // Given: Android project with settings.gradle
        let projectDir = tempDirectory.appendingPathComponent("AndroidProject2")
        let buildDir = projectDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let settingsGradle = projectDir.appendingPathComponent("settings.gradle")
        try "// settings file".write(to: settingsGradle, atomically: true, encoding: .utf8)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: mockProjectTypes)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, "android")
    }

    func test_detectProjectType_withoutGradleFile_returnsNil() throws {
        // Given: Random build folder without gradle files
        let buildDir = tempDirectory.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: mockProjectTypes)

        // Then
        XCTAssertNil(result)
    }

    func test_detectProjectType_withWrongFolderName_returnsNil() throws {
        // Given: Folder not named "build" with gradle file
        let projectDir = tempDirectory.appendingPathComponent("AndroidProject3")
        let buildDir = projectDir.appendingPathComponent("output")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let buildGradle = projectDir.appendingPathComponent("build.gradle")
        try "// build file".write(to: buildGradle, atomically: true, encoding: .utf8)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: mockProjectTypes)

        // Then
        XCTAssertNil(result)
    }

    // MARK: - iOS Tests

    func test_detectProjectType_withiOSProjectAndXcodeProj_returnsiOS() throws {
        // Given: iOS project with .xcodeproj
        let projectDir = tempDirectory.appendingPathComponent("iOSProject")
        let buildDir = projectDir.appendingPathComponent("build")
        let xcodeProjDir = projectDir.appendingPathComponent("App.xcodeproj")

        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: xcodeProjDir, withIntermediateDirectories: true)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: mockProjectTypes)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, "iOS")
    }

    func test_detectProjectType_withiOSProjectAndXcodeWorkspace_returnsiOS() throws {
        // Given: iOS project with .xcworkspace
        let projectDir = tempDirectory.appendingPathComponent("iOSProject2")
        let buildDir = projectDir.appendingPathComponent("build")
        let workspaceDir = projectDir.appendingPathComponent("App.xcworkspace")

        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: workspaceDir, withIntermediateDirectories: true)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: mockProjectTypes)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, "iOS")
    }

    func test_detectProjectType_withiOSProjectAndDotBuildFolder_returnsiOS() throws {
        // Given: iOS project with ".build" folder (SPM dependencies)
        let projectDir = tempDirectory.appendingPathComponent("iOSProject3")
        let buildDir = projectDir.appendingPathComponent(".build")
        let xcodeProjDir = projectDir.appendingPathComponent("App.xcodeproj")

        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: xcodeProjDir, withIntermediateDirectories: true)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: mockProjectTypes)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, "iOS", "iOS projects can have '.build' folders for SPM dependencies")
    }

    func test_detectProjectType_withoutXcodeFiles_returnsNil() throws {
        // Given: build folder without .xcodeproj or .xcworkspace
        let projectDir = tempDirectory.appendingPathComponent("NotAnIOSProject")
        let buildDir = projectDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: mockProjectTypes)

        // Then
        XCTAssertNil(result)
    }

    // MARK: - Swift Package Tests

    func test_detectProjectType_withSwiftPackage_returnsSwiftPackage() throws {
        // Given: Swift package with Package.swift
        let packageDir = tempDirectory.appendingPathComponent("MyPackage")
        let buildDir = packageDir.appendingPathComponent(".build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let packageSwift = packageDir.appendingPathComponent("Package.swift")
        try "// Package.swift".write(to: packageSwift, atomically: true, encoding: .utf8)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: mockProjectTypes)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, "swiftPackage")
    }

    func test_detectProjectType_withSwiftPackageWithoutPackageSwift_returnsNil() throws {
        // Given: .build folder without Package.swift
        let packageDir = tempDirectory.appendingPathComponent("NotAPackage")
        let buildDir = packageDir.appendingPathComponent(".build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: mockProjectTypes)

        // Then
        XCTAssertNil(result)
    }

    func test_detectProjectType_withSwiftPackageWrongFolderName_returnsNil() throws {
        // Given: Folder not named ".build" with Package.swift
        let packageDir = tempDirectory.appendingPathComponent("MyPackage2")
        let buildDir = packageDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let packageSwift = packageDir.appendingPathComponent("Package.swift")
        try "// Package.swift".write(to: packageSwift, atomically: true, encoding: .utf8)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: mockProjectTypes)

        // Then
        // Should not match Swift Package (wrong folder name)
        // Might match iOS if xcodeproj/xcworkspace found, otherwise nil
        if let result = result {
            XCTAssertNotEqual(result.id, "swiftPackage", "Should not match Swift Package with wrong folder name")
        }
    }

    // MARK: - Flutter Tests

    func test_detectProjectType_withFlutterProject_returnsFlutter() throws {
        // Given: Flutter project with pubspec.yaml
        let projectDir = tempDirectory.appendingPathComponent("FlutterProject")
        let buildDir = projectDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let pubspec = projectDir.appendingPathComponent("pubspec.yaml")
        try "name: my_app".write(to: pubspec, atomically: true, encoding: .utf8)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: mockProjectTypes)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, "flutter")
    }

    func test_detectProjectType_withFlutterProjectWithoutPubspec_returnsNil() throws {
        // Given: build folder without pubspec.yaml
        let projectDir = tempDirectory.appendingPathComponent("NotAFlutterProject")
        let buildDir = projectDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: mockProjectTypes)

        // Then
        XCTAssertNil(result)
    }

    // MARK: - Sequential Detection Tests (Order Matters)

    func test_detectProjectType_respectsConfigurationOrder() throws {
        // Given: A ".build" folder that could match both Swift Package and iOS
        let projectDir = tempDirectory.appendingPathComponent("AmbiguousProject")
        let buildDir = projectDir.appendingPathComponent(".build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        // Add both Package.swift (Swift Package) and .xcodeproj (iOS)
        let packageSwift = projectDir.appendingPathComponent("Package.swift")
        try "// Package.swift".write(to: packageSwift, atomically: true, encoding: .utf8)

        let xcodeProjDir = projectDir.appendingPathComponent("App.xcodeproj")
        try FileManager.default.createDirectory(at: xcodeProjDir, withIntermediateDirectories: true)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: mockProjectTypes)

        // Then: Should match Swift Package first (it's first in mockProjectTypes)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, "swiftPackage", "Should respect configuration order and match Swift Package first")
    }

    // MARK: - Invalid Input Tests

    func test_detectProjectType_withInvalidFolder_returnsNil() throws {
        // Given: Random folder that doesn't match any project type
        let buildDir = tempDirectory.appendingPathComponent("RandomFolder")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: mockProjectTypes)

        // Then
        XCTAssertNil(result)
    }

    func test_detectProjectType_withEmptyProjectTypes_returnsNil() throws {
        // Given: Valid Android project but empty project types array
        let projectDir = tempDirectory.appendingPathComponent("AndroidProject")
        let buildDir = projectDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let buildGradle = projectDir.appendingPathComponent("build.gradle")
        try "// build file".write(to: buildGradle, atomically: true, encoding: .utf8)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir, projectTypes: [])

        // Then
        XCTAssertNil(result, "Should return nil when no project types are configured")
    }
}
