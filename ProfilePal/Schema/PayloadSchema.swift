//
//  PayloadSchema.swift
//  ProfilePal
//
//  Created by David Rosenberg on 11/22/26.
//

import Foundation

/// A payload type and the fields it can hold, in a form independent of any manifest format.
nonisolated struct PayloadSchema: Sendable, Hashable {
    /// How settings combine when several payloads of the same type are installed on a device.
    nonisolated enum Interaction: Sendable, Hashable {
        /// The settings from every installed payload are merged.
        case combined

        /// Only one payload of this type can be in effect at a time.
        case exclusive

        /// The behavior isn't documented.
        case undefined
    }

    /// The human-readable title of the payload.
    let title: String?

    /// The payload's domain, used as its `PayloadType`.
    let domain: String

    /// An identifier that tells apart schemas that split one domain across several sources.
    let subdomain: String?

    /// A description of the payload.
    let description: String?

    /// A note that draws the user's attention to something specific about the payload.
    let note: String?

    /// The version of the schema's source, bumped when fields are added or removed.
    let version: Int?

    /// The date the schema's source was last modified.
    let lastModified: Date?

    /// An image representing the payload.
    let icon: Data?

    /// The URL of the app's homepage.
    let appURL: URL?

    /// How settings combine when several payloads of this type are installed on a device.
    let interaction: Interaction?

    /// Whether only one payload of this type can be installed on a device.
    let isUnique: Bool?

    /// The channels the payload can be installed on.
    let scopes: Set<Scope>

    /// The platforms, versions, and device requirements the payload works with.
    let availability: Availability

    /// The payload's top-level fields, in the source's order.
    let fields: [SchemaField]
}
