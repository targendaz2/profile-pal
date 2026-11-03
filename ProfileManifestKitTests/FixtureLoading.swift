//
//  FixtureLoading.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 11/2/26.
//

import Foundation
import Testing

/// A class defined in the test bundle, so `Bundle(for:)` can find the bundle and its fixtures.
private final class BundleToken {}

/// The contents of the fixture `Fixtures/<subject>/<name>.plist` in the test bundle.
func fixtureData(subject: String, named name: String) throws -> Data {
    let url = try #require(
        Bundle(for: BundleToken.self).url(
            forResource: name,
            withExtension: "plist",
            subdirectory: "Fixtures/\(subject)",
        )
    )
    return try Data(contentsOf: url)
}
