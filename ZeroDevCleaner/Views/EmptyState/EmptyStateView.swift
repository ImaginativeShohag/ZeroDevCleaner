//
//  EmptyStateView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI
import SwiftData

struct EmptyStateView: View {
    let hasConfiguredLocations: Bool
    let onStartScan: () -> Void
    let onOpenSettings: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CleaningSession.timestamp, order: .reverse)
    private var allSessions: [CleaningSession]

    @State private var statistics: CleaningStatistics = .empty

    var body: some View {
        HStack(spacing: 0) {
            // Left side - Main action area
            VStack(spacing: 24) {
                if hasConfiguredLocations {
                    // Has configured locations - ready to scan
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue)
                        .iconPulse()

                    VStack(spacing: 8) {
                        Text("Ready to Scan")
                            .font(.title)
                            .fontWeight(.semibold)

                        Text("Click Scan to find cache files")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        Text("System caches and configured locations will be scanned")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Button(action: onStartScan) {
                        Label("Scan", systemImage: "play.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.return, modifiers: .command)
                    .buttonHoverEffect()
                } else {
                    // No locations configured - prompt to add
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                        .iconPulse()

                    VStack(spacing: 8) {
                        Text("No Scan Locations")
                            .font(.title)
                            .fontWeight(.semibold)

                        Text("Add your projects path in settings")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        Text("System caches will be scanned automatically")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Button(action: onOpenSettings) {
                        Label("Open Settings", systemImage: "gear")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .buttonHoverEffect()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Right side - Statistics
            VStack(alignment: .leading, spacing: 16) {
                Text("Statistics")
                    .font(.title2)
                    .fontWeight(.semibold)

                if allSessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)

                        Text("No statistics yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Statistics will appear after cleaning")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Summary Cards
                            StatsSummaryCard(
                                title: "Total Cleaned",
                                value: statistics.formattedTotalSize,
                                icon: "trash.fill",
                                color: .blue
                            )

                            StatsSummaryCard(
                                title: "Sessions",
                                value: "\(statistics.sessionCount)",
                                icon: "clock.fill",
                                color: .green
                            )

                            StatsSummaryCard(
                                title: "Items Deleted",
                                value: "\(statistics.totalItemsCleaned)",
                                icon: "doc.on.doc.fill",
                                color: .orange
                            )

                            StatsSummaryCard(
                                title: "Avg per Session",
                                value: statistics.formattedAverageSize,
                                icon: "chart.bar.fill",
                                color: .purple
                            )

                            Divider()

                            // Recent sessions
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recent Sessions")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)

                                ForEach(allSessions.prefix(5)) { session in
                                    HStack(spacing: 8) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(session.formattedTimestamp)
                                                .font(.caption)
                                                .lineLimit(1)

                                            Text("\(session.itemCount) items")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Text(session.formattedTotalSize)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.blue)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .frame(width: 280)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        }
        .onAppear {
            computeStatistics()
        }
        .onChange(of: allSessions) { _, _ in
            computeStatistics()
        }
    }

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

#Preview("No Locations") {
    EmptyStateView(
        hasConfiguredLocations: false,
        onStartScan: {},
        onOpenSettings: {}
    )
}

#Preview("Has Locations") {
    EmptyStateView(
        hasConfiguredLocations: true,
        onStartScan: {},
        onOpenSettings: {}
    )
}
