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
}

extension Collection {
    /// The collection's sole element, or `nil` if it has zero or several.
    fileprivate var only: Element? { count == 1 ? first : nil }
}
