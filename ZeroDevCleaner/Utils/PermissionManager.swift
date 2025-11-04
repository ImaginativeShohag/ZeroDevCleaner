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
    /// This attempts to read known protected locations to determine if
    /// Full Disk Access has been granted. Without this permission,
    /// the app cannot scan most user directories.
    ///
    /// - Returns: true if Full Disk Access is granted, false otherwise
    func hasFullDiskAccess() -> Bool {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser

        // Try multiple protected locations to ensure reliable detection
        let protectedPaths = [
            homeDir.appendingPathComponent("Library/Safari/History.db"),
            homeDir.appendingPathComponent("Library/Mail"),
            homeDir.appendingPathComponent("Library/Messages"),
            homeDir.appendingPathComponent("Library/Application Support/com.apple.TCC")
        ]

        // Try to access each protected location
        for path in protectedPaths {
            // Try to read the directory or file
            do {
                // For directories, try to list contents
                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: path.path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        // Try to list directory contents
                        _ = try FileManager.default.contentsOfDirectory(atPath: path.path)
                        return true
                    } else {
                        // Try to read file attributes
                        _ = try FileManager.default.attributesOfItem(atPath: path.path)
                        return true
                    }
                }
            } catch {
                // If we get an error, this location is not accessible
                continue
            }
        }

        // If none of the protected locations are accessible, Full Disk Access is not granted
        return false
    }

    /// Opens System Settings to the Full Disk Access pane
    ///
    /// This opens the Privacy & Security settings where users can
    /// grant Full Disk Access to the app. The user will need to:
    /// 1. Find ZeroDevCleaner in the list
    /// 2. Toggle it on
    /// 3. Return to the app
    func requestFullDiskAccess() {
        SuperLog.i("Opening System Settings for Full Disk Access")
        // URL scheme to open System Settings to Full Disk Access
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }

    /// Reveals the app bundle location in Finder
    ///
    /// This helps users find the app to add it to Full Disk Access settings.
    /// The app will be highlighted in Finder after calling this method.
    func revealAppInFinder() {
        SuperLog.i("Revealing app in Finder")
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
