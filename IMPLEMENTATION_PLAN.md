# ZeroDevCleaner - Implementation Plan for Next Features

## Phase 5: Enhanced UI & Polish

### Task 5.1: Sortable Table Columns (2 hours)

**Goal**: Make all table columns sortable by clicking headers

**Step 1: Add Sort State to MainViewModel** (30 min)

1. Open `ZeroDevCleaner/Views/Main/MainViewModel.swift`
2. Add after the `FilterType` enum:

```swift
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
```

3. Add properties after `currentFilter`:

```swift
var sortColumn: SortColumn = .size
var sortOrder: SortOrder = .descending
```

4. Add computed property after `filteredResults`:

```swift
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
```

5. Add sort method:

```swift
func sort(by column: SortColumn) {
    if sortColumn == column {
        sortOrder.toggle()
    } else {
        sortColumn = column
        sortOrder = column == .size ? .descending : .ascending
    }
}
```

**Step 2: Update ScanResultsView** (60 min)

1. Open `ZeroDevCleaner/Views/ScanResults/ScanResultsView.swift`
2. Replace the Table definition with:

```swift
Table(viewModel.sortedAndFilteredResults, selection: $selection) {
    TableColumn("") { folder in
        Toggle("", isOn: Binding(
            get: { folder.isSelected },
            set: { _ in viewModel.toggleSelection(for: folder) }
        ))
        .toggleStyle(.checkbox)
        .labelsHidden()
    }
    .width(40)

    TableColumn("Project") { folder in
        HStack {
            Image(systemName: folder.projectType.icon)
                .foregroundStyle(folder.projectType.color)
            Text(folder.projectName)
        }
    }
    .width(min: 150, ideal: 200, max: 300)

    TableColumn("Type") { folder in
        Text(folder.projectType.displayName)
    }
    .width(min: 100, ideal: 120)

    TableColumn("Size") { folder in
        Text(folder.formattedSize)
            .monospacedDigit()
    }
    .width(min: 80, ideal: 100)

    TableColumn("Last Modified") { folder in
        Text(folder.formattedLastModified)
    }
    .width(min: 120, ideal: 150)

    TableColumn("Path") { folder in
        Text(folder.path.path)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
    }
    .width(min: 200)
}
.tableColumnHeaders {
    TableColumnHeader("") { }
    TableColumnHeader("Project") {
        SortableHeader(title: "Project", column: .projectName, viewModel: viewModel)
    }
    TableColumnHeader("Type") {
        SortableHeader(title: "Type", column: .type, viewModel: viewModel)
    }
    TableColumnHeader("Size") {
        SortableHeader(title: "Size", column: .size, viewModel: viewModel)
    }
    TableColumnHeader("Last Modified") {
        SortableHeader(title: "Last Modified", column: .lastModified, viewModel: viewModel)
    }
    TableColumnHeader("Path") { Text("Path") }
}
```

3. Add SortableHeader component at the bottom of the file:

```swift
struct SortableHeader: View {
    let title: String
    let column: MainViewModel.SortColumn
    @Bindable var viewModel: MainViewModel

    var body: some View {
        Button {
            viewModel.sort(by: column)
        } label: {
            HStack(spacing: 4) {
                Text(title)
                if viewModel.sortColumn == column {
                    Image(systemName: viewModel.sortOrder == .ascending ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
```

**Step 3: Test** (30 min)

- Build and run
- Click each column header
- Verify sort order changes
- Verify sort indicator appears
- Test with filters active

**Acceptance Criteria:**
- ✅ All columns sortable except checkbox
- ✅ Sort indicator shows in active column
- ✅ Default sort is by size (descending)
- ✅ Sort persists during filtering

---

### Task 5.2: Better Confirmation Dialog (1.5 hours)

**Goal**: Show professional confirmation sheet before deletion

**Step 1: Create DeletionConfirmationView** (60 min)

1. Create new file: `ZeroDevCleaner/Views/Dialogs/DeletionConfirmationView.swift`

