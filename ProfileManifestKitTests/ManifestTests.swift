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
        #expect(manifest.icon == Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]))
        #expect(manifest.note == "Requires a restart.")
        #expect(manifest.supervised == true)
        #expect(manifest.userApproved == false)
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

    @Test("Decodes a manifest with only a domain and subkeys")
    func minimal() async throws {
        // Given a manifest whose only keys are pfm_domain and pfm_subkeys
        let data = try fixtureData(subject: "Manifest", named: "minimal")

        // When the manifest is decoded as a Manifest
        let manifest = try PropertyListDecoder().decode(Manifest.self, from: data)

        // Then its domain is the key's value
        #expect(manifest.domain == "com.example.settings")

        // And its subkeys are the key's fields
        #expect(manifest.subkeys.map(\.name) == ["Enabled"])
    }

    @Test("Throws when pfm_domain is missing")
    func missingDomain() async throws {
        // Given a manifest with subkeys but no pfm_domain key
        let data = try fixtureData(subject: "Manifest", named: "missing-domain")

        // When the manifest is decoded as a Manifest
        let error = try #require(throws: DecodingError.self) {
            try PropertyListDecoder().decode(Manifest.self, from: data)
        }

        // Then decoding fails because a required key is absent
        guard case .keyNotFound(let key, _) = error else {
            Issue.record("Expected keyNotFound, got \(error)")
            return
        }

        // And the absent key is pfm_domain
        #expect(key.stringValue == "pfm_domain")
    }

    @Test("Throws when pfm_subkeys is missing")
    func missingSubkeys() async throws {
        // Given a manifest with a domain but no pfm_subkeys key
        let data = try fixtureData(subject: "Manifest", named: "missing-subkeys")

        // When the manifest is decoded as a Manifest
        let error = try #require(throws: DecodingError.self) {
            try PropertyListDecoder().decode(Manifest.self, from: data)
        }

        // Then decoding fails because a required key is absent
        guard case .keyNotFound(let key, _) = error else {
            Issue.record("Expected keyNotFound, got \(error)")
            return
        }

        // And the absent key is pfm_subkeys
        #expect(key.stringValue == "pfm_subkeys")
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
        let result = Result { try Manifest.load(from: url) }

        // Then loading fails
        #expect(throws: (any Error).self) {
            try result.get()
        }
    }

    @Test("Throws when loading from a file that isn't a property list")
    func loadNotAPlist() async throws {
        // Given the URL of a plain text file
        let url = try fixtureURL(subject: "Manifest", named: "not-a-plist", withExtension: "txt")

        // When the manifest is loaded from the URL
        let result = Result { try Manifest.load(from: url) }

        // Then loading fails because the file can't be decoded
        #expect(throws: DecodingError.self) {
            try result.get()
        }
    }
}
