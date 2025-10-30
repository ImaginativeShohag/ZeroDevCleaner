//
//  StatisticsService.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 31/10/25.
//

import Foundation
import SwiftData
import OSLog

protocol StatisticsServiceProtocol: Sendable {
    func saveCleaningSession(
        totalSize: Int64,
        itemCount: Int,
        duration: TimeInterval,
        items: [(name: String, itemType: String, projectType: String?, size: Int64, path: String)]
    ) async throws

    func fetchAllSessions() async throws -> [CleaningSession]
    func fetchRecentSessions(limit: Int) async throws -> [CleaningSession]
    func fetchStatistics() async throws -> CleaningStatistics
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

        print("Saved cleaning session: \(itemCount) items, \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
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

    /// Computes aggregate statistics from all sessions
    func fetchStatistics() async throws -> CleaningStatistics {
        let sessions = try await fetchAllSessions()

        guard !sessions.isEmpty else {
            return CleaningStatistics(totalSizeCleaned: 0, sessionCount: 0, totalItemsCleaned: 0)
        }

        let totalSize = sessions.reduce(0) { $0 + $1.totalSize }
        let totalItems = sessions.reduce(0) { $0 + $1.itemCount }

        return CleaningStatistics(
            totalSizeCleaned: totalSize,
            sessionCount: sessions.count,
            totalItemsCleaned: totalItems
        )
    }

    /// Deletes a specific cleaning session
    func deleteSession(_ session: CleaningSession) async throws {
        modelContext.delete(session)
        try modelContext.save()

        print("Deleted cleaning session from \(session.formattedTimestamp)")
    }

    /// Deletes all cleaning sessions
    func deleteAllSessions() async throws {
        let sessions = try await fetchAllSessions()

        for session in sessions {
            modelContext.delete(session)
        }

        try modelContext.save()

        print("Deleted all cleaning sessions (\(sessions.count) total)")
    }
}
