//
//  FormValueTests.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation
import Testing

@testable import ProfileManifestKit

struct FormValueTests {

    @Test func decodes_each_scalar_type() throws {
        let plist = try PlistFixture.xmlData([
            "s": "hello",
            "i": 42,
            "r": 3.14,
            "b": true,
        ])

        let decoded = try PropertyListDecoder().decode([String: FormValue].self, from: plist)
        #expect(decoded["s"] == .string("hello"))
        #expect(decoded["i"] == .integer(42))
        #expect(decoded["r"] == .real(3.14))
        #expect(decoded["b"] == .boolean(true))  // NOT .integer(1)
    }

    @Test func raw_decoding_coerces_integral_reals_to_integer() throws {
        let plist = try PlistFixture.xmlData([
            "whole": 42,
            "fractional": 3.14,
            "wholeLookingReal": 5.0,
        ])

        let decoded = try PropertyListDecoder().decode([String: FormValue].self, from: plist)

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
        #expect(FormValue.integer(5).normalized(to: .real) == .real(5.0))
        #expect(FormValue.real(5.0).normalized(to: .integer) == .integer(5))
        #expect(FormValue.real(3.14).normalized(to: .real) == .real(3.14))
    }

    @Test func round_trips() throws {
        let original: FormValue = .dictionary([
            "name": .string("Dock"),
            "size": .integer(64),
            "magnify": .boolean(true),
            "ratio": .real(1.5),
        ])

        let encoder = PropertyListEncoder()
        let data = try encoder.encode(original)
        let back = try PropertyListDecoder().decode(FormValue.self, from: data)
        #expect(back == original)
    }
}
