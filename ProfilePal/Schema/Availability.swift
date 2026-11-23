//
//  Availability.swift
//  ProfilePal
//
//  Created by David Rosenberg on 11/22/26.
//

import Foundation
import VersionKit

/// The platforms, versions, and device requirements a payload or field works with.
nonisolated struct Availability: Sendable, Hashable {
    /// The versions that started supporting, deprecated, and stopped supporting something.
    nonisolated struct VersionRange: Sendable, Hashable {
        /// The version that started supporting it.
        let introduced: Version?

        /// The version that deprecated it.
        let deprecated: Version?

        /// The version that stopped supporting it.
        let removed: Version?
    }

    /// The platforms that support it, or `nil` when the source doesn't say.
    let supportedPlatforms: Set<Platform>?

    /// The platforms that don't support it.
    let unsupportedPlatforms: Set<Platform>

    /// The OS versions it's available on, for each platform the source gives versions for.
    let versions: [Platform: VersionRange]

    /// The app versions it's available in, or `nil` when the source gives none.
    let app: VersionRange?

    /// Whether the device must be supervised for it to work.
    let requiresSupervision: Bool

    /// Whether the device must be user approved, or enrolled using DEP, for it to work.
    let requiresUserApproval: Bool
}
