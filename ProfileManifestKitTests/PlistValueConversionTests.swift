//
//  PlistValueConversionTests.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 11/28/26.
//

import Foundation
import Testing

@testable import ProfileManifestKit

@Suite("PlistValue+Conversion")
struct PlistValueConversionTests {
    @Test(
        "Keeps values that already match the field's type",
        arguments: [
            (PlistValue.string("text"), "field-string"),
            (.bool(true), "field-boolean"),
            (.int(2), "field-integer"),
            (.uint(UInt64.max), "field-integer"),
            (.double(1.5), "field-real"),
            (.date(Date(timeIntervalSinceReferenceDate: 0)), "field-date"),
        ],
    )
    func convertMatching(value: PlistValue, fieldName: String) async throws {
        // Given a value of the field's type
        let field = try decodeField(named: fieldName)

        // When the value is loaded as the field's type
        var issues: [ManifestIssue] = []
        let loaded = value.converted(to: field, at: ["Field"], key: "pfm_default", issues: &issues)

        // Then it's unchanged
        #expect(loaded == value)

        // And no issue is recorded
        #expect(issues.isEmpty)
    }

    // A <real> of 2.0 decodes as .int, and an <integer> 2 does too, so the decoder can't say
    // which was written. Loading it as a double isn't reported as a conversion.
    @Test("Loads ints as doubles for real fields without an issue")
    func convertIntToReal() async throws {
        // Given a real field
        // And a whole-number .int, as a <real> of 2.0 decodes
        let field = try decodeField(named: "field-real")
        let value = PlistValue.int(2)

        // When the value is loaded as the field's type
        var issues: [ManifestIssue] = []
        let loaded = value.converted(to: field, at: ["Field"], key: "pfm_default", issues: &issues)

        // Then it's a .double holding the same number
        #expect(loaded == .double(2.0))

        // And no issue is recorded
        #expect(issues.isEmpty)
    }

    @Test(
        "Converts mistyped values that can be read as the field's type",
        arguments: [
            (PlistValue.int(0), "field-boolean", PlistValue.bool(false)),
            (.int(1), "field-boolean", .bool(true)),
            (.string("YES"), "field-boolean", .bool(true)),
            (.string("false"), "field-boolean", .bool(false)),
            (.string("1"), "field-boolean", .bool(true)),
            (.string("12"), "field-integer", .int(12)),
            (.string("0.5"), "field-real", .double(0.5)),
            (.int(7), "field-string", .string("7")),
        ],
    )
    func convertMistyped(value: PlistValue, fieldName: String, expected: PlistValue) async throws {
        // Given a value of another type that can be read as the field's type
        let field = try decodeField(named: fieldName)

        // When the value is loaded as the field's type
        var issues: [ManifestIssue] = []
        let loaded = value.converted(to: field, at: ["Field"], key: "pfm_default", issues: &issues)

        // Then it's the converted value
        #expect(loaded == expected)

        // And one conversion is recorded
        let kind = ManifestIssue.Kind.valueConverted(from: value, to: field.type)
        #expect(issues == [ManifestIssue(fieldPath: ["Field"], key: "pfm_default", kind: kind)])
    }

    @Test(
        "Drops values that can't be read as the field's type",
        arguments: [
            (PlistValue.int(2), "field-boolean"),
            (.string("Days"), "field-integer"),
            (.string("nan"), "field-real"),
            (.double(2.5), "field-integer"),
            (.bool(true), "field-string"),
            (.string("2026-01-01T00:00:00Z"), "field-date"),
            (.dictionary(["key": .int(1)]), "field-array-of-reals"),
        ],
    )
    func convertUnreadable(value: PlistValue, fieldName: String) async throws {
        // Given a value that can't be read as the field's type
        let field = try decodeField(named: fieldName)

        // When the value is loaded as the field's type
        var issues: [ManifestIssue] = []
        let loaded = value.converted(to: field, at: ["Field"], key: "pfm_default", issues: &issues)

        // Then it's left out
        #expect(loaded == nil)

        // And one drop is recorded
        let kind = ManifestIssue.Kind.valueDropped(value, expected: field.type)
        #expect(issues == [ManifestIssue(fieldPath: ["Field"], key: "pfm_default", kind: kind)])
    }

    @Test("Wraps a single value of the item's type in an array")
    func convertSingleToArray() async throws {
        // Given an array field whose subkey is string
        // And a single .string, as Santa's placeholders write one entry
        let field = try decodeField(named: "field-array-of-strings")
        let value = PlistValue.string("com.apple.private")

        // When the value is loaded as the field's type
        var issues: [ManifestIssue] = []
        let loaded = value.converted(to: field, at: ["Field"], key: "pfm_default", issues: &issues)

        // Then it's a one-item array
        #expect(loaded == .array([.string("com.apple.private")]))

        // And one conversion to an array is recorded
        let kind = ManifestIssue.Kind.valueConverted(from: value, to: .array)
        #expect(issues == [ManifestIssue(fieldPath: ["Field"], key: "pfm_default", kind: kind)])
    }

