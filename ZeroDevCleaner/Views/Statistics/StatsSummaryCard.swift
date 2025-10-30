//
//  StatsSummaryCard.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 31/10/25.
//

import SwiftUI

struct StatsSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    StatsSummaryCard(
        title: "Total Cleaned",
        value: "12.5 GB",
        icon: "trash.fill",
        color: .blue
    )
    .padding()
    .frame(width: 280)
}
