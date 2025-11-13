# ZeroDevCleaner - Development Guidelines

## Project Overview

ZeroDevCleaner is a macOS application that helps developers identify and remove build artifacts, caches, and temporary files. It supports multiple project types (Android, iOS, Swift Package, Flutter, Node.js, Rust, Python, Go, Java/Maven, Ruby, .NET, Unity) and system caches (DerivedData, Xcode Archives, Device Support, Documentation Cache, Gradle, CocoaPods, npm, Yarn, Carthage).

## Technical Specifications

- **Swift**: 6.0 with strict concurrency enabled
- **Target**: macOS 15.0+
- **Architecture**: SwiftUI + @Observable + Structured Concurrency + SwiftData
- **Frameworks**: Swift Charts for data visualization
- **Dependencies**: No third-party dependencies
- **Test Coverage**: Maintain >80% test coverage

## Coding Guidelines

### Naming Conventions

Follow these naming conventions for SwiftUI components:
- **Screens**: End with `Screen` (e.g., `HomeScreen`)
- **Sheets**: End with `Sheet` (e.g., `SettingsSheet`)
- **Alerts**: End with `Alert` (e.g., `ConfirmAlert`)
- **Components**: Can end with `View` (e.g., `StatsSummaryCardView`)

### Architecture Patterns

1. **MVVM Pattern**: Use ViewModels with `@Observable` for state management
2. **Protocol-Oriented**: Define protocols for all services to enable testability
3. **Dependency Injection**: Pass dependencies through initializers, not globals (except singletons)
4. **Actor Isolation**: Use `@MainActor` for UI-related classes, `actor` for services
5. **No ViewModel Passing**: Never pass ViewModels to components; keep components reusable and dummy

### Code Organization

```
ZeroDevCleaner/
├── Models/              # Data models (BuildFolder, StaticLocation, etc.)
├── Services/            # Business logic (FileScanner, FileDeleter, StaticLocationScanner)
├── ViewModels/          # State management (@Observable ViewModels), Shared ViewModels
├── UI/                  # SwiftUI views organized by feature
│   ├── Components/      # Reusable UI components
│   ├── Screens/         # Top-level screen views with their ViewModels
│   └── Sheets/          # Modal sheets
└── Utils/               # Utilities and extensions
```

## Development Best Practices

### Concurrency

- Use Swift's structured concurrency (`async`/`await`)
- Avoid `Task {}` unless necessary; prefer structured task groups
- Mark UI-related code with `@MainActor`
- Use `@unchecked Sendable` only when necessary for SwiftData models

### Error Handling

- Use custom `ZeroDevCleanerError` enum for all app errors
- Provide user-friendly error descriptions and recovery suggestions
- Log errors for debugging but show clean messages to users
- Handle partial failures gracefully (e.g., partial deletion failures)

### Testing

- Write unit tests for all ViewModels and Services
- Write integration tests for complete user workflows
- Use mock services implementing protocols for testing
- Ensure all tests pass before committing
- Test error cases and edge cases

### Performance

- Use memoization/caching for expensive operations (sort, filter)
- Invalidate caches when source data changes
- Avoid blocking the main thread - use `Task.detached` for expensive computations
- Pre-sort and pre-cache data before UI updates to prevent freezing
- Use progress handlers for long-running operations

## Commit Guidelines

### Commit Message Format

Follow conventional commits format:
```
<type>: <description>

[optional body]
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`

Examples:
- `feat: add support for Flutter project detection`
- `fix: resolve memory leak in file scanner`
- `refactor: convert RecentFoldersManager to singleton`
- `test: add integration tests for deletion workflow`
- `docs: update README with installation instructions`

### Important Notes

- **Never include AI signatures** in commit messages (no "Generated with Claude Code" or similar)
- Always update this CLAUDE.md file after significant commits
- Ask for clarification if requirements are ambiguous
- Maintain clean git history with descriptive commit messages
- The ViewModel related to a Screen will be at the same directory
- Initialize ViewModel only in a Screen or Sheet view.
- Don't pass any viewmodel to any sub view. Sub view refers to non Screen or Sheet views.

## Project State

### Current Status
- Core app complete and functional
- **90+ tests passing** (all unit and integration tests)
- Zero build warnings
- Ready for production use

### Recent Enhancements (November 2025)

**Phase 1 - Core Features:**
1. **Quick Filters** - Preset filtering for large files and old items
2. **Additional Project Types** - Added Go, Java/Maven, Ruby, .NET, Unity support (5 new types)
3. **Age Indicators** - Visual warnings for items not modified in 30+ days
4. **Custom Cache Locations** - Full CRUD system for user-defined cache paths with:
   - Pattern matching support for filtering sub-items
   - Predefined color selection (12 colors)
   - Custom name, icon, and color display in UI
   - Automatic scanning integrated into workflow
   - Proper UI rendering with all metadata
   - **Collapsible sub-items** - Custom caches behave like DerivedData with expandable children
5. **Enhanced Statistics on Home** - Statistics dashboard integrated into home view with Monthly/Yearly/Cumulative trend visualization, date range filtering, and project breakdown

**Phase 2 - Polish & Security (Latest):**
6. **Scanner Security Hardening** - Critical security fixes to prevent scanning outside designated directories:
   - Resolves symlinks to canonical paths before scanning
   - Checks symlinks BEFORE checking if directory (prevents following malicious links)
   - Boundary checking ensures scanner stays within root directory
   - Logs warnings when attempting to scan outside bounds
