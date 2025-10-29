//
//  PermissionManager.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation
import AppKit

/// Manages macOS permissions, specifically Full Disk Access
@MainActor
final class PermissionManager: Sendable {
    /// Shared singleton instance
    static let shared = PermissionManager()

    private init() {}

    /// Checks if the app has Full Disk Access permission
    ///
    /// This attempts to read a known protected file to determine if
    /// Full Disk Access has been granted. Without this permission,
    /// the app cannot scan most user directories.
    ///
    /// - Returns: true if Full Disk Access is granted, false otherwise
    func hasFullDiskAccess() -> Bool {
        // Try to access a known protected location
        // Safari's history database requires Full Disk Access
        let testPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Safari/History.db")

        return FileManager.default.isReadableFile(atPath: testPath.path)
    }

    /// Opens System Settings to the Full Disk Access pane
    ///
    /// This opens the Privacy & Security settings where users can
    /// grant Full Disk Access to the app. The user will need to:
    /// 1. Find ZeroDevCleaner in the list
    /// 2. Toggle it on
    /// 3. Return to the app
    func requestFullDiskAccess() {
        // URL scheme to open System Settings to Full Disk Access
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }

    /// Reveals the app bundle location in Finder
    ///
    /// This helps users find the app to add it to Full Disk Access settings.
    /// The app will be highlighted in Finder after calling this method.
    func revealAppInFinder() {
        guard let bundlePath = Bundle.main.bundleURL.path as String? else { return }
        NSWorkspace.shared.selectFile(bundlePath, inFileViewerRootedAtPath: "")
    }

    /// Checks if a specific path is accessible
    ///
    /// - Parameter path: The URL to check
    /// - Returns: true if the path can be read, false otherwise
    func canAccessPath(_ path: URL) -> Bool {
        return FileManager.default.isReadableFile(atPath: path.path)
    }
}
