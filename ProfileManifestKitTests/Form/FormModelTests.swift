//
//  FormModelTests.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 9/11/26.
//

import Foundation
import SwiftUI
import Testing

@testable import ProfileManifestKit

// MARK: - Helpers

/// Decode a manifest from a PlistFixture value tree.
private func decodeManifest(_ root: [String: Any]) throws -> PFMPayload {
    let data = try PlistFixture.xmlData(root)
    return try PropertyListDecoder().decode(PFMPayload.self, from: data)
}

/// Pull the underlying dictionary out of a PFMValue, or fail.
private func dict(_ value: PFMValue?) throws -> [String: PFMValue] {
    guard case .dictionary(let d)? = value else {
        Issue.record("expected .dictionary, got \(String(describing: value))")
        throw TestError.shape
    }
    return d
}

private enum TestError: Error { case shape }

// MARK: - Seeding tests

@Suite("Tree seeding") @MainActor
struct SeedingTests {

    @Test("Scalar defaults populate the initial tree, coerced to declared type")
    func seeds_scalar_defaults() throws {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.seed", title: "Seed",
                subkeys: [
                    PlistFixture.key(name: "Mode", type: "string", default: "auto"),
                    PlistFixture.key(name: "Count", type: "integer", default: 10),
                    // A real declared as an integer-valued literal: must coerce to .real
                    PlistFixture.key(name: "Ratio", type: "real", default: 2),
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let root = try dict(model.root)

        #expect(root["Mode"] == .string("auto"))
        #expect(root["Count"] == .integer(10))
        // normalized(to:) at work: pfm_type real wins over the integer literal
        #expect(root["Ratio"] == .real(2.0))
        #expect(root["Ratio"] != .integer(2))
    }

    @Test("Keys without a default are absent from the tree, not present-but-empty")
    func omits_keys_without_defaults() throws {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.seed", title: "Seed",
                subkeys: [
                    PlistFixture.key(name: "HasDefault", type: "string", default: "x"),
                    PlistFixture.key(name: "NoDefault", type: "string"),
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let root = try dict(model.root)

        #expect(root["HasDefault"] == .string("x"))
        #expect(root["NoDefault"] == nil)  // absent, not .string("")
        #expect(root.keys.contains("NoDefault") == false)
    }

    @Test("Nested dict with a default only on the inner key seeds the inner value")
    func seeds_nested_default() throws {
        // {Outer: {Inner: <default>}} — not {Outer: {}} and not {}
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.seed", title: "Seed",
                subkeys: [
                    PlistFixture.key(
                        name: "Outer", type: "dictionary",
                        subkeys: [
                            PlistFixture.key(name: "Inner", type: "string", default: "deep"),
                            PlistFixture.key(name: "Sibling", type: "string"),  // no default
                        ],
                    )
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let outer = try dict(try dict(model.root)["Outer"])

        #expect(outer["Inner"] == .string("deep"))
        #expect(outer["Sibling"] == nil)
    }

    @Test("A nested dict with no defaults anywhere stays absent")
    func omits_empty_nested_dict() throws {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.seed", title: "Seed",
                subkeys: [
                    PlistFixture.key(
                        name: "Outer", type: "dictionary",
                        subkeys: [
                            PlistFixture.key(name: "Inner", type: "string")  // no default
                        ],
                    )
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let root = try dict(model.root)

        // Nothing to seed → the whole Outer key is absent.
        #expect(root["Outer"] == nil)
    }

    @Test("Arrays start empty even when element subkeys exist")
    func arrays_start_empty() throws {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.seed", title: "Seed",
                subkeys: [
                    PlistFixture.key(
                        name: "Tags", type: "array",
                        subkeys: [
                            PlistFixture.key(type: "string")  // array-element subkey, no name
                        ],
                    )
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let root = try dict(model.root)

        // No explicit default array → the key is absent (user adds rows later).
        #expect(root["Tags"] == nil)
    }
}

// MARK: - Value round-trip tests

@Suite("Value round-trip") @MainActor
struct RoundTripTests {

    @Test("Set then read returns the same value")
    func set_then_get() throws {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.rt", title: "RT",
                subkeys: [
                    PlistFixture.key(name: "Field", type: "string")
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let path = FormPath.root.appending(key: "Field")

        model.setValue(.string("hello"), at: path)
        #expect(model.value(at: path) == .string("hello"))
    }

    @Test("Overwriting replaces the value")
    func overwrite() throws {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.rt", title: "RT",
                subkeys: [
                    PlistFixture.key(name: "Field", type: "integer", default: 1)
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let path = FormPath.root.appending(key: "Field")

        #expect(model.value(at: path) == .integer(1))  // from default
        model.setValue(.integer(99), at: path)
        #expect(model.value(at: path) == .integer(99))
    }
}

// MARK: - Deep set tests

@Suite("Deep set") @MainActor
struct DeepSetTests {

    /// Build a model with a two-level nested dict already seeded.
    private func nestedModel() throws -> FormModel {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.deep", title: "Deep",
                subkeys: [
                    PlistFixture.key(
                        name: "A", type: "dictionary",
                        subkeys: [
                            PlistFixture.key(
                                name: "B", type: "dictionary",
                                subkeys: [
                                    PlistFixture.key(
                                        name: "C", type: "string", default: "c-default", ),
                                    PlistFixture.key(
                                        name: "D", type: "string", default: "d-default", ),
                                ],
                            )
                        ],
                    )
                ],
            )
        )
        return FormModel(manifest: manifest)
    }

    @Test("Setting a.b.c leaves a.b.d untouched")
    func siblings_survive_deep_set() throws {
        let model = try nestedModel()
        let cPath = FormPath(components: [.key("A"), .key("B"), .key("C")])
        let dPath = FormPath(components: [.key("A"), .key("B"), .key("D")])

        #expect(model.value(at: dPath) == .string("d-default"))

        model.setValue(.string("c-new"), at: cPath)

        #expect(model.value(at: cPath) == .string("c-new"))
        // The whole point: D must not be clobbered by the spine rebuild.
        #expect(model.value(at: dPath) == .string("d-default"))
    }

    @Test("Setting into a not-yet-existing branch creates the spine")
    func creates_missing_spine() throws {
        // A manifest whose nested keys have no defaults → A is absent initially.
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.deep", title: "Deep",
                subkeys: [
                    PlistFixture.key(
                        name: "A", type: "dictionary",
                        subkeys: [
                            PlistFixture.key(
                                name: "B", type: "dictionary",
                                subkeys: [
                                    PlistFixture.key(name: "C", type: "string")
                                ],
                            )
                        ],
                    )
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let cPath = FormPath(components: [.key("A"), .key("B"), .key("C")])

        #expect(model.value(at: FormPath.root.appending(key: "A")) == nil)

        model.setValue(.string("created"), at: cPath)

        #expect(model.value(at: cPath) == .string("created"))
    }
}

// MARK: - Absent vs. empty tests

@Suite("Absent vs empty") @MainActor
struct AbsenceTests {

    @Test("Setting nil removes the key entirely")
    func nil_removes_key() throws {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.abs", title: "Abs",
                subkeys: [
                    PlistFixture.key(name: "Field", type: "string", default: "x")
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let path = FormPath.root.appending(key: "Field")

        #expect(model.value(at: path) == .string("x"))
        model.setValue(nil, at: path)

        #expect(model.value(at: path) == nil)
        // Genuinely gone from the underlying dict, not stored as null/empty.
        let root = try dict(model.root)
        #expect(root.keys.contains("Field") == false)
    }

    @Test("Empty string through stringBinding clears the key")
    func empty_string_clears() throws {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.abs", title: "Abs",
                subkeys: [
                    PlistFixture.key(name: "Field", type: "string", default: "x")
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let path = FormPath.root.appending(key: "Field")

        model.stringBinding(at: path).wrappedValue = ""

        #expect(model.value(at: path) == nil)  // "" is absence, not .string("")
    }
}

// MARK: - Array index set/remove tests

@Suite("Array editing") @MainActor
struct ArrayTests {

    /// A model whose Tags array has been pre-filled with three strings.
    private func modelWithTags() throws -> (FormModel, FormPath) {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.arr", title: "Arr",
                subkeys: [
                    PlistFixture.key(
                        name: "Tags", type: "array",
                        subkeys: [
                            PlistFixture.key(type: "string")
                        ],
                    )
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let tagsPath = FormPath.root.appending(key: "Tags")
        model.setValue(.array([.string("a"), .string("b"), .string("c")]), at: tagsPath)
        return (model, tagsPath)
    }

    @Test("Setting at an index replaces that element")
    func set_at_index() throws {
        let (model, tagsPath) = try modelWithTags()
        let second = tagsPath.appending(index: 1)

        model.setValue(.string("B"), at: second)

        #expect(model.value(at: tagsPath) == .array([.string("a"), .string("B"), .string("c")]))
    }

    @Test("Nil-ing an index removes and shifts subsequent elements")
    func remove_at_index() throws {
        let (model, tagsPath) = try modelWithTags()
        let second = tagsPath.appending(index: 1)

        model.setValue(nil, at: second)

        #expect(model.value(at: tagsPath) == .array([.string("a"), .string("c")]))
    }

    @Test("Setting an out-of-bounds index is a no-op")
    func out_of_bounds_is_no_op() throws {
        let (model, tagsPath) = try modelWithTags()
        let tenth = tagsPath.appending(index: 10)

        model.setValue(.string("z"), at: tenth)

        // Array unchanged; no crash, no phantom element.
        #expect(model.value(at: tagsPath) == .array([.string("a"), .string("b"), .string("c")]))
    }
}

// MARK: - Inverted bool binding tests

@Suite("Inverted boolean binding") @MainActor
struct InvertedBoolTests {

    private func boolModel() throws -> (FormModel, FormPath) {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.inv", title: "Inv",
                subkeys: [
                    PlistFixture.key(
                        name: "Flag", type: "boolean",
                        extra: ["pfm_value_inverted": true], )
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        return (model, FormPath.root.appending(key: "Flag"))
    }

    @Test("Displayed true stores false when inverted")
    func displayed_true_stores_false() throws {
        let (model, path) = try boolModel()

        model.boolBinding(at: path, inverted: true).wrappedValue = true
        #expect(model.value(at: path) == .boolean(false))  // stored value is inverted
    }

    @Test("Stored false displays as true when inverted")
    func stored_false_displays_true() throws {
        let (model, path) = try boolModel()
        model.setValue(.boolean(false), at: path)

        #expect(model.boolBinding(at: path, inverted: true).wrappedValue == true)
    }
}

@Suite("Condition evaluator") @MainActor
struct EvaluatorTests {

    /// Build a model with a controlling key and a dependent key that's excluded
    /// when the controller equals a given value.
    private func modelExcludingWhen(
        controller: String,
        equals trigger: PFMValue,
    ) throws -> (FormModel, PFMSubkey) {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.cond", title: "Cond",
                subkeys: [
                    PlistFixture.key(name: controller, type: "string"),
                    PlistFixture.key(
                        name: "Dependent", type: "string",
                        extra: [
                            "pfm_exclude": [
                                PlistFixture.exclusion(targets: [
                                    PlistFixture.condition(
                                        target: controller,
                                        ["pfm_range_list": [trigger.plistValue]],
                                    )
                                ])
                            ]
                        ],
                    ),
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let dependent = manifest.subkeys.first { $0.name == "Dependent" }!
        return (model, dependent)
    }

    /// Model with two controllers and a dependent excluded by a SINGLE entry
    /// containing TWO conditions (tests AND-within-entry).
    fileprivate func modelExcludedWhenBoth(
        _ ctrlA: String, equals a: PFMValue,
        _ ctrlB: String, equals b: PFMValue,
    ) throws -> (FormModel, PFMSubkey) {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.cond", title: "Cond",
                subkeys: [
                    PlistFixture.key(name: ctrlA, type: "string"),
                    PlistFixture.key(name: ctrlB, type: "string"),
                    PlistFixture.key(
                        name: "Dependent", type: "string",
                        extra: [
                            "pfm_exclude": [
                                PlistFixture.exclusion(targets: [
                                    PlistFixture.condition(
                                        target: ctrlA, ["pfm_range_list": [a.plistValue]], ),
                                    PlistFixture.condition(
                                        target: ctrlB, ["pfm_range_list": [b.plistValue]], ),
                                ])
                            ]
                        ],
                    ),
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let dep = manifest.subkeys.first { $0.name == "Dependent" }!
        return (model, dep)
    }

    /// Model with two controllers and a dependent excluded by TWO separate
    /// entries, one condition each (tests OR-across-entries).
    fileprivate func modelExcludedWhenEither(
        _ ctrlA: String, equals a: PFMValue,
        _ ctrlB: String, equals b: PFMValue,
    ) throws -> (FormModel, PFMSubkey) {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.cond", title: "Cond",
                subkeys: [
                    PlistFixture.key(name: ctrlA, type: "string"),
                    PlistFixture.key(name: ctrlB, type: "string"),
                    PlistFixture.key(
                        name: "Dependent", type: "string",
                        extra: [
                            "pfm_exclude": [
                                PlistFixture.exclusion(targets: [
                                    PlistFixture.condition(
                                        target: ctrlA, ["pfm_range_list": [a.plistValue]], )
                                ]),
                                PlistFixture.exclusion(targets: [
                                    PlistFixture.condition(
                                        target: ctrlB, ["pfm_range_list": [b.plistValue]], )
                                ]),
                            ]
                        ],
                    ),
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let dep = manifest.subkeys.first { $0.name == "Dependent" }!
        return (model, dep)

    }

    @Test("rangeList: excluded when controller equals trigger")
    func range_list_match() throws {
        let (model, dep) = try modelExcludingWhen(controller: "Mode", equals: .string("off"))
        let ctrl = FormPath.root.appending(key: "Mode")

        model.setValue(.string("off"), at: ctrl)
        #expect(model.isExcluded(dep) == true)

        model.setValue(.string("on"), at: ctrl)
        #expect(model.isExcluded(dep) == false)

        model.setValue(nil, at: ctrl)  // absent → equals-any is false
        #expect(model.isExcluded(dep) == false)
    }

    @Test("present: true holds only when the key exists")
    func present_true() throws {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.cond", title: "Cond",
                subkeys: [
                    PlistFixture.key(name: "Ctrl", type: "string"),
                    PlistFixture.key(
                        name: "Dependent", type: "string",
                        extra: [
                            "pfm_exclude": [
                                PlistFixture.exclusion(targets: [
                                    PlistFixture.condition(target: "Ctrl", ["pfm_present": true])
                                ])
                            ]
                        ],
                    ),
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let dep = manifest.subkeys.first { $0.name == "Dependent" }!
        let ctrl = FormPath.root.appending(key: "Ctrl")

        // Absent → present:true is false → not excluded.
        #expect(model.isExcluded(dep) == false)

        // Set → key exists → present:true holds → excluded.
        model.setValue(.string("anything"), at: ctrl)
        #expect(model.isExcluded(dep) == true)

        // Cleared back to absent → not excluded again.
        model.setValue(nil, at: ctrl)
        #expect(model.isExcluded(dep) == false)
    }

    @Test("nRangeList: absent value counts as 'not any'")
    func not_range_list_absence() throws {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.cond", title: "Cond",
                subkeys: [
                    PlistFixture.key(name: "Ctrl", type: "string"),
                    PlistFixture.key(
                        name: "Dependent", type: "string",
                        extra: [
                            "pfm_exclude": [
                                PlistFixture.exclusion(targets: [
                                    PlistFixture.condition(
                                        target: "Ctrl", ["pfm_n_range_list": ["x"]], )
                                ])
                            ]
                        ],
                    ),
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let dep = manifest.subkeys.first { $0.name == "Dependent" }!
        let ctrl = FormPath.root.appending(key: "Ctrl")

        // Absent → "not any of [x]" is TRUE → excluded. This is the polarity that
        // a manual click-through never hits, because you always end up setting the field.
        #expect(model.isExcluded(dep) == true)

        // Set to "x" → it IS in the list → n_range_list is false → not excluded.
        model.setValue(.string("x"), at: ctrl)
        #expect(model.isExcluded(dep) == false)

        // Set to "y" → not in the list → n_range_list is true → excluded.
        model.setValue(.string("y"), at: ctrl)
        #expect(model.isExcluded(dep) == true)
    }

    @Test("AND within an entry: both conditions must hold")
    func and_within_entry() throws {
        let (model, dep) = try modelExcludedWhenBoth(
            "ModeA", equals: .string("off"),
            "ModeB", equals: .string("off"),
        )
        let a = FormPath.root.appending(key: "ModeA")
        let b = FormPath.root.appending(key: "ModeB")

        // Neither set → neither condition holds → not excluded.
        #expect(model.isExcluded(dep) == false)

        // Only A matches → AND fails → not excluded.
        model.setValue(.string("off"), at: a)
        #expect(model.isExcluded(dep) == false)

        // Only B matches → AND fails → not excluded.
        model.setValue(.string("on"), at: a)
        model.setValue(.string("off"), at: b)
        #expect(model.isExcluded(dep) == false)

        // Both match → AND holds → excluded.
        model.setValue(.string("off"), at: a)
        #expect(model.isExcluded(dep) == true)
    }

    @Test("OR across entries: any entry triggers exclusion")
    func or_across_entries() throws {
        let (model, dep) = try modelExcludedWhenEither(
            "ModeA", equals: .string("off"),
            "ModeB", equals: .string("off"),
        )
        let a = FormPath.root.appending(key: "ModeA")
        let b = FormPath.root.appending(key: "ModeB")

        // Neither → not excluded.
        #expect(model.isExcluded(dep) == false)

        // A alone matches → its entry holds → excluded.
        model.setValue(.string("off"), at: a)
        #expect(model.isExcluded(dep) == true)

        // B alone matches → the other entry holds → still excluded.
        model.setValue(.string("on"), at: a)
        model.setValue(.string("off"), at: b)
        #expect(model.isExcluded(dep) == true)

        // Both match → excluded (OR, so no double-count concern).
        model.setValue(.string("off"), at: a)
        #expect(model.isExcluded(dep) == true)
    }

    @Test("conditional with no pfm_require never makes a key required")
    func conditional_no_require_is_no_op() throws {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.cond", title: "Cond",
                subkeys: [
                    PlistFixture.key(name: "Ctrl", type: "string"),
                    PlistFixture.key(
                        name: "Dep", type: "string",
                        extra: [
                            "pfm_conditionals": [
                                // note: no pfm_require key
                                PlistFixture.conditional(targets: [
                                    PlistFixture.condition(
                                        target: "Ctrl", ["pfm_range_list": ["go"]], )
                                ])
                            ]
                        ],
                    ),
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let dep = manifest.subkeys.first { $0.name == "Dep" }!

        model.setValue(.string("go"), at: FormPath.root.appending(key: "Ctrl"))
        #expect(model.isRequired(dep) == false)  // no pfm_require → no effect, even when condition holds
    }

    @Test("conditional with pfm_require: push never makes a key required in the UI")
    func conditional_push_require_is_no_op() throws {
        let manifest = try decodeManifest(
            PlistFixture.manifest(
                domain: "com.example.cond", title: "Cond",
                subkeys: [
                    PlistFixture.key(name: "Ctrl", type: "string"),
                    PlistFixture.key(
                        name: "Dep", type: "string",
                        extra: [
                            "pfm_conditionals": [
                                PlistFixture.conditional(
                                    require: "push",
                                    targets: [
                                        PlistFixture.condition(
                                            target: "Ctrl", ["pfm_range_list": ["go"]], )
                                    ],
                                )
                            ]
                        ],
                    ),
                ],
            )
        )
        let model = FormModel(manifest: manifest)
        let dep = manifest.subkeys.first { $0.name == "Dep" }!

        model.setValue(.string("go"), at: FormPath.root.appending(key: "Ctrl"))
        // push only matters for MDM delivery, same exclusion as the static require check.
        #expect(model.isRequired(dep) == false)
    }
}
