//
//  FieldKind.swift
//  ProfilePal
//
//  Created by David Rosenberg on 11/22/26.
//

import Foundation

/// The constraints every typed value in a field kind meets.
typealias SchemaValue = Sendable & Hashable

/// The kind of value a field holds, with the default and constraints for that kind.
nonisolated enum FieldKind: Sendable, Hashable {
    case string(StringField)
    case integer(NumberField<Int>)
    case real(NumberField<Double>)
    case boolean(BooleanField)
    case date(DateField)
    case data(DataField)
    indirect case array(ArrayField)
    case dictionary(DictionaryField)
}

/// The default and constraints for a field that holds a string.
nonisolated struct StringField: Sendable, Hashable {
    /// The value the field takes when the user doesn't set one.
    let defaultValue: String?

    /// An example value shown to the user, never written to the payload.
    let placeholder: String?

    /// The only values the field allows, or `nil` when it allows any value.
    let choices: [Choice<String>]?

    /// A regular expression the field's value must match.
    let pattern: String?
}

/// The default and constraints for a field that holds an integer or a real number.
nonisolated struct NumberField<Value: SchemaValue & Comparable>: Sendable, Hashable {
    /// The value the field takes when the user doesn't set one.
    let defaultValue: Value?

    /// An example value shown to the user, never written to the payload.
    let placeholder: Value?

    /// The only values the field allows, or `nil` when it allows any value.
    let choices: [Choice<Value>]?

    /// The smallest and largest values the field allows, or `nil` when neither is limited.
    let range: Bounds<Value>?
}

/// The default and display options for a field that holds a Boolean.
nonisolated struct BooleanField: Sendable, Hashable {
    /// The value the field takes when the user doesn't set one.
    let defaultValue: Bool?

    /// Whether the value shown to the user is the opposite of the one written to the payload.
    ///
    /// Set when the field's title or description is worded as the opposite of its value.
    let isInverted: Bool

    /// The only values the field allows, with a title for each, or `nil` to show a plain toggle.
    let choices: [Choice<Bool>]?
}

/// The default for a field that holds a date.
nonisolated struct DateField: Sendable, Hashable {
    /// The value the field takes when the user doesn't set one.
    let defaultValue: Date?
}

/// The default for a field that holds raw data.
nonisolated struct DataField: Sendable, Hashable {
    /// The value the field takes when the user doesn't set one.
    let defaultValue: Data?
}

/// The item definition and size limits for a field that holds an array.
nonisolated struct ArrayField: Sendable, Hashable {
    /// The field every item in the array follows, or `nil` when the source doesn't describe them.
    let item: SchemaField?

    /// The fewest and most items the array allows, or `nil` when neither is limited.
    let count: Bounds<Int>?
}

/// The nested fields of a field that holds a dictionary.
nonisolated struct DictionaryField: Sendable, Hashable {
    /// The fields the dictionary can hold, in the source's order.
    let fields: [SchemaField]
}

/// One value a field allows, and the title shown for it.
nonisolated struct Choice<Value: SchemaValue>: Sendable, Hashable {
    /// The value written to the payload.
    let value: Value

    /// The human-readable title shown for the value, or `nil` to show the value itself.
    let title: String?
}

/// Inclusive lower and upper limits, either of which may be absent.
nonisolated struct Bounds<Value: SchemaValue & Comparable>: Sendable, Hashable {
    /// The smallest value allowed, or `nil` for no lower limit.
    let min: Value?

    /// The largest value allowed, or `nil` for no upper limit.
    let max: Value?
}
