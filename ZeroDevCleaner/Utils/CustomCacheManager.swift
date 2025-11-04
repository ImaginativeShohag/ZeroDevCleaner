//
//  CustomCacheManager.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 31/10/25.
//

import Foundation
import Observation

/// Manages persistence and validation of custom cache locations
@MainActor
@Observable
final class CustomCacheManager {
    private(set) var locations: [CustomCacheLocation] = []

    // Singleton instance
    static let shared = CustomCacheManager()

    private init() {
        loadLocations()
    }

    // MARK: - CRUD Operations

    /// Add a new custom cache location
    func addLocation(_ location: CustomCacheLocation) {
        // Validate before adding
        guard location.validate() else {
            SuperLog.w("Attempted to add invalid location: \(location.path.path)")
            return
        }

        // Check for duplicates
        if locations.contains(where: { $0.path == location.path }) {
            SuperLog.w("Location already exists: \(location.path.path)")
            return
        }

        locations.append(location)
        saveLocations()
        SuperLog.i("Added custom cache location: \(location.name)")
    }

    /// Update an existing location
    func updateLocation(_ location: CustomCacheLocation) {
        guard let index = locations.firstIndex(where: { $0.id == location.id }) else {
            SuperLog.w("Location not found for update: \(location.id)")
            return
        }

        locations[index] = location
        saveLocations()
        SuperLog.i("Updated custom cache location: \(location.name)")
    }

    /// Remove a location by ID
    func removeLocation(id: UUID) {
        guard let index = locations.firstIndex(where: { $0.id == id }) else {
            SuperLog.w("Location not found for removal: \(id)")
            return
        }

        let name = locations[index].name
        locations.remove(at: index)
        saveLocations()
        SuperLog.i("Removed custom cache location: \(name)")
    }

    /// Toggle enabled state for a location
    func toggleEnabled(id: UUID) {
        guard let index = locations.firstIndex(where: { $0.id == id }) else {
            return
        }

        locations[index].isEnabled.toggle()
        saveLocations()
    }

    /// Update last scanned time for a location
    func updateLastScanned(id: UUID, date: Date = Date()) {
        guard let index = locations.firstIndex(where: { $0.id == id }) else {
            return
        }

        locations[index].lastScanned = date
        saveLocations()
    }

    /// Get all enabled locations
    var enabledLocations: [CustomCacheLocation] {
        locations.filter(\.isEnabled)
    }

    // MARK: - Persistence

    private func saveLocations() {
        Preferences.customCacheLocations = locations
        SuperLog.d("Saved \(self.locations.count) custom cache locations")
    }

    private func loadLocations() {
        if let savedLocations = Preferences.customCacheLocations {
            locations = savedLocations
            SuperLog.i("Loaded \(self.locations.count) custom cache locations")
        } else {
            SuperLog.d("No saved custom cache locations found")
        }
    }
}
