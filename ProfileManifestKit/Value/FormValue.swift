//
//  FormValue.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation

public enum FormValue: Sendable, Hashable {
    case string(String)
    case integer(Int)
    case real(Double)
    case boolean(Bool)
    case date(Date)
    case data(Data)
    indirect case array([FormValue])
    indirect case dictionary([String: FormValue])
}

// MARK: - Decodable
extension FormValue: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Order matters: Bool before Int (a plist <true/> will also decode as Int 1)
        if let b = try? container.decode(Bool.self) {
            self = .boolean(b)
        } else if let i = try? container.decode(Int.self) {
            self = .integer(i)
        } else if let d = try? container.decode(Double.self) {
            self = .real(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let date = try? container.decode(Date.self) {
            self = .date(date)
        } else if let data = try? container.decode(Data.self) {
            self = .data(data)
        } else if let arr = try? container.decode([FormValue].self) {
            self = .array(arr)
        } else if let dict = try? container.decode([String: FormValue].self) {
            self = .dictionary(dict)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Value is not a recognized property-list type",
            )
        }
    }
}

// MARK: - Encodable
extension FormValue: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()

        switch self {
            case .string(let v):
                try c.encode(v)
            case .integer(let v):
                try c.encode(v)
            case .real(let v):
                try c.encode(v)
            case .boolean(let v):
                try c.encode(v)
            case .date(let v):
                try c.encode(v)
            case .data(let v):
                try c.encode(v)
            case .array(let v):
                try c.encode(v)
            case .dictionary(let v):
                try c.encode(v)
        }
    }
}

// MARK: - Convenience Accessors
extension FormValue {
    /// This value as a `Double` when it is numeric (`integer` or `real`), otherwise `nil`.
    public var doubleValue: Double? {
        switch self {
            case .integer(let i):
                return Double(i)
            case .real(let r):
                return r
            default:
                return nil
        }
    }

    public var displayString: String {
        switch self {
            case .string(let s):
                return s
            case .integer(let i):
                return String(i)
            case .real(let r):
                return String(r)
            case .boolean(let b):
                return b ? "true" : "false"
            case .date(let date):
                return date.formatted()
            case .data:
                return "<data>"
            case .array:
                return ""
            case .dictionary:
                return ""
        }
    }

    /// Coerce a decoded value to match the subkey's declared pfm_type.
    func normalized(to type: PFMType) -> FormValue {
        switch (type, self) {
            case (.real, .integer(let i)):
                return .real(Double(i))
            case (.integer, .real(let r)):
                // Int(r) traps on NaN/infinite/out-of-range input from an untrusted manifest;
                // fall back to leaving it as .real rather than crashing.
                guard let i = Int(exactly: r.rounded(.towardZero)) else { return self }
                return .integer(i)
            default:
                return self
        }
    }

    /// Build the initial value for a subkey from its pfm_default, coerced to
    /// the declared pfm_type. Returns nil when the subkey has no default —
    /// an unset field is absent from the tree, not present-but-empty.
    static func seed(for key: PFMSubkey) -> FormValue? {
        guard let def = key.defaultValue else { return nil }
        return def.normalized(to: key.type)
    }
}

extension FormValue {
    /// Convert back to a plist-serializable `Any`, for use with PlistFixture
    /// (which builds value trees from raw Foundation types).
    var plistValue: Any {
        switch self {
            case .string(let s):
                return s
            case .integer(let i):
                return i
            case .real(let r):
                return r
            case .boolean(let b):
                return b
            case .date(let date):
                return date
            case .data(let data):
                return data
            case .array(let arr):
                return arr.map(\.plistValue)
            case .dictionary(let dict):
                return dict.mapValues(\.plistValue)
        }
    }
}
