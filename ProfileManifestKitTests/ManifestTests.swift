//
//  ManifestTests.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 11/20/26.
//

import Foundation
import Testing

@testable import ProfileManifestKit

@Suite("Manifest")
struct ManifestTests {
    @Test("Decodes every key into its property")
    func allKeys() async throws {
        // Given a manifest with every key set to a distinct value
        let data = try fixtureData(subject: "Manifest", named: "all-keys")

        // When the manifest is decoded as a Manifest
        let manifest = try PropertyListDecoder().decode(Manifest.self, from: data)

        // Then each Apple-defined key's value is in its property
        #expect(manifest.domain == "com.example.settings")
        #expect(manifest.title == "Example Settings")
        #expect(manifest.description == "Configures the example app.")
        #expect(manifest.subkeys.map(\.name) == ["Enabled"])
        #expect(manifest.targets == [.systemManaged])
        #expect(manifest.version == 3)
        #expect(manifest.formatVersion == 1)

        // And each extended key's value is in its property
        #expect(manifest.subdomain == "network")
        #expect(manifest.interaction == .exclusive)
        #expect(manifest.unique == true)
        #expect(manifest.icon == Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]))
        #expect(manifest.note == "Requires a restart.")
        #expect(manifest.appURL == "https://example.com/app")
        #expect(manifest.supervised == true)
        #expect(manifest.userApproved == false)
        #expect(manifest.platforms == ["iOS", "macOS"])
        #expect(manifest.iOSMin == "14.0")
        #expect(manifest.iOSDeprecated == "15.0")
        #expect(manifest.iOSMax == "16.0")
        #expect(manifest.macOSMin == "11.0")
        #expect(manifest.macOSDeprecated == "12.0")
        #expect(manifest.macOSMax == "13.0")
        #expect(manifest.tvOSMin == "17.0")
        #expect(manifest.tvOSDeprecated == "18.0")
        #expect(manifest.tvOSMax == "19.0")
        #expect(manifest.lastModified == (try Date("2026-10-27T12:00:00Z", strategy: .iso8601)))
    }

    @Test("Decodes a manifest with only its required keys")
    func minimal() async throws {
        // Given a manifest with only pfm_domain, pfm_subkeys, and pfm_platforms
        let data = try fixtureData(subject: "Manifest", named: "minimal")

        // When the manifest is decoded as a Manifest
        let manifest = try PropertyListDecoder().decode(Manifest.self, from: data)

        // Then each required key's value is in its property
        #expect(manifest.domain == "com.example.settings")
        #expect(manifest.subkeys.map(\.name) == ["Enabled"])
        #expect(manifest.platforms == ["macOS"])
    }

    @Test(
        "Throws when a required key is missing",
        arguments: zip(
            ["missing-domain", "missing-subkeys", "missing-platforms"],
            ["pfm_domain", "pfm_subkeys", "pfm_platforms"],
        ),
    )
    func missingRequiredKey(fileName: String, missingKey: String) async throws {
        // Given a manifest missing pfm_domain, pfm_subkeys, or pfm_platforms
        // And containing every other required key
        let data = try fixtureData(subject: "Manifest", named: fileName)

        // When the manifest is decoded as a Manifest
        let error = try #require(throws: DecodingError.self) {
            try PropertyListDecoder().decode(Manifest.self, from: data)
        }

        // Then decoding fails because a required key is absent
        guard case .keyNotFound(let key, _) = error else {
            Issue.record("Expected keyNotFound, got \(error)")
            return
        }

