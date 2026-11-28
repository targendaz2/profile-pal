//
//  FixtureLoading.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 11/2/26.
//

import Foundation
import Testing

@testable import ProfileManifestKit

/// A class defined in the test bundle, so `Bundle(for:)` can find the bundle and its fixtures.
private final class BundleToken {}

/// The URL of the fixture `Fixtures/<subject>/<name>.<fileExtension>` in the test bundle.
func fixtureURL(
    subject: String,
    named name: String,
    withExtension fileExtension: String = "plist",
) throws -> URL {
    try #require(
        Bundle(for: BundleToken.self).url(
            forResource: name,
            withExtension: fileExtension,
            subdirectory: "Fixtures/\(subject)",
        )
    )
}

/// The contents of the fixture `Fixtures/<subject>/<name>.plist` in the test bundle.
func fixtureData(subject: String, named name: String) throws -> Data {
    try Data(contentsOf: fixtureURL(subject: subject, named: name))
}

/// The `ManifestField` in the fixture `Fixtures/PlistValue/<name>.plist`.
func decodeField(named name: String) throws -> ManifestField {
    let data = try fixtureData(subject: "PlistValue", named: name)
    return try PropertyListDecoder().decode(ManifestField.self, from: data)
}
