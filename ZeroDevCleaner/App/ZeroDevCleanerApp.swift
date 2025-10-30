//
//  ZeroDevCleanerApp.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI

@main
struct ZeroDevCleanerApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) { }

            // Add Settings to app menu
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandMenu("Scan") {
                Button("Select Folder...") {
                    NotificationCenter.default.post(name: .selectFolder, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Start Scan") {
                    NotificationCenter.default.post(name: .startScan, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            CommandMenu("Selection") {
                Button("Select All") {
                    NotificationCenter.default.post(name: .selectAll, object: nil)
                }
                .keyboardShortcut("a", modifiers: .command)

                Button("Deselect All") {
                    NotificationCenter.default.post(name: .deselectAll, object: nil)
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])

                Divider()

                Button("Remove Selected") {
                    NotificationCenter.default.post(name: .deleteSelected, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: [])
            }
        }
    }
}

// Notification names for keyboard shortcuts
extension Notification.Name {
    static let selectFolder = Notification.Name("selectFolder")
    static let startScan = Notification.Name("startScan")
    static let selectAll = Notification.Name("selectAll")
    static let deselectAll = Notification.Name("deselectAll")
    static let deleteSelected = Notification.Name("deleteSelected")
    static let openSettings = Notification.Name("openSettings")
}
