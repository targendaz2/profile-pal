//
//  FormPath.swift
//  ProfileManifestKit
//
//  Created by David Rosenberg on 9/10/26.
//

import Foundation

public struct FormPath: Hashable, Sendable {
    enum Component: Hashable, Sendable {
        case key(String)
        case index(Int)
    }
    var components: [Component]

    static var root: FormPath {
        FormPath(components: [])
    }

    func appending(_ c: Component) -> FormPath {
        FormPath(components: components + [c])
    }

    func appending(key: String) -> FormPath {
        appending(.key(key))
    }

    func appending(index: Int) -> FormPath {
        appending(.index(index))
    }
}
