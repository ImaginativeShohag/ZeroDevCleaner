//
//  ScanProgressView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import SwiftUI

struct ScanProgressView: View {
    let progress: Double
    let currentPath: String
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            ProgressView(value: progress, total: 1.0) {
                Text("Scanning...")
                    .font(.headline)
            } currentValueLabel: {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .progressViewStyle(.linear)
            .frame(maxWidth: 400)

            VStack(spacing: 8) {
                Text("Current Path:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(currentPath)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }

            Button("Cancel", action: onCancel)
                .buttonStyle(.bordered)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ScanProgressView(
        progress: 0.45,
        currentPath: "/Users/test/Projects/MyApp/build",
        onCancel: {}
    )
}
