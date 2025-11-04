//
//  ImportSettingsSheet.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 04/11/25.
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
final class ImportSettingsViewModel {
    var importMode: ImportMode = .merge
    var isLoading = false
    var isImporting = false
    var errorMessage: String?
    var loadedExport: SettingsExport?

    private let importer: SettingsImporterProtocol

    init(importer: SettingsImporterProtocol = SettingsImporter()) {
        self.importer = importer
    }

    var canImport: Bool {
        loadedExport != nil && !isImporting
    }

    var previewText: String {
        guard let export = loadedExport else {
            return "No file selected"
        }

        let scanCount = export.scanLocations.count
        let cacheCount = export.customCacheLocations.count
        let total = scanCount + cacheCount

        guard total > 0 else {
            return "File contains no settings"
        }

        var parts: [String] = []
        if scanCount > 0 {
            parts.append("\(scanCount) scan location\(scanCount == 1 ? "" : "s")")
        }
        if cacheCount > 0 {
            parts.append("\(cacheCount) custom cache\(cacheCount == 1 ? "" : "s")")
        }

        return "Importing \(parts.joined(separator: " and "))"
    }

    func selectFile() {
        let panel = NSOpenPanel()
        panel.title = "Import Settings"
        panel.message = "Choose a settings file to import"
        panel.prompt = "Import"
        panel.allowedContentTypes = [.init(filenameExtension: "zdcsettings")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        panel.begin { [weak self] response in
            guard let self = self else { return }
            guard response == .OK, let url = panel.url else { return }

            Task { @MainActor in
                await self.loadSettings(from: url)
            }
        }
    }

    private func loadSettings(from url: URL) async {
        isLoading = true
        errorMessage = nil
        loadedExport = nil

        do {
            let export = try await importer.loadSettings(from: url)
            loadedExport = export
        } catch let error as ZeroDevCleanerError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load settings: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func performImport(onSuccess: @escaping () -> Void) async {
        guard let export = loadedExport else { return }

        isImporting = true
        errorMessage = nil

        await importer.applySettings(export, mode: importMode)

        isImporting = false
        onSuccess()
    }
}

struct ImportSettingsSheet: View {
    @State private var viewModel = ImportSettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "square.and.arrow.down")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text("Import Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()
            }

            // Description
            Text("Import settings from a previously exported file. Choose whether to merge with or replace your current settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // File Selection
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: viewModel.loadedExport != nil ? "checkmark.circle.fill" : "doc.badge.arrow.up")
                        .foregroundStyle(viewModel.loadedExport != nil ? .green : .secondary)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.loadedExport != nil ? "File loaded successfully" : "No file selected")
                            .font(.headline)

                        if let export = viewModel.loadedExport {
                            Text("Version \(export.version) • Exported \(export.exportDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button(viewModel.loadedExport != nil ? "Change File..." : "Select File...") {
                        viewModel.selectFile()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading)
                    .buttonHoverEffect()
                }
                .padding(12)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)

                // Preview
                if let export = viewModel.loadedExport {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contents")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        if !export.scanLocations.isEmpty {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(.blue)
                                    .font(.caption)
                                Text("\(export.scanLocations.count) scan location\(export.scanLocations.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                            }
                        }

                        if !export.customCacheLocations.isEmpty {
                            HStack {
                                Image(systemName: "folder.badge.gearshape")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text("\(export.customCacheLocations.count) custom cache\(export.customCacheLocations.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
            }

            // Import Mode Selection
            if viewModel.loadedExport != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Import Mode")
                        .font(.headline)

                    VStack(spacing: 8) {
                        ImportModeOption(
                            mode: .merge,
                            isSelected: viewModel.importMode == .merge,
                            title: "Merge",
                            description: "Add imported items to your existing settings",
                            icon: "plus.circle"
                        ) {
                            viewModel.importMode = .merge
                        }

                        ImportModeOption(
                            mode: .replace,
                            isSelected: viewModel.importMode == .replace,
                            title: "Replace",
                            description: "Remove all existing settings and use imported ones",
                            icon: "arrow.triangle.2.circlepath"
                        ) {
                            viewModel.importMode = .replace
                        }
                    }
                }
            }

            // Error message
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }

            Spacer()

            Divider()

            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonHoverEffect()

                Spacer()

                Button("Import") {
                    Task {
                        await viewModel.performImport {
                            dismiss()
                        }
                    }
                }
                .disabled(!viewModel.canImport)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .buttonHoverEffect()
            }
        }
        .padding(20)
        .frame(width: 550)
    }
}

// MARK: - Import Mode Option

struct ImportModeOption: View {
    let mode: ImportMode
    let isSelected: Bool
    let title: String
    let description: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.title3)

                Image(systemName: icon)
                    .foregroundStyle(isSelected ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .primary : .secondary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .hoverEffect()
    }
}

#Preview("Initial State") {
    ImportSettingsSheet()
}
