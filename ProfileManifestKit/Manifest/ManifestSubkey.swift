//
//  ManifestSubkey.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation

/// A single key within a manifest. Represents one `pfm_subkeys` entry — a field the
/// user configures. Subkeys nest: dictionaries and arrays carry their own `subkeys`.
struct ManifestSubkey: Sendable, Decodable, Equatable {
    // MARK: - Identity & docs

    /// `pfm_name` — the key's name. **Optional**: keys that are immediate subkeys of an
    /// array have no name (they're positional), so this is nil for array-element subkeys.
    var name: String?

    /// `pfm_title` — human-readable title shown as the field label.
    var title: String?

    /// `pfm_description` — description of the key.
    var description: String?

    /// `pfm_description_extended` — longer clarifying text.
    var descriptionExtended: String?

    /// `pfm_note` — a note to bring something to the user's attention.
    var note: String?

    // MARK: - Type & value

    /// `pfm_type` — the stored plist type of this key's value.
    var type: PFMType

    /// `pfm_type_input` — overrides the type the *user* edits, when it differs from `type`.
    var typeInput: PFMType?

    /// `pfm_default` — the key's default value. Only set when the app defines a real default;
    /// same plist type as `type`. Use `placeholder` for example values instead.
    var defaultValue: PFMValue?

    /// `pfm_value_placeholder` — an example value shown but never exported.
    var placeholder: PFMValue?

    // MARK: - Constraints

    /// `pfm_range_list` — the set of legal values (renders as a picker).
    var rangeList: [PFMValue]?

    /// `pfm_range_list_titles` — human labels matching `rangeList` one-to-one.
    var rangeListTitles: [String]?

    /// `pfm_range_list_allow_custom_value` — let the user enter a value outside the list.
    var rangeListAllowsCustom: Bool?

    /// `pfm_range_min` — minimum numeric value.
    var rangeMin: PFMValue?

    /// `pfm_range_max` — maximum numeric value.
    var rangeMax: PFMValue?

    /// `pfm_format` — a regular expression the value must match.
    var format: String?

    /// `pfm_repetition_min` — minimum number of items in an array.
    var repetitionMin: Int?

    /// `pfm_repetition_max` — maximum number of items in an array.
    var repetitionMax: Int?

    // MARK: - Requirement

    /// `pfm_require` — string form: `always` / `always-nested` / `push`.
    var require: RequireMode?

    /// `pfm_required` — boolean shorthand; `true` is equivalent to `pfm_require = always`.
    var required: Bool?

    /// `pfm_conditionals` — conditions under which this key becomes required.
    var conditionals: [Conditional]?

    // MARK: - Visibility

    /// `pfm_exclude` — conditions under which this key is dropped from the payload entirely.
    var exclude: [Exclusion]?

    /// `pfm_hidden` — statically hide the key or its container (`all` / `container`).
    var hidden: HiddenMode?

    /// `pfm_enabled` — whether the key is included in the payload content by default.
    var enabled: Bool?

    /// `pfm_excluded` — whether the key is excluded from the exported payload.
    var excluded: Bool?

    // MARK: - Presentation

    /// `pfm_view` — overrides the default control (e.g. `slider`).
    var view: String?

    /// `pfm_segments` — segment title → array of keypaths, for a segmented control.
    var segments: [String: [String]]?

    /// `pfm_value_unit` — unit the value represents (e.g. "milliseconds").
    var valueUnit: String?

    /// `pfm_value_inverted` — the user-entered boolean should be stored inverted.
    var valueInverted: Bool?

    /// `pfm_date_style` — date-picker style (`dateAndTime` / `time`).
    var dateStyle: String?

    /// `pfm_date_allow_past` — allow past dates in the picker.
    var dateAllowPast: Bool?

    /// `pfm_sensitive` — value may be sensitive; profile encryption may be warranted.
    var sensitive: Bool?

    /// `pfm_allowed_file_types` — file extensions/UTIs allowed for a `data` value.
    var allowedFileTypes: [String]?

    // MARK: - Platform gating

    /// `pfm_platforms` — platforms that support this key.
    var platforms: [String]?

    /// `pfm_n_platforms` — platforms that do *not* support this key.
    var nPlatforms: [String]?

    /// `pfm_macos_min` — first macOS version supporting this key.
    var macosMin: String?

    /// `pfm_macos_max` — last macOS version supporting this key.
    var macosMax: String?

    // MARK: - Nesting

    /// `pfm_subkeys` — keys nested under this one (for `dictionary` and `array` types).
    var subkeys: [ManifestSubkey]?

    enum CodingKeys: String, CodingKey {
        case name = "pfm_name"
        case title = "pfm_title"
        case description = "pfm_description"
        case descriptionExtended = "pfm_description_extended"
        case note = "pfm_note"
        case type = "pfm_type"
        case typeInput = "pfm_type_input"
        case defaultValue = "pfm_default"
        case placeholder = "pfm_value_placeholder"
        case rangeList = "pfm_range_list"
        case rangeListTitles = "pfm_range_list_titles"
        case rangeListAllowsCustom = "pfm_range_list_allow_custom_value"
        case rangeMin = "pfm_range_min"
        case rangeMax = "pfm_range_max"
        case format = "pfm_format"
        case repetitionMin = "pfm_repetition_min"
        case repetitionMax = "pfm_repetition_max"
        case require = "pfm_require"
        case required = "pfm_required"
        case conditionals = "pfm_conditionals"
        case exclude = "pfm_exclude"
        case hidden = "pfm_hidden"
        case enabled = "pfm_enabled"
        case excluded = "pfm_excluded"
        case view = "pfm_view"
        case segments = "pfm_segments"
        case valueUnit = "pfm_value_unit"
        case valueInverted = "pfm_value_inverted"
        case dateStyle = "pfm_date_style"
        case dateAllowPast = "pfm_date_allow_past"
        case sensitive = "pfm_sensitive"
        case allowedFileTypes = "pfm_allowed_file_types"
        case platforms = "pfm_platforms"
        case nPlatforms = "pfm_n_platforms"
        case macosMin = "pfm_macos_min"
        case macosMax = "pfm_macos_max"
        case subkeys = "pfm_subkeys"
    }
}
