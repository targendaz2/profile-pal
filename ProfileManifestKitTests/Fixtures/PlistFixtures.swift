//
//  PlistFixtures.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation

enum PlistFixtures {
    static var dock: [String: Any] {
        PlistFixture.manifest(
            domain: "com.apple.dock",
            title: "Dock",
            subkeys: [
                PlistFixture.key(
                    name: "showrecents-immutable",
                    type: "boolean",
                    title: "Prevents changing recents display",
                    default: false,
                ),
                PlistFixture.key(
                    name: "dblclickbehavior",
                    type: "string",
                    title: "Doubleclick behavior",
                    rangeList: [
                        "minimize",
                        "maximize",
                        "none",
                    ],
                    rangeListTitles: [
                        "Minimize",
                        "Maximize",
                        "None",
                    ],
                ),
            ],
        )
    }

    static var trap: [String: Any] {
        PlistFixture.manifest(
            domain: "com.example.test",
            title: "Test",
            subkeys: [
                PlistFixture.key(
                    name: "Mode",
                    type: "string",
                    default: "auto",
                    rangeList: ["auto", "manual"],
                ),
                PlistFixture.key(
                    name: "Tags",
                    type: "array",
                    subkeys: [
                        // no name → array-element subkey
                        PlistFixture.key(type: "string")
                    ],
                ),
                PlistFixture.key(
                    name: "MaxItems",
                    type: "integer",
                    default: 10,
                    required: true,
                ),
            ],
        )
    }
}
