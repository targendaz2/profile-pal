//
//  ManifestFormView.swift
//  ProfilePal
//
//  The whole render layer: one recursive view over ProfileManifestKit's headless
//  form tree. The framework prepares each Field (control + labels + bindings); the
//  app owns all layout and styling here.
//

import ProfileManifestKit
import SwiftUI

struct ManifestFormView: View {
    @State var model: FormModel

    var body: some View {
        Form { ForEach(model.formTree) { NodeView(node: $0, model: model) } }
            .formStyle(.grouped)
    }
}

private struct NodeView: View {
    let node: FormNode
    let model: FormModel

    var body: some View {
        switch node {
            case .field(let field):
                LabeledContent {
                    control(field)
                } label: {
                    HStack(spacing: 8) {
                        Toggle("", isOn: field.isSet).labelsHidden()
                        VStack(alignment: .leading, spacing: 1) {
                            Text(field.title)
                            if let help = field.help {
                                Text(help).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

            case .group(_, let title, let isSet, let children):
                Section {
                    ForEach(children) { NodeView(node: $0, model: model) }
                } header: {
                    HStack {
                        Toggle("", isOn: isSet).labelsHidden()
                        Text(title ?? "")
                    }
                }

            case .array(let id, let title, let rows):
                Section(title ?? "") {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        NodeView(node: row, model: model)
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    model.removeArrayElement(at: id, index: index)
                                }
                            }
                    }
                    Button("Add") { model.addArrayElement(at: id) }
                }

            case .segmented(let id, let tabs, let groups):
                let selection = model.stringBinding(at: id)
                Picker("", selection: selection) {
                    ForEach(tabs, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                let current =
                    selection.wrappedValue.isEmpty ? (tabs.first ?? "") : selection.wrappedValue
                ForEach(groups[current] ?? []) { NodeView(node: $0, model: model) }

            @unknown default:
                EmptyView()
        }
    }

    @ViewBuilder func control(_ field: Field) -> some View {
        switch field.control {
            case .textField(let secure):
                if secure {
                    SecureField("", text: field.text)
                } else {
                    TextField("", text: field.text)
                }
            case .toggle:
                Toggle("", isOn: field.bool).labelsHidden()
            case .radioTwoState(let titles):
                Picker("", selection: field.bool) {
                    Text(titles.first ?? "").tag(true)
                    Text(titles.last ?? "").tag(false)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            case .popUp(let options, _):
                Picker("", selection: field.selection) {
                    ForEach(options) { Text($0.title).tag(Optional($0.value)) }
                }
                .labelsHidden()
            case .slider(let lo, let hi):
                Slider(value: field.number, in: lo...hi)
            case .stepper:
                Stepper("", value: field.number).labelsHidden()
            case .datePicker:
                DatePicker("", selection: field.date).labelsHidden()
            case .fileDrop:
                Text("Drop a file…").foregroundStyle(.secondary)
            case .unsupported:
                EmptyView()
            @unknown default:
                EmptyView()
        }
    }
}

#Preview {
    ManifestFormView(model: FormModel(manifest: sampleManifest()))
        .frame(width: 420, height: 460)
}

/// A small hand-built manifest covering several control types, for the preview.
private func sampleManifest() -> PayloadManifest {
    // Per-subkey typed locals: one giant [String: Any] literal trips the preview
    // type-checker ("unable to type-check this expression in reasonable time").
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