7. **UI Consistency** - Unified button hover effects across entire application
8. **Enhanced Type Column** - Shows folder name with project type (e.g., "Node.js (node_modules)")
9. **Form Validations** - Comprehensive validation for custom cache settings with inline error messages
10. **Code Organization** - Extracted child sheets to separate files for better maintainability
11. **Preview Variations** - Added multiple preview states for all components (empty, mid-progress, complete states)

**Phase 3 - Settings Management (November 2025):**
12. **Settings Export/Import** - Complete backup and restore functionality for user configurations:
   - Export settings to `.zdcsettings` JSON file with version tracking
   - Selective export - choose scan locations, custom caches, or both
   - Import with preview - see what will be imported before applying
   - Merge mode - add imported settings to existing ones (no duplicates)
   - Replace mode - completely replace current settings with imported ones
   - Version validation to ensure compatibility
   - Comprehensive error handling for invalid files
   - Keyboard shortcuts (⌘E to export, ⌘I to import)
   - Full test coverage with unit and integration tests

**Phase 4 - Code Refactoring (November 2025):**
13. **FilterManager** - Extracted filtering logic from MainViewModel into dedicated FilterManager:
   - Separated FilterType and ComparisonOperator enums into FilterManager
   - Delegated all filter-related properties and state management
   - Improved code organization and maintainability
   - Enhanced separation of concerns for better testability
   - Maintained backward compatibility with existing filter API

### Key Features
- Multi-location scanning with persistent settings
- **Settings export/import** - Backup and restore scan locations and custom caches across devices
- **Custom cache locations** - Add/edit/delete user-defined cache paths with pattern matching, color coding, and validation
- Static cache location detection (9 types)
- Tabbed interface (Build Folders / System Caches)
- **Quick filter presets** - Instant filtering with preset chips (All, Large >1GB, Huge >5GB, Old >30 days, Recent <7 days)
- **Age-based visual indicators** - Warning badges showing items not modified in 30+ days with days-since-modification tooltips
- **Enhanced statistics dashboard**:
  - **Date range filtering** - View Last 7/30/90 days, Last Year, or All Time
  - **Project breakdown visualization** - See which project types (Android, iOS, etc.) consume most space
  - **Multiple chart view types** - Daily, Monthly, Yearly aggregations, and Cumulative trend lines
  - **Interactive charts** - Bar charts for periodic views, Line+Area charts for cumulative tracking
  - **Expandable session details** - Click to view items deleted in each cleaning session
- Statistics persistence with SwiftData for historical tracking
- Hero-first home layout with prominent scan action
- Intelligent archive and device name parsing
- Collapsible sub-items with individual selection
- Full keyboard shortcuts support
- Background pre-sorting for smooth UI performance

### UI Components (Enhanced)
- **EmptyStateView (Home)** - Integrated statistics dashboard with:
  - Date range picker (Last 7/30/90 days, Last Year, All Time)
  - Chart view type selector (Daily/Monthly/Yearly/Cumulative)
  - Summary cards (Total Cleaned, Sessions, Items Deleted, Average per Session)
  - Project breakdown section showing space usage by project type
  - Interactive bar and line charts with trend visualization
- **SettingsSheet** - Tabbed interface for Scan Locations and Custom Caches with drag-and-drop support
- **QuickFiltersBar** - Clickable filter chips with icons for instant result filtering
- **ScanResultsView** - Enhanced with age warning badges and quick filters integration
- **Custom Cache Management** - Full CRUD operations with:
  - Add/Edit sheets with folder picker and pattern matching
  - Grid of 12 predefined colors (Blue, Green, Orange, Red, Purple, Pink, Yellow, Cyan, Indigo, Teal, Mint, Brown)
  - Row-level enable/disable toggles
  - Validation for path accessibility
  - Last scanned timestamp tracking
  - Automatic scanning during main scan workflow

### Supported Project Types (12)
1. Android (`build/`)
2. iOS (`build/`)
3. Swift Package (`.build/`)
4. Flutter (`build/`)
5. Node.js (`node_modules/`)
6. Rust (`target/`)
7. Python (`__pycache__/`, `venv/`, etc.)
8. **Go (`vendor/`)**
9. **Java/Maven (`target/`)**
10. **Ruby (`vendor/`)**
11. **.NET (`bin/`, `obj/`)**
12. **Unity (`Library/`, `Temp/`)**

### System Cache Locations (9)
1. DerivedData
2. Xcode Archives
3. iOS Device Support
4. Xcode Documentation Cache
5. Gradle Cache
6. CocoaPods Cache
7. npm Cache
8. Yarn Cache
9. Carthage Cache

## For AI Agents

When working on this project:

1. **Read this file** before starting any work
2. **Follow naming conventions** strictly for consistency
3. **Never pass ViewModels** to reusable components
4. **Write tests** for new features before marking them complete
5. **Update this file** after implementing significant features
6. **Ask for clarification** when requirements are ambiguous
7. **Maintain code quality** - prefer clarity over cleverness
8. **Use descriptive names** for variables, methods, and types
9. **Document complex logic** with inline comments
10. **Run tests** before committing to ensure nothing breaks