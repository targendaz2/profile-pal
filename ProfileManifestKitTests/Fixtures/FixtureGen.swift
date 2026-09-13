//
//  FixtureGen.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation

/// Builds property-list fixtures programmatically so the emitted XML is always
/// well-formed. Construct a manifest as nested dictionaries/arrays, then call
/// `xmlData()` or `write(to:)`. Because PropertyListSerialization does the
/// encoding, you can't produce the malformed XML that hand-writing invites.
enum PlistFixture {
    /// A manifest payload with the required top-level keys pre-filled.
    /// Pass subkeys built with `key(...)`.
    static func manifest(
        domain: String,
        title: String,
        formatVersion: Int = 1,
        subkeys: [[String: Any]],
    ) -> [String: Any] {
        [
            "pfm_domain": domain,
            "pfm_title": title,
            "pfm_format_version": formatVersion,
            "pfm_subkeys": subkeys,
            "pfm_version": 1,
            "pfm_interaction": "undefined",
            "pfm_last_modified": Date().ISO8601Format(),
            "pfm_unique": true,
        ]
    }

    /// A single subkey. Only the fields you pass are emitted, so fixtures stay
    /// minimal. `extra` carries any pfm_* keys this helper doesn't name.
    static func key(
        name: String? = nil,
        type: String,
        title: String? = nil,
        `default`: Any? = nil,
        placeholder: Any? = nil,
        rangeList: [Any]? = nil,
        rangeListTitles: [String]? = nil,
        required: Bool? = nil,
        require: String? = nil,
        subkeys: [[String: Any]]? = nil,
        extra: [String: Any] = [:],
    ) -> [String: Any] {
        var dict: [String: Any] = ["pfm_type": type]
        if let name { dict["pfm_name"] = name }
        if let title { dict["pfm_title"] = title }
        if let d = `default` { dict["pfm_default"] = d }
        if let placeholder { dict["pfm_value_placeholder"] = placeholder }
        if let rangeList { dict["pfm_range_list"] = rangeList }
        if let rangeListTitles { dict["pfm_range_list_titles"] = rangeListTitles }
        if let required { dict["pfm_required"] = required }
        if let require { dict["pfm_require"] = require }
        if let subkeys { dict["pfm_subkeys"] = subkeys }
        for (k, v) in extra { dict[k] = v }
        return dict
    }

    /// A pfm_conditionals entry.
    static func conditional(
        require: String? = nil,
        targets: [[String: Any]],
    ) -> [String: Any] {
        var dict: [String: Any] = ["pfm_target_conditions": targets]
        if let require { dict["pfm_require"] = require }
        return dict
    }

    /// A pfm_exclude entry.
    static func exclusion(targets: [[String: Any]]) -> [String: Any] {
        ["pfm_target_conditions": targets]
    }

    /// A single target condition. Pass whichever operator applies via `extra`,
    /// e.g. ["pfm_range_list": ["VPN"]] or ["pfm_present": true].
    static func condition(target: String, _ extra: [String: Any]) -> [String: Any] {
        var dict: [String: Any] = ["pfm_target": target]
        for (k, v) in extra { dict[k] = v }
        return dict
    }

    // MARK: Emit

    /// Serialize to well-formed XML plist data.
    static func xmlData(_ root: [String: Any]) throws -> Data {
        try PropertyListSerialization.data(
            fromPropertyList: root,
            format: .xml,
            options: 0,
        )
    }

    /// Write a fixture to disk (e.g. into Tests/.../Fixtures/).
    static func write(_ root: [String: Any], to url: URL) throws {
        try xmlData(root).write(to: url)
    }
}
