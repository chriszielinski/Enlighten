//
//  Quadrant.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 10/29/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Foundation

/// Represents one of four quadrants or the center of a Cartesian coordinate system.
@objc
public enum Quadrant: Int, CustomStringConvertible {
    case center
    case topRight
    case topLeft
    case bottomLeft
    case bottomRight

    public var description: String {
        switch self {
        case .center:
            return "Center"
        case .topRight:
            return "Top Right"
        case .topLeft:
            return "Top Left"
        case .bottomLeft:
            return "Bottom Left"
        case .bottomRight:
            return "Bottom Right"
        }
    }
}
