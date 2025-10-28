//
//  ZeroDevCleanerError.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation

/// Custom errors for ZeroDevCleaner operations
enum ZeroDevCleanerError: LocalizedError {
    case permissionDenied(URL)
    case fileNotFound(URL)
    case deletionFailed(URL, Error)
    case scanCancelled
    case invalidPath(URL)
    case calculationFailed(URL, Error)
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let url):
            return "Permission denied to access: \(url.path)"

        case .fileNotFound(let url):
            return "File or folder not found: \(url.path)"

        case .deletionFailed(let url, let error):
            return "Failed to delete \(url.lastPathComponent): \(error.localizedDescription)"

        case .scanCancelled:
            return "Scan was cancelled"

        case .invalidPath(let url):
            return "Invalid path: \(url.path)"

        case .calculationFailed(let url, let error):
            return "Failed to calculate size of \(url.lastPathComponent): \(error.localizedDescription)"

        case .unknownError(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Please grant Full Disk Access in System Settings → Privacy & Security → Full Disk Access"

        case .fileNotFound:
            return "The file may have been moved or deleted. Try scanning again."

        case .deletionFailed:
            return "Make sure you have write permissions and the file is not in use."

        case .scanCancelled:
            return "You can start a new scan whenever you're ready."

        case .invalidPath:
            return "Please select a valid directory path."

        case .calculationFailed:
            return "The folder may be inaccessible. Try scanning with elevated permissions."

        case .unknownError:
            return "Please try again or contact support if the problem persists."
        }
    }
}
