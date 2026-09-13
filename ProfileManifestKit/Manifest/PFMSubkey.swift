//
//  PFMSubkey.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation

/// A single key within a manifest. Represents one `pfm_subkeys` entry — a field the
/// user configures. Subkeys nest: dictionaries and arrays carry their own `subkeys`.
struct PFMSubkey: Sendable, Decodable, Equatable {
    // MARK: Apple-defined keys

    /// Indicates the conditions whether this key should be required.
    var conditionals: [PFMConditional]?

    /// The key's default value.
    /// Important: Must be the same type as the key's `pfm_type`.
    /// Only set this when the app's source or documentation confirms an actual default. For example or template values, use `pfm_value_placeholder` instead. Do not combine with `pfm_require` — a required key with a default is contradictory.
    var defaultValue: PFMValue?

    /// Description of the key.
    var description: String?

    /// Indicates the conditions whether this key should be included in the payload.
    var exclude: [PFMExclusion]?

    /// A regular expression that the value must match.
    var format: String?

    /// The name of the key.
    /// Required on all keys except for keys which are immediate subkeys of an array.
    var name: String?

    /// The maximum number of items allowed in an array.
    var repetitionMax: Int?

    /// The minimum number of items allowed in an array.
    var repetitionMin: Int?

    /// Indicates whether this key is required to be present in the payload.
    var require: PFMRequireMode?

    /// Indicates whether this key is required to be present in the payload. If set to `true` it's equal to `pfm_require=always`.
    var required: Bool?

    /// An array of legal values for this key.
    /// Important: The array must be the same type as the key's `pfm_type`.
    var rangeList: [PFMValue]?

    /// The maximum value for this key.
    /// Important: Must be the same type as the key's `pfm_type`.
    var rangeMax: PFMValue?

    /// The minimum value for this key.
    /// Important: Must be the same type as the key's `pfm_type`.
    var rangeMin: PFMValue?

    /// This key describes keys nested under the current key.
    var subkeys: [PFMSubkey]?

    /// The scope where the payload is valid. Default value is: `user`.
    var targets: [PFMTarget]?

    /// The title of the key.
    var title: String?

    /// The data type of the value for this key.
    var type: PFMType

    // MARK: Extended keys

    /// File extensions or UTIs allowed when using a file as value for a `Data` key.
    var allowedFileTypes: [String]?

    /// Version of the Application that started deprecating the key or payload.
    var appDeprecated: String?

    /// The last version of the Application that supported the key.
    var appMax: String?

    /// Version of the Application that started supporting the key.
    /// Should be set on all new keys when they were introduced in a version newer than the app's initial release.
    var appMin: String?

    /// KeyPath to another key which value to copy as the default for this key.
    var defaultCopy: String?

    /// If set to `true` this key will allow the date picker to select dates in the past.
    var dateAllowPast: Bool?

    /// This key can be used to alter the style of the date picker. If no value is set, `dateAndTime` is used.
    var dateStyle: PFMDateStyle?

    /// An extended and more descriptive text used to for example clarify ambiguous behavior or add more context.
    var descriptionExtended: String?

    /// The exact description string from the documentation.
    var descriptionReference: String?

    /// URL to additional documentation for the key.
    var documentationURL: URL?

    /// If the key should be included in the payload content by default.
    var enabled: Bool?

    /// If the key should be excluded from the exported payload.
    var excluded: Bool?

    /// If the key or container should be hidden from the user by default.
    var hidden: PFMHiddenMode?

    /// Version of iOS that started deprecating the key.
    var iOSDeprecated: String?

    /// Version of iOS that stopped supporting the key.
    var iOSMax: String?

    /// Version of iOS that started supporting the key.
    var iOSMin: String?

    /// Version of macOS that started deprecating the key.
    var macOSDeprecated: String?

    /// Version of macOS that stopped supporting the key.
    var macOSMax: String?

    /// Version of macOS that started supporting the key.
    var macOSMin: String?

    /// A note to emphasize or bring something specific to the user's attention about the key.
    var note: String?

    /// Platforms that don't support the key.
    var nPlatforms: [PFMPlatform]?

    /// Platforms that support the key.
    var platforms: [PFMPlatform]?

    /// Will allow the user to either select a value from a popUp list or enter a custom value.
    /// Note: This key is ignored if `pfm_type_input` is set.
    var rangeListAllowCustom: Bool?

    /// Titles matching the values in the `pfm_range_list` key. Titles should be human-readable labels, not the raw values themselves.
    /// Important: If this key is used together with `pfm_range_list` it must contain an equal number of items.
    var rangeListTitles: [String]?

    /// This key can be used show a segmented control.
    /// The keys in the dictionary will be set as the segment titles.
    /// The value is an array of strings where each string is the KeyPath for each key to show under the selected segment.
    var segments: [String: [String]]?

    /// Indication that the value for this key might be sensitive and that encrypting the profile might be necessary to protect the value.
    var sensitive: Bool?

    /// Dictionary where the keys are available substitution variables and their value is a Substitution Variables Dictionary.
    var substitutionVariables: [String: PFMSubstitutionVariable]?

    /// Requires the device to be supervised for this key to work.
    /// Note: Supervision is not available on macOS, see `pfm_user_approved`.
    var supervised: Bool?

    /// The data type of the input value for this key.
    /// This is used when it makes sense for the user to input another value type than the `pfm_type` specifies.
    /// See also: `pfm_value_processor`.
    var typeInput: PFMType?

    /// Version of tvOS that started deprecating the key.
    var tvOSDeprecated: String?

