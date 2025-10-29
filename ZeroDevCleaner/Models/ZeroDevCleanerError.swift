//
//  ZeroDevCleanerError.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation

/// Custom errors for ZeroDevCleaner operations
enum ZeroDevCleanerError: LocalizedError, Sendable {
    case permissionDenied(URL)
    case fileNotFound(URL)
    case deletionFailed(URL, Error)
    case scanCancelled
    case invalidPath(URL)
    case calculationFailed(URL, Error)
    case outOfDiskSpace
    case folderInUse(URL)
    case networkDriveNotSupported(URL)
    case noResultsFound(URL)
    case partialDeletionFailure([URL])
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission Denied"

        case .fileNotFound:
            return "Folder Not Found"

        case .deletionFailed(let url, _):
            return "Failed to Delete \(url.lastPathComponent)"

        case .scanCancelled:
            return "Scan Cancelled"

        case .invalidPath:
            return "Invalid Path"

        case .calculationFailed:
            return "Failed to Calculate Size"

        case .outOfDiskSpace:
            return "Out of Disk Space"

        case .folderInUse:
            return "Folder In Use"

        case .networkDriveNotSupported:
            return "Network Drive Not Supported"

        case .noResultsFound:
            return "No Build Folders Found"

        case .partialDeletionFailure:
            return "Some Items Could Not Be Deleted"

        case .unknownError:
            return "An Unexpected Error Occurred"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied(let url):
            return "ZeroDevCleaner needs Full Disk Access to scan '\(url.lastPathComponent)'.\n\nGrant Full Disk Access in System Settings → Privacy & Security → Full Disk Access, then restart the app."

        case .fileNotFound(let url):
            return "The folder '\(url.lastPathComponent)' no longer exists or has been moved.\n\nTry scanning a different folder or refresh your scan."

        case .deletionFailed(let url, let error):
            return "Could not delete '\(url.lastPathComponent)'.\n\nMake sure the folder is not in use by another application. Close any apps using it and try again.\n\nDetails: \(error.localizedDescription)"

        case .scanCancelled:
            return "The scan was cancelled. You can start a new scan whenever you're ready."

        case .invalidPath(let url):
            return "The path '\(url.path)' is not valid.\n\nPlease select a valid directory using the folder selector."

        case .calculationFailed(let url, let error):
            return "Could not calculate the size of '\(url.lastPathComponent)'.\n\nThe folder may be inaccessible or corrupted.\n\nDetails: \(error.localizedDescription)"

        case .outOfDiskSpace:
            return "Your disk is out of space.\n\nFree up some space and try again. You can use this app to delete build folders to reclaim space!"

        case .folderInUse(let url):
            return "The folder '\(url.lastPathComponent)' is currently in use.\n\nClose any applications using this folder (Xcode, Android Studio, etc.) and try again."

        case .networkDriveNotSupported(let url):
            return "Cannot scan '\(url.lastPathComponent)' because it's on a network drive.\n\nNetwork drives are not currently supported. Please scan local folders only."

        case .noResultsFound(let url):
            return "No build folders were found in '\(url.lastPathComponent)'.\n\nTry scanning a different folder that contains Android, iOS, or Swift Package projects with build artifacts."

        case .partialDeletionFailure(let urls):
            let count = urls.count
            let names = urls.prefix(3).map { $0.lastPathComponent }.joined(separator: ", ")
            let more = count > 3 ? " and \(count - 3) more" : ""
            return "\(count) item(s) could not be deleted: \(names)\(more).\n\nThese folders may be in use by other applications. Close those apps and try again."

        case .unknownError(let error):
            return "An unexpected error occurred: \(error.localizedDescription)\n\nPlease try again. If the problem persists, try restarting the app."
        }
    }
}
