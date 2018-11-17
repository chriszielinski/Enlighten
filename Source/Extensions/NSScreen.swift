//
//  NSScreen.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 10/29/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

extension NSScreen {
    /// Returns the center point of the screen.
    public var visibleFrameCenter: NSPoint {
        return visibleFrame.center
    }

    /// Returns the `Quadrant` the point is located in.
    ///
    /// - Parameter point: A point specifying a location in the coordinate system of the screen.
    public func quadrant(of point: NSPoint) -> Quadrant {
        let screenCenter = visibleFrameCenter

        if point == screenCenter {
            return .center
        } else if point.x < screenCenter.x {
            if point.y < screenCenter.y {
                return .bottomLeft
            } else {
                return .topLeft
            }
        } else {
            if point.y < screenCenter.y {
                return .bottomRight
            } else {
                return .topRight
            }
        }
    }
}
