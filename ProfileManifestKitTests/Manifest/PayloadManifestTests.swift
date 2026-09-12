//
//  PayloadManifestTests.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation
import Testing

@testable import ProfileManifestKit

struct PayloadManifestTests {

    @Test func decodes_dock_manifest() throws {
        let data = try PlistFixture.xmlData(PlistFixtures.dock)
        let manifest = try PropertyListDecoder().decode(PayloadManifest.self, from: data)

        #expect(manifest.domain == "com.apple.dock")
        #expect(!manifest.subkeys.isEmpty)
    }

    @Test func decodes_trap_fixture() throws {
        let data = try PlistFixture.xmlData(PlistFixtures.trap)
        let manifest = try PropertyListDecoder().decode(PayloadManifest.self, from: data)
        #expect(manifest.subkeys.count == 3)

        let mode = manifest.subkeys[0]
        #expect(mode.name == "Mode")
        #expect(mode.rangeList == [.string("auto"), .string("manual")])
        #expect(mode.defaultValue == .string("auto"))

        // The array-element subkey has no name — this is the assertion that
        // proves `name` is correctly optional.
        let tags = manifest.subkeys[1]
        #expect(tags.type == .array)
        #expect(tags.subkeys?.first?.name == nil)
        #expect(tags.subkeys?.first?.type == .string)

        let maxItems = manifest.subkeys[2]
        #expect(maxItems.required == true)
        #expect(maxItems.defaultValue == .integer(10))
    }
}
