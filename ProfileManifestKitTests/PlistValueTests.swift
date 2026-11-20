//
//  PlistValueTests.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 11/1/26.
//

import Foundation
import Testing

@testable import ProfileManifestKit

@Suite("PlistValue")
struct PlistValueTests {
    @Test(
        "Parses bool values correctly",
        arguments: zip(["bool-false", "bool-true"], [false, true]),
    )
    func parseBool(fileName: String, expected: Bool) async throws {
        // Given a plist whose value is a <true/> or <false/> tag
        let data = try fixtureData(subject: "PlistValue", named: fileName)

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's a .bool holding the tag's value
        #expect(value == .bool(expected))
    }

    @Test("Parses ints as ints", arguments: zip(["integer-one", "integer-zero"], [1, 0]))
    func parseInt(fileName: String, expected: Int) async throws {
        // Given a plist whose value is an <integer> tag of 1 or 0
        let data = try fixtureData(subject: "PlistValue", named: fileName)

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's an .int holding the tag's value
        #expect(value == .int(expected))

        // And not a .bool, which is tried before Int when decoding
        if case .bool = value {
            Issue.record("Decoded an <integer> tag as a .bool")
        }
    }

    @Test("Parses ints above Int.max as exact uints")
    func parseIntAboveIntMax() async throws {
        // Given a plist whose value is an <integer> tag of UInt64.max
        let data = try fixtureData(subject: "PlistValue", named: "integer-above-int-max")

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's a .uint holding the tag's exact value
        #expect(value == .uint(UInt64.max))
    }

    @Test("Parses fractional reals as doubles")
    func parseFractionalReal() async throws {
        // Given a plist whose value is a <real> tag of 1.5
        let data = try fixtureData(subject: "PlistValue", named: "real-fractional")

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's a .double holding the tag's value
        #expect(value == .double(1.5))

        // And not an .int, which is tried before Double when decoding
        if case .int = value {
            Issue.record("Decoded a fractional <real> tag as an .int")
        }
    }

    // PropertyListDecoder lets a whole-number <real> decode as Int, and PlistValue tries Int
    // before Double, so 2.0 comes back as .int. coerced(to:) relies on this; this test
    // catches it changing.
    @Test("Parses whole reals as ints (decoder quirk)")
    func parseWholeReal() async throws {
        // Given a plist whose value is a <real> tag of 2.0
        let data = try fixtureData(subject: "PlistValue", named: "real-whole")

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's an .int holding the tag's value
        #expect(value == .int(2))
    }

    @Test(
        "Parses numeric and boolean strings as strings",
        arguments: zip(["string-numeric", "string-boolean"], ["123", "true"]),
    )
    func parseStrings(fileName: String, expected: String) async throws {
        // Given a plist whose value is a <string> tag of "123" or "true"
        let data = try fixtureData(subject: "PlistValue", named: fileName)

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's a .string holding the tag's value
        #expect(value == .string(expected))

        // And not an .int or .bool, which are tried before String when decoding
        switch value {
            case .int, .bool: Issue.record("Decoded a <string> tag as \(value)")
            default: break
        }
    }

    @Test("Parses data as data")
    func parseData() async throws {
        // Given a plist whose value is a <data> tag holding the bytes 1, 2, 3
        let data = try fixtureData(subject: "PlistValue", named: "data")

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's a .data holding the tag's bytes
        #expect(value == .data(Data([1, 2, 3])))
    }

    @Test("Parses dates as dates")
    func parseDates() async throws {
        // Given a plist whose value is a <date> tag of 2026-01-02T03:04:05Z
        let data = try fixtureData(subject: "PlistValue", named: "date")

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's a .date holding the tag's value
        let expected = try Date("2026-01-02T03:04:05Z", strategy: .iso8601)
        #expect(value == .date(expected))

        // And not a .double, which is tried before Date when decoding
        if case .double = value {
            Issue.record("Decoded a <date> tag as a .double")
        }
    }

    @Test("Parses arrays of small integers as arrays, not data")
    func parseArray() async throws {
        // Given a plist whose value is an <array> of <integer> tags 1 and 2
        let data = try fixtureData(subject: "PlistValue", named: "array-small-integers")

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's an .array of .int values matching the tags
        #expect(value == .array([.int(1), .int(2)]))

        // And not a .data, which is tried before arrays and can decode from a list of bytes
        if case .data = value {
            Issue.record("Decoded an <array> of integers as .data")
        }
    }

    @Test("Parses empty arrays as arrays, not data")
    func parseEmptyArray() async throws {
        // Given a plist whose value is an empty <array/> tag
        let data = try fixtureData(subject: "PlistValue", named: "array-empty")

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's an empty .array
        #expect(value == .array([]))

        // And not a .data, which is tried before arrays and can decode from an empty list of bytes
        if case .data = value {
            Issue.record("Decoded an empty <array/> as .data")
        }
    }

    @Test("Parses empty dictionaries as dictionaries, not arrays")
    func parseEmptyDictionary() async throws {
        // Given a plist whose value is an empty <dict/> tag
        let data = try fixtureData(subject: "PlistValue", named: "dict-empty")

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's an empty .dictionary
        #expect(value == .dictionary([:]))

        // And not an .array, which is tried before dictionaries when decoding
        if case .array = value {
            Issue.record("Decoded an empty <dict/> as an .array")
        }
    }

