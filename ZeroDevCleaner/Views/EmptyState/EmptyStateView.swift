//
//  EmptyStateView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI
import SwiftData
import Charts

struct EmptyStateView: View {
    let hasConfiguredLocations: Bool
    let onStartScan: () -> Void
    let onOpenSettings: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CleaningSession.timestamp, order: .reverse)
    private var allSessions: [CleaningSession]

    @State private var statistics: CleaningStatistics = .empty

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Statistics Section at Top
                if !allSessions.isEmpty {
                    VStack(spacing: 20) {
                        // Summary Cards Grid
                        HStack(spacing: 16) {
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
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)

                        // Cleaning History Chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cleaning History")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)

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
                            .padding(.horizontal)
                        }

                        Divider()
                            .padding(.vertical, 8)
                    }
                }

                // Scan Action Section at Bottom
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
                .frame(maxWidth: .infinity)
                .padding(.vertical, allSessions.isEmpty ? 100 : 40)
            }
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
