//
//  Control.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/11/26.
//

import Foundation

/// How a visible subkey renders. `control(for:)` decides the case; the step-7
/// renderer is a plain switch over it.
public enum Control: Equatable {
    case textField(secure: Bool)
    case toggle(inverted: Bool)
    case radioTwoState(titles: [String])
    case popUp(values: [PFMValue], titles: [String], allowsCustom: Bool)
    case slider(min: Double, max: Double)
    case stepper(min: Double?, max: Double?)
    case datePicker(style: String?)
    case fileDrop(types: [String])
    case arrayTable(element: ManifestSubkey)
    case dictionary(subkeys: [ManifestSubkey])
    case segmented(tabs: [String], segments: [String: [String]])
    case unsupported
}

/// Resolve how a subkey should render. Pure function: subkey in, `Control` out.
///
/// Order is load-bearing: enumerated/explicit-hint controls must win before
/// type-based defaults, or an enumerated string would render as a plain text box.
/// Never traps — an unrecognized shape degrades to `.unsupported`.
public func control(for key: ManifestSubkey) -> Control {
    if let segments = key.segments {
        return .segmented(tabs: key.rangeListTitles ?? Array(segments.keys), segments: segments)
    }

    if let values = key.rangeList {
        let titles = key.rangeListTitles ?? values.map(\.displayString)
        return .popUp(
            values: values,
            titles: titles,
            allowsCustom: key.rangeListAllowsCustom ?? false,
        )
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

        case .array:
            return .arrayTable(element: key.subkeys?.first ?? key)

        case .dictionary:
            return .dictionary(subkeys: key.subkeys ?? [])
    }
}
