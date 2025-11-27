//
//  ProjectTypesSettingsViewModel.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 28/11/25.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class ProjectTypesSettingsViewModel {
    var projectTypes: [ProjectTypeConfig] = []
    var isLoading = false
    var errorMessage: String?
    var showSuccessMessage = false
    var successMessage: String = ""
    var showResetConfirmation = false
    var showEditor = false
    var editingProjectType: ProjectTypeConfig?

    private let configurationManager: ConfigurationManager

    init(configurationManager: ConfigurationManager = .shared) {
        self.configurationManager = configurationManager
    }

    // MARK: - Load Configuration

    func loadConfiguration() {
        isLoading = true
        errorMessage = nil

        do {
            let config = try configurationManager.loadConfiguration()
            projectTypes = config.projectTypes
        } catch {
            errorMessage = "Failed to load configuration: \(error.localizedDescription)"
            SuperLog.e("Failed to load configuration: \(error)")
        }

        isLoading = false
    }

    // MARK: - Save Configuration

    func saveConfiguration() {
        isLoading = true
        errorMessage = nil

        do {
            let config = BuildFolderConfiguration(
                version: "1.0",
                projectTypes: projectTypes
            )

            // Validate before saving
            let warnings = configurationManager.validateConfiguration(config)
            if !warnings.isEmpty {
                errorMessage = "Configuration has warnings:\n" + warnings.joined(separator: "\n")
                SuperLog.w("Configuration warnings: \(warnings)")
            }

            try configurationManager.saveConfiguration(config)
            showSuccessMessage = true
            successMessage = "Configuration saved successfully"
            SuperLog.i("Configuration saved successfully")
        } catch {
            errorMessage = "Failed to save configuration: \(error.localizedDescription)"
            SuperLog.e("Failed to save configuration: \(error)")
        }

        isLoading = false
    }

    // MARK: - Reset to Defaults

    func confirmReset() {
        showResetConfirmation = true
    }

    func resetToDefaults() async {
        isLoading = true
        errorMessage = nil
        showResetConfirmation = false

        do {
            try await configurationManager.resetToDefaults()
            loadConfiguration()
            showSuccessMessage = true
            successMessage = "Configuration reset to defaults"
            SuperLog.i("Configuration reset to defaults")
        } catch {
            errorMessage = "Failed to reset configuration: \(error.localizedDescription)"
            SuperLog.e("Failed to reset configuration: \(error)")
        }

        isLoading = false
    }

    // MARK: - Add/Edit/Delete Project Types

    func addProjectType() {
        editingProjectType = nil
        showEditor = true
    }

    func editProjectType(_ projectType: ProjectTypeConfig) {
        editingProjectType = projectType
        showEditor = true
    }

    func deleteProjectType(_ projectType: ProjectTypeConfig) {
        projectTypes.removeAll { $0.id == projectType.id }
        saveConfiguration()
    }

    func saveProjectType(_ projectType: ProjectTypeConfig) {
        if let index = projectTypes.firstIndex(where: { $0.id == projectType.id }) {
            // Update existing
            projectTypes[index] = projectType
        } else {
            // Add new
            projectTypes.append(projectType)
        }

        saveConfiguration()
        showEditor = false
        editingProjectType = nil
    }

    // MARK: - Reorder

    func moveProjectType(from source: IndexSet, to destination: Int) {
        projectTypes.move(fromOffsets: source, toOffset: destination)
        saveConfiguration()
    }
}
