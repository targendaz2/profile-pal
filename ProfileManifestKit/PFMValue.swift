//
//  PFMValue.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation

enum PFMValue: Sendable, Hashable {
    case string(String)
    case integer(Int)
    case real(Double)
    case boolean(Bool)
    case date(Date)
    case data(Data)
    indirect case array([PFMValue])
    indirect case dictionary([String: PFMValue])
}

// MARK: - Decodable
extension PFMValue: Decodable {
    init(from decoder: any Decoder) throws {
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
        } else if let arr = try? container.decode([PFMValue].self) {
            self = .array(arr)
        } else if let dict = try? container.decode([String: PFMValue].self) {
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
extension PFMValue: Encodable {
    func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()

        switch self {
            case .string(let v): try c.encode(v)
            case .integer(let v): try c.encode(v)
            case .real(let v): try c.encode(v)
            case .boolean(let v): try c.encode(v)
            case .date(let v): try c.encode(v)
            case .data(let v): try c.encode(v)
            case .array(let v): try c.encode(v)
            case .dictionary(let v): try c.encode(v)
        }
    }
}

// MARK: - Convenience Accessors
extension PFMValue {
    var asDouble: Double? {
        switch self {
            case .integer(let i): return Double(i)
            case .real(let r): return r
            default: return nil
        }
    }

    var displayString: String {
        switch self {
            case .string(let s): return s
            case .integer(let i): return String(i)
            case .real(let r): return String(r)
            case .boolean(let b): return b ? "true" : "false"
            case .date(let date): return date.formatted()
            case .data: return "<data>"
            case .array: return ""
            case .dictionary: return ""
        }
    }
}
