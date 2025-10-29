//
//  Logger+Extensions.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import OSLog

extension Logger {
    /// Main app logger for general application events
    static let app = Logger(subsystem: "org.imaginativeworld.ZeroDevCleaner", category: "app")

    /// Scanner logger for file scanning operations
    static let scanning = Logger(subsystem: "org.imaginativeworld.ZeroDevCleaner", category: "scanning")

    /// Deletion logger for file deletion operations
    static let deletion = Logger(subsystem: "org.imaginativeworld.ZeroDevCleaner", category: "deletion")

    /// Permission logger for permission-related operations
    static let permission = Logger(subsystem: "org.imaginativeworld.ZeroDevCleaner", category: "permission")
}
