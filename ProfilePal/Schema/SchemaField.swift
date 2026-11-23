//
//  SchemaField.swift
//  ProfilePal
//
//  Created by David Rosenberg on 11/22/26.
//

import Foundation

/// One field of a payload: the kind of value it holds, how it's shown, and when it applies.
nonisolated struct SchemaField: Sendable, Hashable {
    /// The field's key in the payload.
    ///
    /// For an array's item, an identifier only, since items have no key. Often `nil` there.
    let name: String?

    /// The kind of value the field holds, with the default and constraints for that kind.
    let kind: FieldKind

    /// The text and links shown to the user for the field.
    let presentation: FieldPresentation

    /// When the field must be present in the payload.
    let requirement: Requirement

    /// The platforms, versions, and device requirements the field works with.
    let availability: Availability

    /// The channels the field can be installed on, or `nil` to inherit the payload's.
    let scopes: Set<Scope>?

    /// Whether the field's value may be sensitive enough to warrant encrypting the profile.
    let isSensitive: Bool
}

/// The text and links shown to the user for a field.
nonisolated struct FieldPresentation: Sendable, Hashable {
    /// The human-readable title of the field, or its name when the source gives no title.
    ///
    /// `nil` only when the field has neither, as an array's item often doesn't.
    let title: String?

    /// A description of the field.
    let description: String?

    /// A note that draws the user's attention to something specific about the field.
    let note: String?

    /// The unit the field's value represents, such as minutes or characters.
    let unit: String?

    /// A URL to additional documentation for the field.
    let documentationURL: URL?
}

/// When a field must be present in the payload.
nonisolated struct Requirement: Sendable, Hashable {
    /// How strictly a field is required, from least to most strict.
    ///
    /// Cases are declared in order of strictness, so `<` compares them and `max` picks the
    /// strictest of two levels.
    enum Level: Sendable, Hashable, Comparable {
        /// The field can be left out.
        case optional

        /// The field is required only when the profile is installed by MDM.
        case mdmOnly

        /// The field is always required.
        case always

        /// The field is always required, even inside a nested dictionary that's itself optional.
        case alwaysNested
    }

    /// How strictly the field is required.
    let level: Level
}
