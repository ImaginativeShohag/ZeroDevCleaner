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

    /// Project-specific breakdown
    let projectBreakdown: [String: ProjectStats]

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

    nonisolated static let empty = CleaningStatistics(
        totalSizeCleaned: 0,
        sessionCount: 0,
        totalItemsCleaned: 0,
        projectBreakdown: [:]
    )
}

/// Statistics for a specific project type
struct ProjectStats {
    let projectType: String
    let totalSize: Int64
    let itemCount: Int

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

/// Date range for filtering statistics
enum DateRange: String, CaseIterable, Identifiable {
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case last90Days = "Last 90 Days"
    case lastYear = "Last Year"
    case allTime = "All Time"

    var id: String { rawValue }

    /// Get the start date for this range
    nonisolated func startDate() -> Date? {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .last7Days:
            return calendar.date(byAdding: .day, value: -7, to: now)
        case .last30Days:
            return calendar.date(byAdding: .day, value: -30, to: now)
        case .last90Days:
            return calendar.date(byAdding: .day, value: -90, to: now)
        case .lastYear:
            return calendar.date(byAdding: .year, value: -1, to: now)
        case .allTime:
            return nil // No filtering
        }
    }
}

/// Chart visualization type
enum ChartViewType: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case monthly = "Monthly"
    case yearly = "Yearly"
    case cumulative = "Cumulative"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .daily: return "calendar"
        case .monthly: return "calendar.badge.clock"
        case .yearly: return "calendar.badge.clock"
        case .cumulative: return "chart.line.uptrend.xyaxis"
        }
    }

    var description: String {
        switch self {
        case .daily: return "Show daily cleaning amounts"
        case .monthly: return "Show monthly aggregated totals"
        case .yearly: return "Show yearly aggregated totals"
        case .cumulative: return "Show cumulative total over time"
        }
    }
}

/// Represents an aggregated data point for charts
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let size: Int64
    let sessionCount: Int

    var sizeInGB: Double {
        Double(size) / 1_000_000_000
    }
}