```swift
//
//  DeletionConfirmationView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import SwiftUI

struct DeletionConfirmationView: View {
    let foldersToDelete: [BuildFolder]
    let totalSize: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)

            // Title
            VStack(spacing: 8) {
                Text("Confirm Deletion")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("\(foldersToDelete.count) item\(foldersToDelete.count == 1 ? "" : "s") will be moved to Trash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Item list
            VStack(alignment: .leading, spacing: 12) {
                Text("Items to delete:")
                    .font(.headline)

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(foldersToDelete.prefix(10))) { folder in
                            HStack {
                                Image(systemName: folder.projectType.icon)
                                    .foregroundStyle(folder.projectType.color)
                                Text(folder.projectName)
                                    .font(.callout)
                                Spacer()
                                Text(folder.formattedSize)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if foldersToDelete.count > 10 {
                            Text("...and \(foldersToDelete.count - 10) more")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    }
                }
                .frame(maxHeight: 200)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Total size
                HStack {
                    Text("Total size:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(totalSize)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Reassurance
            Text("These items will be moved to the Trash and can be restored if needed.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                .controlSize(.large)

                Button("Move to Trash") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            }
        }
        .padding(32)
        .frame(width: 480)
    }
}

#Preview {
    DeletionConfirmationView(
        foldersToDelete: [
            BuildFolder(
                path: URL(fileURLWithPath: "/test/build"),
                projectType: .android,
                size: 1024 * 1024 * 50,
                projectName: "AndroidApp",
                lastModified: Date()
            )
        ],
        totalSize: "50 MB",
        onConfirm: {},
        onCancel: {}
    )
}
```

**Step 2: Integrate with MainViewModel** (30 min)

1. Open `MainViewModel.swift`
2. Add property:

```swift
var showDeletionConfirmation: Bool = false
```

3. Update `deleteSelectedFolders()` to show confirmation first:

```swift
func showDeleteConfirmation() {
    guard !selectedFolders.isEmpty else { return }
    showDeletionConfirmation = true
}

func confirmDeletion() {
    showDeletionConfirmation = false
    deleteSelectedFolders()
}
```

4. In `MainView.swift`, add sheet:

```swift
.sheet(isPresented: $viewModel.showDeletionConfirmation) {
    DeletionConfirmationView(
        foldersToDelete: viewModel.selectedFolders,
        totalSize: viewModel.formattedSelectedSize,
        onConfirm: { viewModel.confirmDeletion() },
        onCancel: { viewModel.showDeletionConfirmation = false }
    )
}
```

5. Update "Remove Selected" button to call `showDeleteConfirmation()` instead

**Acceptance Criteria:**
- ✅ Shows custom sheet before deletion
- ✅ Lists items to be deleted (up to 10, then "...and X more")
- ✅ Shows total size prominently
- ✅ Keyboard shortcuts work (Esc to cancel, Enter to confirm)

---

### Task 5.3: Better Deletion Progress (1.5 hours)

**Goal**: Show detailed progress during deletion

**Step 1: Create DeletionProgressView** (60 min)

1. Create `ZeroDevCleaner/Views/Dialogs/DeletionProgressView.swift`

```swift
//
//  DeletionProgressView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import SwiftUI

struct DeletionProgressView: View {
    let currentItem: String
    let progress: Double
    let currentIndex: Int
    let totalItems: Int
    let deletedSize: Int64
    let totalSize: Int64
    let canCancel: Bool
    let onCancel: () -> Void

    var deletedSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: deletedSize, countStyle: .file)
    }

    var totalSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text("Deleting Build Folders...")
                .font(.headline)

            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            // Current item
            VStack(spacing: 8) {
                Text("Deleting:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(currentItem)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity)
            }

            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)

                HStack {
                    Text("\(currentIndex) of \(totalItems)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(deletedSizeFormatted) of \(totalSizeFormatted)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            // Cancel button
            if canCancel {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(32)
        .frame(width: 400)
    }
}

#Preview {
    DeletionProgressView(
        currentItem: "MyAndroidApp",
        progress: 0.45,
        currentIndex: 5,
        totalItems: 11,
        deletedSize: 1024 * 1024 * 50,
        totalSize: 1024 * 1024 * 112,
        canCancel: true,
        onCancel: {}
    )
}
```

**Step 2: Update MainViewModel** (30 min)

1. Add properties:

```swift
var showDeletionProgress: Bool = false
var currentDeletionItem: String = ""
var deletedItemCount: Int = 0
var deletedSize: Int64 = 0
```

