//
//  ManifestCondition.swift
//  ProfilePal
//
//  Created by David Rosenberg on 10/26/26.
//

import Foundation

/// A condition that tests the state of another field.
struct ManifestTargetCondition: Codable, Sendable {
    /// The name of the target field.
    let target: String

    /// Whether the target field must be present in the payload.
    let present: Bool?

    /// The values the target field's value must be one of.
    let rangeList: [PlistValue]?

    /// The values the target field's value must not be one of.
    let negatedRangeList: [PlistValue]?

    /// The values the target field's value must contain at least one of.
    let containsAny: [PlistValue]?

    /// The values the target field's value must not contain any of.
    let negatedContainsAny: [PlistValue]?

    enum CodingKeys: String, CodingKey {
        case target = "pfm_target"
        case present = "pfm_present"
        case rangeList = "pfm_range_list"
        case negatedRangeList = "pfm_n_range_list"
        case containsAny = "pfm_contains_any"
        case negatedContainsAny = "pfm_n_contains_any"
    }
}

/// A rule that changes when the field is required once all of its conditions match.
struct ManifestConditionalRule: Codable, Sendable {
    /// When the field must be present in the payload if the conditions match.
    let require: ManifestRequirement?

    /// The conditions that must all match for the rule to apply.
    let targetConditions: [ManifestTargetCondition]

    enum CodingKeys: String, CodingKey {
        case require = "pfm_require"
        case targetConditions = "pfm_target_conditions"
    }
}

/// A rule that excludes the field from the payload once all of its conditions match.
struct ManifestExclusionRule: Codable, Sendable {
    /// The conditions that must all match for the field to be excluded.
    let targetConditions: [ManifestTargetCondition]

    enum CodingKeys: String, CodingKey {
        case targetConditions = "pfm_target_conditions"
    }
}
