//
//  Common.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/13/26.
//

import Foundation

enum PFMTarget: String, Sendable, Decodable {
    case user
    case userManaged = "user-managed"
    case system
    case systemManaged = "system-managed"
}

enum PFMPlatform: String, Sendable, Decodable, Equatable {
    case iOS, macOS, tvOS
}

struct PFMSubstitutionVariable: Sendable, Decodable, Equatable {
    /// Description of the substitution value.
    var description: String?

    /// Example substitution value for the substitution variable.
    var valuePlaceholder: String?

    /// Source of the substitution value.
    var substitutionSource: PFMSubstitutionSource?

    enum CodingKeys: String, CodingKey {
        case description = "pfm_description"
        case valuePlaceholder = "pfm_value_placeholder"
        case substitutionSource = "pfm_substitution_source"
    }
}

enum PFMSubstitutionSource: String, Sendable, Decodable {
    case local, mdm
}
