//
//  AddCustomCacheSheet.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 01/11/25.
//

import SwiftUI
import AppKit

struct AddCustomCacheSheet: View {
    var customCacheManager: CustomCacheManager
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedPath: URL?
    @State private var pattern: String = ""
    @State private var selectedColor: Color = .blue
    @State private var validationError: String?

    // Predefined colors
    private let availableColors: [(name: String, color: Color)] = [
        ("Blue", .blue),
        ("Green", .green),
        ("Orange", .orange),
        ("Red", .red),
        ("Purple", .purple),
        ("Pink", .pink),
        ("Yellow", .yellow),
        ("Cyan", .cyan),
        ("Indigo", .indigo),
        ("Teal", .teal),
        ("Mint", .mint),
        ("Brown", .brown)
    ]

    private var isValid: Bool {
        // Must have a path selected
        guard selectedPath != nil else { return false }

        // Name must not be empty or just whitespace
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        return true
    }

    private func validatePath() -> String? {
        guard let path = selectedPath else {
            return "Please select a folder"
        }

        // Check if path exists
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path.path, isDirectory: &isDirectory)

        if !exists {
            return "Selected folder does not exist"
        }

        if !isDirectory.boolValue {
            return "Selected path is not a folder"
        }

        return nil
    }

    private func validateName() -> String? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return "Name cannot be empty"
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Custom Cache")
                .font(.title2)
                .fontWeight(.semibold)

            Form {
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Text("Path:")
                    if let path = selectedPath {
                        Text(path.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("No folder selected")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Button("Select Folder") {
                        openFolderPicker()
                    }
                    .buttonStyle(.bordered)
                }

                TextField("Pattern (optional, e.g., *.log)", text: $pattern)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                        ForEach(availableColors, id: \.name) { colorItem in
                            Button {
                                selectedColor = colorItem.color
                            } label: {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(colorItem.color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(selectedColor == colorItem.color ? Color.primary : Color.clear, lineWidth: 3)
                                        )
                                    Text(colorItem.name)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            // Validation Error
            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    // Clear previous errors
                    validationError = nil

                    // Validate
                    if let error = validateName() ?? validatePath() {
                        validationError = error
                        return
                    }

                    guard let path = selectedPath else { return }

                    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let cache = CustomCacheLocation(
                        name: trimmedName,
                        path: path,
                        pattern: pattern.isEmpty ? nil : pattern,
                        colorHex: selectedColor.toHex() ?? "007AFF"
                    )
                    customCacheManager.addLocation(cache)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.defaultAction)
                .buttonHoverEffect()
            }
        }
        .padding()
        .frame(width: 500)
    }

    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Choose a cache folder"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            selectedPath = url
            if name.isEmpty {
                name = url.lastPathComponent
            }
        }
    }
}

#Preview("Empty State") {
    @Previewable @State var manager = CustomCacheManager.shared
    return AddCustomCacheSheet(customCacheManager: manager)
}
