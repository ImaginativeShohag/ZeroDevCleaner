//
//  FileScannerProtocol.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation

/// Progress callback for scanning operations
typealias ScanProgressHandler = @Sendable (String, Int) -> Void

/// Protocol for scanning directories for build folders
protocol FileScannerProtocol: Sendable {
    /// Scans a directory for build folders
    /// - Parameters:
    ///   - url: Root directory to scan
    ///   - progressHandler: Called with current path and found count
    /// - Returns: Array of found build folders
    func scanDirectory(
        at url: URL,
        progressHandler: ScanProgressHandler?
    ) async throws -> [BuildFolder]
}
