//
//  ComprehensiveFiltersView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 04/11/25.
//

import SwiftUI

struct ComprehensiveFiltersView: View {
    @Bindable var viewModel: MainViewModel

    var body: some View {
        HStack(spacing: 16) {
            // Size Filter
            HStack(spacing: 8) {
                Text("Size:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Size value picker
                Picker("Size Value", selection: Binding(
                    get: { viewModel.sizeFilterValue ?? -1 },
                    set: { newValue in
                        viewModel.sizeFilterValue = newValue == -1 ? nil : newValue
                    }
                )) {
                    Text("Any").tag(Int64(-1))
                    Divider()
                    Text("100 MB").tag(Int64(100 * 1024 * 1024))
                    Text("500 MB").tag(Int64(500 * 1024 * 1024))
                    Text("1 GB").tag(Int64(1 * 1024 * 1024 * 1024))
                    Text("5 GB").tag(Int64(5 * 1024 * 1024 * 1024))
                    Text("10 GB").tag(Int64(10 * 1024 * 1024 * 1024))
                    Text("50 GB").tag(Int64(50 * 1024 * 1024 * 1024))
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 100)

                // Size condition picker
                Picker("Size Operator", selection: $viewModel.sizeFilterOperator) {
                    ForEach(MainViewModel.ComparisonOperator.allCases, id: \.self) { op in
                        Text(op.displayName).tag(op)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 60)
                .disabled(viewModel.sizeFilterValue == nil)
            }

            Divider()
                .frame(height: 20)

            // Days Old Filter
            HStack(spacing: 8) {
                Text("Days Old:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Days value picker
                Picker("Days Value", selection: Binding(
                    get: { viewModel.daysOldFilterValue ?? -1 },
                    set: { newValue in
                        viewModel.daysOldFilterValue = newValue == -1 ? nil : newValue
                    }
                )) {
                    Text("Any").tag(-1)
                    Divider()
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                    Text("60 days").tag(60)
                    Text("90 days").tag(90)
                    Text("180 days").tag(180)
                    Text("365 days").tag(365)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 100)

                // Days condition picker
                Picker("Days Operator", selection: $viewModel.daysOldFilterOperator) {
                    ForEach(MainViewModel.ComparisonOperator.allCases, id: \.self) { op in
                        Text(op.displayName).tag(op)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 60)
                .disabled(viewModel.daysOldFilterValue == nil)
            }

            Spacer()

            // Clear button
            if viewModel.sizeFilterValue != nil || viewModel.daysOldFilterValue != nil {
                Button {
                    viewModel.sizeFilterValue = nil
                    viewModel.daysOldFilterValue = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear")
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    ComprehensiveFiltersView(viewModel: MainViewModel())
        .frame(width: 700)
}
