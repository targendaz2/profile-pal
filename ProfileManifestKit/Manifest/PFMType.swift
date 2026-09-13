//
//  PFMType.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation

public enum PFMType: String, Sendable, Decodable {
    case string, integer, real, boolean, date, data, array, dictionary, url

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self).lowercased()
        guard let value = PFMType(rawValue: raw) else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Unknown pfm_type: \(raw)",
            )
        }
        self = value
    }
}
