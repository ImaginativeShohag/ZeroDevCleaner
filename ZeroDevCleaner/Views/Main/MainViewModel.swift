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
    // MARK: - Filter Types

    enum FilterType: String, CaseIterable, Sendable {
        case all = "All"
        case android = "Android"
        case iOS = "iOS"
        case swiftPackage = "Swift Package"

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .android: return "cube.fill"
            case .iOS: return "apple.logo"
            case .swiftPackage: return "shippingbox.fill"
            }
        }
    }

    // MARK: - State Properties

    /// Currently selected folder to scan
    var selectedFolder: URL?

    /// Results from the last scan
    var scanResults: [BuildFolder] = []

    /// Current filter type
    var currentFilter: FilterType = .all

    /// Filtered results based on current filter
    var filteredResults: [BuildFolder] {
        guard currentFilter != .all else { return scanResults }

        return scanResults.filter { folder in
            switch currentFilter {
            case .all:
                return true
            case .android:
                return folder.projectType == .android
            case .iOS:
                return folder.projectType == .iOS
            case .swiftPackage:
                return folder.projectType == .swiftPackage
            }
        }
    }

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

    /// Whether to show permission error alert (special handling)
    var showPermissionError: Bool = false

    // MARK: - Dependencies

    private let scanner: FileScannerProtocol
    private let deleter: FileDeleterProtocol
    let recentFoldersManager = RecentFoldersManager()

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

    /// Selects a folder at the given URL
    func selectFolder(at url: URL) {
        // Verify it's a directory
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            handleError(ZeroDevCleanerError.fileNotFound(url))
            return
        }

        selectedFolder = url
    }

    // MARK: - Scanning

    /// Starts scanning the selected folder
    func startScan() {
        guard let folder = selectedFolder else { return }

        // Check for Full Disk Access permission first
        if !PermissionManager.shared.hasFullDiskAccess() {
            currentError = .permissionDenied(folder)
            showPermissionError = true
            return
        }

        // Cancel any existing scan
        cancelScan()

        // Reset state
        scanResults = []
        scanProgress = 0.0
        currentScanPath = ""
        isScanning = true

        // Start scan task
        scanTask = Task {
            do {
                let results = try await scanner.scanDirectory(at: folder) { [weak self] path, count in
                    guard let self else { return }
                    Task { @MainActor in
                        self.currentScanPath = path
                        self.scanProgress = Double(count) / 100.0 // Approximate progress
                    }
                }

                // Update results on main actor
                self.scanResults = results
                self.isScanning = false

                // Add to recent folders on successful scan
                self.recentFoldersManager.addFolder(folder)
            } catch {
                self.handleError(error)
                self.isScanning = false
            }
        }
    }

    /// Cancels the current scan
    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
    }

    // MARK: - Selection Management

    /// Toggles selection for a specific folder
    func toggleSelection(for folder: BuildFolder) {
        if let index = scanResults.firstIndex(where: { $0.id == folder.id }) {
            scanResults[index].isSelected.toggle()
        }
    }

    /// Reveals the folder in Finder
    func showInFinder(folder: BuildFolder) {
        NSWorkspace.shared.selectFile(
            folder.path.path,
            inFileViewerRootedAtPath: folder.path.deletingLastPathComponent().path
        )
    }

    /// Selects all folders (in current filter view)
    func selectAll() {
        let filteredIds = Set(filteredResults.map(\.id))
        for index in scanResults.indices {
            if filteredIds.contains(scanResults[index].id) {
                scanResults[index].isSelected = true
            }
        }
    }

    /// Deselects all folders (in current filter view)
    func deselectAll() {
        let filteredIds = Set(filteredResults.map(\.id))
        for index in scanResults.indices {
            if filteredIds.contains(scanResults[index].id) {
                scanResults[index].isSelected = false
            }
        }
    }

    /// Returns currently selected folders
    var selectedFolders: [BuildFolder] {
        scanResults.filter(\.isSelected)
    }

    /// Total number of folders found
    var totalFoldersCount: Int {
        scanResults.count
    }

    /// Total size of all folders
    var totalSpaceSize: Int64 {
        scanResults.reduce(0) { $0 + $1.size }
    }

    /// Formatted total size
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSpaceSize, countStyle: .file)
    }

    /// Total size of selected folders
    var selectedSize: Int64 {
        selectedFolders.reduce(0) { $0 + $1.size }
    }

    /// Formatted selected size
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }

    // MARK: - Deletion

    /// Deletes selected folders
    func deleteSelectedFolders() {
        let foldersToDelete = selectedFolders
        guard !foldersToDelete.isEmpty else { return }

        isDeleting = true
        deletionProgress = 0.0

        Task {
            do {
                try await deleter.delete(folders: foldersToDelete) { [weak self] current, total in
                    guard let self else { return }
                    Task { @MainActor in
                        self.deletionProgress = Double(current) / Double(total)
                    }
                }

                // Remove deleted folders from results
                for folder in foldersToDelete {
                    if let index = self.scanResults.firstIndex(where: { $0.id == folder.id }) {
                        self.scanResults.remove(at: index)
                    }
                }

                self.isDeleting = false
            } catch {
                self.handleError(error)
                self.isDeleting = false
            }
        }
    }

    // MARK: - Error Handling

    /// Handles errors and shows them to user
    private func handleError(_ error: Error) {
        if let cleanerError = error as? ZeroDevCleanerError {
            currentError = cleanerError
        } else {
            currentError = .unknownError(error)
        }
        showError = true
    }

    /// Dismisses current error
    func dismissError() {
        showError = false
        showPermissionError = false
        currentError = nil
    }

    /// Opens System Settings to grant Full Disk Access
    func openSystemSettings() {
        PermissionManager.shared.requestFullDiskAccess()
        dismissError()
    }

    /// Reveals app location in Finder for Full Disk Access setup
    func revealAppInFinder() {
        PermissionManager.shared.revealAppInFinder()
    }
}
