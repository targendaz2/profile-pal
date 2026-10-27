//
//  Manifest.swift
//  ProfilePal
//
//  Created by David Rosenberg on 10/27/26.
//

import Foundation
import SemanticVersion

/// A payload manifest describing one payload domain and its fields.
struct Manifest: Codable, Sendable {
    // MARK: - Apple-defined keys

    /// The payload's domain, used as its `PayloadType`.
    let domain: String

    /// The human-readable title of the payload.
    let title: String?

    /// A description of the payload.
    let description: String?

    /// The payload's fields.
    let subkeys: [ManifestField]

    /// The scopes where the payload is valid. Defaults to `.user`.
    let targets: [ManifestTarget]?

    /// The version of the manifest file.
    ///
    /// Bump only when subkeys are added or removed.
    let version: Int?

    /// The version of the manifest format.
    let formatVersion: Int

    // MARK: - Extended keys

    /// An identifier that lets one payload domain be split across multiple manifest files.
    ///
    /// Without it, files sharing a `domain` are treated as duplicates and overwrite each other.
    let subdomain: String?

    /// How settings combine when multiple payloads of this type are installed on a device.
    let interaction: ManifestInteraction

    /// A 64×64 pixel image representing the payload.
    let icon: Data?

    /// A note that draws the user's attention to something specific about the payload.
    let note: String?

    /// Whether the device must be supervised for the payload to work.
    ///
    /// - Note: Supervision isn't available on macOS; see `userApproved`.
    let supervised: Bool?

    /// Whether the device must be user approved, or enrolled using DEP, for the payload to work.
    let userApproved: Bool?

    /// The iOS version that started supporting the payload.
    let iOSMin: SemanticVersion?

    /// The iOS version that deprecated the payload.
    let iOSDeprecated: SemanticVersion?

    /// The iOS version that stopped supporting the payload.
    let iOSMax: SemanticVersion?

    /// The macOS version that started supporting the payload.
    let macOSMin: SemanticVersion?

    /// The macOS version that deprecated the payload.
    let macOSDeprecated: SemanticVersion?

    /// The macOS version that stopped supporting the payload.
    let macOSMax: SemanticVersion?

    /// The tvOS version that started supporting the payload.
    let tvOSMin: SemanticVersion?

    /// The tvOS version that deprecated the payload.
    let tvOSDeprecated: SemanticVersion?

    /// The tvOS version that stopped supporting the payload.
    let tvOSMax: SemanticVersion?

    /// The date the manifest was last modified.
    let lastModified: Date?

    enum CodingKeys: String, CodingKey {
        case domain = "pfm_domain"
        case title = "pfm_title"
        case description = "pfm_description"
        case subkeys = "pfm_subkeys"
        case targets = "pfm_targets"
        case version = "pfm_version"
        case formatVersion = "pfm_format_version"

        case subdomain = "pfm_subdomain"
        case interaction = "pfm_interaction"
        case icon = "pfm_icon"
        case note = "pfm_note"
        case supervised = "pfm_supervised"
        case userApproved = "pfm_user_approved"
        case iOSMin = "pfm_ios_min"
        case iOSDeprecated = "pfm_ios_deprecated"
        case iOSMax = "pfm_ios_max"
        case macOSMin = "pfm_macos_min"
        case macOSDeprecated = "pfm_macos_deprecated"
        case macOSMax = "pfm_macos_max"
        case tvOSMin = "pfm_tvos_min"
        case tvOSDeprecated = "pfm_tvos_deprecated"
        case tvOSMax = "pfm_tvos_max"
        case lastModified = "pfm_last_modified"
    }

    /// Decodes a manifest from the property list file at `url`.
    ///
    /// - Throws: An error if the file can't be read or isn't a valid manifest.
    static func load(from url: URL) throws -> Self {
        let data = try Data(contentsOf: url)
        return try PropertyListDecoder().decode(Self.self, from: data)
    }
}

/// How settings combine when multiple payloads of the same type are installed on a device.
enum ManifestInteraction: String, Codable, Sendable {
    /// The settings from every installed payload are merged.
    case combined

    /// Only one payload of this type can be in effect at a time.
    case exclusive

    /// The behavior isn't documented.
    case undefined
}

/// A scope where a payload or field is valid.
enum ManifestTarget: String, Codable, Sendable {
    /// The user channel, whether installed manually or by MDM.
    case user

    /// The user channel, only when installed by MDM.
    case userManaged = "user-managed"

    /// The device channel, whether installed manually or by MDM.
    case system

    /// The device channel, only when installed by MDM.
    case systemManaged = "system-managed"
}
