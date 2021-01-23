//
//  NSRectEdge.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 10/30/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

extension NSRectEdge: CustomStringConvertible {

    /// `.minX`
    static let left: NSRectEdge = .minX
    /// `.maxY`
    static let above: NSRectEdge = .maxY
    /// `.maxX`
    static let right: NSRectEdge = .maxX
    /// `.minY`
    static let below: NSRectEdge = .minY

    /// Returns the respective receiver in a flipped coordinate system.
    var inFlippedCoordinateSystem: NSRectEdge {
        switch self {
        case .below:
            return .above
        case .above:
            return .below
        default:
            return self
        }
    }

    public var description: String {
        switch self {
        case .minX:
            return "Left (.minX)"
        case .maxY:
            return "Above (.maxY)"
        case .maxX:
            return "Right (.maxX)"
        case .minY:
            return "Below (.minY)"
        @unknown default:
            return "Unknown"
        }
    }
}
