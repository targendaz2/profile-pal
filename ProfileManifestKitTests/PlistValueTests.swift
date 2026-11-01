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
