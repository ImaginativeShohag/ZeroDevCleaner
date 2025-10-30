//
//  CleaningStatistics.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 31/10/25.
//

import Foundation
import SwiftData

/// Represents a single cleaning session
@Model
final class CleaningSession: @unchecked Sendable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var totalSize: Int64
    var itemCount: Int
    var duration: TimeInterval

    @Relationship(deleteRule: .cascade, inverse: \CleanedItem.session)
    var items: [CleanedItem]

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        totalSize: Int64 = 0,
        itemCount: Int = 0,
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.totalSize = totalSize
        self.itemCount = itemCount
        self.duration = duration
        self.items = []
    }

    /// Formatted total size (e.g., "1.2 GB")
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    /// Formatted timestamp (e.g., "Oct 31, 2025 at 10:30 AM")
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    /// Formatted duration (e.g., "2.5s" or "1m 30s")
    var formattedDuration: String {
        if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(seconds)s"
        }
    }
}

/// Represents an individual item that was cleaned in a session
@Model
final class CleanedItem: @unchecked Sendable {
    @Attribute(.unique) var id: UUID
    var name: String
    var itemType: String  // "Build Folder", "System Cache", etc.
    var projectType: String?  // "Android", "iOS", "Swift Package", etc.
    var size: Int64
    var path: String

    @Relationship
    var session: CleaningSession?

    init(
        id: UUID = UUID(),
        name: String,
        itemType: String,
        projectType: String? = nil,
        size: Int64,
        path: String
    ) {
        self.id = id
        self.name = name
        self.itemType = itemType
        self.projectType = projectType
        self.size = size
        self.path = path
    }

    /// Formatted size (e.g., "512 MB")
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

/// Aggregate statistics computed from sessions
struct CleaningStatistics {
    /// Total size cleaned across all sessions
    let totalSizeCleaned: Int64

    /// Total number of cleaning sessions
    let sessionCount: Int

    /// Total number of items cleaned
    let totalItemsCleaned: Int

    /// Average size per session
    var averageSizePerSession: Int64 {
        sessionCount > 0 ? totalSizeCleaned / Int64(sessionCount) : 0
    }

    /// Average items per session
    var averageItemsPerSession: Double {
        sessionCount > 0 ? Double(totalItemsCleaned) / Double(sessionCount) : 0
    }

    /// Formatted total size
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSizeCleaned, countStyle: .file)
    }

    /// Formatted average size per session
    var formattedAverageSize: String {
        ByteCountFormatter.string(fromByteCount: averageSizePerSession, countStyle: .file)
    }

    static let empty = CleaningStatistics(
        totalSizeCleaned: 0,
        sessionCount: 0,
        totalItemsCleaned: 0
    )
}
