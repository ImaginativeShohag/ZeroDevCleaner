//
//  SFSymbolPickerSheet.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 28/11/25.
//

import SwiftUI

struct SFSymbolPickerSheet: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    // Common SF Symbols for project types
    private let commonSymbols = [
        // Folders & Files
        "folder.fill", "folder.badge.gear", "folder.badge.plus", "folder.badge.minus",
        "shippingbox.fill", "archivebox.fill", "doc.fill", "doc.text.fill",
        "tray.full.fill", "tray.fill", "tray.2.fill", "cabinet.fill",

        // Development
        "hammer.fill", "wrench.and.screwdriver.fill", "terminal.fill", "chevron.left.forwardslash.chevron.right",
        "curlybraces", "curlybraces.square.fill", "swift", "gear.badge",
        "cpu.fill", "memorychip.fill", "figure.run", "building.columns.fill",

        // Apps & Platforms
        "app.badge.fill", "app.fill", "apps.iphone", "iphone",
        "ipad", "macbook", "applewatch", "appletv.fill",
        "visionpro.fill", "display", "desktopcomputer", "laptopcomputer",

        // Code & Build
        "cube.fill", "cube.transparent.fill", "square.stack.3d.up.fill", "building.2.fill",
        "gearshape.fill", "gearshape.2.fill", "gearshape.circle.fill", "slider.horizontal.3",
        "command.circle.fill", "option", "control", "command.square.fill",

        // Programming Languages
        "text.badge.star", "text.badge.checkmark", "text.badge.plus", "text.alignleft",
        "character.cursor.ibeam", "keyboard.fill", "ellipsis.curlybraces", "function",

        // Version Control
        "arrow.triangle.branch", "arrow.triangle.merge", "arrow.triangle.pull",
        "arrow.up.arrow.down.circle.fill", "point.3.connected.trianglepath.dotted", "link.circle.fill",

        // Database & Storage
        "externaldrive.fill", "internaldrive.fill", "externaldrive.connected.to.line.below.fill",
        "server.rack", "cylinder.fill", "opticaldiscdrive.fill", "sdcard.fill",

        // Network & Cloud
        "network", "wifi", "antenna.radiowaves.left.and.right", "globe",
        "cloud.fill", "icloud.fill", "arrow.down.circle.fill", "arrow.up.circle.fill",

        // Testing & Debug
        "ant.fill", "ladybug.fill", "gamecontroller.fill", "scope",
        "wrench.fill", "wrench.adjustable.fill", "location.fill.viewfinder", "target",

        // Energy & Performance
        "bolt.fill", "bolt.circle.fill", "bolt.horizontal.fill", "flame.fill",
        "flame.circle.fill", "gauge.high", "speedometer", "timer",

        // Symbols & Badges
        "star.fill", "heart.fill", "circle.fill", "square.fill",
        "triangle.fill", "diamond.fill", "hexagon.fill", "octagon.fill",
        "pentagon.fill", "seal.fill", "shield.fill", "badge.plus.radiowaves.right",

        // Arrows & Directions
        "arrow.up.circle.fill", "arrow.down.circle.fill", "arrow.left.circle.fill", "arrow.right.circle.fill",
        "arrow.triangle.2.circlepath", "arrow.clockwise.circle.fill", "arrow.counterclockwise.circle.fill",
        "arrow.up.right.circle.fill", "arrow.forward.circle.fill", "arrow.backward.circle.fill",

        // Special & Effects
        "sparkle", "sparkles", "wand.and.stars", "wand.and.stars.inverse",
        "lightbulb.fill", "lightbulb.circle.fill", "laser.burst", "atom",
        "magnifyingglass", "magnifyingglass.circle.fill", "sparkles.rectangle.stack.fill",

        // Charts & Analytics
        "chart.bar.fill", "chart.pie.fill", "chart.line.uptrend.xyaxis",
        "chart.xyaxis.line", "chart.bar.xaxis", "level.fill", "gauge.with.dots.needle.bottom.50percent",

        // Misc
        "brain", "brain.head.profile", "cpu", "sensor.fill",
        "poweron", "poweroff", "moon.fill", "sun.max.fill",
        "tag.fill", "bookmark.fill", "flag.fill", "flag.2.crossed.fill"
    ]

    private var filteredSymbols: [String] {
        if searchText.isEmpty {
            return commonSymbols
        } else {
            return commonSymbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 60, maximum: 80))
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("SF Symbols")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .buttonHoverEffect()
            }
            .padding()

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search symbols...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        VStack(spacing: 8) {
                            Image(systemName: symbol)
                                .font(.title)
                                .foregroundStyle(selectedIcon == symbol ? .white : .primary)
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedIcon == symbol ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(selectedIcon == symbol ? Color.accentColor : Color.clear, lineWidth: 2)
                                )

                            Text(symbol)
                                .font(.caption2)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                                .frame(height: 30)
                        }
                        .frame(width: 80)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedIcon = symbol
                            dismiss()
                        }
                        .hoverEffect(scale: 1.05, brightness: 0.1)
                    }
                }
                .padding()
            }

            if filteredSymbols.isEmpty {
                ContentUnavailableView {
                    Label("No Symbols Found", systemImage: "magnifyingglass")
                } description: {
                    Text("Try a different search term")
                }
                .frame(maxHeight: .infinity)
            }

            Divider()

            // Footer
            HStack {
                Text("\(filteredSymbols.count) symbols")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Tip: You can also type the symbol name directly in the text field")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }
}

#Preview {
    @Previewable @State var selectedIcon = "folder.fill"
    return SFSymbolPickerSheet(selectedIcon: $selectedIcon)
}
