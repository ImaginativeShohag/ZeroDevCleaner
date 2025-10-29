//
//  MainViewModel.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI
import Observation
import OSLog

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

    enum SortColumn: String, CaseIterable {
        case projectName = "Project"
        case type = "Type"
        case size = "Size"
        case lastModified = "Last Modified"
    }

    enum SortOrder {
        case ascending
        case descending

        mutating func toggle() {
            self = self == .ascending ? .descending : .ascending
        }
    }

    // MARK: - State Properties

    /// Currently selected folder to scan
    var selectedFolder: URL?

    /// Results from the last scan
    var scanResults: [BuildFolder] = []

    /// Current filter type
    var currentFilter: FilterType = .all

    /// Current sort column
    var sortColumn: SortColumn = .size

    /// Current sort order
    var sortOrder: SortOrder = .descending

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

    /// Sorted and filtered results
    var sortedAndFilteredResults: [BuildFolder] {
        let filtered = filteredResults

        return filtered.sorted { lhs, rhs in
            let result: Bool
            switch sortColumn {
            case .projectName:
                result = lhs.projectName.localizedStandardCompare(rhs.projectName) == .orderedAscending
            case .type:
                result = lhs.projectType.rawValue < rhs.projectType.rawValue
            case .size:
                result = lhs.size < rhs.size
            case .lastModified:
                result = lhs.lastModified < rhs.lastModified
            }
            return sortOrder == .ascending ? result : !result
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

    /// Whether to show deletion confirmation dialog
    var showDeletionConfirmation: Bool = false

    /// Whether to show deletion progress dialog
    var showDeletionProgress: Bool = false

    /// Current item being deleted
    var currentDeletionItem: String = ""

    /// Number of items deleted so far
    var deletedItemCount: Int = 0

    /// Total size of items deleted so far
    var deletedSize: Int64 = 0

    // MARK: - Static Locations

    /// Static locations (DerivedData, caches, etc.)
    var staticLocations: [StaticLocation] = []

    /// Whether to include static locations in results
    var includeStaticLocations: Bool = true

    /// Whether static location scan is in progress
    var isScanningStatic: Bool = false

    // MARK: - Dependencies

    private let scanner: FileScannerProtocol
    private let deleter: FileDeleterProtocol
    private let staticScanner: StaticLocationScannerProtocol
    let recentFoldersManager = RecentFoldersManager()

    // MARK: - Private Properties

    private var scanTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        scanner: FileScannerProtocol,
        deleter: FileDeleterProtocol,
        staticScanner: StaticLocationScannerProtocol
    ) {
        self.scanner = scanner
        self.deleter = deleter
        self.staticScanner = staticScanner
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
        let staticScanner = StaticLocationScanner()

        self.init(scanner: scanner, deleter: deleter, staticScanner: staticScanner)
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

        // Check if it's a network drive
        do {
            let values = try url.resourceValues(forKeys: [.volumeIsLocalKey])
            if let isLocal = values.volumeIsLocal, !isLocal {
                handleError(ZeroDevCleanerError.networkDriveNotSupported(url))
                return
            }
        } catch {
            // If we can't determine, allow the selection
        }

        selectedFolder = url
    }

    // MARK: - Scanning

    /// Starts scanning the selected folder
    func startScan() {
        guard let folder = selectedFolder else { return }

        // Prevent concurrent scans
        guard !isScanning else {
            Logger.scanning.warning("Attempted to start scan while scan already in progress")
            return
        }

        // Prevent scanning while deleting
        guard !isDeleting else {
            Logger.scanning.warning("Attempted to start scan while deletion in progress")
            return
        }

        Logger.scanning.info("Starting scan at: \(folder.path)")

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

                Logger.scanning.info("Scan completed. Found \(results.count) build folders")

                // Check for empty results
                if results.isEmpty {
                    Logger.scanning.notice("No build folders found at: \(folder.path)")
                    self.currentError = .noResultsFound(folder)
                    self.showError = true
                } else {
                    // Add to recent folders on successful scan with results
                    self.recentFoldersManager.addFolder(folder)
                }
            } catch let error as NSError {
                Logger.scanning.error("Scan failed with NSError: \(error.localizedDescription, privacy: .public)")

                // Check if this is a permission error
                // NSFileReadNoPermissionError = 257
                // NSFileReadNoSuchFileError = 260 (sometimes returned for permission issues)
                if error.domain == NSCocoaErrorDomain &&
                   (error.code == 257 || error.code == 260 || error.code == 513) {
                    // This is a permission issue
                    self.currentError = .permissionDenied(folder)
                    self.showPermissionError = true
                } else if error.localizedDescription.lowercased().contains("permission") ||
                          error.localizedDescription.lowercased().contains("not permitted") {
                    // Catch any other permission-related errors by description
                    self.currentError = .permissionDenied(folder)
                    self.showPermissionError = true
                } else {
                    self.handleError(error)
                }
                self.isScanning = false
            } catch {
                Logger.scanning.error("Scan failed: \(error.localizedDescription, privacy: .public)")
                self.handleError(error)
                self.isScanning = false
            }
        }
    }

    /// Cancels the current scan
    func cancelScan() {
        // Only log and show errors if we were actually scanning
        let wasScanning = isScanning

        if wasScanning {
            Logger.scanning.info("Cancelling scan")
        }

        scanTask?.cancel()
        scanTask = nil
        isScanning = false

        // Only show cancelled error if we were actually scanning and have no results
        if wasScanning && scanResults.isEmpty {
            currentError = .scanCancelled
            showError = true
        } else if wasScanning {
            Logger.scanning.info("Scan cancelled. Showing \(self.scanResults.count) partial results")
        }
    }

    /// Scans static locations (DerivedData, caches, etc.)
    func scanStaticLocations() {
        guard !isScanningStatic else {
            Logger.scanning.warning("Static scan already in progress")
            return
        }

        Logger.scanning.info("Starting static location scan")

        isScanningStatic = true

        Task {
            do {
                let types = StaticLocationType.allCases
                let results = try await staticScanner.scanStaticLocations(types: types) { [weak self] path, count in
                    guard let self else { return }
                    Task { @MainActor in
                        self.currentScanPath = path
                    }
                }

                self.staticLocations = results
                self.isScanningStatic = false

                let existingCount = results.filter(\.exists).count
                Logger.scanning.info("Static scan complete. Found \(existingCount) of \(types.count) locations")
            } catch {
                Logger.scanning.error("Static scan failed: \(error.localizedDescription, privacy: .public)")
                self.handleError(error)
                self.isScanningStatic = false
            }
        }
    }

    /// Toggles selection for a specific static location
    func toggleStaticLocationSelection(for location: StaticLocation) {
        if let index = staticLocations.firstIndex(where: { $0.id == location.id }) {
            staticLocations[index].isSelected.toggle()
        }
    }

    // MARK: - Selection Management

    /// Sorts results by the given column
    func sort(by column: SortColumn) {
        if sortColumn == column {
            sortOrder.toggle()
        } else {
            sortColumn = column
            sortOrder = column == .size ? .descending : .ascending
        }
    }

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

    /// Returns currently selected static locations
    var selectedStaticLocations: [StaticLocation] {
        staticLocations.filter(\.isSelected)
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

    /// Total size of selected folders (including static locations)
    var selectedSize: Int64 {
        let buildFoldersSize = selectedFolders.reduce(0) { $0 + $1.size }
        let staticLocationsSize = selectedStaticLocations.reduce(0) { $0 + $1.size }
        return buildFoldersSize + staticLocationsSize
    }

    /// Formatted selected size
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }

    /// Total count of selected items (build folders + static locations)
    var totalSelectedCount: Int {
        selectedFolders.count + selectedStaticLocations.count
    }

    // MARK: - Deletion

    /// Shows deletion confirmation dialog
    func showDeleteConfirmation() {
        guard !selectedFolders.isEmpty || !selectedStaticLocations.isEmpty else { return }
        showDeletionConfirmation = true
    }

    /// Confirms deletion and starts the delete process
    func confirmDeletion() {
        showDeletionConfirmation = false
        deleteSelectedFolders()
    }

    /// Deletes selected folders and static locations
    private func deleteSelectedFolders() {
        let foldersToDelete = selectedFolders
        let staticToDelete = selectedStaticLocations

        guard !foldersToDelete.isEmpty || !staticToDelete.isEmpty else { return }

        // Prevent concurrent deletions
        guard !isDeleting else {
            Logger.deletion.warning("Attempted to start deletion while deletion already in progress")
            return
        }

        // Prevent deletion while scanning
        guard !isScanning else {
            Logger.deletion.warning("Attempted to start deletion while scan in progress")
            return
        }

        let totalItemsToDelete = foldersToDelete.count + staticToDelete.count
        Logger.deletion.info("Starting deletion of \(totalItemsToDelete) items (\(foldersToDelete.count) build folders, \(staticToDelete.count) static locations)")

        // Initialize progress tracking
        isDeleting = true
        deletionProgress = 0.0
        showDeletionProgress = true
        deletedItemCount = 0
        deletedSize = 0
        currentDeletionItem = ""

        Task {
            do {
                // Combine URLs from both sources
                let allURLs = foldersToDelete.map { $0.path } + staticToDelete.map { $0.path }
                let allItems: [(name: String, size: Int64)] =
                    foldersToDelete.map { ($0.projectName, $0.size) } +
                    staticToDelete.map { ($0.displayName, $0.size) }

                try await deleter.delete(urls: allURLs) { [weak self] current, total in
                    guard let self else { return }
                    Task { @MainActor in
                        self.deletedItemCount = current
                        if current > 0 && current <= allItems.count {
                            let currentItem = allItems[current - 1]
                            self.currentDeletionItem = currentItem.name
                            // Calculate total deleted size from all completed items
                            self.deletedSize = allItems.prefix(current).reduce(0) { $0 + $1.size }
                        }
                        self.deletionProgress = Double(current) / Double(total)
                    }
                }

                // All deletions succeeded - remove all deleted items from results
                for folder in foldersToDelete {
                    if let index = self.scanResults.firstIndex(where: { $0.id == folder.id }) {
                        self.scanResults.remove(at: index)
                    }
                }

                for location in staticToDelete {
                    if let index = self.staticLocations.firstIndex(where: { $0.id == location.id }) {
                        self.staticLocations.remove(at: index)
                    }
                }

                Logger.deletion.info("Successfully deleted \(totalItemsToDelete) items")
                self.isDeleting = false
                self.showDeletionProgress = false
            } catch let error as ZeroDevCleanerError {
                // Handle partial deletion failure
                if case .partialDeletionFailure(let failedURLs) = error {
                    let failedSet = Set(failedURLs)

                    // Remove only successfully deleted folders
                    let successfulFolders = foldersToDelete.filter { !failedSet.contains($0.path) }
                    for folder in successfulFolders {
                        if let index = self.scanResults.firstIndex(where: { $0.id == folder.id }) {
                            self.scanResults.remove(at: index)
                        }
                    }

                    // Remove only successfully deleted static locations
                    let successfulStatic = staticToDelete.filter { !failedSet.contains($0.path) }
                    for location in successfulStatic {
                        if let index = self.staticLocations.firstIndex(where: { $0.id == location.id }) {
                            self.staticLocations.remove(at: index)
                        }
                    }

                    Logger.deletion.warning("Partial deletion failure: \(failedURLs.count) of \(totalItemsToDelete) failed")
                }

                self.handleError(error)
                self.isDeleting = false
                self.showDeletionProgress = false
            } catch {
                Logger.deletion.error("Deletion failed: \(error.localizedDescription, privacy: .public)")
                self.handleError(error)
                self.isDeleting = false
                self.showDeletionProgress = false
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
