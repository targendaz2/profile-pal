//
//  ControlTests.swift
//  ProfileManifestKitTests
//
//  Created by David Rosenberg on 9/11/26.
//

import Foundation
import Testing

@testable import ProfileManifestKit

struct ControlTests {

    /// Build a `key(...)` fixture and decode it to a `ManifestSubkey` through the
    /// real pipeline. Flat (rather than `subkey(PlistFixture.key(...))`) so call
    /// sites stay one-line and swift-format doesn't churn on nested calls.
    private func subkey(
        name: String? = nil,
        type: String,
        rangeList: [Any]? = nil,
        rangeListTitles: [String]? = nil,
        subkeys: [[String: Any]]? = nil,
        extra: [String: Any] = [:],
    ) throws -> ManifestSubkey {
        let fixture = PlistFixture.key(
            name: name,
            type: type,
            rangeList: rangeList,
            rangeListTitles: rangeListTitles,
            subkeys: subkeys,
            extra: extra,
        )
        return try PropertyListDecoder().decode(
            ManifestSubkey.self,
            from: PlistFixture.xmlData(fixture),
        )
    }

    // MARK: Type defaults (no hints)

    @Test func string_defaults_to_text_field() throws {
        #expect(control(for: try subkey(type: "string")) == .textField(secure: false))
    }

    @Test func url_defaults_to_text_field() throws {
        #expect(control(for: try subkey(type: "url")) == .textField(secure: false))
    }

    @Test func integer_without_bounds_is_text_field() throws {
        #expect(control(for: try subkey(type: "integer")) == .textField(secure: false))
    }

    @Test func real_without_bounds_is_text_field() throws {
        #expect(control(for: try subkey(type: "real")) == .textField(secure: false))
    }

    @Test func boolean_without_titles_is_toggle() throws {
        #expect(control(for: try subkey(type: "boolean")) == .toggle(inverted: false))
    }

    @Test func date_defaults_to_date_picker() throws {
        #expect(control(for: try subkey(type: "date")) == .datePicker(style: nil))
    }

    @Test func data_defaults_to_file_drop() throws {
        #expect(control(for: try subkey(type: "data")) == .fileDrop(types: []))
    }

    @Test func container_types_are_unsupported_leaves() throws {
        // Dictionaries and arrays are structural (the form tree turns them into
        // group/array nodes), so they are not leaf controls.
        #expect(control(for: try subkey(type: "array")) == .unsupported)
        #expect(control(for: try subkey(type: "dictionary")) == .unsupported)
    }

    // MARK: Enumerated / hint controls win before type defaults

    @Test func range_list_on_string_is_pop_up_not_text_field() throws {
        let key = try subkey(type: "string", rangeList: ["a", "b"])
        #expect(
            control(for: key)
                == .popUp(
                    options: [
                        .init(value: .string("a"), title: "a"),
                        .init(value: .string("b"), title: "b"),
                    ],
                    allowsCustom: false,
                ))
    }

    @Test func range_list_titles_used_when_present() throws {
        let key = try subkey(type: "string", rangeList: ["a", "b"], rangeListTitles: ["A", "B"])
        #expect(
            control(for: key)
                == .popUp(
                    options: [
                        .init(value: .string("a"), title: "A"),
                        .init(value: .string("b"), title: "B"),
                    ],
                    allowsCustom: false,
                ))
    }

    @Test func range_list_allows_custom_surfaces() throws {
        let extra: [String: Any] = ["pfm_range_list_allow_custom_value": true]
        let key = try subkey(type: "string", rangeList: ["a"], extra: extra)
        #expect(
            control(for: key)
                == .popUp(options: [.init(value: .string("a"), title: "a")], allowsCustom: true))
    }

    // MARK: Boolean variants

    @Test func boolean_with_two_titles_is_radio() throws {
        let key = try subkey(type: "boolean", rangeListTitles: ["On", "Off"])
        #expect(control(for: key) == .radioTwoState(titles: ["On", "Off"]))
    }

    @Test func value_inverted_surfaces_in_toggle() throws {
        let key = try subkey(type: "boolean", extra: ["pfm_value_inverted": true])
        #expect(control(for: key) == .toggle(inverted: true))
    }

    // MARK: Numeric variants

    @Test func integer_slider_view_with_both_bounds_is_slider() throws {
        let key = try subkey(
            type: "integer",
            extra: ["pfm_view": "slider", "pfm_range_min": 0, "pfm_range_max": 10],
        )
        #expect(control(for: key) == .slider(min: 0, max: 10))
    }

    @Test func integer_with_one_bound_is_stepper() throws {
        let key = try subkey(type: "integer", extra: ["pfm_range_max": 10])
        #expect(control(for: key) == .stepper(min: nil, max: 10))
    }

    // MARK: Overrides

    @Test func type_input_overrides_stored_type() throws {
        // Stored as string, edited as boolean → toggle, not a text field.
        let key = try subkey(type: "string", extra: ["pfm_type_input": "boolean"])
        #expect(control(for: key) == .toggle(inverted: false))
    }

    @Test func sensitive_string_is_secure_text_field() throws {
        let key = try subkey(type: "string", extra: ["pfm_sensitive": true])
        #expect(control(for: key) == .textField(secure: true))
    }

    @Test func date_style_surfaces() throws {
        let key = try subkey(type: "date", extra: ["pfm_date_style": "time"])
        #expect(control(for: key) == .datePicker(style: "time"))
    }

    @Test func data_allowed_types_surface() throws {
        let key = try subkey(type: "data", extra: ["pfm_allowed_file_types": ["public.png"]])
        #expect(control(for: key) == .fileDrop(types: ["public.png"]))
    }
}
