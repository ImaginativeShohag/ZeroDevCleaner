//
//  ProjectValidator.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation

final class ProjectValidator: ProjectValidatorProtocol, Sendable {
    nonisolated(unsafe) private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func isValidAndroidProject(buildFolder: URL) -> Bool {
        // Check if folder is named "build"
        guard buildFolder.lastPathComponent == "build" else {
            return false
        }

        // Look for build.gradle or build.gradle.kts in parent directories
        if findFileInParentDirectories(from: buildFolder, named: "build.gradle") ||
           findFileInParentDirectories(from: buildFolder, named: "build.gradle.kts") {
            return true
        }

        // Look for settings.gradle or settings.gradle.kts
        if findFileInParentDirectories(from: buildFolder, named: "settings.gradle") ||
           findFileInParentDirectories(from: buildFolder, named: "settings.gradle.kts") {
            return true
        }

        // Check for app/build.gradle pattern (multi-module project)
        let parentURL = buildFolder.deletingLastPathComponent()
        if parentURL.lastPathComponent == "app" {
            let grandparentURL = parentURL.deletingLastPathComponent()
            if directoryContainsFile(directory: grandparentURL, named: "settings.gradle") ||
               directoryContainsFile(directory: grandparentURL, named: "settings.gradle.kts") {
                return true
            }
        }

        return false
    }

    func isValidiOSProject(buildFolder: URL) -> Bool {
        let folderName = buildFolder.lastPathComponent

        // iOS/Xcode projects can have both "build" and ".build" folders
        // - "build" is used for legacy builds or in-place builds
        // - ".build" is used for SPM dependencies in Xcode projects
        guard folderName == "build" || folderName == ".build" else {
            return false
        }

        // Look for .xcodeproj or .xcworkspace in parent directories
        let parentURL = buildFolder.deletingLastPathComponent()
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: parentURL,
                includingPropertiesForKeys: nil
            )
            if contents.contains(where: { $0.pathExtension == "xcodeproj" }) {
                return true
            }
            if contents.contains(where: { $0.pathExtension == "xcworkspace" }) {
                return true
            }
        } catch {
            return false
        }

        return false
    }

    func isValidSwiftPackage(buildFolder: URL) -> Bool {
        // Check if folder is named ".build"
        guard buildFolder.lastPathComponent == ".build" else {
            return false
        }

        // Look for Package.swift in parent directory
        return findFileInParentDirectories(from: buildFolder, named: "Package.swift", maxLevels: 2)
    }

    func isValidFlutterProject(buildFolder: URL) -> Bool {
        // Check if folder is named "build"
        guard buildFolder.lastPathComponent == "build" else {
            return false
        }

        // Look for pubspec.yaml in parent directory
        return findFileInParentDirectories(from: buildFolder, named: "pubspec.yaml", maxLevels: 2)
    }

    func isValidNodeJSProject(buildFolder: URL) -> Bool {
        // Check if folder is named "node_modules"
        guard buildFolder.lastPathComponent == "node_modules" else {
            return false
        }

        // Look for package.json in parent directory
        let parentURL = buildFolder.deletingLastPathComponent()
        return directoryContainsFile(directory: parentURL, named: "package.json")
    }

    func isValidRustProject(buildFolder: URL) -> Bool {
        // Check if folder is named "target"
        guard buildFolder.lastPathComponent == "target" else {
            return false
        }

        // Look for Cargo.toml in parent directory
        let parentURL = buildFolder.deletingLastPathComponent()
        return directoryContainsFile(directory: parentURL, named: "Cargo.toml")
    }

    func isValidPythonProject(buildFolder: URL) -> Bool {
        let folderName = buildFolder.lastPathComponent

        // Python cache folders can be __pycache__, venv, .venv, env, .env
        guard folderName == "__pycache__" ||
              folderName == "venv" ||
              folderName == ".venv" ||
              folderName == "env" ||
              folderName == ".env" else {
            return false
        }

        // For __pycache__, just verify it exists (it's always Python)
        if folderName == "__pycache__" {
            return true
        }

        // For venv/env folders, look for Python-related files in parent
        let parentURL = buildFolder.deletingLastPathComponent()

        // Check for common Python project files
        if directoryContainsFile(directory: parentURL, named: "requirements.txt") ||
           directoryContainsFile(directory: parentURL, named: "setup.py") ||
           directoryContainsFile(directory: parentURL, named: "pyproject.toml") ||
           directoryContainsFile(directory: parentURL, named: "Pipfile") ||
           directoryContainsFile(directory: parentURL, named: "poetry.lock") {
            return true
        }

        return false
    }

    func detectProjectType(buildFolder: URL) -> ProjectType? {
        // Order matters: check more specific types first
        if isValidSwiftPackage(buildFolder: buildFolder) {
            return .swiftPackage
        } else if isValidFlutterProject(buildFolder: buildFolder) {
            return .flutter
        } else if isValidNodeJSProject(buildFolder: buildFolder) {
            return .nodeJS
        } else if isValidRustProject(buildFolder: buildFolder) {
            return .rust
        } else if isValidPythonProject(buildFolder: buildFolder) {
            return .python
        } else if isValidAndroidProject(buildFolder: buildFolder) {
            return .android
        } else if isValidiOSProject(buildFolder: buildFolder) {
            return .iOS
        }
        return nil
    }

    // MARK: - Private Helpers

    private func fileExists(at path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    private func directoryContainsFile(directory: URL, named: String) -> Bool {
        fileExists(at: directory.appendingPathComponent(named).path)
    }

    private func findFileInParentDirectories(from url: URL, named: String, maxLevels: Int = 5) -> Bool {
        var currentURL = url.deletingLastPathComponent()
        var level = 0

        while level < maxLevels {
            if directoryContainsFile(directory: currentURL, named: named) {
                return true
            }
            let parentURL = currentURL.deletingLastPathComponent()
            if parentURL == currentURL { break }
            currentURL = parentURL
            level += 1
        }
        return false
    }
}
