//
//  ProfileManifestKitTests.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation
import Testing

@testable import ProfileManifestKit

struct PFMValueTests {

    @Test func decodes_each_scalar_type() throws {
        let plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>s</key><string>hello</string>
                <key>i</key><integer>42</integer>
                <key>r</key><real>3.14</real>
                <key>b</key><true/>
            </dict>
            </plist>
            """.data(using: .utf8)!

        let decoded = try PropertyListDecoder().decode([String: PFMValue].self, from: plist)
        #expect(decoded["s"] == .string("hello"))
        #expect(decoded["i"] == .integer(42))
        #expect(decoded["r"] == .real(3.14))
        #expect(decoded["b"] == .boolean(true))  // NOT .integer(1)
    }

    @Test func raw_decoding_coerces_integral_reals_to_integer() throws {
        let plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>whole</key><integer>42</integer>
                <key>fractional</key><real>3.14</real>
                <key>wholeLookingReal</key><real>5.0</real>
            </dict>
            </plist>
            """.data(using: .utf8)!

        let decoded = try PropertyListDecoder().decode([String: PFMValue].self, from: plist)

        // An <integer> must land in .integer, never .real
        #expect(decoded["whole"] == .integer(42))

        // A <real> must land in .real, never .integer
        #expect(decoded["fractional"] == .real(3.14))

        // Documents a known PropertyListDecoder limitation: an integral-valued <real>
        // decodes as .integer because the decoder coerces across numeric types.
        // The int/real distinction is restored later via normalized(to:), driven by pfm_type.
        #expect(decoded["wholeLookingReal"] == .integer(5))  // not .real(5.0) — decoder coerces
    }

    @Test func normalizes_to_declared_type() throws {
        #expect(PFMValue.integer(5).normalized(to: .real) == .real(5.0))
        #expect(PFMValue.real(5.0).normalized(to: .integer) == .integer(5))
        #expect(PFMValue.real(3.14).normalized(to: .real) == .real(3.14))
    }

    @Test func round_trips() throws {
        let original: PFMValue = .dictionary([
            "name": .string("Dock"),
            "size": .integer(64),
            "magnify": .boolean(true),
            "ratio": .real(1.5),
        ])

        let encoder = PropertyListEncoder()
        let data = try encoder.encode(original)
        let back = try PropertyListDecoder().decode(PFMValue.self, from: data)
        #expect(back == original)
    }
}
