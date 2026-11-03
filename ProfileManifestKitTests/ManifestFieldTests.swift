//
//  ManifestFieldTests.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 11/2/26.
//

import Foundation
import Testing

@testable import ProfileManifestKit

@Suite("ManifestField")
struct ManifestFieldTests {
    @Test("Decodes every key into its property")
    func allKeys() async throws {
        // Given a field with every key set to a distinct value
        let data = try fixtureData(subject: "ManifestField", named: "all-keys")

        // When the field is decoded as a ManifestField
        let field = try PropertyListDecoder().decode(ManifestField.self, from: data)

        // Then each Apple-defined key's value is in its property
        #expect(field.name == "Timeout")
        #expect(field.title == "Idle Timeout")
        #expect(field.description == "How long to wait before locking.")
        #expect(field.type == .integer)
        #expect(field.defaultValue == .int(5))
        #expect(field.rangeList == [.int(1), .int(5), .int(10)])
        #expect(field.rangeMin == 0.5)
        #expect(field.rangeMax == 60.5)
        #expect(field.format == "^[0-9]+$")
        let subkey = try #require(field.subkeys?.only)
        #expect(subkey.name == "Child")
        #expect(subkey.type == .string)
        #expect(field.repetitionMin == 2)
        #expect(field.repetitionMax == 8)
        #expect(field.require == .push)
        #expect(field.required == true)
        let conditional = try #require(field.conditionals?.only)
        #expect(conditional.require == .always)
        let conditionalTarget = try #require(conditional.targetConditions.only)
        #expect(conditionalTarget.target == "Enabled")
        #expect(conditionalTarget.present == true)
        let exclusion = try #require(field.exclude?.only)
        let exclusionTarget = try #require(exclusion.targetConditions.only)
        #expect(exclusionTarget.target == "Mode")
        #expect(exclusionTarget.rangeList == [.string("off")])
        #expect(field.targets == [.system])

        // And each extended key's value is in its property
        #expect(field.placeholder == .int(15))
        #expect(field.rangeListTitles == ["One", "Five", "Ten"])
        #expect(field.valueUnit == "minutes")
        #expect(field.note == "Applies after restart.")
        #expect(field.documentationURL == "https://example.com/docs")
        #expect(field.sensitive == true)
        #expect(field.supervised == false)
        #expect(field.userApproved == true)
        #expect(field.iOSMin == "14.0")
        #expect(field.iOSDeprecated == "15.0")
        #expect(field.iOSMax == "16.0")
        #expect(field.macOSMin == "11.0")
        #expect(field.macOSDeprecated == "12.0")
        #expect(field.macOSMax == "13.0")
        #expect(field.tvOSMin == "17.0")
        #expect(field.tvOSDeprecated == "18.0")
        #expect(field.tvOSMax == "19.0")
    }

    @Test("Decodes a field with only a type")
    func minimal() async throws {
        // Given a field whose only key is pfm_type
        let data = try fixtureData(subject: "ManifestField", named: "minimal")

        // When the field is decoded as a ManifestField
        let field = try PropertyListDecoder().decode(ManifestField.self, from: data)

        // Then its type is the key's value
        #expect(field.type == .string)

        // And it has no name, which array subkeys may leave out
        #expect(field.name == nil)
    }

    @Test("Throws when pfm_type is missing")
    func missingType() async throws {
        // Given a field with no pfm_type key
        let data = try fixtureData(subject: "ManifestField", named: "missing-type")

        // When the field is decoded as a ManifestField
        let error = try #require(throws: DecodingError.self) {
            try PropertyListDecoder().decode(ManifestField.self, from: data)
        }

        // Then decoding fails because a required key is absent
        guard case .keyNotFound(let key, _) = error else {
            Issue.record("Expected keyNotFound, got \(error)")
            return
        }

        // And the absent key is pfm_type
        #expect(key.stringValue == "pfm_type")
    }

    // The spec lists eight pfm_type values. Real manifests sometimes use others, but the models
    // follow the spec strictly, so an undocumented type fails the whole field.
    @Test("Throws when pfm_type isn't a documented type")
    func unknownType() async throws {
        // Given a field whose pfm_type is url, which the spec doesn't define
        let data = try fixtureData(subject: "ManifestField", named: "unknown-type")

        // When the field is decoded as a ManifestField
        let error = try #require(throws: DecodingError.self) {
            try PropertyListDecoder().decode(ManifestField.self, from: data)
        }

        // Then decoding fails because a value is invalid
        guard case .dataCorrupted(let context) = error else {
            Issue.record("Expected dataCorrupted, got \(error)")
            return
        }

        // And the invalid value is pfm_type's
        #expect(context.codingPath.last?.stringValue == "pfm_type")
    }
}

extension Collection {
    /// The collection's sole element, or `nil` if it has zero or several.
    fileprivate var only: Element? { count == 1 ? first : nil }
}
