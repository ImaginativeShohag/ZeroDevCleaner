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
    @State private var selectedDateRange: DateRange = .allTime
    @State private var chartViewType: ChartViewType = .daily

    var filteredSessions: [CleaningSession] {
        guard let startDate = selectedDateRange.startDate() else {
            return allSessions
        }
        return allSessions.filter { $0.timestamp >= startDate }
    }

    var chartDataPoints: [ChartDataPoint] {
        switch chartViewType {
        case .daily:
            return dailyDataPoints
        case .monthly:
            return monthlyDataPoints
        case .yearly:
            return yearlyDataPoints
        case .cumulative:
            return cumulativeDataPoints
        }
    }

    private var dailyDataPoints: [ChartDataPoint] {
        filteredSessions.map { session in
            ChartDataPoint(date: session.timestamp, size: session.totalSize, sessionCount: 1)
        }
    }

    private var monthlyDataPoints: [ChartDataPoint] {
        let calendar = Calendar.current
        var monthlyData: [String: (size: Int64, count: Int)] = [:]

        for session in filteredSessions {
            let components = calendar.dateComponents([.year, .month], from: session.timestamp)
            if let date = calendar.date(from: components) {
                let key = date.ISO8601Format()
                if var existing = monthlyData[key] {
                    existing.size += session.totalSize
                    existing.count += 1
                    monthlyData[key] = existing
                } else {
                    monthlyData[key] = (session.totalSize, 1)
                }
            }
        }

        return monthlyData.map { key, value in
            ChartDataPoint(date: ISO8601DateFormatter().date(from: key) ?? Date(), size: value.size, sessionCount: value.count)
        }.sorted { $0.date < $1.date }
    }

    private var yearlyDataPoints: [ChartDataPoint] {
        let calendar = Calendar.current
        var yearlyData: [String: (size: Int64, count: Int)] = [:]

        for session in filteredSessions {
            let components = calendar.dateComponents([.year], from: session.timestamp)
            if let date = calendar.date(from: components) {
                let key = date.ISO8601Format()
                if var existing = yearlyData[key] {
                    existing.size += session.totalSize
                    existing.count += 1
                    yearlyData[key] = existing
                } else {
                    yearlyData[key] = (session.totalSize, 1)
                }
            }
        }

        return yearlyData.map { key, value in
            ChartDataPoint(date: ISO8601DateFormatter().date(from: key) ?? Date(), size: value.size, sessionCount: value.count)
        }.sorted { $0.date < $1.date }
    }

    private var cumulativeDataPoints: [ChartDataPoint] {
        var cumulative: Int64 = 0
        return filteredSessions.reversed().map { session in
            cumulative += session.totalSize
            return ChartDataPoint(date: session.timestamp, size: cumulative, sessionCount: 1)
        }
    }

    private var axisLabelFormat: Date.FormatStyle {
        switch chartViewType {
        case .daily:
            return .dateTime.month().day()
        case .monthly:
            return .dateTime.year().month(.abbreviated)
        case .yearly:
            return .dateTime.year()
        case .cumulative:
            return .dateTime.month().day()
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Section - Primary Scan Action
                VStack(spacing: 16) {
                    Spacer()

                    if hasConfiguredLocations {
                        // Has configured locations - ready to scan
                        VStack(spacing: 24) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.blue.gradient)
                                .iconPulse()
                                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)

                            VStack(spacing: 12) {
                                Text("Ready to Scan")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)

                                Text("Find and clean build artifacts, caches, and temporary files")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 500)
                            }

                            Button(action: onStartScan) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.fill")
                                        .font(.title3)
                                    Text("Start Scanning")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                                .frame(minWidth: 200)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .keyboardShortcut(.return, modifiers: .command)
                            .buttonHoverEffect()
                            .shadow(color: .accentColor.opacity(0.3), radius: 10, x: 0, y: 5)

                            // Warning message
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Must review before deletion")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.top, 8)
                        }
                    } else {
                        // No locations configured - prompt to add
                        VStack(spacing: 24) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 80))
                                .foregroundStyle(.orange.gradient)
                                .iconPulse()
                                .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)

                            VStack(spacing: 12) {
                                Text("Get Started")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)

                                Text("Add your project folders to start scanning")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 500)

                                Text("System caches will be automatically included")
                                    .font(.callout)
                                    .foregroundStyle(.tertiary)
                            }

                            Button(action: onOpenSettings) {
                                HStack(spacing: 12) {
                                    Image(systemName: "gear")
                                        .font(.title3)
                                    Text("Open Settings")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                                .frame(minWidth: 200)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .buttonHoverEffect()
                            .shadow(color: .accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

                // Statistics Section - Always visible
                Divider()
                    .padding(.vertical, 20)

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

                        // Cleaning History Chart
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "chart.xyaxis.line")
                                    .foregroundStyle(.blue)
                                Text("Cleaning History")
                                    .font(.title3)
                                    .fontWeight(.semibold)

                                Spacer()

                                // Date Range Picker
                                Picker("Time Period", selection: $selectedDateRange) {
                                    ForEach(DateRange.allCases) { range in
                                        Text(range.rawValue).tag(range)
                                    }
                                }
                                .pickerStyle(.menu)

                                // Chart View Type Picker
                                Picker("Chart View", selection: $chartViewType) {
                                    ForEach(ChartViewType.allCases) { viewType in
                                        Label(viewType.rawValue, systemImage: viewType.icon)
                                            .tag(viewType)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                            }
                            .padding(.horizontal)

                            GroupBox {
                                Chart {
                                    ForEach(chartDataPoints) { dataPoint in
                                        if chartViewType == .cumulative {
                                            // Line chart for cumulative view
                                            LineMark(
                                                x: .value("Date", dataPoint.date),
                                                y: .value("Size", dataPoint.sizeInGB)
                                            )
                                            .foregroundStyle(.blue.gradient)
                                            .lineStyle(StrokeStyle(lineWidth: 3))

                                            AreaMark(
                                                x: .value("Date", dataPoint.date),
                                                y: .value("Size", dataPoint.sizeInGB)
                                            )
                                            .foregroundStyle(.blue.opacity(0.1).gradient)
                                        } else {
                                            // Bar chart for daily/monthly/yearly views
                                            BarMark(
                                                x: .value("Date", dataPoint.date),
                                                y: .value("Size", dataPoint.sizeInGB)
                                            )
                                            .foregroundStyle(.blue.gradient)
                                        }
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks(position: .leading) { value in
                                        AxisGridLine()
                                        AxisValueLabel {
                                            if let doubleValue = value.as(Double.self) {
                                                Text("\(String(format: "%.1f", doubleValue)) GB")
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks { value in
                                        AxisGridLine()
                                        AxisValueLabel(format: axisLabelFormat)
                                    }
                                }
                                .frame(height: 220)
                                .padding()
                            }
                            .padding(.horizontal)
                        }

                        // Project Breakdown Section
                        if !statistics.projectBreakdown.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "chart.pie.fill")
                                        .foregroundStyle(.green)
                                    Text("Project Breakdown")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal)

                                GroupBox {
                                    VStack(alignment: .leading, spacing: 12) {
                                        // Sort by size descending
                                        let sortedProjects = statistics.projectBreakdown.values.sorted { $0.totalSize > $1.totalSize }

                                        ForEach(sortedProjects, id: \.projectType) { stats in
                                            HStack {
                                                // Project type icon and name
                                                if let projectType = ProjectType(rawValue: stats.projectType.lowercased()) {
                                                    Image(systemName: projectType.iconName)
                                                        .foregroundStyle(projectType.color)
                                                        .frame(width: 20)
                                                    Text(projectType.displayName)
                                                        .font(.headline)
                                                } else {
                                                    Image(systemName: "folder.fill")
                                                        .foregroundStyle(.gray)
                                                        .frame(width: 20)
                                                    Text(stats.projectType)
                                                        .font(.headline)
                                                }

                                                Spacer()

                                                // Stats
                                                VStack(alignment: .trailing, spacing: 2) {
                                                    Text(stats.formattedSize)
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                        .monospacedDigit()
                                                    Text("\(stats.itemCount) item\(stats.itemCount == 1 ? "" : "s")")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            .padding(.vertical, 8)

                                            if stats.projectType != sortedProjects.last?.projectType {
                                                Divider()
                                            }
                                        }
                                    }
                                    .padding()
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            computeStatistics()
        }
        .onChange(of: allSessions) { _, _ in
            computeStatistics()
        }
        .onChange(of: selectedDateRange) { _, _ in
            computeStatistics()
        }
    }

    private func computeStatistics() {
        guard !filteredSessions.isEmpty else {
            statistics = CleaningStatistics(totalSizeCleaned: 0, sessionCount: 0, totalItemsCleaned: 0, projectBreakdown: [:])
            return
        }

        let totalSize = filteredSessions.reduce(0) { $0 + $1.totalSize }
        let totalItems = filteredSessions.reduce(0) { $0 + $1.itemCount }

        // Compute project breakdown
        var projectBreakdown: [String: ProjectStats] = [:]

        for session in filteredSessions {
            for item in session.items {
                guard let projectType = item.projectType else { continue }

                if let existingStats = projectBreakdown[projectType] {
                    projectBreakdown[projectType] = ProjectStats(
                        projectType: projectType,
                        totalSize: existingStats.totalSize + item.size,
                        itemCount: existingStats.itemCount + 1
                    )
                } else {
                    projectBreakdown[projectType] = ProjectStats(
                        projectType: projectType,
                        totalSize: item.size,
                        itemCount: 1
                    )
                }
            }
        }

        statistics = CleaningStatistics(
            totalSizeCleaned: totalSize,
            sessionCount: filteredSessions.count,
            totalItemsCleaned: totalItems,
            projectBreakdown: projectBreakdown
        )
    }
}

// MARK: - Quick Info Card Component

struct QuickInfoCard: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
