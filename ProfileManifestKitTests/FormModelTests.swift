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
private func decodeManifest(_ root: [String: Any]) throws -> PayloadManifest {
    let data = try PlistFixture.xmlData(root)
    return try PropertyListDecoder().decode(PayloadManifest.self, from: data)
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
