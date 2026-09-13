//
//  FormTreeTests.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 9/12/26.
//

import Foundation
import Testing

@testable import ProfileManifestKit

@MainActor
struct FormTreeTests {

    /// Build a FormModel from top-level subkey fixtures.
    private func model(_ subkeys: [[String: Any]]) throws -> FormModel {
        let data = try PlistFixture.xmlData(
            PlistFixture.manifest(domain: "com.example", title: "T", subkeys: subkeys))
        let manifest = try PropertyListDecoder().decode(PayloadManifest.self, from: data)
        return FormModel(manifest: manifest)
    }

    @Test func flat_scalars_become_fields() throws {
        let m = try model([
            PlistFixture.key(name: "A", type: "string"),
            PlistFixture.key(name: "B", type: "boolean"),
        ])
        let tree = m.formTree
        #expect(tree.count == 2)
        guard case .field(let a) = tree[0], case .field(let b) = tree[1] else {
            Issue.record("expected two fields")
            return
        }
        #expect(a.path == FormPath.root.appending(key: "A"))
        #expect(a.control == .textField(secure: false))
        #expect(b.control == .toggle(inverted: false))
    }

    @Test func hidden_subkey_is_omitted() throws {
        let m = try model([
            PlistFixture.key(name: "A", type: "string"),
            PlistFixture.key(name: "Secret", type: "string", extra: ["pfm_hidden": "all"]),
        ])
        let tree = m.formTree
        #expect(tree.count == 1)
        guard case .field(let a) = tree[0] else {
            Issue.record("expected field")
            return
        }
        #expect(a.path == FormPath.root.appending(key: "A"))
    }

    @Test func dictionary_becomes_group_with_children() throws {
        let m = try model([
            PlistFixture.key(
                name: "Group",
                type: "dictionary",
                subkeys: [
                    PlistFixture.key(name: "X", type: "string"),
                    PlistFixture.key(name: "Y", type: "integer"),
                ],
            )
        ])
        let tree = m.formTree
        #expect(tree.count == 1)
        guard case .group(let id, _, let children) = tree[0] else {
            Issue.record("expected group")
            return
        }
        #expect(id == FormPath.root.appending(key: "Group"))
        #expect(children.count == 2)
        guard case .field(let x) = children[0] else {
            Issue.record("expected nested field")
            return
        }
        #expect(x.path == FormPath.root.appending(key: "Group").appending(key: "X"))
    }

    @Test func empty_array_is_array_node_with_no_rows() throws {
        let element = PlistFixture.key(type: "string")
        let m = try model([PlistFixture.key(name: "Tags", type: "array", subkeys: [element])])
        guard case .array(let id, _, _, let rows) = m.formTree[0] else {
            Issue.record("expected array")
            return
        }
        #expect(id == FormPath.root.appending(key: "Tags"))
        #expect(rows.isEmpty)
    }

    @Test func array_has_a_row_per_element() throws {
        let element = PlistFixture.key(type: "string")
        let m = try model([PlistFixture.key(name: "Tags", type: "array", subkeys: [element])])
        m.setValue(.array([.string("a"), .string("b")]), at: FormPath.root.appending(key: "Tags"))
        guard case .array(_, _, _, let rows) = m.formTree[0] else {
            Issue.record("expected array")
            return
        }
        #expect(rows.count == 2)
        guard case .field(let r0) = rows[0] else {
            Issue.record("expected field row")
            return
        }
        #expect(r0.path == FormPath.root.appending(key: "Tags").appending(index: 0))
    }

    @Test func required_and_control_surface_on_field() throws {
        let m = try model([PlistFixture.key(name: "A", type: "string", required: true)])
        guard case .field(let a) = m.formTree[0] else {
            Issue.record("expected field")
            return
        }
        #expect(a.isRequired)
        #expect(a.control == .textField(secure: false))
    }

    // MARK: Segmented controls

    @Test func segmented_groups_members_and_hides_them_from_flat_list() throws {
        let m = try model([
            PlistFixture.key(
                name: "View", type: "string",
                rangeListTitles: ["Basic", "Advanced"],
                extra: ["pfm_segments": ["Basic": ["A"], "Advanced": ["B"]]],
            ),
            PlistFixture.key(name: "A", type: "string"),
            PlistFixture.key(name: "B", type: "boolean"),
            PlistFixture.key(name: "C", type: "string"),
        ])
        let tree = m.formTree

        // The segmented control replaces A and B in the flat list; C stays flat.
        #expect(tree.count == 2)
        guard case .segmented(let id, let tabs, let groups) = tree[0] else {
            Issue.record("expected a segmented node first")
            return
        }
        #expect(id == FormPath.root.appending(key: "View"))
        #expect(tabs == ["Basic", "Advanced"])

        guard case .field(let a)? = groups["Basic"]?.first else {
            Issue.record("expected field A under Basic")
            return
        }
        #expect(a.path == FormPath.root.appending(key: "A"))

        guard case .field(let b)? = groups["Advanced"]?.first else {
            Issue.record("expected field B under Advanced")
            return
        }
        #expect(b.control == .toggle(inverted: false))

        guard case .field(let c) = tree[1] else {
            Issue.record("expected C to remain flat")
            return
        }
        #expect(c.path == FormPath.root.appending(key: "C"))
    }

    @Test func segmented_tab_order_follows_range_list_titles() throws {
        let m = try model([
            PlistFixture.key(
                name: "View", type: "string",
                rangeListTitles: ["Second", "First"],
                extra: ["pfm_segments": ["First": ["A"], "Second": ["B"]]],
            ),
            PlistFixture.key(name: "A", type: "string"),
            PlistFixture.key(name: "B", type: "string"),
        ])
        guard case .segmented(_, let tabs, _) = m.formTree[0] else {
            Issue.record("expected a segmented node")
            return
        }
        // Order comes from pfm_range_list_titles, not the (unordered) segments dict.
        #expect(tabs == ["Second", "First"])
    }
}
