//
//  SettingsImporterTests.swift
//  ZeroDevCleanerTests
//
//  Created by Md. Mahmudul Hasan Shohag on 04/11/25.
//

import XCTest
@testable import ZeroDevCleaner

final class SettingsImporterTests: XCTestCase {
    var sut: SettingsImporter!
    var tempDirectory: URL!
    var testFileURL: URL!

    override func setUp() async throws {
        try await super.setUp()
        sut = SettingsImporter()

        // Create temp directory for test files
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        testFileURL = tempDirectory.appendingPathComponent("test-settings.zdcsettings")

        // Clear preferences before each test
        Preferences.scanLocations = nil
        Preferences.customCacheLocations = nil
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        sut = nil
        Preferences.reset()
        try await super.tearDown()
    }

    // MARK: - Load Tests

    func test_loadSettings_withValidFile_succeeds() async throws {
        // Given: A valid export file
        let export = SettingsExport(
            scanLocations: [
                ScanLocation(name: "Projects", path: URL(fileURLWithPath: "/Users/test/Projects"))
            ],
            customCacheLocations: [
                CustomCacheLocation(name: "Cache", path: URL(fileURLWithPath: "/tmp/cache"))
            ]
        )

        try createTestFile(export)

        // When
        let loaded = try await sut.loadSettings(from: testFileURL)

        // Then
        XCTAssertEqual(loaded.version, SettingsExport.currentVersion)
        XCTAssertEqual(loaded.scanLocations.count, 1)
        XCTAssertEqual(loaded.customCacheLocations.count, 1)
        XCTAssertEqual(loaded.scanLocations[0].name, "Projects")
    }

    func test_loadSettings_withInvalidJSON_throwsError() async {
        // Given: Invalid JSON file
        let invalidJSON = "{ invalid json }"
        try! invalidJSON.write(to: testFileURL, atomically: true, encoding: .utf8)

        // When/Then
        do {
            _ = try await sut.loadSettings(from: testFileURL)
            XCTFail("Should throw error for invalid JSON")
        } catch let error as ZeroDevCleanerError {
            if case .importFailed = error {
                // Success
            } else {
                XCTFail("Should throw importFailed error")
            }
        } catch {
            XCTFail("Should throw ZeroDevCleanerError")
        }
    }

    func test_loadSettings_withUnsupportedVersion_throwsError() async {
        // Given: File with unsupported version
        let futureExport = """
        {
            "version": "99.0",
            "exportDate": "\(ISO8601DateFormatter().string(from: Date()))",
            "scanLocations": [],
            "customCacheLocations": []
        }
        """
        try! futureExport.write(to: testFileURL, atomically: true, encoding: .utf8)

        // When/Then
        do {
            _ = try await sut.loadSettings(from: testFileURL)
            XCTFail("Should throw error for unsupported version")
        } catch let error as ZeroDevCleanerError {
            if case .unsupportedVersion(let version) = error {
                XCTAssertEqual(version, "99.0")
            } else {
                XCTFail("Should throw unsupportedVersion error")
            }
        } catch {
            XCTFail("Should throw ZeroDevCleanerError")
        }
    }

    func test_loadSettings_withNonExistentFile_throwsError() async {
        // Given: Non-existent file
        let nonExistentURL = tempDirectory.appendingPathComponent("does-not-exist.zdcsettings")

        // When/Then
        do {
            _ = try await sut.loadSettings(from: nonExistentURL)
            XCTFail("Should throw error for non-existent file")
        } catch let error as ZeroDevCleanerError {
            if case .importFailed = error {
                // Success
            } else {
                XCTFail("Should throw importFailed error")
            }
        } catch {
            XCTFail("Should throw ZeroDevCleanerError")
        }
    }

    // MARK: - Merge Mode Tests

    func test_applySettings_mergeMode_addsToExisting() async {
        // Given: Existing settings
        Preferences.scanLocations = [
            ScanLocation(name: "Existing", path: URL(fileURLWithPath: "/existing"))
        ]

        // And: Import with new location
        let export = SettingsExport(
            scanLocations: [
                ScanLocation(name: "New", path: URL(fileURLWithPath: "/new"))
            ],
            customCacheLocations: []
        )

        // When
        await sut.applySettings(export, mode: .merge)

        // Then
        XCTAssertEqual(Preferences.scanLocations?.count, 2)
        XCTAssertTrue(Preferences.scanLocations?.contains(where: { $0.name == "Existing" }) == true)
        XCTAssertTrue(Preferences.scanLocations?.contains(where: { $0.name == "New" }) == true)
    }

