//
//  Manifest+Typing.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 11/28/26.
//

import Foundation

extension Manifest {
    /// Loads every field's default and range list as the field's type, recording each issue.
    ///
    /// Placeholders are only displayed, so they keep whatever type they decoded as.
    mutating func typeValues() {
        var issues: [ManifestIssue] = []

        for index in subkeys.indices {
            subkeys[index].typeValues(under: [], issues: &issues)
        }

        self.issues += issues
    }
}

extension ManifestField {
    /// Loads this field's values, and its subkeys' values, as their fields' types.
    mutating func typeValues(under parentPath: [String], issues: inout [ManifestIssue]) {
        let path = parentPath + [name ?? "[]"]
        let field = self

        if let value = defaultValue {
            let key = CodingKeys.defaultValue.rawValue
            defaultValue = value.converted(to: field, at: path, key: key, issues: &issues)
        }

        if let values = rangeList {
            let key = CodingKeys.rangeList.rawValue
            let titles = rangeListTitles
            var loadedValues: [PlistValue] = []
            var loadedTitles: [String] = []

            for (index, value) in values.enumerated() {
                guard let loaded = value.converted(to: field, at: path, key: key, issues: &issues)
                else {
                    continue
                }

                loadedValues.append(loaded)

                if let titles, index < titles.count {
                    loadedTitles.append(titles[index])
                }
            }

            rangeList = loadedValues

            // Keep a value's title only while titles and values still line up one to one.
            if let titles, titles.count == values.count {
                rangeListTitles = loadedTitles
            }
        }

        // Mutate through the optional, so each nested field changes in place without copying.
        for index in subkeys?.indices ?? 0..<0 {
            subkeys?[index].typeValues(under: path, issues: &issues)
        }
    }
}