    @Test("Converts a single value to the item's type before wrapping it")
    func convertSingleToArrayWithConversion() async throws {
        // Given an array field whose subkey is string
        // And a single .int
        let field = try decodeField(named: "field-array-of-strings")
        let value = PlistValue.int(7)

        // When the value is loaded as the field's type
        var issues: [ManifestIssue] = []
        let loaded = value.converted(to: field, at: ["Field"], key: "pfm_default", issues: &issues)

        // Then it's a one-item array of the converted item
        #expect(loaded == .array([.string("7")]))

        // And both the wrapping and the item's conversion are recorded
        #expect(
            issues == [
                ManifestIssue(
                    fieldPath: ["Field"],
                    key: "pfm_default",
                    kind: .valueConverted(from: .int(7), to: .array),
                ),
                ManifestIssue(
                    fieldPath: ["Field", "[]"],
                    key: "pfm_default",
                    kind: .valueConverted(from: .int(7), to: .string),
                ),
            ]
        )
    }

    @Test("Loads array items as the array's subkey")
    func convertArrayItems() async throws {
        // Given an array field whose subkey is real
        // And whose default is an <array> of <real> tags 1.0 and 2.5
        let field = try decodeField(named: "field-array-of-reals")
        let value = try #require(field.defaultValue)

        // When the default is loaded as the field's type
        var issues: [ManifestIssue] = []
        let loaded = value.converted(
            to: field,
            at: ["Ratios"],
            key: "pfm_default",
            issues: &issues,
        )

        // Then every item is a .double
        #expect(loaded == .array([.double(1.0), .double(2.5)]))

        // And no issue is recorded
        #expect(issues.isEmpty)
    }

    @Test("Drops only the array items that can't be read as the subkey")
    func convertArrayDropsItem() async throws {
        // Given an array field whose subkey is real
        // And an .array holding a .double, a .string that isn't a number, and an .int
        let field = try decodeField(named: "field-array-of-reals")
        let value = PlistValue.array([.double(1.5), .string("high"), .int(2)])

        // When the value is loaded as the field's type
        var issues: [ManifestIssue] = []
        let loaded = value.converted(
            to: field,
            at: ["Ratios"],
            key: "pfm_default",
            issues: &issues,
        )

        // Then the other items load as .double
        #expect(loaded == .array([.double(1.5), .double(2)]))

        // And the dropped item is recorded under the array's item
        let kind = ManifestIssue.Kind.valueDropped(.string("high"), expected: .real)
        #expect(
            issues == [ManifestIssue(fieldPath: ["Ratios", "[]"], key: "pfm_default", kind: kind)]
        )
    }

    @Test("Loads dictionary values as the subkey with the same name")
    func convertDictionaryValues() async throws {
        // Given a dictionary field with a real Ratio subkey and an integer Count subkey
        // And whose default holds a whole Ratio, a Count, and an Extra key with no subkey
        let field = try decodeField(named: "field-dictionary-with-real")
        let value = try #require(field.defaultValue)

        // When the default is loaded as the field's type
        var issues: [ManifestIssue] = []
        let loaded = value.converted(
            to: field,
            at: ["Settings"],
            key: "pfm_default",
            issues: &issues,
        )

        // Then Ratio is a .double and the other values are unchanged
        #expect(
            loaded == .dictionary(["Ratio": .double(2.0), "Count": .int(3), "Extra": .int(4)]))

        // And no issue is recorded
        #expect(issues.isEmpty)
    }

    @Test("Drops only the dictionary values that can't be read as their subkey")
    func convertDictionaryDropsValue() async throws {
        // Given a dictionary field with a real Ratio subkey and an integer Count subkey
        // And a .dictionary whose Ratio is a .string that isn't a number
        let field = try decodeField(named: "field-dictionary-with-real")
        let value = PlistValue.dictionary(["Ratio": .string("high"), "Count": .int(3)])

        // When the value is loaded as the field's type
        var issues: [ManifestIssue] = []
        let loaded = value.converted(
            to: field,
            at: ["Settings"],
            key: "pfm_default",
            issues: &issues,
        )

        // Then only Count is left
        #expect(loaded == .dictionary(["Count": .int(3)]))

        // And the dropped value is recorded under its subkey
        let kind = ManifestIssue.Kind.valueDropped(.string("high"), expected: .real)
        #expect(
            issues == [
                ManifestIssue(fieldPath: ["Settings", "Ratio"], key: "pfm_default", kind: kind)
            ]
        )
    }
}