    func test_applySettings_mergeMode_avoidsPathDuplicates() async {
        // Given: Existing location
        let existingPath = URL(fileURLWithPath: "/Users/test/Projects")
        Preferences.scanLocations = [
            ScanLocation(name: "Projects", path: existingPath)
        ]

        // And: Import with same path but different name
        let export = SettingsExport(
            scanLocations: [
                ScanLocation(name: "My Projects", path: existingPath)
            ],
            customCacheLocations: []
        )

        // When
        await sut.applySettings(export, mode: .merge)

        // Then: Should not duplicate
        XCTAssertEqual(Preferences.scanLocations?.count, 1)
        XCTAssertEqual(Preferences.scanLocations?[0].name, "Projects")
    }

    func test_applySettings_mergeMode_customCaches() async {
        // Given: Existing custom cache
        Preferences.customCacheLocations = [
            CustomCacheLocation(name: "Old Cache", path: URL(fileURLWithPath: "/old"))
        ]

        // And: Import with new cache
        let export = SettingsExport(
            scanLocations: [],
            customCacheLocations: [
                CustomCacheLocation(name: "New Cache", path: URL(fileURLWithPath: "/new"))
            ]
        )

        // When
        await sut.applySettings(export, mode: .merge)

        // Then
        XCTAssertEqual(Preferences.customCacheLocations?.count, 2)
        XCTAssertTrue(Preferences.customCacheLocations?.contains(where: { $0.name == "Old Cache" }) == true)
        XCTAssertTrue(Preferences.customCacheLocations?.contains(where: { $0.name == "New Cache" }) == true)
    }

    // MARK: - Replace Mode Tests

    func test_applySettings_replaceMode_replacesExisting() async {
        // Given: Existing settings
        Preferences.scanLocations = [
            ScanLocation(name: "Old1", path: URL(fileURLWithPath: "/old1")),
            ScanLocation(name: "Old2", path: URL(fileURLWithPath: "/old2"))
        ]

        // And: Import with new locations
        let export = SettingsExport(
            scanLocations: [
                ScanLocation(name: "New", path: URL(fileURLWithPath: "/new"))
            ],
            customCacheLocations: []
        )

        // When
        await sut.applySettings(export, mode: .replace)

        // Then: Old locations replaced
        XCTAssertEqual(Preferences.scanLocations?.count, 1)
        XCTAssertEqual(Preferences.scanLocations?[0].name, "New")
    }

    func test_applySettings_replaceMode_withEmptyImport_clearsSettings() async {
        // Given: Existing settings
        Preferences.scanLocations = [
            ScanLocation(name: "Existing", path: URL(fileURLWithPath: "/existing"))
        ]
        Preferences.customCacheLocations = [
            CustomCacheLocation(name: "Cache", path: URL(fileURLWithPath: "/cache"))
        ]

        // And: Empty import
        let export = SettingsExport(scanLocations: [], customCacheLocations: [])

        // When
        await sut.applySettings(export, mode: .replace)

        // Then: Settings cleared
        XCTAssertNil(Preferences.scanLocations)
        XCTAssertNil(Preferences.customCacheLocations)
    }

    func test_applySettings_replaceMode_customCaches() async {
        // Given: Existing custom caches
        Preferences.customCacheLocations = [
            CustomCacheLocation(name: "Old1", path: URL(fileURLWithPath: "/old1")),
            CustomCacheLocation(name: "Old2", path: URL(fileURLWithPath: "/old2"))
        ]

        // And: Import with new cache
        let export = SettingsExport(
            scanLocations: [],
            customCacheLocations: [
                CustomCacheLocation(name: "New", path: URL(fileURLWithPath: "/new"))
            ]
        )

        // When
        await sut.applySettings(export, mode: .replace)

        // Then: Old caches replaced
        XCTAssertEqual(Preferences.customCacheLocations?.count, 1)
        XCTAssertEqual(Preferences.customCacheLocations?[0].name, "New")
    }

    // MARK: - Helper Methods

    private func createTestFile(_ export: SettingsExport) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(export)
        try data.write(to: testFileURL)
    }
}
