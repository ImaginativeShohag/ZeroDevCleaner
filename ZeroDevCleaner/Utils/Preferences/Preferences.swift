//
//  Copyright © 2024 Md. Mahmudul Hasan Shohag. All rights reserved.
//

import Foundation

/// This `enum` is contains the keys for the `Preferences`.
extension Key {
    static let customCacheLocations: Key = "custom_cache_locations"
    static let scanLocations: Key = "scan_locations"
}

/// `Preferences` is a wrapper for `UserDefaults`.
///
/// Basic usages:
///
/// ```swift
/// let locations = Preferences.customCacheLocations
/// ```
///
/// Observation example:
///
/// ```swift
/// var observation = Preferences.$customCacheLocations.observe { old, new in
///     print("Changed from: \(old) to \(new)")
/// }
/// ```
@MainActor
public enum Preferences {
    @CodableUserDefault(key: .customCacheLocations)
    static var customCacheLocations: [CustomCacheLocation]?

    @CodableUserDefault(key: .scanLocations)
    static var scanLocations: [ScanLocation]?

    // MARK: - Reset

    public static func reset() {
        customCacheLocations = nil
        scanLocations = nil
    }
}
