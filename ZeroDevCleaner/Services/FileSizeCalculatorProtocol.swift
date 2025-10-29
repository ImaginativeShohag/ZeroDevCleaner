//
//  FileSizeCalculatorProtocol.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation

/// Protocol for calculating directory sizes
protocol FileSizeCalculatorProtocol: Sendable {
    /// Calculates the total size of a directory
    func calculateSize(of url: URL) async throws -> Int64
}
