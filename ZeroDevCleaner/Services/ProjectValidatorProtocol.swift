//
//  ProjectValidatorProtocol.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation

/// Protocol for validating development project structures
protocol ProjectValidatorProtocol: Sendable {
    /// Validates if a folder is part of an Android project
    func isValidAndroidProject(buildFolder: URL) -> Bool

    /// Validates if a folder is part of an iOS/Xcode project
    func isValidiOSProject(buildFolder: URL) -> Bool

    /// Validates if a folder is part of a Swift Package
    func isValidSwiftPackage(buildFolder: URL) -> Bool

    /// Determines project type if valid, nil otherwise
    func detectProjectType(buildFolder: URL) -> ProjectType?
}
