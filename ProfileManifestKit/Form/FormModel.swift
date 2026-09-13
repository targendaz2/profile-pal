//
//  FormModel.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/11/26.
//

import Foundation
import Observation
import SwiftUI

@Observable @MainActor
public final class FormModel {
    public let manifest: PayloadManifest
    private(set) var root: PFMValue
    private(set) var errors: [FormPath: [String]] = [:]

    public init(manifest: PayloadManifest) {
        self.manifest = manifest
        self.root = Self.initialTree(for: manifest.subkeys)
    }

    static func initialTree(for subkeys: [ManifestSubkey]) -> PFMValue {
        var dict: [String: PFMValue] = [:]
        for key in subkeys {
            guard let name = key.name else { continue }  // array-element subkeys have no name
            if let seeded = seededValue(for: key) {
                dict[name] = seeded
            }
        }
        return .dictionary(dict)
    }

    private static func seededValue(for key: ManifestSubkey) -> PFMValue? {
        switch key.type {
            case .dictionary:
                // Recurse into nested dict subkeys; include it only if something seeded.
                guard let subs = key.subkeys else { return PFMValue.seed(for: key) }
                let nested = initialTree(for: subs)
                if case .dictionary(let d) = nested, d.isEmpty {
                    // no nested defaults → fall back to own default (usually nil)
                    return PFMValue.seed(for: key)
                }
                return nested
            case .array:
                // Arrays start empty unless there's an explicit default array.
                return PFMValue.seed(for: key)
            default:
                return PFMValue.seed(for: key)
        }
    }

    // MARK: Read

    public func value(at path: FormPath) -> PFMValue? {
        var current: PFMValue? = root
        for component in path.components {
            switch (current, component) {
                case (.dictionary(let d), .key(let k)):
                    current = d[k]
                case (.array(let a), .index(let i)):
                    current = a.indices.contains(i) ? a[i] : nil
                default:
                    return nil
            }
        }
        return current
    }

    // MARK: Write

    public func setValue(_ newValue: PFMValue?, at path: FormPath) {
        root = Self.set(newValue, at: path.components, in: root)
        // validation hook lands in step 5; for now, writing is enough
    }

    /// Immutable recursive set — rebuilds the spine of the tree along `path`.
    private static func set(
        _ newValue: PFMValue?,
        at components: [FormPath.Component],
        in node: PFMValue,
    ) -> PFMValue {
        guard let first = components.first else {
            return newValue ?? .dictionary([:])  // replacing the node itself
        }
        let rest = Array(components.dropFirst())

        switch (node, first) {
            case (.dictionary(var d), .key(let k)):
                if rest.isEmpty {
                    if let newValue { d[k] = newValue } else { d.removeValue(forKey: k) }
                } else {
                    let child = d[k] ?? .dictionary([:])
                    d[k] = set(newValue, at: rest, in: child)
                }
                return .dictionary(d)

            case (.array(var a), .index(let i)):
                guard a.indices.contains(i) else { return node }
                if rest.isEmpty {
                    if let newValue { a[i] = newValue } else { a.remove(at: i) }
                } else {
                    a[i] = set(newValue, at: rest, in: a[i])
                }
                return .array(a)

            default:
                return node  // path doesn't match tree shape; no-op
        }
    }
}

extension FormModel {
    /// Generic binding to the raw PFMValue at a path.
    public func binding(at path: FormPath) -> Binding<PFMValue?> {
        Binding(
            get: { self.value(at: path) },
            set: { self.setValue($0, at: path) },
        )
    }

    /// String-typed binding for text fields. Empty string clears the key.
    public func stringBinding(at path: FormPath) -> Binding<String> {
        Binding(
            get: {
                if case .string(let s) = self.value(at: path) { return s }
                return ""
            },
            set: { self.setValue($0.isEmpty ? nil : .string($0), at: path) },
        )
    }

    /// Bool-typed binding, honoring pfm_value_inverted.
    public func boolBinding(at path: FormPath, inverted: Bool = false) -> Binding<Bool> {
        Binding(
            get: {
                if case .boolean(let b) = self.value(at: path) { return inverted ? !b : b }
                return false
            },
            set: { self.setValue(.boolean(inverted ? !$0 : $0), at: path) },
        )
    }

