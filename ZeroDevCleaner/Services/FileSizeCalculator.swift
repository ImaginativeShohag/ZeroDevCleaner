//
//  FileSizeCalculator.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation

final class FileSizeCalculator: FileSizeCalculatorProtocol {
    nonisolated(unsafe) private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func calculateSize(of url: URL) async throws -> Int64 {
        try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    let size = try self.calculateSizeSync(of: url)
                    continuation.resume(returning: size)
                } catch {
                    continuation.resume(throwing: ZeroDevCleanerError.calculationFailed(url, error))
                }
            }
        }
    }

    private nonisolated func calculateSizeSync(of url: URL) throws -> Int64 {
        var totalSize: Int64 = 0
        let keys: [URLResourceKey] = [.isDirectoryKey, .totalFileSizeKey, .fileSizeKey]

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            throw ZeroDevCleanerError.invalidPath(url)
        }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(keys)) else {
                continue
            }

            if let fileSize = resourceValues.totalFileSize ?? resourceValues.fileSize {
                totalSize += Int64(fileSize)
            }
        }

        return totalSize
    }
}
