//
//  Platform.swift
//  ProfilePal
//
//  Created by David Rosenberg on 11/22/26.
//

import Foundation

/// An Apple platform that a payload or field can support.
///
/// A closed set: a source that names any other platform gets a diagnostic instead.
nonisolated enum Platform: CaseIterable, Sendable, Hashable {
    case iOS
    case iPadOS
    case macOS
    case macCatalyst
    case tvOS
    case visionOS
    case watchOS
}
