//
//  FormNode.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/12/26.
//

import Foundation

/// One editable leaf the app renders. Carries everything the app needs to draw
/// and bind the control; the app reads `subkey` for labels/help text.
public struct Field: Identifiable, Equatable {
    public var path: FormPath
    public var subkey: ManifestSubkey
    public var control: Control
    public var isRequired: Bool
    public var errors: [String]

    public var id: FormPath { path }
    public var title: String { subkey.title ?? subkey.name ?? "" }
}

/// The render tree the app walks. Structure mirrors the manifest: scalars are
/// `field`s, dictionaries are `group`s, arrays are repeatable `array` rows. The
/// framework decides structure and control; the app decides how each node looks.
public enum FormNode: Identifiable, Equatable {
    case field(Field)
    case group(id: FormPath, title: String?, children: [FormNode])
    case array(id: FormPath, title: String?, template: ManifestSubkey, rows: [FormNode])
    /// A tab selector: `tabs` in display order, `groups` maps each tab to the
    /// member nodes shown while it's selected. The selection is a string stored at
    /// `id` (bind it there); the members are pulled out of the flat sibling list.
    case segmented(id: FormPath, tabs: [String], groups: [String: [FormNode]])

    public var id: FormPath {
        switch self {
            case .field(let field):
                return field.path
            case .group(let id, _, _):
                return id
            case .array(let id, _, _, _):
                return id
            case .segmented(let id, _, _):
                return id
        }
    }
}

extension FormModel {
    /// The visible render tree for the whole manifest, rebuilt from current state.
    /// Reading this inside a SwiftUI view establishes observation, so edits that
    /// change visibility re-render automatically.
    public var formTree: [FormNode] {
        nodes(for: manifest.subkeys, at: .root)
    }

    private func nodes(for subkeys: [ManifestSubkey], at base: FormPath) -> [FormNode] {
        // Names claimed by a segmented control render inside it, not in the flat list.
        let consumed = segmentMembers(of: subkeys)
        return subkeys.compactMap { subkey -> FormNode? in
            if let name = subkey.name, consumed.contains(name) { return nil }
            if subkey.segments != nil {
                return segmentedNode(for: subkey, siblings: subkeys, at: base)
            }
            return node(for: subkey, at: base)
        }
    }

    /// Every sibling name referenced by any segmented control at this level.
    private func segmentMembers(of subkeys: [ManifestSubkey]) -> Set<String> {
        var names: Set<String> = []
        for subkey in subkeys {
            guard let segments = subkey.segments else { continue }
            for members in segments.values { names.formUnion(members) }
        }
        return names
    }

    /// Build a segmented node: tabs from `pfm_range_list_titles` (order matters),
    /// each tab's members resolved against the sibling list into child nodes. A
    /// referenced member that's missing or hidden is simply dropped.
    private func segmentedNode(
        for key: ManifestSubkey,
        siblings: [ManifestSubkey],
        at base: FormPath,
    ) -> FormNode? {
        guard isVisible(key), let name = key.name, let segments = key.segments else { return nil }
        let path = base.appending(key: name)
        let tabs = key.rangeListTitles ?? Array(segments.keys)
        let byName = Dictionary(
            siblings.compactMap { sibling in sibling.name.map { ($0, sibling) } },
            uniquingKeysWith: { first, _ in first },
        )
        var groups: [String: [FormNode]] = [:]
        for tab in tabs {
            groups[tab] = (segments[tab] ?? []).compactMap { member in
                byName[member].flatMap { node(for: $0, at: base) }
            }
        }
        return .segmented(id: path, tabs: tabs, groups: groups)
    }

    private func node(for subkey: ManifestSubkey, at base: FormPath) -> FormNode? {
        guard isVisible(subkey) else { return nil }
        guard let name = subkey.name else { return nil }  // named children only; array rows below
        let path = base.appending(key: name)

        switch control(for: subkey) {
            case .dictionary(let children):
                return .group(
                    id: path,
                    title: subkey.title,
                    children: nodes(for: children, at: path),
                )
            case .arrayTable(let template):
                return .array(
                    id: path,
                    title: subkey.title,
                    template: template,
                    rows: rows(of: template, at: path),
                )
            case let control:
                return .field(
                    Field(
                        path: path,
                        subkey: subkey,
                        control: control,
                        isRequired: isRequired(subkey),
                        errors: errors[path] ?? [],
                    ))
        }
    }

    /// Build one node per existing element of an array value. Elements are
    /// positional (the template subkey has no name), so they're addressed by index.
    private func rows(of template: ManifestSubkey, at base: FormPath) -> [FormNode] {
        guard case .array(let elements)? = value(at: base) else { return [] }
        return elements.indices.map { index in
            let path = base.appending(index: index)
            switch control(for: template) {
                case .dictionary(let children):
                    return .group(id: path, title: nil, children: nodes(for: children, at: path))
                case let control:
                    return .field(
                        Field(
                            path: path,
                            subkey: template,
                            control: control,
                            isRequired: false,
                            errors: errors[path] ?? [],
                        ))
            }
        }
    }
}