2. Update `deleteSelectedFolders()` to show progress:

```swift
func deleteSelectedFolders() {
    let foldersToDelete = selectedFolders
    guard !foldersToDelete.isEmpty else { return }

    // ... existing guard checks ...

    showDeletionProgress = true
    deletedItemCount = 0
    deletedSize = 0
    let totalSize = foldersToDelete.reduce(0) { $0 + $1.size }

    Task {
        do {
            try await deleter.delete(folders: foldersToDelete) { [weak self] current, total in
                guard let self else { return }
                Task { @MainActor in
                    self.deletedItemCount = current
                    if current <= foldersToDelete.count {
                        self.currentDeletionItem = foldersToDelete[current - 1].projectName
                        self.deletedSize += foldersToDelete[current - 1].size
                    }
                    self.deletionProgress = Double(current) / Double(total)
                }
            }

            // Success - remove all
            // ... existing code ...
            self.showDeletionProgress = false
        } catch {
            // ... existing error handling ...
            self.showDeletionProgress = false
        }
    }
}
```

3. Add to MainView:

```swift
.sheet(isPresented: $viewModel.showDeletionProgress) {
    DeletionProgressView(
        currentItem: viewModel.currentDeletionItem,
        progress: viewModel.deletionProgress,
        currentIndex: viewModel.deletedItemCount,
        totalItems: viewModel.selectedFolders.count,
        deletedSize: viewModel.deletedSize,
        totalSize: viewModel.selectedSize,
        canCancel: false,
        onCancel: {}
    )
    .interactiveDismissDisabled()
}
```

**Acceptance Criteria:**
- ✅ Shows during deletion
- ✅ Progress updates smoothly
- ✅ Current item name shows
- ✅ Size progress updates
- ✅ Closes automatically on completion

---

### Task 5.4: Visual Polish & Animations (3 hours)

**Goal**: Add professional polish with smooth animations and styling

**Step 1: Add Hover Effects** (45 min)

1. Update `ScanResultsView.swift` table rows:

```swift
.tableStyle(.inset(alternatesRowBackgrounds: true))
.alternatingRowBackgrounds()
```

2. Add hover modifier to buttons:

```swift
.buttonStyle(.borderedProminent)
.controlSize(.large)
.buttonBorderShape(.roundedRectangle(radius: 8))
```

**Step 2: Add Transitions** (60 min)

1. In `MainView.swift`, add transitions between states:

```swift
if viewModel.selectedFolder == nil {
    EmptyStateView(...)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
} else if viewModel.isScanning {
    ScanProgressView(...)
        .transition(.opacity)
} else if !viewModel.scanResults.isEmpty {
    ScanResultsView(...)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
}
```

2. Wrap in:

```swift
Group {
    // ... views ...
}
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedFolder != nil)
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isScanning)
```

**Step 3: Improve Colors & Styling** (45 min)

1. Add extension for project type colors:

```swift
extension ProjectType {
    var color: Color {
        switch self {
        case .android: return .green
        case .iOS: return .blue
        case .swiftPackage: return .orange
        }
    }
}
```

2. Update summary card with better styling
3. Consistent spacing throughout
4. Better dark mode support

**Step 4: Loading States** (30 min)

1. Add skeleton loading for scan progress (optional)
2. Smooth state transitions
3. Better empty states

**Acceptance Criteria:**
- ✅ All transitions are smooth
- ✅ Dark mode looks good
- ✅ Consistent spacing and styling
- ✅ Feels polished and professional

---

## Testing After Phase 5

After completing Phase 5 tasks:

1. **Build and run the app**
2. **Test all new features**:
   - Sort by each column
   - Delete items and see new confirmation/progress dialogs
   - Check animations and transitions
3. **Verify no regressions**
4. **Update CLAUDE.md**
5. **Commit changes**

---

## Next: Phase 8 or Phase 9

After Phase 5 is complete, move to:
- **Phase 8**: Performance Optimization (if app feels slow)
- **Phase 9**: App Icon (if ready for branding)
- **Additional Project Types**: If want more features

See `docs/13-remaining-features-plan.md` for detailed specs on Phase 8 and 9.
