//
//  CustomCacheLocation.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 31/10/25.
//

import Foundation
import SwiftUI

/// Represents a user-defined custom cache location
struct CustomCacheLocation: Identifiable, Codable, Hashable, Sendable {
    /// Unique identifier
    let id: UUID

    /// Display name for the cache location
    var name: String

    /// Full path to the cache directory
    var path: URL

    /// Optional pattern to match within the path (e.g., "*.log", "cache-*")
    var pattern: String?

    /// Whether this location is enabled for scanning
    var isEnabled: Bool

    /// Color for visual identification
    var colorHex: String

    /// Date when this location was added
    let dateAdded: Date

    /// Last time this location was scanned
    var lastScanned: Date?

    init(
        id: UUID = UUID(),
        name: String,
        path: URL,
        pattern: String? = nil,
        isEnabled: Bool = true,
        colorHex: String = "007AFF", // Default blue
        dateAdded: Date = Date(),
        lastScanned: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.pattern = pattern
        self.isEnabled = isEnabled
        self.colorHex = colorHex
        self.dateAdded = dateAdded
        self.lastScanned = lastScanned
    }

    /// SwiftUI Color from hex string
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    /// Icon for custom cache locations
    var iconName: String {
        "folder.badge.gearshape"
    }

    /// Formatted last scanned time
    var formattedLastScanned: String {
        guard let lastScanned = lastScanned else {
            return "Never"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastScanned, relativeTo: Date())
    }

    /// Validates if the path exists and is accessible
    func validate() -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])

        return String(format: "%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}
