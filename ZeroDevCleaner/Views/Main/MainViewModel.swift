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
        case flutter = "Flutter"
        case nodeJS = "Node.js"
        case rust = "Rust"
        case python = "Python"

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .android: return "cube.fill"
            case .iOS: return "apple.logo"
            case .swiftPackage: return "shippingbox.fill"
            case .flutter: return "wind"
            case .nodeJS: return "atom"
            case .rust: return "gearshape.2.fill"
            case .python: return "chevron.left.forwardslash.chevron.right"
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

    enum ResultsTab: String, CaseIterable, Sendable {
        case buildFolders = "Build Folders"
        case systemCaches = "System Caches"

        var icon: String {
            switch self {
            case .buildFolders: return "folder.fill"
            case .systemCaches: return "externaldrive.fill"
            }
        }
    }

    // MARK: - State Properties

    /// Current active tab
    var currentTab: ResultsTab = .buildFolders

    /// Results from the last scan
    var scanResults: [BuildFolder] = [] {
        didSet { invalidateFilterCache() }
    }

    /// Current filter type
    var currentFilter: FilterType = .all {
        didSet { invalidateFilterCache() }
    }

    /// Current sort column
    var sortColumn: SortColumn = .size {
        didSet { invalidateSortCache() }
    }

    /// Current sort order
    var sortOrder: SortOrder = .descending {
        didSet { invalidateSortCache() }
    }

    // MARK: - Performance: Cached Results

    private var cachedFilteredResults: [BuildFolder]?
    private var cachedFilter: FilterType?
    private var cachedSortedResults: [BuildFolder]?
    private var cachedSortColumn: SortColumn?
    private var cachedSortOrder: SortOrder?

    private func invalidateFilterCache() {
        cachedFilteredResults = nil
        cachedSortedResults = nil // Filter change invalidates sort too
    }

    private func invalidateSortCache() {
        cachedSortedResults = nil
    }

    /// Filtered results based on current filter
    var filteredResults: [BuildFolder] {
        // Return cached result if filter unchanged
        if let cached = cachedFilteredResults, cachedFilter == currentFilter {
            return cached
        }

        // Compute fresh results
        let results: [BuildFolder]
        if currentFilter == .all {
            results = scanResults
        } else {
            results = scanResults.filter { folder in
                switch currentFilter {
                case .all:
                    return true
                case .android:
                    return folder.projectType == .android
                case .iOS:
                    return folder.projectType == .iOS
                case .swiftPackage:
                    return folder.projectType == .swiftPackage
                case .flutter:
                    return folder.projectType == .flutter
                case .nodeJS:
                    return folder.projectType == .nodeJS
                case .rust:
                    return folder.projectType == .rust
                case .python:
                    return folder.projectType == .python
                }
            }
        }

        // Cache and return
        cachedFilteredResults = results
        cachedFilter = currentFilter
        return results
    }

    /// Sorted and filtered results
    var sortedAndFilteredResults: [BuildFolder] {
        // Return cached result if parameters unchanged
        if let cached = cachedSortedResults,
           cachedFilter == currentFilter,
           cachedSortColumn == sortColumn,
           cachedSortOrder == sortOrder {
            return cached
        }

        let filtered = filteredResults

        let sorted = filtered.sorted { lhs, rhs in
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

        // Cache and return
        cachedSortedResults = sorted
        cachedSortColumn = sortColumn
        cachedSortOrder = sortOrder
        return sorted
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

    // MARK: - Scanning

    /// Starts scanning configured locations and system caches
    func startScan(locations: [ScanLocation], locationManager: ScanLocationManager? = nil) {
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

        Logger.scanning.info("Starting comprehensive scan - \(locations.count) locations + system caches")

        // Cancel any existing scan
        cancelScan()

        // Reset state
        scanResults = []
        staticLocations = []
        scanProgress = 0.0
        currentScanPath = ""
        isScanning = true
        isScanningStatic = true

        // Start scan task
        scanTask = Task {
            var allBuildFolders: [BuildFolder] = []

            // Scan configured locations
            if !locations.isEmpty {
                for (index, location) in locations.enumerated() {
                    Logger.scanning.info("Scanning location \(index + 1)/\(locations.count): \(location.path.path, privacy: .public)")

                    do {
                        currentScanPath = location.path.path
                        let results = try await scanner.scanDirectory(at: location.path) { [weak self] path, _ in
                            guard let self else { return }
                            Task { @MainActor in
                                self.currentScanPath = path
                            }
                        }

                        allBuildFolders.append(contentsOf: results)
                        Logger.scanning.info("Found \(results.count) build folders in \(location.name)")

                        // Update last scanned time
                        if let manager = locationManager {
                            manager.updateLastScanned(for: location)
                        }
                    } catch {
                        Logger.scanning.error("Failed to scan location \(location.name): \(error.localizedDescription, privacy: .public)")
                        // Continue with other locations
                    }
                }
            }

            // Scan static locations (system caches)
            do {
                Logger.scanning.info("Scanning system caches")
                let types = StaticLocationType.allCases
                let staticResults = try await staticScanner.scanStaticLocations(types: types) { [weak self] path, _ in
                    guard let self else { return }
                    Task { @MainActor in
                        self.currentScanPath = path
                    }
                }

                self.staticLocations = staticResults
                let existingCount = staticResults.filter(\.exists).count
                Logger.scanning.info("Found \(existingCount) of \(types.count) system cache locations")
            } catch {
                Logger.scanning.error("Static scan failed: \(error.localizedDescription, privacy: .public)")
                // Continue even if static scan fails
            }

            // Update results
            self.scanResults = allBuildFolders
            self.isScanning = false
            self.isScanningStatic = false

            let totalFound = allBuildFolders.count + self.staticLocations.filter(\.exists).count
            Logger.scanning.info("Scan complete. Found \(allBuildFolders.count) build folders and \(self.staticLocations.filter(\.exists).count) system caches")

            if totalFound == 0 {
                Logger.scanning.notice("No items found in any location")
                self.currentError = .scanCancelled
                self.showError = true
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

    /// Toggles selection for a specific static location
    func toggleStaticLocationSelection(for location: StaticLocation) {
        if let index = staticLocations.firstIndex(where: { $0.id == location.id }) {
            staticLocations[index].isSelected.toggle()
            let newState = staticLocations[index].isSelected

            // If location has sub-items, toggle them all to match parent
            if !staticLocations[index].subItems.isEmpty {
                for subIndex in staticLocations[index].subItems.indices {
                    staticLocations[index].subItems[subIndex].isSelected = newState
                }
            }
        }
    }

    /// Toggles selection for a specific sub-item within a static location
    func toggleSubItemSelection(for location: StaticLocation, subItemId: UUID) {
        if let locationIndex = staticLocations.firstIndex(where: { $0.id == location.id }),
           let subItemIndex = staticLocations[locationIndex].subItems.firstIndex(where: { $0.id == subItemId }) {
            staticLocations[locationIndex].subItems[subItemIndex].isSelected.toggle()

            // Update parent selection based on sub-items
            let allSelected = staticLocations[locationIndex].subItems.allSatisfy(\.isSelected)
            let noneSelected = staticLocations[locationIndex].subItems.allSatisfy { !$0.isSelected }

            if allSelected {
                staticLocations[locationIndex].isSelected = true
            } else if noneSelected {
                staticLocations[locationIndex].isSelected = false
            }
            // For partial selection, we keep parent unselected but show in UI
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

    /// Returns currently selected static locations (parent level or sub-items)
    var selectedStaticLocations: [StaticLocation] {
        staticLocations.filter(\.isSelected)
    }

    /// Returns all selected sub-items across all static locations
    var selectedSubItems: [(location: StaticLocation, subItem: StaticLocationSubItem)] {
        var result: [(StaticLocation, StaticLocationSubItem)] = []
        for location in staticLocations where !location.isSelected {
            // Only include sub-items if parent is NOT selected
            // (if parent is selected, the whole location is deleted)
            for subItem in location.subItems where subItem.isSelected {
                result.append((location, subItem))
            }
        }
        return result
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

    /// Total size of selected folders (including static locations and sub-items)
    var selectedSize: Int64 {
        let buildFoldersSize = selectedFolders.reduce(0) { $0 + $1.size }
        let staticLocationsSize = selectedStaticLocations.reduce(0) { $0 + $1.size }
        let subItemsSize = selectedSubItems.reduce(0) { $0 + $1.subItem.size }
        return buildFoldersSize + staticLocationsSize + subItemsSize
    }

    /// Formatted selected size
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }

    /// Total count of selected items (build folders + static locations + sub-items)
    var totalSelectedCount: Int {
        selectedFolders.count + selectedStaticLocations.count + selectedSubItems.count
    }

    // MARK: - Deletion

    /// Shows deletion confirmation dialog
    func showDeleteConfirmation() {
        guard !selectedFolders.isEmpty || !selectedStaticLocations.isEmpty || !selectedSubItems.isEmpty else { return }
        showDeletionConfirmation = true
    }

    /// Confirms deletion and starts the delete process
    func confirmDeletion() {
        showDeletionConfirmation = false
        deleteSelectedFolders()
    }

    /// Deletes selected folders, static locations, and sub-items
    private func deleteSelectedFolders() {
        let foldersToDelete = selectedFolders
        let staticToDelete = selectedStaticLocations
        let subItemsToDelete = selectedSubItems

        guard !foldersToDelete.isEmpty || !staticToDelete.isEmpty || !subItemsToDelete.isEmpty else { return }

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

        let totalItemsToDelete = foldersToDelete.count + staticToDelete.count + subItemsToDelete.count
        Logger.deletion.info("Starting deletion of \(totalItemsToDelete) items (\(foldersToDelete.count) build folders, \(staticToDelete.count) static locations, \(subItemsToDelete.count) sub-items)")

        // Initialize progress tracking
        isDeleting = true
        deletionProgress = 0.0
        showDeletionProgress = true
        deletedItemCount = 0
        deletedSize = 0
        currentDeletionItem = ""

        Task {
            do {
                // Combine URLs from all sources
                let allURLs = foldersToDelete.map { $0.path } +
                              staticToDelete.map { $0.path } +
                              subItemsToDelete.map { $0.subItem.path }
                let allItems: [(name: String, size: Int64)] =
                    foldersToDelete.map { ($0.projectName, $0.size) } +
                    staticToDelete.map { ($0.displayName, $0.size) } +
                    subItemsToDelete.map { ($0.subItem.name, $0.subItem.size) }

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

                // Remove successfully deleted sub-items
                for (location, subItem) in subItemsToDelete {
                    if let locationIndex = self.staticLocations.firstIndex(where: { $0.id == location.id }),
                       let subItemIndex = self.staticLocations[locationIndex].subItems.firstIndex(where: { $0.id == subItem.id }) {
                        self.staticLocations[locationIndex].subItems.remove(at: subItemIndex)
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

                    // Remove only successfully deleted sub-items
                    let successfulSubItems = subItemsToDelete.filter { !failedSet.contains($0.subItem.path) }
                    for (location, subItem) in successfulSubItems {
                        if let locationIndex = self.staticLocations.firstIndex(where: { $0.id == location.id }),
                           let subItemIndex = self.staticLocations[locationIndex].subItems.firstIndex(where: { $0.id == subItem.id }) {
                            self.staticLocations[locationIndex].subItems.remove(at: subItemIndex)
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