        // And the absent key is the one the manifest leaves out
        #expect(key.stringValue == missingKey)
    }

    // The spec lists three pfm_interaction values. The models follow the spec strictly, so an
    // undocumented value fails the whole manifest rather than being dropped.
    @Test("Throws when pfm_interaction isn't a documented value")
    func unknownInteraction() async throws {
        // Given a manifest whose pfm_interaction is merged, which the spec doesn't define
        let data = try fixtureData(subject: "Manifest", named: "unknown-interaction")

        // When the manifest is decoded as a Manifest
        let error = try #require(throws: DecodingError.self) {
            try PropertyListDecoder().decode(Manifest.self, from: data)
        }

        // Then decoding fails because a value is invalid
        guard case .dataCorrupted(let context) = error else {
            Issue.record("Expected dataCorrupted, got \(error)")
            return
        }

        // And the invalid value is pfm_interaction's
        #expect(context.codingPath.last?.stringValue == "pfm_interaction")
    }

    @Test("Loads a manifest from a file URL")
    func load() async throws {
        // Given the URL of a valid manifest file
        let url = try fixtureURL(subject: "Manifest", named: "minimal")

        // When the manifest is loaded from the URL
        let manifest = try Manifest.load(from: url)

        // Then it's the file's manifest
        #expect(manifest.domain == "com.example.settings")
        #expect(manifest.subkeys.map(\.name) == ["Enabled"])
    }

    @Test("Throws when loading from a file that doesn't exist")
    func loadMissingFile() async throws {
        // Given the URL of a file that doesn't exist
        let url = FileManager.default.temporaryDirectory
            .appending(path: "\(UUID().uuidString).plist")

        // When the manifest is loaded from the URL
        let error = try #require(throws: CocoaError.self) {
            try Manifest.load(from: url)
        }

        // Then loading fails because the file doesn't exist
        #expect(error.code == .fileReadNoSuchFile)
    }

    @Test("Throws when loading from a file that isn't a property list")
    func loadNotAPlist() async throws {
        // Given the URL of a plain text file
        let url = try fixtureURL(subject: "Manifest", named: "not-a-plist", withExtension: "txt")

        // When the manifest is loaded from the URL
        let error = try #require(throws: DecodingError.self) {
            try Manifest.load(from: url)
        }

        // Then loading fails because the file can't be decoded
        guard case .dataCorrupted = error else {
            Issue.record("Expected dataCorrupted, got \(error)")
            return
        }
    }

    // Smoke test: each fixture is an unmodified manifest from an open-source project (see
    // Fixtures/Manifest/THIRD-PARTY-NOTICES.md), so it uses the keys and layouts real authors
    // write rather than ones chosen to suit the models.
    @Test(
        "Loads real-world manifests",
        arguments: zip(
            ["real-xcreds", "real-macoslaps"],
            ["com.twocanoes.xcreds", "com.joshua-d-miller.macoslaps"],
        ),
    )
    func loadRealWorld(fileName: String, domain: String) async throws {
        // Given the URL of xCreds' or macOSLAPS' published manifest
        let url = try fixtureURL(subject: "Manifest", named: fileName)

        // When the manifest is loaded from the URL
        let manifest = try Manifest.load(from: url)

        // Then its domain is the project's
        #expect(manifest.domain == domain)

        // And it has fields
        #expect(!manifest.subkeys.isEmpty)
    }

    // xCreds writes whole-number <real> defaults, which PropertyListDecoder reads as .int.
    // coerced(to:) exists for this case: without it, re-encoding would write them as <integer>.
    @Test("Coerces a real-world whole-number real default to .double")
    func coerceRealWorldDefault() async throws {
        // Given xCreds' published manifest
        let url = try fixtureURL(subject: "Manifest", named: "real-xcreds")
        let manifest = try Manifest.load(from: url)

        // And its real field loginWindowBackgroundImageAlpha, whose default is <real>1</real>
        let field = try #require(
            manifest.subkeys.first { $0.name == "loginWindowBackgroundImageAlpha" }
        )
        let defaultValue = try #require(field.defaultValue)

        // When the default is coerced to the field
        let coerced = defaultValue.coerced(to: field)

        // Then it's a .double holding the default's value
        #expect(coerced == .double(1))
    }
}
