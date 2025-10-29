//
//  FileDeleterProtocol.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 29/10/25.
//

import Foundation

/// Progress callback for deletion operations
typealias DeletionProgressHandler = @Sendable (Int, Int) -> Void

/// Protocol for deleting build folders
protocol FileDeleterProtocol: Sendable {
    /// Deletes folders by moving them to Trash
    /// - Parameters:
    ///   - folders: Folders to delete
    ///   - progressHandler: Called with current index and total count
    func delete(
        folders: [BuildFolder],
        progressHandler: DeletionProgressHandler?
    ) async throws
}
