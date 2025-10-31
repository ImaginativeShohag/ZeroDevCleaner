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

#Preview {
    HStack(spacing: 16) {
        StatsSummaryCard(
            title: "Total Cleaned",
            value: "12.5 GB",
            icon: "trash.fill",
            color: .blue
        )

        StatsSummaryCard(
            title: "Sessions",
            value: "42",
            icon: "clock.fill",
            color: .green
        )
    }
    .padding()
}
