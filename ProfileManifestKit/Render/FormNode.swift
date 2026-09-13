//
//  FormNode.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/12/26.
//

import Foundation
import SwiftUI

/// One editable leaf, fully prepared: labels, metadata, and ready-to-bind values.
/// The app never touches the manifest model — it reads this and picks a widget by
/// `control`. Not `Equatable` (it carries `Binding`s); identify it by `id`.
public struct Field: Identifiable {
    public let id: FormPath
    public let control: Control
    public let title: String
    public let help: String?
    public let note: String?
    public let isRequired: Bool

    public var isSet: Binding<Bool>  // present-in-payload vs absent
    public var text: Binding<String>
    public var bool: Binding<Bool>
    public var number: Binding<Double>
    public var date: Binding<Date>
    public var selection: Binding<PFMValue?>
}

/// The render tree the app walks. Structure mirrors the manifest: scalars are
/// `field`s, dictionaries `group`s, arrays repeatable `array` rows, and a
/// `segmented` control groups sibling members under tabs.
public enum FormNode: Identifiable {
    case field(Field)
    case group(id: FormPath, title: String?, isSet: Binding<Bool>, children: [FormNode])
    case array(id: FormPath, title: String?, rows: [FormNode])
    case segmented(
        id: FormPath,
        selection: Binding<String>,
        tabs: [String],
        groups: [String: [FormNode]],
    )

    public var id: FormPath {
        switch self {
            case .field(let field): return field.id
            case .group(let id, _, _, _): return id
            case .array(let id, _, _): return id
            case .segmented(let id, _, _, _): return id
        }
    }
}

extension FormModel {
    /// The visible render tree for the whole manifest, rebuilt from current state.
    /// Reading it in a SwiftUI view establishes observation, so edits that change
    /// visibility re-render automatically.
    public var formTree: [FormNode] {
        nodes(for: manifest.subkeys, at: .root)
    }

    private func nodes(for subkeys: [PFMSubkey], at base: FormPath) -> [FormNode] {
        let consumed = segmentMembers(of: subkeys)
        return subkeys.compactMap { subkey -> FormNode? in
            guard let name = subkey.name else { return nil }
            if consumed.contains(name) { return nil }  // rendered under a segmented control
            if subkey.segments != nil {
                return segmentedNode(for: subkey, siblings: subkeys, at: base)
            }
            return node(for: subkey, at: base)
        }
    }

    /// Build one non-segmented node (field / group / array).
    private func node(for subkey: PFMSubkey, at base: FormPath) -> FormNode? {
        guard isVisible(subkey), let name = subkey.name else { return nil }
        let path = base.appending(key: name)
        switch subkey.type {
            case .dictionary:
                return .group(
                    id: path,
                    title: subkey.title,
                    isSet: isSetBinding(for: subkey, at: path),
                    children: nodes(for: subkey.subkeys ?? [], at: path),
                )
            case .array:
                return .array(
                    id: path,
                    title: subkey.title,
                    rows: rows(of: subkey.subkeys?.first, at: path),
                )
            default:
                return .field(field(for: subkey, at: path))
        }
    }

    private func field(for subkey: PFMSubkey, at path: FormPath) -> Field {
        Field(
            id: path,
            control: control(for: subkey),
            title: subkey.title ?? subkey.name ?? "",
            help: subkey.description,
            note: subkey.note,
            isRequired: isRequired(subkey),
            isSet: isSetBinding(for: subkey, at: path),
            text: stringBinding(at: path),
            bool: boolBinding(at: path, inverted: subkey.valueInverted ?? false),
            number: doubleBinding(at: path),
            date: dateBinding(at: path),
            selection: valueBinding(at: path),
        )
    }

    /// One node per existing array element (positional → addressed by index).
    private func rows(of template: PFMSubkey?, at base: FormPath) -> [FormNode] {
        guard case .array(let elements)? = value(at: base), let template else { return [] }
        return elements.indices.map { index in
            let path = base.appending(index: index)
            switch template.type {
                case .dictionary:
                    return .group(
                        id: path,
                        title: nil,
                        isSet: .constant(true),
                        children: nodes(for: template.subkeys ?? [], at: path),
                    )
                default:
                    return .field(field(for: template, at: path))
            }
        }
    }

    private func segmentMembers(of subkeys: [PFMSubkey]) -> Set<String> {
        var names: Set<String> = []
        for subkey in subkeys {
            guard let segments = subkey.segments else { continue }
            for members in segments.values { names.formUnion(members) }
        }
        return names
    }

    private func segmentedNode(
        for key: PFMSubkey,
        siblings: [PFMSubkey],
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
        return .segmented(
            id: path,
            selection: stringBinding(at: path),
            tabs: tabs,
            groups: groups,
        )
    }
}
