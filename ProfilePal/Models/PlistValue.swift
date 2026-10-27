//
//  PlistValue.swift
//  ProfilePal
//
//  Created by David Rosenberg on 10/26/26.
//

import Foundation

/// A property list value whose type isn't known until it's decoded.
///
/// Used where a manifest or payload key can hold any plist type, such as a field's default value.
enum PlistValue: Codable, Sendable, Equatable {
    case string(String)
    case bool(Bool)
    case int(Int)
    case double(Double)
    case data(Data)
    case date(Date)
    case array([PlistValue])
    case dictionary([String: PlistValue])

    /// The wrapped value as an untyped Swift value, with nested arrays and dictionaries unwrapped.
    var value: Any {
        switch self {
            case .string(let v): v
            case .bool(let v): v
            case .int(let v): v
            case .double(let v): v
            case .data(let v): v
            case .date(let v): v
            case .array(let v): v.map(\.value)
            case .dictionary(let v): v.mapValues(\.value)
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Int.self) {
            self = .int(v)
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

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
            case .string(let v): try container.encode(v)
            case .bool(let v): try container.encode(v)
            case .int(let v): try container.encode(v)
            case .double(let v): try container.encode(v)
            case .data(let v): try container.encode(v)
            case .date(let v): try container.encode(v)
            case .array(let v): try container.encode(v)
            case .dictionary(let v): try container.encode(v)
        }
    }
}
