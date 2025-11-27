//
//  MainViewModel.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI
import Observation
import SwiftData

@Observable
@MainActor
final class MainViewModel {
    // MARK: - Type Aliases (from FilterManager)

    typealias FilterType = FilterManager.FilterType
    typealias ComparisonOperator = FilterManager.ComparisonOperator

    // MARK: - Filter Manager

    let filterManager = FilterManager()

    // MARK: - Sort and Tab Types

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
        didSet { invalidateSortCache() }
    }

    // MARK: - Filter Properties (delegated to FilterManager)

    var currentFilter: FilterType {
        get { filterManager.currentFilter }
        set {
            filterManager.currentFilter = newValue
            invalidateSortCache()
        }
    }

    var currentPreset: FilterPreset {
        get { filterManager.currentPreset }
        set {
            filterManager.currentPreset = newValue
            invalidateSortCache()
        }
    }

    var sizeFilterValue: Int64? {
        get { filterManager.sizeFilterValue }
        set {
            filterManager.sizeFilterValue = newValue
            invalidateSortCache()
        }
    }

    var sizeFilterOperator: ComparisonOperator {
        get { filterManager.sizeFilterOperator }
        set {
            filterManager.sizeFilterOperator = newValue
            invalidateSortCache()
        }
    }

    var daysOldFilterValue: Int? {
        get { filterManager.daysOldFilterValue }
        set {
            filterManager.daysOldFilterValue = newValue
            invalidateSortCache()
        }
    }

    var daysOldFilterOperator: ComparisonOperator {
        get { filterManager.daysOldFilterOperator }
        set {
            filterManager.daysOldFilterOperator = newValue
            invalidateSortCache()
        }
    }

    var showComprehensiveFilters: Bool {
        get { filterManager.showComprehensiveFilters }
        set {
            filterManager.showComprehensiveFilters = newValue
            // No need to invalidate cache for UI-only property
        }
    }

    /// Current sort column
    var sortColumn: SortColumn = .size {
        didSet { invalidateSortCache() }
    }

    /// Current sort order
    var sortOrder: SortOrder = .descending {
        didSet { invalidateSortCache() }
    }

    // MARK: - Performance: Cached Results (Sorting only)

    private var cachedSortedResults: [BuildFolder]?
    private var cachedSortColumn: SortColumn?
    private var cachedSortOrder: SortOrder?

    private func invalidateSortCache() {
        cachedSortedResults = nil
    }

    /// Filtered results based on current filter and preset
    var filteredResults: [BuildFolder] {
        return filterManager.filteredResults(from: scanResults)
    }

    /// Sorted and filtered results
    var sortedAndFilteredResults: [BuildFolder] {
        // Return cached result if parameters unchanged
        if let cached = cachedSortedResults,
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

    /// Filtered static locations based on current preset
    var filteredStaticLocations: [StaticLocation] {
        return filterManager.filteredStaticLocations(from: staticLocations)
    }

    /// Whether to include static locations in results
    var includeStaticLocations: Bool = true

    /// Whether static location scan is in progress
    var isScanningStatic: Bool = false

    // MARK: - Dependencies

    private let scanner: FileScannerProtocol
    private let deleter: FileDeleterProtocol
    private let staticScanner: StaticLocationScannerProtocol
    private var modelContext: ModelContext?

    // MARK: - Private Properties

    private var scanTask: Task<Void, Never>?
    private var deletionStartTime: Date?

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

    /// Configures the model context for statistics tracking
    func configureModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Scanning

    /// Starts scanning configured locations and system caches
    func startScan(locations: [ScanLocation], locationManager: ScanLocationManager? = nil) {
        // Prevent concurrent scans
        guard !isScanning else {
            SuperLog.w("Attempted to start scan while scan already in progress")
            return
        }

        // Prevent scanning while deleting
        guard !isDeleting else {
            SuperLog.w("Attempted to start scan while deletion in progress")
            return
        }

        SuperLog.i("Starting comprehensive scan - \(locations.count) locations + system caches")

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
                    SuperLog.i("Scanning location \(index + 1)/\(locations.count): \(location.path.path)")

                    do {
                        currentScanPath = location.path.path

                        // Update progress based on location being scanned
                        // Reserve 80% for locations, 20% for static caches
                        let locationProgress = Double(index) / Double(locations.count) * 0.8
                        scanProgress = locationProgress

                        let results = try await scanner.scanDirectory(at: location.path) { [weak self] path, count in
                            guard let self else { return }
                            Task { @MainActor in
                                self.currentScanPath = path
                                // Update progress within this location
                                let baseProgress = Double(index) / Double(locations.count) * 0.8
                                let incrementProgress = (1.0 / Double(locations.count)) * 0.8 * min(Double(count) / 100.0, 1.0)
                                self.scanProgress = baseProgress + incrementProgress
                            }
                        }

                        allBuildFolders.append(contentsOf: results)
                        SuperLog.i("Found \(results.count) build folders in \(location.name)")

                        // Update last scanned time
                        if let manager = locationManager {
                            manager.updateLastScanned(for: location)
                        }
                    } catch {
                        SuperLog.e("Failed to scan location \(location.name): \(error.localizedDescription)")
                        // Continue with other locations
                    }
                }

                // Mark locations as 80% done
                scanProgress = 0.8
            }

            // Scan static locations (system caches)
            do {
                SuperLog.i("Scanning system caches")
                // Exclude .custom since custom caches are scanned separately below
                let types = StaticLocationType.allCases.filter { $0 != .custom }
                let staticResults = try await staticScanner.scanStaticLocations(types: types) { [weak self] path, current in
                    guard let self else { return }
                    Task { @MainActor in
                        self.currentScanPath = path
                        // Update progress: 80% done from locations, now doing remaining 15%
                        let staticProgress = 0.8 + (Double(current) / Double(types.count) * 0.15)
                        self.scanProgress = staticProgress
                    }
                }

                self.staticLocations = staticResults
                let existingCount = staticResults.filter(\.exists).count
                SuperLog.i("Found \(existingCount) of \(types.count) system cache locations")
            } catch {
                SuperLog.e("Static scan failed: \(error.localizedDescription)")
                // Continue even if static scan fails
            }

            // Scan custom cache locations
            let enabledCustomCaches = CustomCacheManager.shared.enabledLocations
            if !enabledCustomCaches.isEmpty {
                SuperLog.i("Scanning \(enabledCustomCaches.count) custom cache locations")

                for (index, customCache) in enabledCustomCaches.enumerated() {
                    do {
                        self.currentScanPath = customCache.path.path

                        // Update progress: 95% done, now doing remaining 5%
                        let customProgress = 0.95 + (Double(index + 1) / Double(enabledCustomCaches.count) * 0.05)
                        self.scanProgress = customProgress

                        if let customLocation = try await staticScanner.scanCustomCacheLocation(customCache) {
                            // Append to static locations
                            self.staticLocations.append(customLocation)

                            // Update last scanned time
                            CustomCacheManager.shared.updateLastScanned(id: customCache.id)

                            SuperLog.i("Found custom cache: \(customCache.name) - \(ByteCountFormatter.string(fromByteCount: customLocation.size, countStyle: .file))")
                        }
                    } catch {
                        SuperLog.e("Failed to scan custom cache \(customCache.name): \(error.localizedDescription)")
                        // Continue with other custom caches
                    }
                }
            }

            // Mark scan as complete (100%)
            self.scanProgress = 1.0

            // Pre-sort results in background to avoid UI freeze
            let sortedResults = await Task.detached {
                return allBuildFolders.sorted { lhs, rhs in
                    // Default sort: by size descending
                    return lhs.size > rhs.size
                }
            }.value

            // Update results (already sorted for initial display)
            self.scanResults = sortedResults

            // Pre-populate cache to avoid blocking during initial render
            await Task { @MainActor in
                _ = self.sortedAndFilteredResults
            }.value

            self.isScanning = false
            self.isScanningStatic = false

            let totalFound = allBuildFolders.count + self.staticLocations.filter(\.exists).count
            SuperLog.i("Scan complete. Found \(allBuildFolders.count) build folders and \(self.staticLocations.filter(\.exists).count) system caches")

            if totalFound == 0 {
                SuperLog.i("No items found in any location")
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
            SuperLog.i("Cancelling scan")
        }

        scanTask?.cancel()
        scanTask = nil
        isScanning = false

        // Only show cancelled error if we were actually scanning and have no results
        if wasScanning && scanResults.isEmpty {
            currentError = .scanCancelled
            showError = true
        } else if wasScanning {
            SuperLog.i("Scan cancelled. Showing \(self.scanResults.count) partial results")
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

                    // Also toggle nested sub-items (e.g., archive versions)
                    if !staticLocations[index].subItems[subIndex].subItems.isEmpty {
                        for nestedIndex in staticLocations[index].subItems[subIndex].subItems.indices {
                            staticLocations[index].subItems[subIndex].subItems[nestedIndex].isSelected = newState
                        }
                    }
                }
            }
        }
    }

    /// Toggles selection for a specific sub-item within a static location
    func toggleSubItemSelection(for location: StaticLocation, subItemId: UUID) {
        if let locationIndex = staticLocations.firstIndex(where: { $0.id == location.id }),
           let subItemIndex = staticLocations[locationIndex].subItems.firstIndex(where: { $0.id == subItemId }) {

            // Toggle the sub-item
            staticLocations[locationIndex].subItems[subItemIndex].isSelected.toggle()
            let newState = staticLocations[locationIndex].subItems[subItemIndex].isSelected

            // If this sub-item has nested items (e.g., archive app group), select/deselect all nested items too
            if !staticLocations[locationIndex].subItems[subItemIndex].subItems.isEmpty {
                for nestedIndex in staticLocations[locationIndex].subItems[subItemIndex].subItems.indices {
                    staticLocations[locationIndex].subItems[subItemIndex].subItems[nestedIndex].isSelected = newState
                }
            }

            // Update parent location selection based on all sub-items
            updateParentSelection(at: locationIndex)
        }
    }

    /// Toggles selection for a nested sub-item (e.g., archive version within app group)
    func toggleNestedSubItemSelection(for location: StaticLocation, subItemId: UUID, nestedItemId: UUID) {
        if let locationIndex = staticLocations.firstIndex(where: { $0.id == location.id }),
           let subItemIndex = staticLocations[locationIndex].subItems.firstIndex(where: { $0.id == subItemId }),
           let nestedIndex = staticLocations[locationIndex].subItems[subItemIndex].subItems.firstIndex(where: { $0.id == nestedItemId }) {

            // Toggle the nested item
            staticLocations[locationIndex].subItems[subItemIndex].subItems[nestedIndex].isSelected.toggle()

            // Update app group selection based on nested items
            updateSubItemSelection(at: locationIndex, subItemIndex: subItemIndex)

            // Update parent location selection based on all sub-items
            updateParentSelection(at: locationIndex)
        }
    }

    /// Updates sub-item (app group) selection based on its nested items
    private func updateSubItemSelection(at locationIndex: Int, subItemIndex: Int) {
        let allNestedSelected = staticLocations[locationIndex].subItems[subItemIndex].subItems.allSatisfy(\.isSelected)
        let noneNestedSelected = staticLocations[locationIndex].subItems[subItemIndex].subItems.allSatisfy { !$0.isSelected }

        if allNestedSelected {
            staticLocations[locationIndex].subItems[subItemIndex].isSelected = true
        } else if noneNestedSelected {
            staticLocations[locationIndex].subItems[subItemIndex].isSelected = false
        } else {
            // Partial selection - keep unselected but UI will show minus icon
            staticLocations[locationIndex].subItems[subItemIndex].isSelected = false
        }
    }

    /// Updates parent location selection based on all sub-items (including nested)
    private func updateParentSelection(at locationIndex: Int) {
        // Check if we need to look at nested items too
        var allSelected = true
        var noneSelected = true

        for subItem in staticLocations[locationIndex].subItems {
            if !subItem.subItems.isEmpty {
                // This sub-item has nested items - check them all
                for nestedItem in subItem.subItems {
                    if nestedItem.isSelected {
                        noneSelected = false
                    } else {
                        allSelected = false
                    }
                }
            } else {
                // Regular sub-item without nesting
                if subItem.isSelected {
                    noneSelected = false
                } else {
                    allSelected = false
                }
            }
        }

        if allSelected {
            staticLocations[locationIndex].isSelected = true
        } else if noneSelected {
            staticLocations[locationIndex].isSelected = false
        } else {
            // Partial selection - keep unselected but UI will show minus icon
            staticLocations[locationIndex].isSelected = false
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
    // MARK: - Build Folder Selection (Recursive)

    /// Toggle selection for a build folder (cascades to all children recursively)
    func toggleBuildFolderSelection(for folder: BuildFolder) {
        guard let index = findFolderIndex(folder.id, in: scanResults) else { return }

        // Toggle based on path
        toggleFolderAtPath(index, in: &scanResults)

        // Invalidate cache to ensure UI updates
        invalidateSortCache()
    }

    /// Find folder index recursively
    private func findFolderIndex(_ id: UUID, in folders: [BuildFolder], path: [Int] = []) -> [Int]? {
        for (index, folder) in folders.enumerated() {
            if folder.id == id {
                return path + [index]
            }
            if let subPath = findFolderIndex(id, in: folder.subItems, path: path + [index]) {
                return subPath
            }
        }
        return nil
    }

    /// Toggle folder selection at given path
    private func toggleFolderAtPath(_ path: [Int], in folders: inout [BuildFolder]) {
        guard !path.isEmpty else { return }

        if path.count == 1 {
            // Top-level folder
            folders[path[0]].isSelected.toggle()
            toggleAllChildren(in: &folders[path[0]].subItems, to: folders[path[0]].isSelected)
        } else {
            // Nested folder - recursively navigate and toggle
            toggleNestedFolderAtPath(path, in: &folders, currentIndex: 0)
        }
    }

    /// Helper to recursively navigate and toggle nested folders
    private func toggleNestedFolderAtPath(_ path: [Int], in folders: inout [BuildFolder], currentIndex: Int) {
        if currentIndex == path.count - 1 {
            // We've reached the target folder
            folders[path[currentIndex]].isSelected.toggle()
            toggleAllChildren(in: &folders[path[currentIndex]].subItems, to: folders[path[currentIndex]].isSelected)
        } else {
            // Navigate deeper
            toggleNestedFolderAtPath(path, in: &folders[path[currentIndex]].subItems, currentIndex: currentIndex + 1)
        }
    }

    /// Recursively toggle all children
    private func toggleAllChildren(in folders: inout [BuildFolder], to isSelected: Bool) {
        for i in folders.indices {
            folders[i].isSelected = isSelected
            toggleAllChildren(in: &folders[i].subItems, to: isSelected)
        }
    }

    /// Legacy method for backward compatibility
    func toggleSelection(for folder: BuildFolder) {
        toggleBuildFolderSelection(for: folder)
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
        let filteredIds = Set(collectAllFolderIds(from: filteredResults))
        selectAllRecursive(in: &scanResults, matching: filteredIds)
        // Invalidate cache to ensure UI updates
        invalidateSortCache()
    }

    /// Select all matching folders recursively
    private func selectAllRecursive(in folders: inout [BuildFolder], matching ids: Set<UUID>) {
        for i in folders.indices {
            if ids.contains(folders[i].id) {
                folders[i].isSelected = true
            }
            selectAllRecursive(in: &folders[i].subItems, matching: ids)
        }
    }

    /// Deselects all folders (in current filter view)
    func deselectAll() {
        let filteredIds = Set(collectAllFolderIds(from: filteredResults))
        deselectAllRecursive(in: &scanResults, matching: filteredIds)
        // Invalidate cache to ensure UI updates
        invalidateSortCache()
    }

    /// Deselect all matching folders recursively
    private func deselectAllRecursive(in folders: inout [BuildFolder], matching ids: Set<UUID>) {
        for i in folders.indices {
            if ids.contains(folders[i].id) {
                folders[i].isSelected = false
            }
            deselectAllRecursive(in: &folders[i].subItems, matching: ids)
        }
    }

    /// Collect all folder IDs recursively (including children)
    private func collectAllFolderIds(from folders: [BuildFolder]) -> [UUID] {
        var ids: [UUID] = []
        for folder in folders {
            ids.append(folder.id)
            ids.append(contentsOf: collectAllFolderIds(from: folder.subItems))
        }
        return ids
    }

    /// Remove a folder by ID recursively from the folder tree
    private func removeFolderRecursively(_ id: UUID, from folders: inout [BuildFolder]) {
        // Try to remove at top level
        if let index = folders.firstIndex(where: { $0.id == id }) {
            folders.remove(at: index)
            return
        }

        // Recursively search in children
        for i in folders.indices {
            removeFolderRecursively(id, from: &folders[i].subItems)
        }
    }

    /// Returns currently selected folders (only top-level, excludes children of selected parents)
    var selectedFolders: [BuildFolder] {
        collectTopLevelSelectedFolders(from: scanResults)
    }

    /// Recursively collect only top-level selected folders (don't include children if parent is selected)
    private func collectTopLevelSelectedFolders(from folders: [BuildFolder]) -> [BuildFolder] {
        var selected: [BuildFolder] = []
        for folder in folders {
            if folder.isSelected {
                // Parent is selected - include it but don't traverse children
                selected.append(folder)
            } else {
                // Parent not selected - check children
                selected.append(contentsOf: collectTopLevelSelectedFolders(from: folder.subItems))
            }
        }
        return selected
    }

    /// Returns currently selected static locations (parent level or sub-items)
    var selectedStaticLocations: [StaticLocation] {
        staticLocations.filter(\.isSelected)
    }

    /// Returns all selected sub-items across all static locations (including nested items)
    var selectedSubItems: [(location: StaticLocation, subItem: StaticLocationSubItem)] {
        var result: [(StaticLocation, StaticLocationSubItem)] = []
        for location in staticLocations where !location.isSelected {
            // Only include sub-items if parent is NOT selected
            // (if parent is selected, the whole location is deleted)
            for subItem in location.subItems {
                // Check if this sub-item has nested items (e.g., archive app groups)
                if !subItem.subItems.isEmpty {
                    // For app groups, collect selected versions
                    for nestedItem in subItem.subItems where nestedItem.isSelected {
                        result.append((location, nestedItem))
                    }
                } else if subItem.isSelected {
                    // Regular sub-item
                    result.append((location, subItem))
                }
            }
        }
        return result
    }

    /// Total number of folders found
    var totalFoldersCount: Int {
        countAllFolders(in: scanResults)
    }

    /// Recursively count all folders including nested ones
    private func countAllFolders(in folders: [BuildFolder]) -> Int {
        folders.reduce(0) { $0 + 1 + countAllFolders(in: $1.subItems) }
    }

    /// Get count for a specific filter type
    func count(for filter: FilterType) -> Int {
        return filterManager.count(for: filter, in: scanResults)
    }

    /// Filter types sorted by count (descending)
    var sortedFilterTypes: [FilterType] {
        return filterManager.sortedFilterTypes(for: scanResults)
    }

    /// Total size of all folders (only count top-level to avoid double-counting in hierarchies)
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
            SuperLog.w("Attempted to start deletion while deletion already in progress")
            return
        }

        // Prevent deletion while scanning
        guard !isScanning else {
            SuperLog.w("Attempted to start deletion while scan in progress")
            return
        }

        let totalItemsToDelete = foldersToDelete.count + staticToDelete.count + subItemsToDelete.count
        SuperLog.i("Starting deletion of \(totalItemsToDelete) items (\(foldersToDelete.count) build folders, \(staticToDelete.count) static locations, \(subItemsToDelete.count) sub-items)")

        // Initialize progress tracking
        isDeleting = true
        deletionProgress = 0.0
        showDeletionProgress = true
        deletedItemCount = 0
        deletedSize = 0
        currentDeletionItem = ""
        deletionStartTime = Date()  // Track start time for statistics

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
                    removeFolderRecursively(folder.id, from: &self.scanResults)
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

                SuperLog.i("Successfully deleted \(totalItemsToDelete) items")

                // Save statistics to SwiftData
                await self.saveCleaningStatistics(
                    folders: foldersToDelete,
                    staticLocations: staticToDelete,
                    subItems: subItemsToDelete
                )

                self.isDeleting = false
                self.showDeletionProgress = false
            } catch let error as ZeroDevCleanerError {
                // Handle partial deletion failure
                if case .partialDeletionFailure(let failedURLs) = error {
                    let failedSet = Set(failedURLs)

                    // Remove only successfully deleted folders
                    let successfulFolders = foldersToDelete.filter { !failedSet.contains($0.path) }
                    for folder in successfulFolders {
                        removeFolderRecursively(folder.id, from: &self.scanResults)
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

                    SuperLog.w("Partial deletion failure: \(failedURLs.count) of \(totalItemsToDelete) failed")
                }

                self.handleError(error)
                self.isDeleting = false
                self.showDeletionProgress = false
            } catch {
                SuperLog.e("Deletion failed: \(error.localizedDescription)")
                self.handleError(error)
                self.isDeleting = false
                self.showDeletionProgress = false
            }
        }
    }

    // MARK: - Statistics

    /// Resets to home screen by clearing all results
    func resetToHome() {
        SuperLog.i("Resetting to home screen")
        scanResults = []
        staticLocations = []
        currentFilter = .all
        scanProgress = 0.0
        currentScanPath = ""
    }

    /// Saves cleaning statistics to SwiftData
    private func saveCleaningStatistics(
        folders: [BuildFolder],
        staticLocations: [StaticLocation],
        subItems: [(location: StaticLocation, subItem: StaticLocationSubItem)]
    ) async {
        guard let modelContext = modelContext,
              let startTime = deletionStartTime else {
            print("Cannot save statistics: modelContext or startTime not available")
            return
        }

        let duration = Date().timeIntervalSince(startTime)
        let totalSize = folders.reduce(0) { $0 + $1.size } +
                       staticLocations.reduce(0) { $0 + $1.size } +
                       subItems.reduce(0) { $0 + $1.subItem.size }
        let itemCount = folders.count + staticLocations.count + subItems.count

        // Prepare items data
        var items: [(name: String, itemType: String, projectType: String?, size: Int64, path: String)] = []

        // Add build folders
        for folder in folders {
            items.append((
                name: folder.projectName,
                itemType: "Build Folder",
                projectType: folder.projectType.displayName,
                size: folder.size,
                path: folder.path.path
            ))
        }

        // Add static locations
        for location in staticLocations {
            items.append((
                name: location.displayName,
                itemType: "System Cache",
                projectType: nil,
                size: location.size,
                path: location.path.path
            ))
        }

        // Add sub-items
        for (location, subItem) in subItems {
            items.append((
                name: subItem.name,
                itemType: "System Cache (\(location.type.displayName))",
                projectType: nil,
                size: subItem.size,
                path: subItem.path.path
            ))
        }

        // Save statistics using StatisticsService
        do {
            let service = StatisticsService(modelContainer: modelContext.container)
            try await service.saveCleaningSession(
                totalSize: totalSize,
                itemCount: itemCount,
                duration: duration,
                items: items
            )
            print("Statistics saved: \(itemCount) items, \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)), \(String(format: "%.1fs", duration))")
        } catch {
            print("Failed to save statistics: \(error.localizedDescription)")
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
