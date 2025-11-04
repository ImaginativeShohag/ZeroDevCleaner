//
//  SettingsExporterTests.swift
//  ZeroDevCleanerTests
//
//  Created by Md. Mahmudul Hasan Shohag on 04/11/25.
//

import XCTest
@testable import ZeroDevCleaner

final class SettingsExporterTests: XCTestCase {
    var sut: SettingsExporter!
    var tempDirectory: URL!
    var testFileURL: URL!

    override func setUp() async throws {
        try await super.setUp()
        sut = SettingsExporter()

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

    // MARK: - Export Tests

    func test_exportSettings_withScanLocations_succeeds() async throws {
        // Given: Some scan locations
        let locations = [
            ScanLocation(name: "Projects", path: URL(fileURLWithPath: "/Users/test/Projects")),
            ScanLocation(name: "Documents", path: URL(fileURLWithPath: "/Users/test/Documents"))
        ]
        Preferences.scanLocations = locations

        let options = ExportOptions(includeScanLocations: true, includeCustomCaches: false)

        // When
        try await sut.exportSettings(to: testFileURL, options: options)

        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path), "Export file should exist")

        // Verify contents
        let data = try Data(contentsOf: testFileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export = try decoder.decode(SettingsExport.self, from: data)

        XCTAssertEqual(export.version, SettingsExport.currentVersion)
        XCTAssertEqual(export.scanLocations.count, 2)
        XCTAssertEqual(export.customCacheLocations.count, 0)
        XCTAssertEqual(export.scanLocations[0].name, "Projects")
    }

    func test_exportSettings_withCustomCaches_succeeds() async throws {
        // Given: Some custom caches
        let caches = [
            CustomCacheLocation(name: "Build Cache", path: URL(fileURLWithPath: "/tmp/cache")),
            CustomCacheLocation(name: "Logs", path: URL(fileURLWithPath: "/tmp/logs"), pattern: "*.log")
        ]
        Preferences.customCacheLocations = caches

        let options = ExportOptions(includeScanLocations: false, includeCustomCaches: true)

        // When
        try await sut.exportSettings(to: testFileURL, options: options)

        // Then
        let data = try Data(contentsOf: testFileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export = try decoder.decode(SettingsExport.self, from: data)

        XCTAssertEqual(export.scanLocations.count, 0)
        XCTAssertEqual(export.customCacheLocations.count, 2)
        XCTAssertEqual(export.customCacheLocations[0].name, "Build Cache")
        XCTAssertEqual(export.customCacheLocations[1].pattern, "*.log")
    }

    func test_exportSettings_withAllOptions_succeeds() async throws {
        // Given: Both scan locations and custom caches
        Preferences.scanLocations = [
            ScanLocation(name: "Projects", path: URL(fileURLWithPath: "/Users/test/Projects"))
        ]
        Preferences.customCacheLocations = [
            CustomCacheLocation(name: "Cache", path: URL(fileURLWithPath: "/tmp/cache"))
        ]

        let options = ExportOptions.all

        // When
        try await sut.exportSettings(to: testFileURL, options: options)

        // Then
        let data = try Data(contentsOf: testFileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export = try decoder.decode(SettingsExport.self, from: data)

        XCTAssertEqual(export.scanLocations.count, 1)
        XCTAssertEqual(export.customCacheLocations.count, 1)
    }

    func test_exportSettings_withNoOptions_throwsError() async {
        // Given: Options with nothing selected
        let options = ExportOptions(includeScanLocations: false, includeCustomCaches: false)

        // When/Then
        do {
            try await sut.exportSettings(to: testFileURL, options: options)
            XCTFail("Should throw error when no options selected")
        } catch let error as ZeroDevCleanerError {
            if case .noSettingsToExport = error {
                // Success
            } else {
                XCTFail("Should throw noSettingsToExport error")
            }
        } catch {
            XCTFail("Should throw ZeroDevCleanerError")
        }
    }

    func test_exportSettings_withEmptySettings_throwsError() async {
        // Given: No settings configured
        Preferences.scanLocations = nil
        Preferences.customCacheLocations = nil

        let options = ExportOptions.all

        // When/Then
        do {
            try await sut.exportSettings(to: testFileURL, options: options)
            XCTFail("Should throw error when no settings exist")
        } catch let error as ZeroDevCleanerError {
            if case .noSettingsToExport = error {
                // Success
            } else {
                XCTFail("Should throw noSettingsToExport error")
            }
        } catch {
            XCTFail("Should throw ZeroDevCleanerError")
        }
    }

    func test_exportSettings_createsValidJSON() async throws {
        // Given
        Preferences.scanLocations = [
            ScanLocation(name: "Test", path: URL(fileURLWithPath: "/test"))
        ]
        let options = ExportOptions(includeScanLocations: true, includeCustomCaches: false)

        // When
        try await sut.exportSettings(to: testFileURL, options: options)

        // Then: Verify it's valid, pretty-printed JSON
        let data = try Data(contentsOf: testFileURL)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("\"version\""))
        XCTAssertTrue(jsonString.contains("\"exportDate\""))
        XCTAssertTrue(jsonString.contains("\"scanLocations\""))
        XCTAssertTrue(jsonString.contains("\n"), "Should be pretty printed")
    }

    // MARK: - Preview Tests

    func test_previewExport_returnsCorrectCount() {
        // Given
        Preferences.scanLocations = [
            ScanLocation(name: "Projects", path: URL(fileURLWithPath: "/Users/test/Projects"))
        ]
        Preferences.customCacheLocations = [
            CustomCacheLocation(name: "Cache", path: URL(fileURLWithPath: "/tmp/cache"))
        ]

        let options = ExportOptions.all

        // When
        let preview = sut.previewExport(options: options)

        // Then
        XCTAssertNotNil(preview)
        XCTAssertEqual(preview?.totalItems, 2)
        XCTAssertEqual(preview?.scanLocations.count, 1)
        XCTAssertEqual(preview?.customCacheLocations.count, 1)
    }

    func test_previewExport_withEmptySettings_returnsNil() {
        // Given: No settings
        Preferences.scanLocations = nil
        Preferences.customCacheLocations = nil

        let options = ExportOptions.all

        // When
        let preview = sut.previewExport(options: options)

        // Then
        XCTAssertNil(preview)
    }
}
