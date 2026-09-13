//
//  PayloadManifest.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation

/// A decoded payload manifest — the top-level `.plist` describing one payload domain
/// and its keys. Maps the `pfm_*` payload-level keys from the ProfileManifests format.
public struct PayloadManifest: Sendable, Decodable {
    /// `pfm_domain` — the payload's domain, written as `PayloadType` on export.
    public var domain: String

    /// `pfm_title` — human-readable payload title.
    public var title: String

    /// `pfm_description` — description of the payload.
    public var description: String?

    /// `pfm_format_version` — the preference-manifest format version.
    var formatVersion: Int?

    /// `pfm_version` — version of this manifest file.
    var version: Int?

    /// `pfm_subkeys` — the payload's keys, in display order.
    public var subkeys: [ManifestSubkey]

    /// `pfm_unique` — whether only one payload of this type may be installed.
    var unique: Bool?

    /// `pfm_subdomain` — disambiguates multiple files sharing one domain.
    var subdomain: String?

    /// `pfm_targets` — scopes where the payload is valid (user/system/…).
    var targets: [String]?

    /// `pfm_platforms` — platforms the payload supports.
    var platforms: [String]?

    enum CodingKeys: String, CodingKey {
        case domain = "pfm_domain"
        case title = "pfm_title"
        case description = "pfm_description"
        case formatVersion = "pfm_format_version"
        case version = "pfm_version"
        case subkeys = "pfm_subkeys"
        case unique = "pfm_unique"
        case subdomain = "pfm_subdomain"
        case targets = "pfm_targets"
        case platforms = "pfm_platforms"
    }
}
