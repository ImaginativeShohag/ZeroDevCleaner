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

    func detectProjectType(buildFolder: URL) -> ProjectType? {
        if isValidAndroidProject(buildFolder: buildFolder) {
            return .android
        } else if isValidSwiftPackage(buildFolder: buildFolder) {
            return .swiftPackage
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
