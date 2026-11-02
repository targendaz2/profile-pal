//
//  PlistValueTests.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 11/1/26.
//

import Foundation
import Testing

@testable import ProfileManifestKit

struct PlistValueTests {
    @Test(
        "Parses bool values correctly",
        arguments: zip(["bool-false", "bool-true"], [false, true]),
    )
    func parseBool(fileName: String, expected: Bool) async throws {
        // Given a plist whose value is a <true/> or <false/> tag
        let data = try fixtureData(named: fileName)

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's a .bool holding the tag's value
        #expect(value == .bool(expected))
    }

    @Test("Parses ints as ints", arguments: zip(["integer-one", "integer-zero"], [1, 0]))
    func parseInt(fileName: String, expected: Int) async throws {
        // Given a plist whose value is an <integer> tag of 1 or 0
        let data = try fixtureData(named: fileName)

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's a .int holding the tag's value
        #expect(value == .int(expected))

        // And not a .bool, which is tried before Int when decoding
        if case .bool = value {
            Issue.record("Decoded an <integer> tag as a .bool")
        }
    }

    @Test("Parses fractional reals as doubles")
    func parseFractionalReal() async throws {
        // Given a plist whose value is a <real> tag of 1.5
        let data = try fixtureData(named: "real-fractional")

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's a .double holding the tag's value
        #expect(value == .double(1.5))

        // And not a .int, which is tried before Double when decoding
        if case .int = value {
            Issue.record("Decoded a fractional <real> tag as a .int")
        }
    }

    // PropertyListDecoder lets a whole-number <real> decode as Int, and PlistValue tries Int
    // before Double, so 2.0 comes back as .int. coerced(to:) relies on this; this test
    // catches it changing.
    @Test("Parses whole reals as ints (decoder quirk)")
    func parseWholeReal() async throws {
        // Given a plist whose value is a <real> tag of 2.0
        let data = try fixtureData(named: "real-whole")

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's a .int holding the tag's value
        #expect(value == .int(2))
    }

    @Test(
        "Parses numeric and boolean strings as strings",
        arguments: zip(["string-numeric", "string-boolean"], ["123", "true"]),
    )
    func parseStrings(fileName: String, expected: String) async throws {
        // Given a plist whose value is a <string> tag of "123" or "true"
        let data = try fixtureData(named: fileName)

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's a .string holding the tag's value
        #expect(value == .string(expected))

        // And not a .int or .bool, which are tried before String when decoding
        switch value {
            case .int, .bool: Issue.record("Decoded a <string> tag as \(value)")
            default: break
        }
    }

    @Test("Parses data as data")
    func parseData() async throws {
        // Given a plist whose value is a <data> tag holding the bytes 1, 2, 3
        let data = try fixtureData(named: "data")

        // When the value is decoded as a PlistValue
        let value = try decodeValue(from: data)

        // Then it's a .data holding the tag's bytes
        #expect(value == .data(Data([1, 2, 3])))
    }

    @Test("Parses dates as dates")
    func parseDates() async throws {
        // Given a plist whose value is a <date> tag of 2026-01-02T03:04:05Z
        let data = try fixtureData(named: "date")

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
        let data = try fixtureData(named: "array-small-integers")

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
        let data = try fixtureData(named: "array-empty")

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
        let data = try fixtureData(named: "dict-empty")

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
        let data = try fixtureData(named: "nested")

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

        // Then it comes back as a .int
        #expect(decoded == [.int(2)])
    }
}

// MARK: - Fixtures

/// A class defined in the test bundle, so `Bundle(for:)` can find the bundle and its fixtures.
private final class BundleToken {}

/// The contents of the fixture `Fixtures/PlistValue/<name>.plist` in the test bundle.
private func fixtureData(named name: String) throws -> Data {
    let url = try #require(
        Bundle(for: BundleToken.self).url(
            forResource: name,
            withExtension: "plist",
            subdirectory: "Fixtures/PlistValue",
        )
    )
    return try Data(contentsOf: url)
}

/// The `PlistValue` stored under the `value` key of a fixture.
private func decodeValue(from data: Data) throws -> PlistValue {
    let root = try PropertyListDecoder().decode([String: PlistValue].self, from: data)
    return try #require(root["value"])
}
