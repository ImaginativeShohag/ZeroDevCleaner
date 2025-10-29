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
                    onSelectFolder: viewModel.selectFolder,
                    onFolderDropped: { url in
                        viewModel.selectFolder(at: url)
                    }
                )
            } else if viewModel.isScanning {
                ScanProgressView(
                    progress: viewModel.scanProgress,
                    currentPath: viewModel.currentScanPath,
                    onCancel: viewModel.cancelScan
                )
            } else {
                ScanResultsView(
                    results: viewModel.scanResults,
                    onToggleSelection: viewModel.toggleSelection,
                    onSelectAll: viewModel.selectAll,
                    onDeselectAll: viewModel.deselectAll,
                    onDelete: viewModel.deleteSelectedFolders,
                    onShowInFinder: viewModel.showInFinder,
                    selectedSize: viewModel.formattedSelectedSize
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
