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
                    results: viewModel.filteredResults,
                    currentFilter: $viewModel.currentFilter,
                    onToggleSelection: viewModel.toggleSelection,
                    onSelectAll: viewModel.selectAll,
                    onDeselectAll: viewModel.deselectAll,
                    onDelete: viewModel.deleteSelectedFolders,
                    onShowInFinder: viewModel.showInFinder,
                    selectedSize: viewModel.formattedSelectedSize,
                    totalCount: viewModel.totalFoldersCount,
                    totalSize: viewModel.formattedTotalSize
                )
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            if let error = viewModel.currentError {
                Text(error.localizedDescription)
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
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Select Folder") {
                    viewModel.selectFolder()
                }
            }

            if viewModel.selectedFolder != nil {
                ToolbarItem(placement: .automatic) {
                    Button("Scan") {
                        viewModel.startScan()
                    }
                    .disabled(viewModel.isScanning)
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
                        }

                        Divider()

                        Button("Clear Recent Folders") {
                            viewModel.recentFoldersManager.clearAll()
                        }
                    } label: {
                        Label("Recent", systemImage: "clock.arrow.circlepath")
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectFolder)) { _ in
            viewModel.selectFolder()
        }
        .onReceive(NotificationCenter.default.publisher(for: .startScan)) { _ in
            if viewModel.selectedFolder != nil && !viewModel.isScanning {
                viewModel.startScan()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectAll)) { _ in
            if !viewModel.scanResults.isEmpty {
                viewModel.selectAll()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deselectAll)) { _ in
            if !viewModel.scanResults.isEmpty {
                viewModel.deselectAll()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deleteSelected)) { _ in
            if !viewModel.selectedFolders.isEmpty {
                viewModel.deleteSelectedFolders()
            }
        }
    }
}

#Preview {
    MainView()
}
