//
//  Scope.swift
//  ProfilePal
//
//  Created by David Rosenberg on 11/22/26.
//

import Foundation

/// A channel that a payload or field can be installed on.
nonisolated enum Scope: Sendable, Hashable {
    /// The user channel, whether installed manually or by MDM.
    case user

    /// The user channel, only when installed by MDM.
    case userManaged

    /// The device channel, whether installed manually or by MDM.
    case system

    /// The device channel, only when installed by MDM.
    case systemManaged
}
