//
//  MainView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI

struct MainView: View {
    @State private var viewModel = MainViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.scanResults.isEmpty && !viewModel.isScanning {
                EmptyStateView(
                    selectedFolder: viewModel.selectedFolder,
                    onSelectFolder: viewModel.selectFolder,
                    onFolderDropped: { url in
                        viewModel.selectFolder(at: url)
                    },
                    onStartScan: viewModel.startScan
                )
            } else if viewModel.isScanning {
                ScanProgressView(
                    progress: viewModel.scanProgress,
                    currentPath: viewModel.currentScanPath,
                    onCancel: viewModel.cancelScan
                )
            } else {
                ScanResultsView(
                    viewModel: viewModel,
                    onShowInFinder: viewModel.showInFinder
                )
            }
        }
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
            ToolbarItem(placement: .automatic) {
                Button("Select Folder") {
                    viewModel.selectFolder()
                }
                .disabled(viewModel.isScanning || viewModel.isDeleting)
            }

            if viewModel.selectedFolder != nil {
                ToolbarItem(placement: .automatic) {
                    Button("Scan") {
                        viewModel.startScan()
                    }
                    .disabled(viewModel.isScanning || viewModel.isDeleting)
                }
            }

            // Recent folders menu
            if !viewModel.recentFoldersManager.recentFolders.isEmpty {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        ForEach(viewModel.recentFoldersManager.recentFolders, id: \.self) { url in
                            Button(url.lastPathComponent) {
                                viewModel.selectFolder(at: url)
                            }
                            .disabled(viewModel.isScanning || viewModel.isDeleting)
                        }

                        Divider()

                        Button("Clear Recent Folders") {
                            viewModel.recentFoldersManager.clearAll()
                        }
                    } label: {
                        Label("Recent", systemImage: "clock.arrow.circlepath")
                    }
                    .disabled(viewModel.isScanning || viewModel.isDeleting)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectFolder)) { _ in
            if !viewModel.isScanning && !viewModel.isDeleting {
                viewModel.selectFolder()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .startScan)) { _ in
            if viewModel.selectedFolder != nil && !viewModel.isScanning && !viewModel.isDeleting {
                viewModel.startScan()
            }
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
    }
}

#Preview {
    MainView()
}
