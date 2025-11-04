//
//  MainScreen.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI
import SwiftData

struct MainScreen: View {
    @State private var viewModel = MainViewModel()
    @State private var locationManager = ScanLocationManager()
    @State private var showingSettings = false
    @State private var showingAbout = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.scanResults.isEmpty && viewModel.staticLocations.isEmpty && !viewModel.isScanning {
                EmptyStateView(
                    hasConfiguredLocations: !locationManager.enabledLocations.isEmpty,
                    onStartScan: {
                        viewModel.startScan(locations: locationManager.enabledLocations, locationManager: locationManager)
                    },
                    onOpenSettings: {
                        showingSettings = true
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if viewModel.isScanning {
                ScanProgressView(
                    progress: viewModel.scanProgress,
                    currentPath: viewModel.currentScanPath,
                    onCancel: viewModel.cancelScan
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                ScanResultsView(
                    viewModel: viewModel,
                    onShowInFinder: viewModel.showInFinder,
                    onDone: viewModel.resetToHome
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isScanning)
        .animation(.easeInOut(duration: 0.3), value: viewModel.scanResults.isEmpty)
        .frame(minWidth: 900, minHeight: 600)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            if let error = viewModel.currentError {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.localizedDescription)
                        .fontWeight(.semibold)

                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                    }
                }
            }
        }
        .alert("Full Disk Access Required", isPresented: $viewModel.showPermissionError) {
            Button("Open System Settings") {
                viewModel.openSystemSettings()
            }
            Button("Show App in Finder") {
                viewModel.revealAppInFinder()
            }
            Button("OK", role: .cancel) {
                viewModel.dismissError()
            }
        } message: {
            Text("ZeroDevCleaner cannot access this folder without Full Disk Access permission.\n\nTo grant access:\n1. Click 'Open System Settings'\n2. Click 'Show App in Finder' to locate ZeroDevCleaner\n3. In System Settings, click the '+' button under Full Disk Access\n4. Drag ZeroDevCleaner from Finder to the list, or navigate to select it\n5. Make sure the checkbox next to ZeroDevCleaner is enabled\n6. Quit and restart this app\n\n⚠️ You must restart the app after granting permission!")
        }
        .sheet(isPresented: $viewModel.showDeletionConfirmation) {
            DeletionConfirmationView(
                foldersToDelete: viewModel.selectedFolders,
                staticLocationsToDelete: viewModel.selectedStaticLocations,
                subItemsToDelete: viewModel.selectedSubItems,
                totalSize: viewModel.formattedSelectedSize,
                onConfirm: { viewModel.confirmDeletion() },
                onCancel: { viewModel.showDeletionConfirmation = false }
            )
        }
        .sheet(isPresented: $viewModel.showDeletionProgress) {
            DeletionProgressView(
                currentItem: viewModel.currentDeletionItem,
                progress: viewModel.deletionProgress,
                currentIndex: viewModel.deletedItemCount,
                totalItems: viewModel.totalSelectedCount,
                deletedSize: viewModel.deletedSize,
                totalSize: viewModel.selectedSize,
                canCancel: false,
                onCancel: {}
            )
            .interactiveDismissDisabled()
        }
        .toolbar {
            // Scan button - always visible
            ToolbarItem(placement: .automatic) {
                Button {
                    viewModel.startScan(locations: locationManager.enabledLocations, locationManager: locationManager)
                } label: {
                    Label("Scan", systemImage: "play.fill")
                }
                .disabled(viewModel.isScanning || viewModel.isDeleting)
                .keyboardShortcut("r", modifiers: .command)
            }

            // Settings button
            ToolbarItem(placement: .automatic) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                .disabled(viewModel.isScanning || viewModel.isDeleting)
                .keyboardShortcut(",", modifiers: .command)
            }

            // About button
            ToolbarItem(placement: .automatic) {
                Button {
                    showingAbout = true
                } label: {
                    Label("About", systemImage: "info.circle")
                }
            }

            // Exit button
            ToolbarItem(placement: .automatic) {
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Exit", systemImage: "xmark.circle")
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet(locationManager: locationManager)
        }
        .sheet(isPresented: $showingAbout) {
            AboutSheet()
        }
        .onReceive(NotificationCenter.default.publisher(for: .startScan)) { _ in
            if !viewModel.isScanning && !viewModel.isDeleting {
                viewModel.startScan(locations: locationManager.enabledLocations, locationManager: locationManager)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            showingSettings = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAbout)) { _ in
            showingAbout = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectAll)) { _ in
            if !viewModel.scanResults.isEmpty && !viewModel.isScanning && !viewModel.isDeleting {
                viewModel.selectAll()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deselectAll)) { _ in
            if !viewModel.scanResults.isEmpty && !viewModel.isScanning && !viewModel.isDeleting {
                viewModel.deselectAll()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deleteSelected)) { _ in
            if !viewModel.selectedFolders.isEmpty && !viewModel.isScanning && !viewModel.isDeleting {
                viewModel.showDeleteConfirmation()
            }
        }
        .onAppear {
            viewModel.configureModelContext(modelContext)
        }
    }
}

#Preview {
    let schema = Schema([CleaningSession.self, CleanedItem.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])

    return MainScreen()
        .modelContainer(container)
}
