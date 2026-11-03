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

    @Test("Decodes a field with only a type, leaving every optional property nil")
    func minimal() async throws {
        // Given a field whose only key is pfm_type
        let data = try fixtureData(subject: "ManifestField", named: "minimal")

        // When the field is decoded as a ManifestField
        let field = try PropertyListDecoder().decode(ManifestField.self, from: data)

        // Then its type is the key's value
        #expect(field.type == .string)

        // And each optional Apple-defined property is nil, including name
        #expect(field.name == nil)
        #expect(field.title == nil)
        #expect(field.description == nil)
        #expect(field.defaultValue == nil)
        #expect(field.rangeList == nil)
        #expect(field.rangeMin == nil)
        #expect(field.rangeMax == nil)
        #expect(field.format == nil)
        #expect(field.subkeys == nil)
        #expect(field.repetitionMin == nil)
        #expect(field.repetitionMax == nil)
        #expect(field.require == nil)
        #expect(field.required == nil)
        #expect(field.conditionals == nil)
        #expect(field.exclude == nil)
        #expect(field.targets == nil)

        // And each extended property is nil
        #expect(field.placeholder == nil)
        #expect(field.rangeListTitles == nil)
        #expect(field.valueUnit == nil)
        #expect(field.note == nil)
        #expect(field.documentationURL == nil)
        #expect(field.sensitive == nil)
        #expect(field.supervised == nil)
        #expect(field.userApproved == nil)
        #expect(field.iOSMin == nil)
        #expect(field.iOSDeprecated == nil)
        #expect(field.iOSMax == nil)
        #expect(field.macOSMin == nil)
        #expect(field.macOSDeprecated == nil)
        #expect(field.macOSMax == nil)
        #expect(field.tvOSMin == nil)
        #expect(field.tvOSDeprecated == nil)
        #expect(field.tvOSMax == nil)
    }
}

extension Collection {
    /// The collection's sole element, or `nil` if it has zero or several.
    fileprivate var only: Element? { count == 1 ? first : nil }
}
