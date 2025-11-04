//
//  StatisticsService.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 31/10/25.
//

import Foundation
import SwiftData

protocol StatisticsServiceProtocol: Sendable {
    func saveCleaningSession(
        totalSize: Int64,
        itemCount: Int,
        duration: TimeInterval,
        items: [(name: String, itemType: String, projectType: String?, size: Int64, path: String)]
    ) async throws

    func fetchAllSessions() async throws -> [CleaningSession]
    func fetchRecentSessions(limit: Int) async throws -> [CleaningSession]
    func fetchSessionsInDateRange(_ dateRange: DateRange) async throws -> [CleaningSession]
    func fetchStatistics() async throws -> CleaningStatistics
    func fetchStatistics(dateRange: DateRange) async throws -> CleaningStatistics
    func deleteSession(_ session: CleaningSession) async throws
    func deleteAllSessions() async throws
}

@ModelActor
actor StatisticsService: StatisticsServiceProtocol {
    /// Saves a new cleaning session with its items
    func saveCleaningSession(
        totalSize: Int64,
        itemCount: Int,
        duration: TimeInterval,
        items: [(name: String, itemType: String, projectType: String?, size: Int64, path: String)]
    ) async throws {
        let session = CleaningSession(
            timestamp: Date(),
            totalSize: totalSize,
            itemCount: itemCount,
            duration: duration
        )

        // Create cleaned items
        for itemData in items {
            let cleanedItem = CleanedItem(
                name: itemData.name,
                itemType: itemData.itemType,
                projectType: itemData.projectType,
                size: itemData.size,
                path: itemData.path
            )
            cleanedItem.session = session
            session.items.append(cleanedItem)
        }

        modelContext.insert(session)
        try modelContext.save()

        SuperLog.i("Saved cleaning session: \(itemCount) items, \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
    }

    /// Fetches all cleaning sessions, sorted by timestamp (newest first)
    func fetchAllSessions() async throws -> [CleaningSession] {
        let descriptor = FetchDescriptor<CleaningSession>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches recent cleaning sessions up to a specified limit
    func fetchRecentSessions(limit: Int) async throws -> [CleaningSession] {
        var descriptor = FetchDescriptor<CleaningSession>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    /// Fetches sessions within a specific date range
    func fetchSessionsInDateRange(_ dateRange: DateRange) async throws -> [CleaningSession] {
        if dateRange == .allTime {
            return try await fetchAllSessions()
        }

        guard let startDate = dateRange.startDate() else {
            return try await fetchAllSessions()
        }

        let predicate = #Predicate<CleaningSession> { session in
            session.timestamp >= startDate
        }

        let descriptor = FetchDescriptor<CleaningSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Computes aggregate statistics from all sessions
    func fetchStatistics() async throws -> CleaningStatistics {
        try await fetchStatistics(dateRange: .allTime)
    }

    /// Computes aggregate statistics for a specific date range with project breakdown
    func fetchStatistics(dateRange: DateRange) async throws -> CleaningStatistics {
        let sessions = try await fetchSessionsInDateRange(dateRange)

        guard !sessions.isEmpty else {
            return .empty
        }

        let totalSize = sessions.reduce(0) { $0 + $1.totalSize }
        let totalItems = sessions.reduce(0) { $0 + $1.itemCount }

        // Compute project breakdown
        var projectBreakdown: [String: ProjectStats] = [:]

        for session in sessions {
            for item in session.items {
                guard let projectType = item.projectType else { continue }

                if var stats = projectBreakdown[projectType] {
                    stats = ProjectStats(
                        projectType: projectType,
                        totalSize: stats.totalSize + item.size,
                        itemCount: stats.itemCount + 1
                    )
                    projectBreakdown[projectType] = stats
                } else {
                    projectBreakdown[projectType] = ProjectStats(
                        projectType: projectType,
                        totalSize: item.size,
                        itemCount: 1
                    )
                }
            }
        }

        return CleaningStatistics(
            totalSizeCleaned: totalSize,
            sessionCount: sessions.count,
            totalItemsCleaned: totalItems,
            projectBreakdown: projectBreakdown
        )
    }

    /// Deletes a specific cleaning session
    func deleteSession(_ session: CleaningSession) async throws {
        modelContext.delete(session)
        try modelContext.save()

        SuperLog.i("Deleted cleaning session from \(session.formattedTimestamp)")
    }

    /// Deletes all cleaning sessions
    func deleteAllSessions() async throws {
        let sessions = try await fetchAllSessions()

        for session in sessions {
            modelContext.delete(session)
        }

        try modelContext.save()

        SuperLog.i("Deleted all cleaning sessions (\(sessions.count) total)")
    }
}
