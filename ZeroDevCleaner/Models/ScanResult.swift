//
//  ScanResult.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation

/// Represents the result of a directory scan
struct ScanResult: Codable, Sendable {
    /// Root path that was scanned
    let rootPath: URL

    /// When the scan was performed
    let scanDate: Date

    /// All build folders found during the scan
    let buildFolders: [BuildFolder]

    /// How long the scan took
    let scanDuration: TimeInterval

    /// Total size of all found build folders in bytes
    var totalSize: Int64 {
        buildFolders.reduce(0) { $0 + $1.size }
    }

    /// Total size of selected build folders in bytes
    var selectedSize: Int64 {
        buildFolders.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }

    /// Number of selected folders
    var selectedCount: Int {
        buildFolders.filter(\.isSelected).count
    }

    /// Human-readable total size
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    /// Human-readable selected size
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }

    /// Human-readable scan duration
    var formattedScanDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: scanDuration) ?? "\(scanDuration)s"
    }
}
