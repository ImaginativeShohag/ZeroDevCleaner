//
//  ProjectValidatorProtocol.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation

/// Protocol for validating development project structures using configuration
protocol ProjectValidatorProtocol: Sendable {
    /// Detects project type from build folder path using configuration
    /// - Parameter buildFolder: URL to the build folder
    /// - Parameter projectTypes: Array of project type configurations (in priority order)
    /// - Returns: Matching ProjectType or nil if no match
    func detectProjectType(buildFolder: URL, projectTypes: [ProjectTypeConfig]) -> ProjectType?
}
