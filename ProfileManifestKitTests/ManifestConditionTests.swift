//
//  ManifestConditionTests.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 11/20/26.
//

import Foundation
import Testing

@testable import ProfileManifestKit

@Suite("ManifestCondition")
struct ManifestConditionTests {
    // Each list can hold values of any plist type, since it's compared against another field's
    // value, so the lists mix types to show each element decodes on its own.
    @Test("Decodes every target condition key into its property")
    func targetConditionAllKeys() async throws {
        // Given a target condition with every key set to a distinct value
        // And range lists that mix value types
        let data = try fixtureData(
            subject: "ManifestCondition",
            named: "target-condition-all-keys",
        )

        // When the condition is decoded as a ManifestTargetCondition
        let condition = try PropertyListDecoder().decode(ManifestTargetCondition.self, from: data)

        // Then each key's value is in its property
        #expect(condition.target == "Mode")
        #expect(condition.present == false)
        #expect(condition.rangeList == [.string("auto"), .int(2)])
        #expect(condition.negatedRangeList == [.bool(true), .double(1.5)])
        #expect(condition.containsAny == [.string("wifi")])
        #expect(condition.negatedContainsAny == [.int(7)])
    }

    // The spec requires pfm_target, but real manifests leave it out of conditions that test the
    // platform instead of a field, so the models accept it missing (see docs/decisions.md).
    @Test("Decodes a target condition without pfm_target")
    func targetConditionMissingTarget() async throws {
        // Given a target condition whose only key is pfm_present
        let data = try fixtureData(
            subject: "ManifestCondition",
            named: "target-condition-missing-target",
        )

        // When the condition is decoded as a ManifestTargetCondition
        let condition = try PropertyListDecoder().decode(ManifestTargetCondition.self, from: data)

        // Then it has no target
        #expect(condition.target == nil)

        // And its other keys still decode
        #expect(condition.present == true)
    }

    @Test("Decodes a conditional rule with only target conditions")
    func conditionalRuleMinimal() async throws {
        // Given a conditional rule whose only key is pfm_target_conditions
        let data = try fixtureData(subject: "ManifestCondition", named: "conditional-rule-minimal")

        // When the rule is decoded as a ManifestConditionalRule
        let rule = try PropertyListDecoder().decode(ManifestConditionalRule.self, from: data)

        // Then its target conditions are the key's value
        #expect(rule.targetConditions.map(\.target) == ["Enabled"])

        // And it has no requirement, since pfm_require is optional
        #expect(rule.require == nil)
    }

    @Test("Throws when a conditional rule's pfm_target_conditions is missing")
    func conditionalRuleMissingConditions() async throws {
        // Given a conditional rule with pfm_require but no pfm_target_conditions key
        let data = try fixtureData(
            subject: "ManifestCondition",
            named: "conditional-rule-missing-conditions",
        )

        // When the rule is decoded as a ManifestConditionalRule
        let error = try #require(throws: DecodingError.self) {
            try PropertyListDecoder().decode(ManifestConditionalRule.self, from: data)
        }

        // Then decoding fails because a required key is absent
        guard case .keyNotFound(let key, _) = error else {
            Issue.record("Expected keyNotFound, got \(error)")
            return
        }

        // And the absent key is pfm_target_conditions
        #expect(key.stringValue == "pfm_target_conditions")
    }

    @Test("Throws when an exclusion rule's pfm_target_conditions is missing")
    func exclusionRuleMissingConditions() async throws {
        // Given an exclusion rule with no keys
        let data = try fixtureData(
            subject: "ManifestCondition",
            named: "exclusion-rule-missing-conditions",
        )

        // When the rule is decoded as a ManifestExclusionRule
        let error = try #require(throws: DecodingError.self) {
            try PropertyListDecoder().decode(ManifestExclusionRule.self, from: data)
        }

        // Then decoding fails because a required key is absent
        guard case .keyNotFound(let key, _) = error else {
            Issue.record("Expected keyNotFound, got \(error)")
            return
        }

        // And the absent key is pfm_target_conditions
        #expect(key.stringValue == "pfm_target_conditions")
    }
}
