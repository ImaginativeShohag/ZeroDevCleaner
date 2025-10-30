//
//  StatisticsView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 31/10/25.
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CleaningSession.timestamp, order: .reverse)
    private var allSessions: [CleaningSession]

    @State private var statistics: CleaningStatistics = .empty
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedSessionID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Statistics")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()

            if isLoading {
                Spacer()
                ProgressView("Loading statistics...")
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.headline)
                }
                Spacer()
            } else if allSessions.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    Text("No Statistics Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Statistics will appear here after you clean some items")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Summary Cards
                        summaryCardsSection

                        // Cleaning History Chart
                        if !allSessions.isEmpty {
                            cleaningHistoryChart
                        }

                        // Recent Sessions List
                        recentSessionsSection
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .task {
            computeStatistics()
            isLoading = false
        }
        .onChange(of: allSessions) { _, _ in
            computeStatistics()
        }
    }

    // MARK: - Summary Cards Section

    private var summaryCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                SummaryCard(
                    title: "Total Cleaned",
                    value: statistics.formattedTotalSize,
                    icon: "trash.fill",
                    color: .blue
                )

                SummaryCard(
                    title: "Cleaning Sessions",
                    value: "\(statistics.sessionCount)",
                    icon: "clock.fill",
                    color: .green
                )

                SummaryCard(
                    title: "Items Deleted",
                    value: "\(statistics.totalItemsCleaned)",
                    icon: "doc.on.doc.fill",
                    color: .orange
                )

                SummaryCard(
                    title: "Average per Session",
                    value: statistics.formattedAverageSize,
                    icon: "chart.bar.fill",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Cleaning History Chart

    private var cleaningHistoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cleaning History")
                .font(.title2)
                .fontWeight(.semibold)

            GroupBox {
                Chart {
                    ForEach(allSessions.reversed()) { session in
                        BarMark(
                            x: .value("Date", session.timestamp, unit: .day),
                            y: .value("Size", Double(session.totalSize) / 1_000_000_000) // Convert to GB
                        )
                        .foregroundStyle(.blue.gradient)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(String(format: "%.1f", doubleValue)) GB")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 200)
                .padding()
            }
        }
    }

    // MARK: - Recent Sessions Section

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Sessions")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(allSessions.count) session\(allSessions.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            GroupBox {
                if allSessions.isEmpty {
                    Text("No sessions yet")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(allSessions.enumerated()), id: \.element.id) { index, session in
                            SessionRow(session: session, isExpanded: selectedSessionID == session.id)
                                .onTapGesture {
                                    withAnimation {
                                        if selectedSessionID == session.id {
                                            selectedSessionID = nil
                                        } else {
                                            selectedSessionID = session.id
                                        }
                                    }
                                }

                            if index < allSessions.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Data Computation

    private func computeStatistics() {
        guard !allSessions.isEmpty else {
            statistics = CleaningStatistics(totalSizeCleaned: 0, sessionCount: 0, totalItemsCleaned: 0)
            return
        }

        let totalSize = allSessions.reduce(0) { $0 + $1.totalSize }
        let totalItems = allSessions.reduce(0) { $0 + $1.itemCount }

        statistics = CleaningStatistics(
            totalSizeCleaned: totalSize,
            sessionCount: allSessions.count,
            totalItemsCleaned: totalItems
        )
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)

                    Spacer()
                }

                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: CleaningSession
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.formattedTimestamp)
                        .font(.headline)

                    HStack(spacing: 16) {
                        Label(session.formattedTotalSize, systemImage: "externaldrive.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Label("\(session.itemCount) item\(session.itemCount == 1 ? "" : "s")", systemImage: "doc.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Label(session.formattedDuration, systemImage: "clock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())

            if isExpanded && !session.items.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Items Deleted:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)

                    ForEach(session.items.prefix(10), id: \.id) { item in
                        HStack {
                            Image(systemName: item.itemType.contains("Build") ? "hammer.fill" : "folder.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(item.name)
                                .font(.caption)
                                .lineLimit(1)

                            Spacer()

                            Text(item.formattedSize)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }

                    if session.items.count > 10 {
                        Text("+ \(session.items.count - 10) more items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.leading, 24)
            }
        }
        .padding()
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [CleaningSession.self, CleanedItem.self])
}
