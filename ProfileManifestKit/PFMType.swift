//
//  PFMType.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation

enum PFMType: String, Sendable, Decodable {
    case string, integer, real, boolean, date, data, array, dictionary, url
}
