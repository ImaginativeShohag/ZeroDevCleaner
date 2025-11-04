//
//  EditCustomCacheSheet.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 01/11/25.
//

import SwiftUI

struct EditCustomCacheSheet: View {
    let cache: CustomCacheLocation
    var customCacheManager: CustomCacheManager
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var pattern: String
    @State private var selectedColor: Color
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
        // Name must not be empty or just whitespace
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty
    }

    private func validateName() -> String? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return "Name cannot be empty"
        }
        return nil
    }

    init(cache: CustomCacheLocation, customCacheManager: CustomCacheManager) {
        self.cache = cache
        self.customCacheManager = customCacheManager
        _name = State(initialValue: cache.name)
        _pattern = State(initialValue: cache.pattern ?? "")
        _selectedColor = State(initialValue: cache.color)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Custom Cache")
                .font(.title2)
                .fontWeight(.semibold)

            Form {
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Text("Path:")
                    Text(cache.path.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
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

                Button("Save") {
                    // Clear previous errors
                    validationError = nil

                    // Validate
                    if let error = validateName() {
                        validationError = error
                        return
                    }

                    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let updatedCache = CustomCacheLocation(
                        id: cache.id,
                        name: trimmedName,
                        path: cache.path,
                        pattern: pattern.isEmpty ? nil : pattern,
                        isEnabled: cache.isEnabled,
                        colorHex: selectedColor.toHex() ?? cache.colorHex,
                        dateAdded: cache.dateAdded,
                        lastScanned: cache.lastScanned
                    )
                    customCacheManager.updateLocation(updatedCache)
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
}

#Preview("Edit Cache") {
    @Previewable @State var manager = CustomCacheManager.shared
    let cache = CustomCacheLocation(
        name: "Build Artifacts",
        path: URL(fileURLWithPath: "/Users/test/Projects/build"),
        pattern: "*.log",
        colorHex: "FF5733"
    )
    return EditCustomCacheSheet(cache: cache, customCacheManager: manager)
}
