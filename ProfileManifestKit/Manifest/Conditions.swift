//
//  Conditions.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation

/// `pfm_conditionals` entry — makes a key conditionally required.
struct PFMConditional: Sendable, Decodable, Equatable {
    /// Specifies conditions that this key has a dependency with.
    var targetConditions: [PFMTargetCondition]

    /// Specifies how the key will be required if the conditions are met. If omitted, the conditional has no effect.
    var require: PFMRequireMode?

    enum CodingKeys: String, CodingKey {
        case targetConditions = "pfm_target_conditions"
        case require = "pfm_require"
    }

    enum PFMRequireMode: String, Sendable, Decodable {
        /// The key is always required.
        case always

        /// The key is only required when installed via an MDM.
        case push
    }
}

/// `pfm_exclude` entry — conditionally drops a key from the payload.
struct PFMExclusion: Sendable, Decodable, Equatable {
    /// Specifies conditions that this key has a dependency with.
    var targetConditions: [PFMTargetCondition]?

    enum CodingKeys: String, CodingKey {
        case targetConditions = "pfm_target_conditions"
    }
}

/// One condition inside a `pfm_target_conditions` array.
struct PFMTargetCondition: Sendable, Decodable, Equatable {
    /// Evaluates whether the target key value is set to any value from this key.
    /// Important: The array must be the same type as the target key's `pfm_type`.
    var containsAny: [FormValue]?

    /// Evaluates whether the target key value is NOT set to any value from this key.
    /// Important: The array must be the same type as the target key's `pfm_type`.
    var nContainsAny: [FormValue]?

    /// Evaluates whether the target key value does NOT match the value of this key.
    /// Important: The array must be the same type as the target key's `pfm_type`.
    var nRangeList: [FormValue]?

    /// Evaluates the existence of the target key in the exported payload.
    /// If set to `true` the condition satisfies when the target key is present.
    /// If set to `false` the condition satisfies when the target key is absent.
    var present: Bool?

    /// Evaluates whether the target key value matches the value of this key.
    /// Important: The array must be the same type as the target key's `pfm_type`.
    var rangeList: [FormValue]?

    /// The target key to evaluate. For nested keys, the key names can be separated by a dot "."
    var target: String?

    /// Evaluates whether the target key has an empty value in the exported payload.
    var valueEmpty: Bool?

    /// The domain for the target key to evaluate. If not set, the payload domain is used.
    var domain: String?

    /// Which platforms to apply the conditions to.
    /// If the only key present, which platforms to require/exclude the key for.
    var platforms: [PFMPlatform]?

    enum CodingKeys: String, CodingKey {
        case containsAny = "pfm_contains_any"
        case nContainsAny = "pfm_n_contains_any"
        case nRangeList = "pfm_n_range_list"
        case present = "pfm_present"
        case rangeList = "pfm_range_list"
        case target = "pfm_target"
        case valueEmpty = "pfm_value_empty"

        case domain = "pfm_domain"
        case platforms = "pfm_platforms"
    }
}