    @Test("Parses nested arrays and dictionaries with mixed types")
    func parseNested() async throws {
        // Given a plist whose value is an <array> of a mixed-type <dict> and an empty <dict>
        let data = try fixtureData(subject: "PlistValue", named: "nested")

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then every level decodes as the case matching its tag
        let expected: PlistValue = .array([
            .dictionary([
                "name": .string("first"),
                "count": .int(3),
                "ratio": .double(0.25),
                "enabled": .bool(true),
                "tags": .array([.string("a"), .string("b")]),
            ]),
            .dictionary([:]),
        ])
        #expect(value == expected)
    }

    @Test(
        "Round-trips every case through encoding and decoding",
        arguments: [
            PlistValue.string("text"),
            .bool(true),
            .int(42),
            .uint(UInt64.max),
            .double(1.5),
            .data(Data([1, 2, 3])),
            .date(Date(timeIntervalSinceReferenceDate: 0)),
            .array([.int(1), .string("a")]),
            .dictionary(["key": .bool(false)]),
        ],
        [PropertyListSerialization.PropertyListFormat.xml, .binary],
    )
    func roundTrip(
        original: PlistValue,
        format: PropertyListSerialization.PropertyListFormat,
    ) async throws {
        // Given a PlistValue of each case
        // And an XML or binary output format
        let encoder = PropertyListEncoder()
        encoder.outputFormat = format

        // When it's encoded to a plist and decoded back
        let data = try encoder.encode([original])
        let decoded = try PropertyListDecoder().decode([PlistValue].self, from: data)

        // Then it's unchanged
        #expect(decoded == [original])
    }

    // A whole-number double encodes as <real> but decodes as .int, since PlistValue tries Int
    // before Double. coerced(to:) exists to undo this; this test catches it changing.
    @Test("Round-trips whole doubles as ints (decoder quirk)")
    func roundTripWholeDouble() async throws {
        // Given a .double holding a whole number
        let original = PlistValue.double(2.0)

        // When it's encoded to a plist and decoded back
        let data = try PropertyListEncoder().encode([original])
        let decoded = try PropertyListDecoder().decode([PlistValue].self, from: data)

        // Then it comes back as an .int
        #expect(decoded == [.int(2)])
    }

    @Test("Coerces ints to doubles for real fields")
    func coerceIntToReal() async throws {
        // Given a real field
        // And a whole-number .int, as a <real> of 2.0 decodes
        let field = try decodeField(named: "field-real")
        let value = PlistValue.int(2)

        // When the value is coerced to the field
        let coerced = value.coerced(to: field)

        // Then it's a .double holding the same number
        #expect(coerced == .double(2.0))
    }

    @Test(
        "Leaves values unchanged unless coercing an int to real",
        arguments: [
            (PlistValue.int(2), "field-integer"),
            (.int(2), "field-string"),
            (.double(1.5), "field-real"),
            (.string("2"), "field-real"),
            (.bool(true), "field-real"),
        ],
    )
    func coerceUnchanged(value: PlistValue, fieldName: String) async throws {
        // Given a value and field other than an .int and a real field
        let field = try decodeField(named: fieldName)

        // When the value is coerced to the field
        let coerced = value.coerced(to: field)

        // Then it's unchanged
        #expect(coerced == value)
    }

    @Test("Coerces array items to the array's subkey")
    func coerceArrayToField() async throws {
        // Given an array field whose subkey is real
        // And whose default is an <array> of <real> tags 1.0 and 2.5
        let field = try decodeField(named: "field-array-of-reals")
        let value = try #require(field.defaultValue)

        // When the default is coerced to the field
        let coerced = value.coerced(to: field)

        // Then every item is a .double
        #expect(coerced == .array([.double(1.0), .double(2.5)]))
    }

    @Test("Coerces dictionary values to the subkey with the same name")
    func coerceDictionaryToField() async throws {
        // Given a dictionary field with a real Ratio subkey and an integer Count subkey
        // And whose default holds a whole Ratio, a Count, and an Extra key with no subkey
        let field = try decodeField(named: "field-dictionary-with-real")
        let value = try #require(field.defaultValue)

        // When the default is coerced to the field
        let coerced = value.coerced(to: field)

        // Then Ratio is a .double and the other values are unchanged
        #expect(
            coerced == .dictionary(["Ratio": .double(2.0), "Count": .int(3), "Extra": .int(4)]))
    }

    @Test("Leaves values unchanged when their shape doesn't match the field")
    func coerceMismatchedField() async throws {
        // Given an array field whose subkey is real
        // And a .dictionary holding a whole-number .int
        let field = try decodeField(named: "field-array-of-reals")
        let value = PlistValue.dictionary(["key": .int(1)])

        // When the value is coerced to the field
        let coerced = value.coerced(to: field)

        // Then it's unchanged
        #expect(coerced == value)
    }
}

// MARK: - Fixtures

/// The `PlistValue` stored under the `value` key of a fixture.
private func decodeValue(from data: Data) throws -> PlistValue {
    let root = try PropertyListDecoder().decode([String: PlistValue].self, from: data)
    return try #require(root["value"])
}

/// The `ManifestField` in the fixture `Fixtures/PlistValue/<name>.plist`.
private func decodeField(named name: String) throws -> ManifestField {
    let data = try fixtureData(subject: "PlistValue", named: name)
    return try PropertyListDecoder().decode(ManifestField.self, from: data)
}
