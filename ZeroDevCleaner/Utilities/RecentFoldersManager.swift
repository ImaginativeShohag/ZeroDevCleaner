//
//  RecentFoldersManager.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation
import SwiftUI

/// Manages recently scanned folders with UserDefaults persistence
@MainActor
@Observable
final class RecentFoldersManager: Sendable {
    /// Shared singleton instance
    static let shared = RecentFoldersManager()

    /// Maximum number of recent folders to keep
    private static let maxRecentFolders = 5

    /// UserDefaults key for storing recent folders
    private static let recentFoldersKey = "recent_folders"

    /// Private initializer to enforce singleton pattern
    private init() {}

    /// Recent folders list (up to 5 most recent)
    var recentFolders: [URL] {
        get {
            // Load from UserDefaults
            guard let data = UserDefaults.standard.data(forKey: Self.recentFoldersKey),
                  let urls = try? JSONDecoder().decode([URL].self, from: data) else {
                return []
            }

            // Filter out non-existent paths
            return urls.filter { url in
                FileManager.default.fileExists(atPath: url.path)
            }
        }
        set {
            // Keep only first 5 unique items, preserving order
            let unique = newValue.reduce(into: [URL]()) { result, url in
                if !result.contains(url) {
                    result.append(url)
                }
            }

            // Limit to max recent folders
            let limited = Array(unique.prefix(Self.maxRecentFolders))

            // Save to UserDefaults
            if let data = try? JSONEncoder().encode(limited) {
                UserDefaults.standard.set(data, forKey: Self.recentFoldersKey)
            }
        }
    }

    /// Adds a folder to the recent list (moves to front if already exists)
    func addFolder(_ url: URL) {
        var current = recentFolders

        // Remove if exists
        current.removeAll { $0 == url }

        // Add to front
        current.insert(url, at: 0)

        // Update
        recentFolders = current
    }

    /// Clears all recent folders
    func clearAll() {
        recentFolders = []
    }

    /// Removes a specific folder from recent list
    func removeFolder(_ url: URL) {
        var current = recentFolders
        current.removeAll { $0 == url }
        recentFolders = current
    }
}
