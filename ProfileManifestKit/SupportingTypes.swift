//
//  SupportingTypes.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation

enum RequireMode: String, Sendable, Decodable {
    case always
    case alwaysNested = "always-nested"
    case push
}

enum HiddenMode: String, Sendable, Decodable {
    case all
    case container
}

// `pfm_conditionals` entry — makes a key conditionally required.
struct Conditional: Sendable, Decodable {
    var require: RequireMode?  // if nil, the conditional has no effect
    var targetConditions: [TargetCondition]
    enum CodingKeys: String, CodingKey {
        case require = "pfm_require"
        case targetConditions = "pfm_target_conditions"
    }
}

/// `pfm_exclude` entry — conditionally drops a key from the payload.
struct Exclusion: Sendable, Decodable {
    var targetConditions: [TargetCondition]

    enum CodingKeys: String, CodingKey {
        case targetConditions = "pfm_target_conditions"
    }
}

/// One condition inside a `pfm_target_conditions` array.
struct TargetCondition: Sendable, Decodable {
    /// dotted keypath to the key being evaluated
    var target: String?

    /// pfm_domain — cross-payload targeting
    var domain: String?

    /// pfm_present
    var present: Bool?

    /// pfm_value_empty
    var valueEmpty: Bool?

    /// pfm_range_list (equals-any)
    var rangeList: [PFMValue]?

    /// pfm_n_range_list (not-equals-any)
    var nRangeList: [PFMValue]?

    /// pfm_contains_any
    var containsAny: [PFMValue]?

    /// pfm_n_contains_any
    var nContainsAny: [PFMValue]?

    /// pfm_platforms (extended condition)
    var platforms: [String]?

    enum CodingKeys: String, CodingKey {
        case target = "pfm_target"
        case domain = "pfm_domain"
        case present = "pfm_present"
        case valueEmpty = "pfm_value_empty"
        case rangeList = "pfm_range_list"
        case nRangeList = "pfm_n_range_list"
        case containsAny = "pfm_contains_any"
        case nContainsAny = "pfm_n_contains_any"
        case platforms = "pfm_platforms"
    }
}
