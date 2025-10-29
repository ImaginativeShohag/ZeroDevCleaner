//
//  ProjectType.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation
import SwiftUI

/// Represents the type of development project
enum ProjectType: String, Codable, CaseIterable, Sendable {
    case android
    case iOS
    case swiftPackage

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .android:
            return "Android"
        case .iOS:
            return "iOS/Xcode"
        case .swiftPackage:
            return "Swift Package"
        }
    }

    /// SF Symbol icon name for the project type
    var iconName: String {
        switch self {
        case .android:
            return "app.badge.fill"
        case .iOS:
            return "apple.logo"
        case .swiftPackage:
            return "shippingbox.fill"
        }
    }

    /// Color for the project type icon
    var color: Color {
        switch self {
        case .android:
            return .green
        case .iOS:
            return .blue
        case .swiftPackage:
            return .orange
        }
    }

    /// Folder name pattern to search for
    var buildFolderName: String {
        switch self {
        case .android:
            return "build"
        case .iOS, .swiftPackage:
            return ".build"
        }
    }
}
