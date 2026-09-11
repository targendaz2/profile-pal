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
final class FormModel {
    let manifest: PayloadManifest
    private(set) var root: PFMValue
    private(set) var errors: [FormPath: [String]] = [:]

    init(manifest: PayloadManifest) {
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
                    return PFMValue.seed(for: key)  // no nested defaults → fall back to own default (usually nil)
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

    func value(at path: FormPath) -> PFMValue? {
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

    func setValue(_ newValue: PFMValue?, at path: FormPath) {
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
    func binding(at path: FormPath) -> Binding<PFMValue?> {
        Binding(
            get: { self.value(at: path) },
            set: { self.setValue($0, at: path) },
        )
    }

    /// String-typed binding for text fields. Empty string clears the key.
    func stringBinding(at path: FormPath) -> Binding<String> {
        Binding(
            get: {
                if case .string(let s) = self.value(at: path) { return s }
                return ""
            },
            set: { self.setValue($0.isEmpty ? nil : .string($0), at: path) },
        )
    }

    /// Bool-typed binding, honoring pfm_value_inverted.
    func boolBinding(at path: FormPath, inverted: Bool = false) -> Binding<Bool> {
        Binding(
            get: {
                if case .boolean(let b) = self.value(at: path) { return inverted ? !b : b }
                return false
            },
            set: { self.setValue(.boolean(inverted ? !$0 : $0), at: path) },
        )
    }

    /// Double-typed binding for sliders, bridging integer and real.
    func doubleBinding(at path: FormPath) -> Binding<Double> {
        Binding(
            get: { self.value(at: path)?.asDouble ?? 0 },
            set: { self.setValue(.real($0), at: path) },
        )
    }
}
