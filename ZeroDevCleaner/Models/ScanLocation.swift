//
//  ScanLocation.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import Foundation

/// Represents a saved scan location that can be scanned automatically
struct ScanLocation: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var path: URL
    var isEnabled: Bool
    var lastScanned: Date?

    init(id: UUID = UUID(), name: String, path: URL, isEnabled: Bool = true, lastScanned: Date? = nil) {
        self.id = id
        self.name = name
        self.path = path
        self.isEnabled = isEnabled
        self.lastScanned = lastScanned
    }

    var formattedLastScanned: String {
        guard let lastScanned else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastScanned, relativeTo: Date())
    }
}