    /// Version of tvOS that stopped supporting the key.
    var tvOSMax: String?

    /// Version of tvOS that started supporting the key.
    var tvOSMin: String?

    /// Requires the device to be user approved, or enrolled using DEP for this key to work.
    var userApproved: Bool?

    /// KeyPath to another key whose value to copy as the value for this key.
    /// This will disable user input for this key.
    var valueCopy: String?

    /// Only available for `pfm_type`: `real`.
    /// Number of decimal places to be used when setting and exporting the value.
    var valueDecimalPlaces: Int?

    /// Only available for `pfm_type`: `boolean`.
    /// Indicates that the user entered value should be inverted.
    /// This key is used when the `pfm_title` or `pfm_description` is worded in such a way that the value must be inverted to work as expected for the key.
    var valueInverted: Bool?

    /// Name of the value import processor to use when converting an item dropped on the cellview to valid settings.
    /// Note: This enables drag n drop for cellviews that doesn't normally use it.
    /// See also: `pfm_allowed_file_types`
    var valueImportProcessor: String?

    /// Name of the value info processor to use when displaying the information for a `Data` value.
    var valueInfoProcessor: String?

    /// Placeholder value for the key. Placeholder value is never included in the exported payload, it's only used to show an example value.
    /// Use this instead of `pfm_default` for example or template values (e.g., domain.example.com) where the app does not define an actual default.
    /// If `pfm_default` is used for a preference, this will override any value supplied by `pfm_value_placeholder`. As such, this key should only be used when a `pfm_default` value is not defined.
    var placeholder: PFMValue?

    /// Name of the value processor to use when converting a user entered value to the exported value.
    var valueProcessor: String?

    /// When used in a payload subkey that has `pfm_type` or `pfm_type_input` set to array, the items in the array must be unique.
    /// This key should be used as part of the `pfm_subkeys`, not the array preference itself.
    var unique: Bool?

    /// Unit that the value represents. Example: milliseconds, hours, characters etc.
    var valueUnit: String?

    /// The view used to represent the payload key.
    /// Note: This key is not needed for most payload keys and should not be included unless you need to change the default view.
    var view: PFMViewMode?

    // MARK: Coding keys
    enum CodingKeys: String, CodingKey {
        case conditionals = "pfm_conditionals"
        case defaultValue = "pfm_default"
        case description = "pfm_description"
        case exclude = "pfm_exclude"
        case format = "pfm_format"
        case name = "pfm_name"
        case repetitionMax = "pfm_repetition_max"
        case repetitionMin = "pfm_repetition_min"
        case require = "pfm_require"
        case required = "pfm_required"
        case rangeList = "pfm_range_list"
        case rangeMax = "pfm_range_max"
        case rangeMin = "pfm_range_min"
        case subkeys = "pfm_subkeys"
        case targets = "pfm_targets"
        case title = "pfm_title"
        case type = "pfm_type"

        case allowedFileTypes = "pfm_allowed_file_types"
        case appDeprecated = "pfm_app_deprecated"
        case appMax = "pfm_app_max"
        case appMin = "pfm_app_min"
        case defaultCopy = "pfm_default_copy"
        case dateAllowPast = "pfm_date_allow_past"
        case dateStyle = "pfm_date_style"
        case descriptionExtended = "pfm_description_extended"
        case descriptionReference = "pfm_description_reference"
        case documentationURL = "pfm_documentation_url"
        case enabled = "pfm_enabled"
        case excluded = "pfm_excluded"
        case hidden = "pfm_hidden"
        case iOSDeprecated = "pfm_ios_deprecated"
        case iOSMax = "pfm_ios_max"
        case iOSMin = "pfm_ios_min"
        case macOSDeprecated = "pfm_macos_deprecated"
        case macOSMax = "pfm_macos_max"
        case macOSMin = "pfm_macos_min"
        case note = "pfm_note"
        case nPlatforms = "pfm_n_platforms"
        case platforms = "pfm_platforms"
        case rangeListAllowCustom = "pfm_range_list_allow_custom_value"
        case rangeListTitles = "pfm_range_list_titles"
        case segments = "pfm_segments"
        case sensitive = "pfm_sensitive"
        case substitutionVariables = "pfm_substitution_variables"
        case supervised = "pfm_supervised"
        case typeInput = "pfm_type_input"
        case tvOSDeprecated = "pfm_tvos_deprecated"
        case tvOSMax = "pfm_tvos_max"
        case tvOSMin = "pfm_tvos_min"
        case userApproved = "pfm_user_approved"
        case valueCopy = "pfm_value_copy"
        case valueDecimalPlaces = "pfm_value_decimal_places"
        case valueInverted = "pfm_value_inverted"
        case valueImportProcessor = "pfm_value_import_processor"
        case valueInfoProcessor = "pfm_value_info_processor"
        case placeholder = "pfm_value_placeholder"
        case valueProcessor = "pfm_value_processor"
        case unique = "pfm_value_unique"
        case valueUnit = "pfm_value_unit"
        case view = "pfm_view"
    }
    
    // MARK: Subtypes
    
    enum PFMRequireMode: String, Sendable, Decodable {
        /// The key is always required.
        case always

        /// The key is always required even if it is in a nested dictionary.
        case alwaysNested = "always-nested"

        /// The key is only required when installed via an MDM.
        case push
    }

    enum PFMDateStyle: String, Sendable, Decodable {
        case dateAndTime, time
    }

    enum PFMHiddenMode: String, Sendable, Decodable {
        case all, container
    }

    enum PFMViewMode: String, Sendable, Decodable {
        case slider
    }
}
