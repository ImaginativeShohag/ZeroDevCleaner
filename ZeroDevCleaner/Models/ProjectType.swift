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
    case flutter
    case nodeJS
    case rust
    case python
    case go
    case javaMaven
    case ruby
    case dotNet
    case unity

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .android:
            return "Android"
        case .iOS:
            return "iOS/Xcode"
        case .swiftPackage:
            return "Swift Package"
        case .flutter:
            return "Flutter"
        case .nodeJS:
            return "Node.js"
        case .rust:
            return "Rust"
        case .python:
            return "Python"
        case .go:
            return "Go"
        case .javaMaven:
            return "Java/Maven"
        case .ruby:
            return "Ruby"
        case .dotNet:
            return ".NET"
        case .unity:
            return "Unity"
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
        case .flutter:
            return "wind"
        case .nodeJS:
            return "atom"
        case .rust:
            return "gearshape.2.fill"
        case .python:
            return "chevron.left.forwardslash.chevron.right"
        case .go:
            return "g.square.fill"
        case .javaMaven:
            return "cup.and.saucer.fill"
        case .ruby:
            return "diamond.fill"
        case .dotNet:
            return "number.square.fill"
        case .unity:
            return "cube.transparent.fill"
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
        case .flutter:
            return .cyan
        case .nodeJS:
            return .green
        case .rust:
            return .orange
        case .python:
            return .yellow
        case .go:
            return .cyan
        case .javaMaven:
            return .red
        case .ruby:
            return .red
        case .dotNet:
            return .purple
        case .unity:
            return .indigo
        }
    }

    /// Folder name pattern to search for
    var buildFolderName: String {
        switch self {
        case .android, .flutter:
            return "build"
        case .iOS, .swiftPackage:
            return ".build"
        case .nodeJS:
            return "node_modules"
        case .rust, .javaMaven:
            return "target"
        case .python:
            return "__pycache__"
        case .go:
            return "vendor"  // Go modules vendor directory
        case .ruby:
            return "vendor"  // Ruby gems vendor directory
        case .dotNet:
            return "bin"  // .NET build output
        case .unity:
            return "Library"  // Unity project library
        }
    }
}