    /// Double-typed binding for sliders, bridging integer and real.
    // TODO: set always writes .real, even when the subkey's pfm_type is .integer
    // (unlike stringBinding/boolBinding, there's no coercion to the declared type here).
    // Fine while only `real` subkeys use this binding; if an integer-typed slider
    // shows up, coerce via PFMValue.normalized(to:) like PFMValue.seed(for:) does.
    public func doubleBinding(at path: FormPath) -> Binding<Double> {
        Binding(
            get: { self.value(at: path)?.asDouble ?? 0 },
            set: { self.setValue(.real($0), at: path) },
        )
    }
}

extension FormModel {
    /// Resolve a pfm_target dotted keypath against the value tree.
    /// Cross-payload targeting (a non-nil domain) is not yet supported — treated
    /// as unresolvable, so conditions referencing another payload read as "absent".
    func targetValue(_ target: String, domain: String?) -> PFMValue? {
        guard domain == nil else { return nil }  // step-5 limitation, documented
        let path = FormPath(
            components:
                target
                .split(separator: ".")
                .map { .key(String($0)) })
        return value(at: path)
    }
}

extension FormModel {
    /// Evaluate one target condition against current form state.
    func evaluate(_ condition: TargetCondition) -> Bool {
        let value = condition.target.flatMap {
            targetValue($0, domain: condition.domain)
        }

        // pfm_present: true → key must exist; false → key must be absent.
        if let present = condition.present {
            return (value != nil) == present
        }

        // pfm_value_empty: true → value is absent or an empty string/array.
        if let empty = condition.valueEmpty {
            return isEmpty(value) == empty
        }

        // pfm_range_list: value equals any listed value.
        if let list = condition.rangeList {
            guard let value else { return false }
            return list.contains(value)
        }

        // pfm_n_range_list: value equals none of the listed values.
        if let list = condition.nRangeList {
            guard let value else { return true }  // absent ≠ any listed value
            return !list.contains(value)
        }

        // pfm_contains_any: array value shares at least one element with the list.
        if let any = condition.containsAny {
            return containsAny(value, any)
        }

        // pfm_n_contains_any: array value shares no element with the list.
        if let nAny = condition.nContainsAny {
            return !containsAny(value, nAny)
        }

        // pfm_platforms (extended condition): current platform is in the list.
        if let platforms = condition.platforms {
            return platforms.contains(currentPlatform)
        }

        // A condition with no recognized operator is vacuously true.
        return true
    }

    private func isEmpty(_ value: PFMValue?) -> Bool {
        switch value {
            case nil: return true
            case .string(let s): return s.isEmpty
            case .array(let a): return a.isEmpty
            case .dictionary(let d): return d.isEmpty
            default: return false
        }
    }

    private func containsAny(_ value: PFMValue?, _ candidates: [PFMValue]) -> Bool {
        guard case .array(let elements)? = value else { return false }
        return elements.contains { candidates.contains($0) }
    }

    var currentPlatform: String { "macOS" }  // hard-coded for a macOS-only v1
}

extension FormModel {
    /// All conditions in one entry must hold (AND).
    func evaluateAll(_ conditions: [TargetCondition]) -> Bool {
        conditions.allSatisfy { evaluate($0) }
    }

    // MARK: Visibility

    /// A key is excluded if ANY pfm_exclude entry's conditions all hold (OR of ANDs).
    func isExcluded(_ key: ManifestSubkey) -> Bool {
        guard let exclusions = key.exclude else { return false }
        return exclusions.contains { evaluateAll($0.targetConditions) }
    }

    /// Whether a key should render at all: not excluded, not statically hidden,
    /// and applicable to the current platform.
    public func isVisible(_ key: ManifestSubkey) -> Bool {
        if key.hidden == .all { return false }
        if isExcluded(key) { return false }
        if let platforms = key.platforms, !platforms.contains(currentPlatform) {
            return false
        }
        return true
    }

    // MARK: Requirement

    /// A key is required if a static flag says so, OR any pfm_conditionals entry
    /// with a non-nil pfm_require has all its conditions holding.
    public func isRequired(_ key: ManifestSubkey) -> Bool {
        if key.required == true { return true }
        if key.require == .always || key.require == .alwaysNested { return true }

        guard let conditionals = key.conditionals else { return false }
        return conditionals.contains { conditional in
            // .push only matters for MDM delivery, not the local editing UI —
            // same exclusion as the static require check above.
            (conditional.require == .always || conditional.require == .alwaysNested)
                && evaluateAll(conditional.targetConditions)
        }
    }
}
