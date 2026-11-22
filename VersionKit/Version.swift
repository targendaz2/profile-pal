//
//  Version.swift
//  VersionKit
//
//  Created by David Rosenberg on 11/21/26.
//

import Foundation

/// A version number made of dot-separated numeric parts, such as `10.15` or `2024.1.160.0`.
///
/// Versions compare part by part, and missing trailing parts count as zero, so `10.15` equals
/// `10.15.0`. A parsed version keeps its original string for display.
public struct Version: Sendable, Hashable, Comparable, LosslessStringConvertible {
    /// The numeric parts, from most to least significant.
    public let components: [Int]

    /// The exact string the version was parsed from, or its parts joined by dots.
    public let original: String

    /// The parts with trailing zeros removed, so equal versions compare and hash the same.
    private var significantComponents: ArraySlice<Int> {
        var end = components.endIndex

        while end > components.startIndex, components[end - 1] == 0 {
            end -= 1
        }

        return components[..<end]
    }

    /// Parses a version such as `10.15`, keeping `description` as its original string.
    ///
    /// Every dot-separated part must be one or more ASCII digits. Leading zeros are allowed and
    /// parse as integers, so `1.04` has the parts 1 and 4. Anything else, such as `15.x`, `v1.2`,
    /// or an empty string, returns `nil`.
    public init?(_ description: String) {
        var components: [Int] = []

        for part in description.split(separator: ".", omittingEmptySubsequences: false) {
            // ASCII digits only: Int(_:) would also accept a leading sign.
            guard !part.isEmpty, part.allSatisfy({ $0.isASCII && $0.isNumber }) else {
                return nil
            }

            // Fails only when the part is too large for Int.
            guard let number = Int(part) else {
                return nil
            }

            components.append(number)
        }

        self.components = components
        self.original = description
    }

    /// Creates a version from its numeric parts, such as `Version(10, 15)`.
    ///
    /// - Important: Pass at least one part, and no negative parts.
    public init(_ components: Int...) {
        precondition(!components.isEmpty, "A version needs at least one part.")
        precondition(components.allSatisfy { $0 >= 0 }, "Version parts can't be negative.")

        self.components = components
        self.original = components.map(String.init).joined(separator: ".")
    }

    public var description: String { original }

    public static func == (lhs: Version, rhs: Version) -> Bool {
        lhs.significantComponents.elementsEqual(rhs.significantComponents)
    }

    public func hash(into hasher: inout Hasher) {
        for component in significantComponents {
            hasher.combine(component)
        }
    }

    public static func < (lhs: Version, rhs: Version) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)

        for index in 0..<count {
            // A version with fewer parts counts its missing parts as zero.
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0

            if left != right {
                return left < right
            }
        }

        return false
    }
}
