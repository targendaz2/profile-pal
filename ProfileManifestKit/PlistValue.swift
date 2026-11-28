//
//  PlistValue.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 10/26/26.
//

import Foundation

/// A property list value whose type isn't known until it's decoded.
///
/// Used where a manifest or payload key can hold any plist type, such as a field's default value.
public enum PlistValue: Codable, Sendable, Hashable {
    case string(String)
    case bool(Bool)
    case int(Int)
    /// An integer above `Int.max`, which plists allow up to `UInt64.max`.
    case uint(UInt64)
    case double(Double)
    case data(Data)
    case date(Date)
    case array([PlistValue])
    case dictionary([String: PlistValue])

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Each failed attempt builds and discards a DecodingError, so a dictionary costs eight
        // before it matches. Fine at manifest sizes; check the container's shape first if
        // profiling ever shows it.
        if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Int.self) {
            self = .int(v)
        } else if let v = try? container.decode(UInt64.self) {
            // Too big for Int: keep it exact rather than let Double round it.
            self = .uint(v)
        } else if let v = try? container.decode(Double.self) {
            self = .double(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else if let v = try? container.decode(Data.self) {
            self = .data(v)
        } else if let v = try? container.decode(Date.self) {
            self = .date(v)
        } else if let v = try? container.decode([PlistValue].self) {
            self = .array(v)
        } else if let v = try? container.decode([String: PlistValue].self) {
            self = .dictionary(v)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unsupported plist value", )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
            case .string(let v): try container.encode(v)
            case .bool(let v): try container.encode(v)
            case .int(let v): try container.encode(v)
            case .uint(let v): try container.encode(v)
            case .double(let v): try container.encode(v)
            case .data(let v): try container.encode(v)
            case .date(let v): try container.encode(v)
            case .array(let v): try container.encode(v)
            case .dictionary(let v): try container.encode(v)
        }
    }
}
