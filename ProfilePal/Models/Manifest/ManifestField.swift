//
//  ManifestField.swift
//  ProfilePal
//
//  Created by David Rosenberg on 10/26/26.
//

import Foundation

/// A single field in the manifest schema.
struct ManifestField: Codable, Sendable {
    // MARK: - Apple-defined keys

    /// The name of the field.
    ///
    /// Required on all fields except immediate subkeys of an array.
    let name: String?

    /// The human-readable title of the field.
    let title: String?

    /// A description of the field.
    let description: String?

    /// The data type of the field's value.
    let type: ManifestFieldType

    /// The field's default value.
    ///
    /// Only set when the app's source or documentation confirms a real default; use
    /// `placeholder` for example values. Don't combine with `require`.
    ///
    /// - Important: Must match the field's `type`.
    let defaultValue: PlistValue?

    /// The allowed values for the field.
    ///
    /// - Important: Each value must match the field's `type`.
    let rangeList: [PlistValue]?

    /// The minimum value for the field.
    let rangeMin: Double?

    /// The maximum value for the field.
    let rangeMax: Double?

    /// A regular expression the field's value must match.
    let format: String?

    /// The field's nested fields.
    let subkeys: [ManifestField]?

    /// The minimum number of items allowed in an array.
    let repetitionMin: Int?

    /// The maximum number of items allowed in an array.
    let repetitionMax: Int?

    /// When the field must be present in the payload.
    let require: ManifestRequirement?

    /// Whether the field must be present in the payload.
    ///
    /// `true` is equivalent to setting `require` to `.always`.
    let required: Bool?

    /// The conditions under which the field is required.
    let conditionals: [ManifestConditionalRule]?

    /// The conditions under which the field is excluded from the payload.
    let exclude: [ManifestExclusionRule]?

    /// The scopes where the field is valid. Defaults to `.user`.
    let targets: [ManifestTarget]?

    // MARK: - Extended keys

    /// An example value shown to the user, never included in the exported payload.
    ///
    /// Use instead of `defaultValue` when the app doesn't define a real default.
    /// Ignored when `defaultValue` is set.
    let placeholder: PlistValue?

    /// The human-readable titles for the values in `rangeList`.
    ///
    /// - Important: Must contain the same number of items as `rangeList`.
    let rangeListTitles: [String]?

    /// The unit the field's value represents, such as milliseconds, hours, or characters.
    let valueUnit: String?

    /// A note that draws the user's attention to something specific about the field.
    let note: String?

    /// A URL to additional documentation for the field.
    let documentationURL: URL?

    /// Whether the field's value may be sensitive enough to warrant encrypting the profile.
    let sensitive: Bool?

    /// Whether the device must be supervised for the field to work.
    ///
    /// - Note: Supervision isn't available on macOS; see `userApproved`.
    let supervised: Bool?

    /// Whether the device must be user approved, or enrolled using DEP, for the field to work.
    let userApproved: Bool?

    /// The iOS version that started supporting the field.
    let iOSMin: String?

    /// The iOS version that deprecated the field.
    let iOSDeprecated: String?

    /// The iOS version that stopped supporting the field.
    let iOSMax: String?

    /// The macOS version that started supporting the field.
    let macOSMin: String?

    /// The macOS version that deprecated the field.
    let macOSDeprecated: String?

    /// The macOS version that stopped supporting the field.
    let macOSMax: String?

    /// The tvOS version that started supporting the field.
    let tvOSMin: String?

    /// The tvOS version that deprecated the field.
    let tvOSDeprecated: String?

    /// The tvOS version that stopped supporting the field.
    let tvOSMax: String?

    enum CodingKeys: String, CodingKey {
        case name = "pfm_name"
        case title = "pfm_title"
        case description = "pfm_description"
        case type = "pfm_type"
        case defaultValue = "pfm_default"
        case rangeList = "pfm_range_list"
        case rangeMin = "pfm_range_min"
        case rangeMax = "pfm_range_max"
        case format = "pfm_format"
        case subkeys = "pfm_subkeys"
        case repetitionMin = "pfm_repetition_min"
        case repetitionMax = "pfm_repetition_max"
        case require = "pfm_require"
        case required = "pfm_required"
        case conditionals = "pfm_conditionals"
        case exclude = "pfm_exclude"
        case targets = "pfm_targets"

        case placeholder = "pfm_value_placeholder"
        case rangeListTitles = "pfm_range_list_titles"
        case valueUnit = "pfm_value_unit"
        case note = "pfm_note"
        case documentationURL = "pfm_documentation_url"
        case sensitive = "pfm_sensitive"
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
    }
}

/// The data type of a field's value.
enum ManifestFieldType: String, Codable, Sendable {
    case string
    case boolean
    case integer
    case real
    case array
    case dictionary
    case data
    case date
}

/// When a field must be present in the payload.
enum ManifestRequirement: String, Codable, Sendable {
    /// The field is always required.
    case always

    /// The field is required only when the profile is pushed by MDM.
    case push
}
