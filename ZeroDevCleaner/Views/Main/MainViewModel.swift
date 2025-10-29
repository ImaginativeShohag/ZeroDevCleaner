//
//  MainViewModel.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class MainViewModel {
    // MARK: - State Properties

    /// Currently selected folder to scan
    var selectedFolder: URL?

    /// Results from the last scan
    var scanResults: [BuildFolder] = []

    /// Whether a scan is currently in progress
    var isScanning: Bool = false

    /// Current scan progress (0.0 to 1.0)
    var scanProgress: Double = 0.0

    /// Current path being scanned
    var currentScanPath: String = ""

    /// Whether deletion is in progress
    var isDeleting: Bool = false

    /// Current deletion progress (0.0 to 1.0)
    var deletionProgress: Double = 0.0

    /// Current error to display
    var currentError: ZeroDevCleanerError?

    /// Whether to show error alert
    var showError: Bool = false

    // MARK: - Dependencies

    private let scanner: FileScannerProtocol
    private let deleter: FileDeleterProtocol

    // MARK: - Private Properties

    private var scanTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        scanner: FileScannerProtocol,
        deleter: FileDeleterProtocol
    ) {
        self.scanner = scanner
        self.deleter = deleter
    }

    /// Convenience initializer with default dependencies
    convenience init() {
        let validator = ProjectValidator()
        let sizeCalculator = FileSizeCalculator()
        let scanner = FileScanner(
            validator: validator,
            sizeCalculator: sizeCalculator
        )
        let deleter = FileDeleter()

        self.init(scanner: scanner, deleter: deleter)
    }

    // MARK: - Folder Selection

    /// Opens folder selection dialog
    func selectFolder() {
        let panel = NSOpenPanel()
        panel.title = "Select Folder to Scan"
        panel.message = "Choose a directory to scan for build folders"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            selectedFolder = panel.url
        }
    }
}
