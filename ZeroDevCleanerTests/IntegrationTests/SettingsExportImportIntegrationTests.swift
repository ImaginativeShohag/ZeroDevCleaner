//
//  SettingsExportImportIntegrationTests.swift
//  ZeroDevCleanerTests
//
//  Created by Md. Mahmudul Hasan Shohag on 04/11/25.
//

import XCTest
@testable import ZeroDevCleaner

/// Integration tests for complete export/import workflow
@MainActor
final class SettingsExportImportIntegrationTests: XCTestCase {
    var exporter: SettingsExporter!
    var importer: SettingsImporter!
    var tempDirectory: URL!
    var testFileURL: URL!

    override func setUp() async throws {
        try await super.setUp()
        exporter = SettingsExporter()
        importer = SettingsImporter()

        // Create temp directory
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        testFileURL = tempDirectory.appendingPathComponent("integration-test.zdcsettings")

        // Clear preferences
        Preferences.reset()
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        exporter = nil
        importer = nil
        Preferences.reset()
        try await super.tearDown()
    }

    // MARK: - Complete Workflow Tests

    func test_completeWorkflow_exportAndImport_succeeds() async throws {
        // Given: Initial settings
        let originalScanLocations = [
            ScanLocation(name: "Projects", path: URL(fileURLWithPath: "/Users/test/Projects"), isEnabled: true),
            ScanLocation(name: "Documents", path: URL(fileURLWithPath: "/Users/test/Documents"), isEnabled: false)
        ]
        let originalCustomCaches = [
            CustomCacheLocation(
                name: "Build Cache",
                path: URL(fileURLWithPath: "/tmp/cache"),
                pattern: "*.cache",
                isEnabled: true,
                colorHex: "FF0000"
            )
        ]

        Preferences.scanLocations = originalScanLocations
        Preferences.customCacheLocations = originalCustomCaches

        // When: Export settings
        let exportOptions = ExportOptions.all
        try await exporter.exportSettings(to: testFileURL, options: exportOptions)

        // And: Clear current settings (simulate fresh install)
        Preferences.reset()
        XCTAssertNil(Preferences.scanLocations)
        XCTAssertNil(Preferences.customCacheLocations)

        // And: Import settings in replace mode
        let loadedExport = try await importer.loadSettings(from: testFileURL)
        await importer.applySettings(loadedExport, mode: .replace)

        // Then: Settings should be restored
        XCTAssertNotNil(Preferences.scanLocations)
        XCTAssertNotNil(Preferences.customCacheLocations)

        XCTAssertEqual(Preferences.scanLocations?.count, 2)
        XCTAssertEqual(Preferences.customCacheLocations?.count, 1)

        // Verify scan location details
        let restoredScanLocation = Preferences.scanLocations?.first(where: { $0.name == "Projects" })
        XCTAssertNotNil(restoredScanLocation)
        XCTAssertEqual(restoredScanLocation?.path.path, "/Users/test/Projects")
        XCTAssertEqual(restoredScanLocation?.isEnabled, true)

        // Verify custom cache details
        let restoredCache = Preferences.customCacheLocations?.first
        XCTAssertNotNil(restoredCache)
        XCTAssertEqual(restoredCache?.name, "Build Cache")
        XCTAssertEqual(restoredCache?.pattern, "*.cache")
        XCTAssertEqual(restoredCache?.colorHex, "FF0000")
        XCTAssertEqual(restoredCache?.isEnabled, true)
    }

    func test_exportPartialSettings_thenImportMerge() async throws {
        // Given: Initial scan locations only
        Preferences.scanLocations = [
            ScanLocation(name: "Existing", path: URL(fileURLWithPath: "/existing"))
        ]

        // When: Export only custom caches (which don't exist yet)
        // But first add a custom cache
        Preferences.customCacheLocations = [
            CustomCacheLocation(name: "Export Cache", path: URL(fileURLWithPath: "/export"))
        ]

        let exportOptions = ExportOptions(includeScanLocations: false, includeCustomCaches: true)
        try await exporter.exportSettings(to: testFileURL, options: exportOptions)

        // And: Add more scan locations before import
        Preferences.scanLocations?.append(
            ScanLocation(name: "Before Import", path: URL(fileURLWithPath: "/before"))
        )

        // And: Clear custom caches
        Preferences.customCacheLocations = nil

        // And: Import in merge mode
        let loadedExport = try await importer.loadSettings(from: testFileURL)
        await importer.applySettings(loadedExport, mode: .merge)

        // Then: Should have scan locations from before + custom caches from import
        XCTAssertEqual(Preferences.scanLocations?.count, 2)
        XCTAssertEqual(Preferences.customCacheLocations?.count, 1)
        XCTAssertEqual(Preferences.customCacheLocations?[0].name, "Export Cache")
    }

