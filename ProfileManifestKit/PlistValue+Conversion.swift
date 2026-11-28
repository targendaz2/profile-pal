//
//  PlistValue+Conversion.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 11/28/26.
//

import Foundation

extension PlistValue {
    /// The value loaded as `field`'s type, or `nil` if it can't be read as that type.
    ///
    /// The conversions are the ones `docs/decisions.md` lists. Each conversion and each value
    /// left out is recorded in `issues`, at `path` and `key`. An array's items are loaded as the
    /// array's first subkey, and a dictionary's values as the subkey with the same name; an item
    /// or value that can't be loaded is left out on its own, and the rest of the value loads.
    func converted(
        to field: ManifestField,
        at path: [String],
        key: String,
        issues: inout [ManifestIssue],
    ) -> PlistValue? {
        let converted: PlistValue?

        switch field.type {
            case .string: converted = convertedToString()
            case .boolean: converted = convertedToBool()
            case .integer: converted = convertedToInt()
            case .real: converted = convertedToDouble()
            case .data: converted = if case .data = self { self } else { nil }
            case .date: converted = if case .date = self { self } else { nil }
            case .array: return convertedToArray(field, at: path, key: key, issues: &issues)
            case .dictionary:
                return convertedToDictionary(field, at: path, key: key, issues: &issues)
        }

        record(converted, as: field.type, at: path, key: key, issues: &issues)
        return converted
    }

    // MARK: - Scalars

    private func convertedToString() -> PlistValue? {
        switch self {
            case .string: self
            case .int(let v): .string(String(v))
            case .uint(let v): .string(String(v))
            default: nil
        }
    }

    private func convertedToBool() -> PlistValue? {
        switch self {
            case .bool: self

            // An <integer> 0 or 1, as BBEdit's conditions write booleans.
            case .int(0): .bool(false)
            case .int(1): .bool(true)

            // A string such as "false" or "YES". Case doesn't matter.
            case .string(let v):
                switch v.lowercased() {
                    case "true", "yes", "1": .bool(true)
                    case "false", "no", "0": .bool(false)
                    default: nil
                }

            default: nil
        }
    }

    private func convertedToInt() -> PlistValue? {
        switch self {
            case .int, .uint: self

            // A string of an integer, such as "12". Above Int.max, it stays exact as a uint.
            case .string(let v):
                if let int = Int(v) {
                    .int(int)
                } else if let uint = UInt64(v) {
                    .uint(uint)
                } else {
                    nil
                }

            default: nil
        }
    }

    private func convertedToDouble() -> PlistValue? {
        switch self {
            case .double: self

            // An <integer>, or a whole-number <real> the decoder read as one.
            case .int(let v): .double(Double(v))
            case .uint(let v): .double(Double(v))

            // A string of a number, such as "0.5". "nan" and "inf" parse but aren't kept.
            case .string(let v):
                if let double = Double(v), double.isFinite {
                    .double(double)
                } else {
                    nil
                }

            default: nil
        }
    }

    // MARK: - Containers

    private func convertedToArray(
        _ field: ManifestField,
        at path: [String],
        key: String,
        issues: inout [ManifestIssue],
    ) -> PlistValue? {
        let itemField = field.subkeys?.first
        let itemPath = path + [itemField?.name ?? "[]"]

        guard case .array(let items) = self else {
            return wrappedInArray(field, itemField: itemField, at: path, key: key, issues: &issues)
        }

        // No subkey describes the items, so there's no type to load them as.
        guard let itemField else {
            return self
        }

        var loadedItems: [PlistValue] = []

        for item in items {
            if let loaded = item.converted(to: itemField, at: itemPath, key: key, issues: &issues) {
                loadedItems.append(loaded)
            }
        }

        return .array(loadedItems)
    }

    /// A single value loaded as a one-item array, if it can be loaded as the array's item.
    private func wrappedInArray(
        _ field: ManifestField,
        itemField: ManifestField?,
        at path: [String],
        key: String,
        issues: inout [ManifestIssue],
    ) -> PlistValue? {
        // No subkey describes the items, so any single value can be the item.
        guard let itemField else {
            record(.array([self]), as: field.type, at: path, key: key, issues: &issues)
            return .array([self])
        }

        // Load the item separately, so a value that can't be an item leaves only one issue.
        var itemIssues: [ManifestIssue] = []
        let itemPath = path + [itemField.name ?? "[]"]
        let item = converted(to: itemField, at: itemPath, key: key, issues: &itemIssues)

        guard let item else {
            record(nil, as: field.type, at: path, key: key, issues: &issues)
            return nil
        }

        record(.array([item]), as: field.type, at: path, key: key, issues: &issues)
        issues += itemIssues
        return .array([item])
    }

    private func convertedToDictionary(
        _ field: ManifestField,
        at path: [String],
        key: String,
        issues: inout [ManifestIssue],
    ) -> PlistValue? {
        guard case .dictionary(let values) = self else {
            record(nil, as: field.type, at: path, key: key, issues: &issues)
            return nil
        }

        // A linear search per value: a field's subkeys stay small.
        let subkeys = field.subkeys ?? []
        var loadedValues: [String: PlistValue] = [:]

        for (name, value) in values {
            if let subkey = subkeys.first(where: { $0.name == name }) {
                let valuePath = path + [name]
                let loaded = value.converted(to: subkey, at: valuePath, key: key, issues: &issues)
                loadedValues[name] = loaded
            } else {
                // No subkey describes this value, so there's no type to load it as.
                loadedValues[name] = value
            }
        }

        return .dictionary(loadedValues)
    }

    // MARK: - Issues

    /// Records an issue when `loaded` isn't this value unchanged.
    ///
    /// A whole-number <real> the decoder read as an int, loaded back as a double, isn't recorded:
    /// the decoder can't tell it from an <integer>, so it isn't known to be a mismatch.
    private func record(
        _ loaded: PlistValue?,
        as type: ManifestFieldType,
        at path: [String],
        key: String,
        issues: inout [ManifestIssue],
    ) {
        guard let loaded else {
            let kind = ManifestIssue.Kind.valueDropped(self, expected: type)
            issues.append(ManifestIssue(fieldPath: path, key: key, kind: kind))
            return
        }

        let isUnchanged = loaded == self
        let isNumberToReal =
            switch self {
                case .int, .uint: type == .real
                default: false
            }

        guard !isUnchanged, !isNumberToReal else {
            return
        }

        let kind = ManifestIssue.Kind.valueConverted(from: self, to: type)
        issues.append(ManifestIssue(fieldPath: path, key: key, kind: kind))
    }
}
