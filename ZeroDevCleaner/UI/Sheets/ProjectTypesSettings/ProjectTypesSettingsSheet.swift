//
//  ProjectTypesSettingsSheet.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 28/11/25.
//

import SwiftUI

struct ProjectTypesSettingsSheet: View {
    @Bindable var viewModel: ProjectTypesSettingsViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Build Folder Configuration")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Manage project types for build folder detection")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()

            Divider()

            // Toolbar
            HStack {
                Button {
                    viewModel.addProjectType()
                } label: {
                    Label("Add Type", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.bordered)
                .buttonHoverEffect()

                Spacer()

                Button {
                    viewModel.confirmReset()
                } label: {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .buttonHoverEffect()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Project Types List
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading configuration...")
                    Spacer()
                }
            } else if viewModel.projectTypes.isEmpty {
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)

                    Text("No Project Types Configured")
                        .font(.headline)

                    Text("Add project types to detect build folders")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        viewModel.addProjectType()
                    } label: {
                        Label("Add Project Type", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonHoverEffect()

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Info banner
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Detection Order Matters")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text("Project types are checked in the order shown. Drag to reorder. First match wins.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .padding()

                        // List Header
                        HStack(spacing: 12) {
                            Text("#")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .frame(width: 30)

                            Text("Project Type")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 150, alignment: .leading)

                            Text("Folder Names")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 100, alignment: .leading)

                            Text("Validation Mode")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 120, alignment: .leading)

                            Spacer()

                            Text("Actions")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .frame(width: 80)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(nsColor: .controlBackgroundColor))

                        Divider()

                        // Project Types
                        ForEach(Array(viewModel.projectTypes.enumerated()), id: \.element.id) { index, projectType in
                            ProjectTypeRow(
                                index: index + 1,
                                projectType: projectType,
                                onEdit: { viewModel.editProjectType(projectType) },
                                onDelete: { viewModel.deleteProjectType(projectType) }
                            )
                            .contentShape(Rectangle())

                            if index < viewModel.projectTypes.count - 1 {
                                Divider()
                                    .padding(.leading, 50)
                            }
                        }
                    }
                }
            }

            // Error/Success Messages
            if let errorMessage = viewModel.errorMessage {
                Divider()

                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)

                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)

                    Spacer()

                    Button("Dismiss") {
                        viewModel.errorMessage = nil
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                .padding()
                .background(Color.red.opacity(0.1))
            }

            if viewModel.showSuccessMessage {
                Divider()

                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Text(viewModel.successMessage)
                        .font(.caption)
                        .foregroundStyle(.green)

                    Spacer()

                    Button("Dismiss") {
                        viewModel.showSuccessMessage = false
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                .padding()
                .background(Color.green.opacity(0.1))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            viewModel.loadConfiguration()
        }
        .alert("Reset to Defaults", isPresented: $viewModel.showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task {
                    await viewModel.resetToDefaults()
                }
            }
        } message: {
            Text("This will restore the default build folder configuration. Your custom project types will be lost. This action cannot be undone.")
        }
        .sheet(isPresented: $viewModel.showEditor) {
            if let editingType = viewModel.editingProjectType {
                ProjectTypeEditorSheet(
                    projectType: editingType,
                    onSave: { viewModel.saveProjectType($0) },
                    onCancel: { viewModel.showEditor = false }
                )
            } else {
                ProjectTypeEditorSheet(
                    projectType: nil,
                    onSave: { viewModel.saveProjectType($0) },
                    onCancel: { viewModel.showEditor = false }
                )
            }
        }
    }
}

// MARK: - Project Type Row

private struct ProjectTypeRow: View {
    let index: Int
    let projectType: ProjectTypeConfig
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Index
            Text("\(index)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 30)

            // Project Type
            HStack(spacing: 8) {
                Image(systemName: projectType.iconName)
                    .foregroundStyle(Color(hex: projectType.color) ?? .gray)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(projectType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("ID: \(projectType.id)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(minWidth: 150, alignment: .leading)

            // Folder Names
            Text(projectType.folderNames.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(minWidth: 100, alignment: .leading)

            // Validation Mode
            HStack(spacing: 4) {
                Image(systemName: validationModeIcon(projectType.validation.mode))
                    .font(.caption)
                    .foregroundStyle(.blue)

                Text(projectType.validation.mode.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 120, alignment: .leading)

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .help("Edit")
                .hoverEffect(scale: 1.1, brightness: 0.1)

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Delete")
                .hoverEffect(scale: 1.1, brightness: 0.1)
            }
            .frame(width: 80)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .rowHoverEffect()
    }

    private func validationModeIcon(_ mode: ValidationMode) -> String {
        switch mode {
        case .alwaysValid:
            return "checkmark.circle"
        case .parentDirectory:
            return "folder"
        case .parentHierarchy:
            return "arrow.up.doc"
        case .directoryEnumeration:
            return "doc.text.magnifyingglass"
        }
    }
}

#Preview {
    @Previewable @State var viewModel = ProjectTypesSettingsViewModel()
    ProjectTypesSettingsSheet(viewModel: viewModel)
}
