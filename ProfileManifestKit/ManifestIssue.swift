//
//  ManifestIssue.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 11/28/26.
//

import Foundation

/// A problem the kit found while loading a manifest, and handled without failing the load.
public struct ManifestIssue: Sendable, Hashable {
    /// The names of the fields from the manifest's root down to the field with the problem.
    ///
    /// An array's unnamed item appears as `[]`. A dictionary entry with no subkey of its own
    /// appears as its key.
    public let fieldPath: [String]

    /// The manifest key that holds the value, such as `pfm_default`.
    public let key: String

    /// What the kit found, and what it did about it.
    public let kind: Kind

    /// What the kit found, and what it did about it.
    public enum Kind: Sendable, Hashable {
        /// A value, as written, that was loaded as the field's type.
        case valueConverted(from: PlistValue, to: ManifestFieldType)

        /// A value, as written, that couldn't be loaded as the field's type, so it was left out.
        case valueDropped(PlistValue, expected: ManifestFieldType)
    }
}
