//
//  ManifestFormView.swift
//  ProfilePal
//
//  Sample render loop over ProfileManifestKit's headless API. The framework
//  decides structure (FormNode) and control type (Control); the app owns every
//  view and all styling below.
//

import ProfileManifestKit
import SwiftUI

/// Renders a whole manifest by walking the framework's `formTree`.
struct ManifestFormView: View {
    @State var model: FormModel

    var body: some View {
        Form {
            ForEach(model.formTree) { node in
                NodeView(node: node, model: model)
            }
        }
        .formStyle(.grouped)
    }
}

/// One node of the tree. Groups and arrays recurse by rendering child `NodeView`s.
private struct NodeView: View {
    let node: FormNode
    let model: FormModel

    var body: some View {
        switch node {
            case .field(let field):
                FieldView(field: field, model: model)
            case .group(_, let title, let children):
                Section(title ?? "") {
                    ForEach(children) { NodeView(node: $0, model: model) }
                }
            case .array(_, let title, _, let rows):
                Section(title ?? "") {
                    ForEach(rows) { NodeView(node: $0, model: model) }
                }
            case .segmented(let id, let tabs, let groups):
                SegmentedNodeView(id: id, tabs: tabs, groups: groups, model: model)
            @unknown default:
                EmptyView()
        }
    }
}

/// A tab selector whose selection (a string stored at `id`) chooses which member
/// nodes to show. Selection binding and layout are entirely the app's concern.
private struct SegmentedNodeView: View {
    let id: FormPath
    let tabs: [String]
    let groups: [String: [FormNode]]
    let model: FormModel

    var body: some View {
        let selection = model.stringBinding(at: id)
        let current = selection.wrappedValue.isEmpty ? (tabs.first ?? "") : selection.wrappedValue
        Picker("", selection: selection) {
            ForEach(tabs, id: \.self) { Text($0).tag($0) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        ForEach(groups[current] ?? []) { NodeView(node: $0, model: model) }
    }
}

/// One editable leaf. A plain switch over the framework's `Control` — this is the
/// entire "how it looks" layer, and it lives in the app.
private struct FieldView: View {
    let field: Field
    let model: FormModel

    var body: some View {
        switch field.control {
            case .textField(let secure):
                LabeledContent(field.title) {
                    if secure {
                        SecureField("", text: model.stringBinding(at: field.path))
                    } else {
                        TextField("", text: model.stringBinding(at: field.path))
                    }
                }

            case .toggle(let inverted):
                Toggle(field.title, isOn: model.boolBinding(at: field.path, inverted: inverted))

            case .radioTwoState(let titles):
                Picker(field.title, selection: model.boolBinding(at: field.path)) {
                    Text(titles.first ?? "On").tag(true)
                    Text(titles.last ?? "Off").tag(false)
                }
                .pickerStyle(.radioGroup)

            case .popUp(let values, let titles, _):
                Picker(field.title, selection: model.binding(at: field.path)) {
                    ForEach(Array(values.enumerated()), id: \.element) { index, value in
                        Text(index < titles.count ? titles[index] : value.displayString)
                            .tag(Optional(value))
                    }
                }

            case .slider(let min, let max):
                LabeledContent(field.title) {
                    Slider(value: model.doubleBinding(at: field.path), in: min...max)
                }

            case .stepper(_, _):
                Stepper(field.title, value: model.doubleBinding(at: field.path))

            case .datePicker:
                DatePicker(field.title, selection: dateBinding(field.path))

            case .fileDrop:
                LabeledContent(field.title) { Text("(unsupported in sample)") }

            // Containers/segmented become nodes, not leaves, so they never reach a
            // FieldView; the switch stays exhaustive so an unexpected manifest can't crash.
            case .arrayTable, .dictionary, .segmented, .unsupported:
                EmptyView()

            @unknown default:
                EmptyView()
        }
    }

    /// A typed Date binding derived from the framework's generic value binding —
    /// exactly the kind of adaptation the app owns.
    private func dateBinding(_ path: FormPath) -> Binding<Date> {
        Binding(
            get: {
                if case .date(let date)? = model.value(at: path) { return date }
                return .now
            },
            set: { model.setValue(.date($0), at: path) },
        )
    }
}

#Preview {
    ManifestFormView(model: FormModel(manifest: sampleManifest()))
        .frame(width: 420, height: 420)
}

/// A small hand-built manifest covering several control types, for the preview.
private func sampleManifest() -> PayloadManifest {
    // Split into per-subkey typed locals: one giant [String: Any] literal trips the
    // preview type-checker ("unable to type-check this expression in reasonable time").
    let serverURL: [String: Any] = [
        "pfm_name": "ServerURL", "pfm_type": "string", "pfm_title": "Server URL",
    ]
    let enabled: [String: Any] = [
        "pfm_name": "Enabled", "pfm_type": "boolean", "pfm_title": "Enabled",
    ]
    let mode: [String: Any] = [
        "pfm_name": "Mode", "pfm_type": "string", "pfm_title": "Mode",
        "pfm_range_list": ["auto", "manual"],
        "pfm_range_list_titles": ["Automatic", "Manual"],
    ]
    let level: [String: Any] = [
        "pfm_name": "Level", "pfm_type": "integer", "pfm_title": "Level",
        "pfm_view": "slider", "pfm_range_min": 0, "pfm_range_max": 10,
    ]
    let advanced: [String: Any] = [
        "pfm_name": "Advanced", "pfm_type": "dictionary", "pfm_title": "Advanced",
        "pfm_subkeys": [["pfm_name": "Timeout", "pfm_type": "integer", "pfm_title": "Timeout"]],
    ]
    let tags: [String: Any] = [
        "pfm_name": "Tags", "pfm_type": "array", "pfm_title": "Tags",
        "pfm_subkeys": [["pfm_type": "string"]],
    ]
    // A segmented control groups four of the fields above under two tabs.
    let section: [String: Any] = [
        "pfm_name": "Section", "pfm_type": "string", "pfm_title": "Section",
        "pfm_default": "Connection",
        "pfm_range_list_titles": ["Connection", "Options"],
        "pfm_segments": ["Connection": ["ServerURL", "Enabled"], "Options": ["Mode", "Level"]],
    ]
    let subkeys: [[String: Any]] = [section, serverURL, enabled, mode, level, advanced, tags]
    let dict: [String: Any] = [
        "pfm_domain": "com.example.sample",
        "pfm_title": "Sample",
        "pfm_subkeys": subkeys,
    ]
    let data = try! PropertyListSerialization.data(
        fromPropertyList: dict,
        format: .xml,
        options: 0,
    )
    return try! PropertyListDecoder().decode(PayloadManifest.self, from: data)
}
