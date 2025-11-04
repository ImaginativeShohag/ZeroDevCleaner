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

    func isValidGoProject(buildFolder: URL) -> Bool {
        // Check if folder is named "vendor"
        guard buildFolder.lastPathComponent == "vendor" else {
            return false
        }

        // Look for go.mod in parent directory
        let parentURL = buildFolder.deletingLastPathComponent()
        return directoryContainsFile(directory: parentURL, named: "go.mod")
    }

    func isValidJavaMavenProject(buildFolder: URL) -> Bool {
        // Check if folder is named "target"
        guard buildFolder.lastPathComponent == "target" else {
            return false
        }

        // Look for pom.xml in parent directory (Maven)
        let parentURL = buildFolder.deletingLastPathComponent()
        return directoryContainsFile(directory: parentURL, named: "pom.xml")
    }

    func isValidRubyProject(buildFolder: URL) -> Bool {
        // Check if folder is named "vendor"
        guard buildFolder.lastPathComponent == "vendor" else {
            return false
        }

        // Look for Gemfile in parent directory
        let parentURL = buildFolder.deletingLastPathComponent()
        return directoryContainsFile(directory: parentURL, named: "Gemfile")
    }

    func isValidDotNetProject(buildFolder: URL) -> Bool {
        let folderName = buildFolder.lastPathComponent

        // .NET build folders are "bin" or "obj"
        guard folderName == "bin" || folderName == "obj" else {
            return false
        }

        // Look for .csproj, .vbproj, .fsproj, or .sln in parent directories
        let parentURL = buildFolder.deletingLastPathComponent()
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: parentURL,
                includingPropertiesForKeys: nil
            )
            if contents.contains(where: { ["csproj", "vbproj", "fsproj", "sln"].contains($0.pathExtension) }) {
                return true
            }
        } catch {
            return false
        }

        return false
    }

    func isValidUnityProject(buildFolder: URL) -> Bool {
        // Check if folder is named "Library" or "Temp"
        let folderName = buildFolder.lastPathComponent
        guard folderName == "Library" || folderName == "Temp" else {
            return false
        }

        // Look for Assets folder and ProjectSettings folder in parent directory
        let parentURL = buildFolder.deletingLastPathComponent()
        let assetsURL = parentURL.appendingPathComponent("Assets")
        let projectSettingsURL = parentURL.appendingPathComponent("ProjectSettings")

        var isDirectory: ObjCBool = false
        let assetsExists = fileManager.fileExists(atPath: assetsURL.path, isDirectory: &isDirectory) && isDirectory.boolValue

        isDirectory = false
        let projectSettingsExists = fileManager.fileExists(atPath: projectSettingsURL.path, isDirectory: &isDirectory) && isDirectory.boolValue

        return assetsExists && projectSettingsExists
    }

    func detectProjectType(buildFolder: URL) -> ProjectType? {
        // Order matters: check more specific types first
        if isValidSwiftPackage(buildFolder: buildFolder) {
            return .swiftPackage
        } else if isValidFlutterProject(buildFolder: buildFolder) {
            return .flutter
        } else if isValidNodeJSProject(buildFolder: buildFolder) {
            return .nodeJS
        } else if isValidJavaMavenProject(buildFolder: buildFolder) {
            // Check Java/Maven before Rust (both use "target")
            return .javaMaven
        } else if isValidRustProject(buildFolder: buildFolder) {
            return .rust
        } else if isValidPythonProject(buildFolder: buildFolder) {
            return .python
        } else if isValidGoProject(buildFolder: buildFolder) {
            // Check Go before Ruby (both use "vendor")
            return .go
        } else if isValidRubyProject(buildFolder: buildFolder) {
            return .ruby
        } else if isValidDotNetProject(buildFolder: buildFolder) {
            return .dotNet
        } else if isValidUnityProject(buildFolder: buildFolder) {
            return .unity
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
