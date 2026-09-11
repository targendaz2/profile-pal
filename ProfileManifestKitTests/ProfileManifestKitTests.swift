//
//  ProfileManifestKitTests.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation
import Testing

@testable import ProfileManifestKit

struct ProfileManifestKitTests {

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

}
