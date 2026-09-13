//
//  Control.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/11/26.
//

import Foundation

/// The leaf widget a field renders as. Structural kinds (dictionary, array,
/// segmented) are *not* here — the form tree expresses those as node kinds. So a
/// `Field.control` is always a real, renderable leaf control.
public enum Control: Equatable {
    case textField(secure: Bool)
    case toggle(inverted: Bool)
    case radioTwoState(titles: [String])
    case popUp(options: [Option], allowsCustom: Bool)
    case slider(min: Double, max: Double)
    case stepper(min: Double?, max: Double?)
    case datePicker(style: String?)
    case fileDrop(types: [String])
    case unsupported

    /// One choice in a pop-up: the stored value plus its display title.
    public struct Option: Identifiable, Equatable {
        public let value: PFMValue
        public let title: String
        public var id: PFMValue { value }
    }
}

/// Resolve the leaf control for a subkey. Enumerated (`range_list`) wins before the
/// type default. Container types return `.unsupported` — they're structural and the
/// form tree turns them into group/array nodes, so this is never asked of them in
/// practice. Never traps.
func control(for key: ManifestSubkey) -> Control {
    if let values = key.rangeList {
        let titles = key.rangeListTitles ?? values.map(\.displayString)
        let options = zip(values, titles).map { Control.Option(value: $0.0, title: $0.1) }
        return .popUp(options: options, allowsCustom: key.rangeListAllowsCustom ?? false)
    }

    switch key.typeInput ?? key.type {
        case .boolean:
            if let titles = key.rangeListTitles, titles.count == 2 {
                return .radioTwoState(titles: titles)
            }
            return .toggle(inverted: key.valueInverted ?? false)

        case .string, .url:
            return .textField(secure: key.sensitive ?? false)

        case .integer, .real:
            let lo = key.rangeMin?.asDouble
            let hi = key.rangeMax?.asDouble
            if key.view == "slider", let lo, let hi {
                return .slider(min: lo, max: hi)
            }
            if lo != nil || hi != nil {
                return .stepper(min: lo, max: hi)
            }
            return .textField(secure: false)

        case .date:
            return .datePicker(style: key.dateStyle)

        case .data:
            return .fileDrop(types: key.allowedFileTypes ?? [])

        case .array, .dictionary:
            return .unsupported  // structural — the form tree handles these
    }
}
