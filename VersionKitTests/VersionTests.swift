//
//  VersionTests.swift
//  VersionKitTests
//
//  Created by David Rosenberg on 11/21/26.
//

import Testing

@testable import VersionKit

@Suite("Version")
struct VersionTests {
    @Test(
        "Parses versions with one to four numeric parts",
        arguments: zip(
            ["12", "10.15", "10.13.4", "2024.1.160.0"],
            [[12], [10, 15], [10, 13, 4], [2024, 1, 160, 0]],
        ),
    )
    func parse(string: String, expected: [Int]) async throws {
        // Given a version string of one to four dot-separated numbers
        // When it's parsed as a Version
        let version = try #require(Version(string))

        // Then its parts are those numbers
        #expect(version.components == expected)
    }

    // Real manifests write app versions such as OneDrive's 20.033 and Defender's 101.24042.0002.
    @Test(
        "Parses parts with leading zeros as integers",
        arguments: zip(["1.04", "101.24042.0002"], [[1, 4], [101, 24042, 2]]),
    )
    func parseLeadingZeros(string: String, expected: [Int]) async throws {
        // Given a version string with a part that starts with 0
        // When it's parsed as a Version
        let version = try #require(Version(string))

        // Then that part is its integer value
        #expect(version.components == expected)

        // And the original string is kept for display
        #expect(version.description == string)
    }

    // The annotated strings come from Microsoft Office manifests' app versions.
    @Test(
        "Rejects strings that aren't dot-separated numbers",
        arguments: [
            "", "15.x", "16.27 ONLY", "4.31y", "1..2", ".1", "1.", "v1.2", "-1", "+1", " 1",
        ],
    )
    func parseInvalid(string: String) async throws {
        // Given an empty string, a wildcard, an annotation, an empty part, a prefix, or a sign
        // When it's parsed as a Version
        let version = Version(string)

        // Then parsing fails
        #expect(version == nil)
    }

    @Test("Keeps the parsed string as its description")
    func descriptionKeepsOriginal() async throws {
        // Given versions parsed from 10.15 and 10.15.0
        let short = try #require(Version("10.15"))
        let long = try #require(Version("10.15.0"))

        // When their descriptions are read
        let descriptions = [short.description, long.description]

        // Then each is the string it was parsed from
        #expect(descriptions == ["10.15", "10.15.0"])
    }

    @Test("Describes a version made from parts by joining them with dots")
    func descriptionFromComponents() async throws {
        // Given a version made from the parts 10 and 15
        let version = Version(10, 15)

        // When its description is read
        let description = version.description

        // Then it's the parts joined by a dot
        #expect(description == "10.15")
    }

    @Test(
        "Treats missing trailing parts as zero when checking equality",
        arguments: zip(["10.15", "12", "0"], ["10.15.0", "12.0.0", "0.0"]),
    )
    func equalIgnoringTrailingZeros(shorter: String, longer: String) async throws {
        // Given two versions that differ only in trailing zero parts
        let short = try #require(Version(shorter))
        let long = try #require(Version(longer))

        // When they're compared and added to a set
        let versions: Set = [short, long]

        // Then they're equal
        #expect(short == long)

        // And they hash the same, so the set holds one of them
        #expect(versions.count == 1)

        // And neither orders before the other
        #expect(!(short < long) && !(long < short))
    }

    @Test(
        "Orders versions part by part as numbers",
        arguments: zip(
            ["9", "1.9", "10.15", "2024.1.16", "10.15.0", "10.15.9"],
            ["10", "1.10", "10.15.1", "2024.1.160.0", "10.16", "11"],
        ),
    )
    func ordering(lower: String, higher: String) async throws {
        // Given a lower and a higher version, which may have different numbers of parts
        let low = try #require(Version(lower))
        let high = try #require(Version(higher))

        // When they're compared
        let isOrdered = low < high

        // Then the lower one orders first
        #expect(isOrdered)

        // And the higher one doesn't
        #expect(!(high < low))
    }
}
