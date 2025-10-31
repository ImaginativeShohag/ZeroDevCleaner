# ZeroDevCleaner - Development Guidelines

## Project Overview

ZeroDevCleaner is a macOS application that helps developers identify and remove build artifacts, caches, and temporary files. It supports multiple project types (Android, iOS, Swift Package, Flutter, Node.js, Rust, Python) and system caches (DerivedData, Xcode Archives, Device Support, Documentation Cache, Gradle, CocoaPods, npm, Yarn, Carthage).

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
- Avoid blocking the main thread
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

## Project State

### Current Status
- Core app complete and functional
- 60+ tests passing
- Zero build warnings
- Ready for production use

### Key Features
- Multi-location scanning with persistent settings
- Static cache location detection (9 types)
- Tabbed interface (Build Folders / System Caches)
- Statistics tracking with SwiftData
- Intelligent archive and device name parsing
- Collapsible sub-items with individual selection
- Full keyboard shortcuts support

### Supported Project Types (7)
1. Android (`build/`)
2. iOS (`build/`)
3. Swift Package (`.build/`)
4. Flutter (`build/`)
5. Node.js (`node_modules/`)
6. Rust (`target/`)
7. Python (`__pycache__/`, `venv/`, etc.)

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