    func test_exportFromOneDevice_importToAnother_mergeDifferentSettings() async throws {
        // Simulate Device A settings
        let deviceAScanLocations = [
            ScanLocation(name: "Mac Projects", path: URL(fileURLWithPath: "/Users/mac/Projects"))
        ]
        let deviceACustomCaches = [
            CustomCacheLocation(name: "Mac Cache", path: URL(fileURLWithPath: "/Users/mac/cache"))
        ]

        Preferences.scanLocations = deviceAScanLocations
        Preferences.customCacheLocations = deviceACustomCaches

        // Export from Device A
        try await exporter.exportSettings(to: testFileURL, options: .all)

        // Simulate Device B with different settings
        let deviceBScanLocations = [
            ScanLocation(name: "iMac Projects", path: URL(fileURLWithPath: "/Users/imac/Projects"))
        ]
        let deviceBCustomCaches = [
            CustomCacheLocation(name: "iMac Cache", path: URL(fileURLWithPath: "/Users/imac/cache"))
        ]

        Preferences.scanLocations = deviceBScanLocations
        Preferences.customCacheLocations = deviceBCustomCaches

        // Import from Device A to Device B in merge mode
        let loadedExport = try await importer.loadSettings(from: testFileURL)
        await importer.applySettings(loadedExport, mode: .merge)

        // Then: Should have settings from both devices
        XCTAssertEqual(Preferences.scanLocations?.count, 2)
        XCTAssertEqual(Preferences.customCacheLocations?.count, 2)

        XCTAssertTrue(Preferences.scanLocations?.contains(where: { $0.name == "Mac Projects" }) == true)
        XCTAssertTrue(Preferences.scanLocations?.contains(where: { $0.name == "iMac Projects" }) == true)
        XCTAssertTrue(Preferences.customCacheLocations?.contains(where: { $0.name == "Mac Cache" }) == true)
        XCTAssertTrue(Preferences.customCacheLocations?.contains(where: { $0.name == "iMac Cache" }) == true)
    }

    func test_replaceMode_completelyClearsAndRestores() async throws {
        // Given: Original settings
        Preferences.scanLocations = [
            ScanLocation(name: "Original", path: URL(fileURLWithPath: "/original"))
        ]
        Preferences.customCacheLocations = [
            CustomCacheLocation(name: "Original Cache", path: URL(fileURLWithPath: "/original/cache"))
        ]

        // Export
        try await exporter.exportSettings(to: testFileURL, options: .all)

        // Add more settings (simulating usage over time)
        Preferences.scanLocations?.append(
            ScanLocation(name: "Extra", path: URL(fileURLWithPath: "/extra"))
        )
        Preferences.customCacheLocations?.append(
            CustomCacheLocation(name: "Extra Cache", path: URL(fileURLWithPath: "/extra/cache"))
        )

        XCTAssertEqual(Preferences.scanLocations?.count, 2)
        XCTAssertEqual(Preferences.customCacheLocations?.count, 2)

        // Import in replace mode
        let loadedExport = try await importer.loadSettings(from: testFileURL)
        await importer.applySettings(loadedExport, mode: .replace)

        // Then: Should only have original settings
        XCTAssertEqual(Preferences.scanLocations?.count, 1)
        XCTAssertEqual(Preferences.customCacheLocations?.count, 1)
        XCTAssertEqual(Preferences.scanLocations?[0].name, "Original")
        XCTAssertEqual(Preferences.customCacheLocations?[0].name, "Original Cache")
    }

    func test_multipleExportImportCycles_maintainsDataIntegrity() async throws {
        // Given: Initial settings
        var scanLocations = [
            ScanLocation(name: "Test", path: URL(fileURLWithPath: "/test"))
        ]

        Preferences.scanLocations = scanLocations

        // Perform multiple export/import cycles
        for i in 1...5 {
            let cycleFileURL = tempDirectory.appendingPathComponent("cycle-\(i).zdcsettings")

            // Export
            try await exporter.exportSettings(to: cycleFileURL, options: .all)

            // Import
            let loadedExport = try await importer.loadSettings(from: cycleFileURL)
            await importer.applySettings(loadedExport, mode: .replace)

            // Verify data integrity
            XCTAssertEqual(Preferences.scanLocations?.count, 1)
            XCTAssertEqual(Preferences.scanLocations?[0].name, "Test")
            XCTAssertEqual(Preferences.scanLocations?[0].path.path, "/test")
        }
    }

    func test_largeDataset_exportImport_succeeds() async throws {
        // Given: Large number of settings
        var scanLocations: [ScanLocation] = []
        var customCaches: [CustomCacheLocation] = []

        for i in 0..<100 {
            scanLocations.append(
                ScanLocation(name: "Location \(i)", path: URL(fileURLWithPath: "/location/\(i)"))
            )
        }

        for i in 0..<50 {
            customCaches.append(
                CustomCacheLocation(name: "Cache \(i)", path: URL(fileURLWithPath: "/cache/\(i)"))
            )
        }

        Preferences.scanLocations = scanLocations
        Preferences.customCacheLocations = customCaches

        // When: Export and import
        try await exporter.exportSettings(to: testFileURL, options: .all)
        Preferences.reset()

        let loadedExport = try await importer.loadSettings(from: testFileURL)
        await importer.applySettings(loadedExport, mode: .replace)

        // Then: All data should be preserved
        XCTAssertEqual(Preferences.scanLocations?.count, 100)
        XCTAssertEqual(Preferences.customCacheLocations?.count, 50)
    }
}
