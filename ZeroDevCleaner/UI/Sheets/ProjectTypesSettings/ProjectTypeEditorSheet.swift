//
//  ProjectTypeEditorSheet.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 28/11/25.
//

import SwiftUI

struct ProjectTypeEditorSheet: View {
    let projectType: ProjectTypeConfig?
    let onSave: (ProjectTypeConfig) -> Void
    let onCancel: () -> Void

    @State private var id: String
    @State private var displayName: String
    @State private var iconName: String
    @State private var color: String
    @State private var folderNames: String
    @State private var validationMode: ValidationMode
    @State private var maxSearchDepth: String
    @State private var requiredFilesAnyOf: String
    @State private var requiredFilesAllOf: String
    @State private var requiredDirectoriesAnyOf: String
    @State private var requiredDirectoriesAllOf: String
    @State private var fileExtensions: String

    @State private var showValidationError = false
    @State private var validationError: String = ""
    @State private var showIconPicker = false

    init(projectType: ProjectTypeConfig?, onSave: @escaping (ProjectTypeConfig) -> Void, onCancel: @escaping () -> Void) {
        self.projectType = projectType
        self.onSave = onSave
        self.onCancel = onCancel

        // Initialize state from existing project type or defaults
        _id = State(initialValue: projectType?.id ?? "")
        _displayName = State(initialValue: projectType?.displayName ?? "")
        _iconName = State(initialValue: projectType?.iconName ?? "folder.fill")
        _color = State(initialValue: projectType?.color ?? "#808080")
        _folderNames = State(initialValue: projectType?.folderNames.joined(separator: ", ") ?? "")
        _validationMode = State(initialValue: projectType?.validation.mode ?? .alwaysValid)
        _maxSearchDepth = State(initialValue: projectType?.validation.maxSearchDepth.map { String($0) } ?? "")
        _requiredFilesAnyOf = State(initialValue: projectType?.validation.requiredFiles?.anyOf?.joined(separator: ", ") ?? "")
        _requiredFilesAllOf = State(initialValue: projectType?.validation.requiredFiles?.allOf?.joined(separator: ", ") ?? "")
        _requiredDirectoriesAnyOf = State(initialValue: "")
        _requiredDirectoriesAllOf = State(initialValue: projectType?.validation.requiredDirectories?.allOf.joined(separator: ", ") ?? "")
        _fileExtensions = State(initialValue: projectType?.validation.fileExtensions?.joined(separator: ", ") ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(projectType == nil ? "Add Project Type" : "Edit Project Type")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .buttonHoverEffect()

                Button("Save") {
                    saveProjectType()
                }
                .buttonStyle(.borderedProminent)
                .buttonHoverEffect()
                .disabled(!isValid)
            }
            .padding()

            Divider()

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Basic Information
                    GroupBox("Basic Information") {
                        VStack(alignment: .leading, spacing: 12) {
                            // ID
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ID")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                TextField("e.g., android, iOS, flutter", text: $id)
                                    .textFieldStyle(.roundedBorder)
                                    .disabled(projectType != nil) // Can't change ID when editing
                                Text("Unique identifier (lowercase, no spaces)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            // Display Name
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Display Name")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                TextField("e.g., Android, iOS/Xcode", text: $displayName)
                                    .textFieldStyle(.roundedBorder)
                            }

                            // Icon Name
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SF Symbol Icon")
                                    .font(.caption)
                                    .fontWeight(.semibold)

                                HStack(spacing: 8) {
                                    TextField("e.g., folder.fill, app.badge.fill", text: $iconName)
                                        .textFieldStyle(.roundedBorder)

                                    Button {
                                        showIconPicker.toggle()
                                    } label: {
                                        Label("Browse", systemImage: "square.grid.3x3")
                                    }
                                    .buttonStyle(.bordered)
                                    .buttonHoverEffect()

                                    // Preview
                                    Image(systemName: iconName.isEmpty ? "questionmark" : iconName)
                                        .font(.title2)
                                        .foregroundStyle(Color(hex: color) ?? .gray)
                                        .frame(width: 40, height: 28)
                                }
                            }

                            // Color
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Color")
                                    .font(.caption)
                                    .fontWeight(.semibold)

                                // Color grid
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                                    ForEach(ProjectTypeEditorSheet.predefinedColors, id: \.self) { colorHex in
                                        Button {
                                            color = colorHex
                                        } label: {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color(hex: colorHex) ?? .gray)
                                                    .frame(height: 32)

                                                if color == colorHex {
                                                    Image(systemName: "checkmark")
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                        .foregroundStyle(.white)
                                                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .hoverEffect(scale: 1.1, brightness: 0.1)
                                    }
                                }

                                // Custom color input
                                HStack(spacing: 8) {
                                    TextField("Custom hex color", text: $color)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.caption)

                                    // Preview
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: color) ?? .gray)
                                        .frame(width: 32, height: 28)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }

                            // Folder Names
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Folder Names")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                TextField("e.g., build, .build", text: $folderNames)
                                    .textFieldStyle(.roundedBorder)
                                Text("Comma-separated list of folder names to detect")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Validation Configuration
                    GroupBox("Validation Configuration") {
                        VStack(alignment: .leading, spacing: 12) {
                            // Validation Mode
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Validation Mode")
                                    .font(.caption)
                                    .fontWeight(.semibold)

                                Picker("", selection: $validationMode) {
                                    ForEach(ValidationMode.allCases, id: \.self) { mode in
                                        Text(mode.displayName).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)

                                Text(validationMode.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                            }

                            // Mode-specific fields
                            switch validationMode {
                            case .alwaysValid:
                                Text("No additional configuration required")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .italic()

                            case .parentDirectory:
                                parentDirectoryFields

                            case .parentHierarchy:
                                parentHierarchyFields

                            case .directoryEnumeration:
                                directoryEnumerationFields
                            }
                        }
                    }
                }
                .padding()
            }

            // Validation Error
            if showValidationError {
                Divider()

                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)

                    Text(validationError)
                        .font(.caption)
                        .foregroundStyle(.red)

                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
            }
        }
        .frame(width: 700, height: 700)
        .sheet(isPresented: $showIconPicker) {
            SFSymbolPickerSheet(selectedIcon: $iconName)
        }
    }

    // MARK: - Mode-Specific Fields

    @ViewBuilder
    private var parentDirectoryFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Required Files (Any Of)")
                    .font(.caption)
                    .fontWeight(.semibold)
                TextField("e.g., Package.swift, pubspec.yaml", text: $requiredFilesAnyOf)
                    .textFieldStyle(.roundedBorder)
                Text("At least one of these files must exist in parent directory")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Required Files (All Of)")
                    .font(.caption)
                    .fontWeight(.semibold)
                TextField("Optional: files that must all exist", text: $requiredFilesAllOf)
                    .textFieldStyle(.roundedBorder)
                Text("All of these files must exist in parent directory")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Required Directories (All Of)")
                    .font(.caption)
                    .fontWeight(.semibold)
                TextField("Optional: directory names that must all exist", text: $requiredDirectoriesAllOf)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    @ViewBuilder
    private var parentHierarchyFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Max Search Depth")
                    .font(.caption)
                    .fontWeight(.semibold)
                TextField("e.g., 5", text: $maxSearchDepth)
                    .textFieldStyle(.roundedBorder)
                Text("How many levels up to search (1-10)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Required Files (Any Of)")
                    .font(.caption)
                    .fontWeight(.semibold)
                TextField("e.g., build.gradle, settings.gradle", text: $requiredFilesAnyOf)
                    .textFieldStyle(.roundedBorder)
                Text("At least one of these files must exist in parent hierarchy")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var directoryEnumerationFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("File Extensions")
                    .font(.caption)
                    .fontWeight(.semibold)
                TextField("e.g., xcodeproj, xcworkspace", text: $fileExtensions)
                    .textFieldStyle(.roundedBorder)
                Text("Search for files with these extensions in parent directory")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        !id.isEmpty &&
        !displayName.isEmpty &&
        !iconName.isEmpty &&
        !color.isEmpty &&
        !folderNames.isEmpty
    }

    private func saveProjectType() {
        // Parse folder names
        let parsedFolderNames = folderNames
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !parsedFolderNames.isEmpty else {
            validationError = "At least one folder name is required"
            showValidationError = true
            return
        }

        // Build validation rules based on mode
        let validation: ValidationRules

        switch validationMode {
        case .alwaysValid:
            validation = ValidationRules(
                mode: .alwaysValid,
                maxSearchDepth: nil,
                requiredFiles: nil,
                requiredDirectories: nil,
                fileExtensions: nil
            )

        case .parentDirectory:
            let filesAnyOf = parseCommaSeparated(requiredFilesAnyOf)
            let filesAllOf = parseCommaSeparated(requiredFilesAllOf)
            let dirsAllOf = parseCommaSeparated(requiredDirectoriesAllOf)

            validation = ValidationRules(
                mode: .parentDirectory,
                maxSearchDepth: nil,
                requiredFiles: (!filesAnyOf.isEmpty || !filesAllOf.isEmpty) ? FileRequirement(
                    anyOf: filesAnyOf.isEmpty ? nil : filesAnyOf,
                    allOf: filesAllOf.isEmpty ? nil : filesAllOf
                ) : nil,
                requiredDirectories: !dirsAllOf.isEmpty ? DirectoryRequirement(allOf: dirsAllOf) : nil,
                fileExtensions: nil
            )

        case .parentHierarchy:
            let depth = Int(maxSearchDepth)
            let filesAnyOf = parseCommaSeparated(requiredFilesAnyOf)

            validation = ValidationRules(
                mode: .parentHierarchy,
                maxSearchDepth: depth,
                requiredFiles: !filesAnyOf.isEmpty ? FileRequirement(anyOf: filesAnyOf, allOf: nil) : nil,
                requiredDirectories: nil,
                fileExtensions: nil
            )

        case .directoryEnumeration:
            let extensions = parseCommaSeparated(fileExtensions)

            validation = ValidationRules(
                mode: .directoryEnumeration,
                maxSearchDepth: nil,
                requiredFiles: nil,
                requiredDirectories: nil,
                fileExtensions: extensions.isEmpty ? nil : extensions
            )
        }

        let newProjectType = ProjectTypeConfig(
            id: id,
            displayName: displayName,
            iconName: iconName,
            color: color,
            folderNames: parsedFolderNames,
            validation: validation
        )

        onSave(newProjectType)
    }

    private func parseCommaSeparated(_ string: String) -> [String] {
        string
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Predefined Colors

    static let predefinedColors = [
        "#007AFF",  // Blue
        "#34C759",  // Green
        "#FF9500",  // Orange
        "#FF3B30",  // Red
        "#AF52DE",  // Purple
        "#FF2D55",  // Pink
        "#FFCC00",  // Yellow
        "#5AC8FA",  // Cyan
        "#5856D6",  // Indigo
        "#30B0C7",  // Teal
        "#00C7BE",  // Mint
        "#A2845E"   // Brown
    ]
}

// MARK: - ValidationMode Extensions

extension ValidationMode: CaseIterable {
    static var allCases: [ValidationMode] {
        [.alwaysValid, .parentDirectory, .parentHierarchy, .directoryEnumeration]
    }

    var displayName: String {
        switch self {
        case .alwaysValid: return "Always Valid"
        case .parentDirectory: return "Parent Directory"
        case .parentHierarchy: return "Parent Hierarchy"
        case .directoryEnumeration: return "Directory Enumeration"
        }
    }

    var description: String {
        switch self {
        case .alwaysValid:
            return "No validation required - folder is always considered valid"
        case .parentDirectory:
            return "Check for specific files/directories in immediate parent directory"
        case .parentHierarchy:
            return "Search up directory tree for validation files with max depth limit"
        case .directoryEnumeration:
            return "Look for files with specific extensions in parent directory tree"
        }
    }
}

#Preview {
    ProjectTypeEditorSheet(
        projectType: nil,
        onSave: { _ in },
        onCancel: { }
    )
}
