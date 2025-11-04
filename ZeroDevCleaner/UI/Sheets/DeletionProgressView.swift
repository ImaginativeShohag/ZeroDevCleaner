//
//  DeletionProgressView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import SwiftUI

struct DeletionProgressView: View {
    let currentItem: String
    let progress: Double
    let currentIndex: Int
    let totalItems: Int
    let deletedSize: Int64
    let totalSize: Int64
    let canCancel: Bool
    let onCancel: () -> Void

    var deletedSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: deletedSize, countStyle: .file)
    }

    var totalSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text("Deleting Build Folders...")
                .font(.headline)

            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            // Current item
            VStack(spacing: 8) {
                Text("Deleting:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(currentItem)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity)
            }

            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)

                HStack {
                    Text("\(currentIndex) of \(totalItems)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(deletedSizeFormatted) of \(totalSizeFormatted)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            // Cancel button
            if canCancel {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .buttonHoverEffect()
            }
        }
        .padding(32)
        .frame(width: 400)
    }
}

#Preview("Start") {
    DeletionProgressView(
        currentItem: "FirstProject",
        progress: 0.09,
        currentIndex: 1,
        totalItems: 11,
        deletedSize: 1024 * 1024 * 10,
        totalSize: 1024 * 1024 * 112,
        canCancel: true,
        onCancel: {}
    )
}

#Preview("Mid Progress") {
    DeletionProgressView(
        currentItem: "MyAndroidApp",
        progress: 0.45,
        currentIndex: 5,
        totalItems: 11,
        deletedSize: 1024 * 1024 * 50,
        totalSize: 1024 * 1024 * 112,
        canCancel: true,
        onCancel: {}
    )
}

#Preview("Almost Complete") {
    DeletionProgressView(
        currentItem: "LastProject",
        progress: 0.95,
        currentIndex: 10,
        totalItems: 11,
        deletedSize: 1024 * 1024 * 106,
        totalSize: 1024 * 1024 * 112,
        canCancel: false,
        onCancel: {}
    )
}
