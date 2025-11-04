//
//  ZeroDevCleanerApp.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI
import SwiftData

@main
struct ZeroDevCleanerApp: App {
    // SwiftData model container
    let modelContainer: ModelContainer

    init() {
        do {
            // Use in-memory store for previews to avoid initialization issues
            let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

            let schema = Schema([CleaningSession.self, CleanedItem.self])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: isPreview
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainScreen()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 600)
        .modelContainer(modelContainer)
        .commands {
            CommandGroup(replacing: .newItem) { }

            // Add About to app menu
            CommandGroup(replacing: .appInfo) {
                Button("About ZeroDevCleaner") {
                    NotificationCenter.default.post(name: .openAbout, object: nil)
                }
            }

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

            CommandGroup(replacing: .help) {
                Button("ZeroDevCleaner Help") {
                    if let url = URL(string: "https://github.com/ImaginativeShohag/ZeroDevCleaner#readme") {
                        NSWorkspace.shared.open(url)
                    }
                }

                Button("Report an Issue") {
                    if let url = URL(string: "https://github.com/ImaginativeShohag/ZeroDevCleaner/issues/new") {
                        NSWorkspace.shared.open(url)
                    }
                }
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
    static let openAbout = Notification.Name("openAbout")
}
