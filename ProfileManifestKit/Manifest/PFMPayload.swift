//
//  PFMPayload.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation

/// A decoded payload manifest — the top-level `.plist` describing one payload domain
/// and its keys. Maps the `pfm_*` payload-level keys from the ProfileManifests format.
public struct PFMPayload: Sendable, Decodable {
    // MARK: Apple-defined keys

    /// Description of the key or payload.
    public var description: String?

    /// Domain of the payload, will be set as the `PayloadType`.
    public var domain: String

    /// The preference manifest format version.
    var formatVersion: Int?

    /// This key describes keys nested under the current key.
    var subkeys: [PFMSubkey]

    /// The scope where the payload is valid. Default value is: `user`.
    var targets: [PFMTarget]?

    /// The title of the key or payload.
    public var title: String

    /// Version of the manifest file. Bump only when subkeys are added or removed — not for description edits, format fixes, or default corrections.
    var version: Int

    // MARK: Extended keys

    /// URL to the Application's marketing/homepage. Do not use a download link.
    var appURL: URL?

    /// URL to additional documentation for the payload.
    var documentationURL: URL?

    /// Bsse64 encoded data of an image resource that is 64x64 pixels.
    var icon: String?

    /// How payload settings will interact when multiple payloads of the same type are installed on a device.
    var interaction: PFMInteraction

    /// Version of iOS that started deprecating the payload.
    var iOSDeprecated: String?

    /// Version of iOS that stopped supporting the payload.
    var iOSMax: String?

    /// Version of iOS that started supporting the payload.
    var iOSMin: String?

    /// Date the manifest was last modified.
    var lastModified: String

    /// Version of macOS that started deprecating the payload.
    var macOSDeprecated: String?

    /// Version of macOS that stopped supporting the payload.
    var macOSMax: String?

    /// Version of macOS that started supporting the payload.
    var macOSMin: String?

    /// A note to emphasize or bring something specific to the user's attention about the payload.
    var note: String?

    /// Platforms that support the payload.
    var platforms: [PFMPlatform]?

    /// Identifier used to allow a payload domain (`pfm_domain`) to be split in multiple files.
    /// If this is not set, multiple files with the same domain will be read as duplicates and overwrite each other.
    /// Useful for domains that have multiple uses like `com.apple.MCX` and `.GlobalPreferences`.
    var subdomain: String?

    /// Dictionary where the keys are available substitution variables and their value is a Substitution Variables Dictionary.
    var substitutionVariables: [String: PFMSubstitutionVariable]?

    /// Requires the device to be supervised for this payload to work.
    /// Note: Supervision is not available on macOS, see `pfm_user_approved`.
    var supervised: Bool?

    /// Version of tvOS that started deprecating the payload.
    var tvOSDeprecated: String?

    /// Version of tvOS that stopped supporting the payload.
    var tvOSMax: String?

    /// Version of tvOS that started supporting the payload.
    var tvOSMin: String?

    /// Indicates if multiple payloads of this type can be installed on a device. `true` = one payload; `false` = multiple payloads
    var unique: Bool

    /// Requires the device to be user approved, or enrolled using DEP for this payload to work.
    var userApproved: Bool?

    // MARK: Coding keys
    enum CodingKeys: String, CodingKey {
        case description = "pfm_description"
        case domain = "pfm_domain"
        case formatVersion = "pfm_format_version"
        case subkeys = "pfm_subkeys"
        case targets = "pfm_targets"
        case title = "pfm_title"
        case version = "pfm_version"

        case appURL = "pfm_app_url"
        case documentationURL = "pfm_documentation_url"
        case icon = "pfm_icon"
        case interaction = "pfm_interaction"
        case iOSDeprecated = "pfm_ios_deprecated"
        case iOSMax = "pfm_ios_max"
        case iOSMin = "pfm_ios_min"
        case lastModified = "pfm_last_modified"
        case macOSDeprecated = "pfm_macos_deprecated"
        case macOSMax = "pfm_macos_max"
        case macOSMin = "pfm_macos_min"
        case note = "pfm_note"
        case platforms = "pfm_platforms"
        case subdomain = "pfm_subdomain"
        case substitutionVariables = "pfm_substitution_variables"
        case supervised = "pfm_supervised"
        case tvOSDeprecated = "pfm_tvos_deprecated"
        case tvOSMax = "pfm_tvos_max"
        case tvOSMin = "pfm_tvos_min"
        case unique = "pfm_unique"
        case userApproved = "pfm_user_approved"
    }
    
    // MARK: Subtypes
    enum PFMInteraction: String, Sendable, Decodable {
        case combined, exclusive, undefined
    }
}
