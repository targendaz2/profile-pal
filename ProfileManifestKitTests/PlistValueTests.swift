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
