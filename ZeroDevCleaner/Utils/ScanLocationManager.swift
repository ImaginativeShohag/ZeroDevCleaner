//
//  ScanLocationManager.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import Foundation
import Observation

/// Manages saved scan locations with persistent storage
@Observable
@MainActor
final class ScanLocationManager {
    static let shared = ScanLocationManager()

    var locations: [ScanLocation] = [] {
        didSet {
            saveLocations()
        }
    }

    init() {
        loadLocations()
    }

    func addLocation(_ location: ScanLocation) {
        locations.append(location)
    }

    func removeLocation(_ location: ScanLocation) {
        locations.removeAll { $0.id == location.id }
    }

    func updateLocation(_ location: ScanLocation) {
        if let index = locations.firstIndex(where: { $0.id == location.id }) {
            locations[index] = location
        }
    }

    func toggleEnabled(for location: ScanLocation) {
        if let index = locations.firstIndex(where: { $0.id == location.id }) {
            locations[index].isEnabled.toggle()
        }
    }

    func updateLastScanned(for location: ScanLocation) {
        if let index = locations.firstIndex(where: { $0.id == location.id }) {
            locations[index].lastScanned = Date()
        }
    }

    var enabledLocations: [ScanLocation] {
        locations.filter(\.isEnabled)
    }

    private func saveLocations() {
        Preferences.scanLocations = locations
    }

    private func loadLocations() {
        if let savedLocations = Preferences.scanLocations {
            locations = savedLocations
        }
    }
}
