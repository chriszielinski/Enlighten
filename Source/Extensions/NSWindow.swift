//
//  NSWindow.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 10/29/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

extension NSWindow {
    /// Returns the edge insets, in points, of a point in a window.
    ///
    /// - Parameter point: The point for which to calculate the edge insets for.
    /// - Returns: The edge insets of `point` in the window.
    func edgeInsetsFromWindow(of point: NSPoint) -> NSEdgeInsets {
        return edgeInsetsFromWindow(of: NSRect(origin: point, size: .zero))
    }

    /// Returns the edge insets, in points, of a rectangle in a window.
    ///
    /// - Parameter rect: The rectangle for which to calculate the edge insets for.
    /// - Returns: The edge insets of `rect` in the window.
    func edgeInsetsFromWindow(of rect: NSRect) -> NSEdgeInsets {
        return NSEdgeInsets(top: frame.size.height - rect.maxY,
                            left: rect.minX,
                            bottom: rect.minY,
                            right: frame.size.width - rect.maxX)
    }

    /// Returns the window `Quadrant` the point is located in.
    ///
    /// - Parameter point: A point specifying a location in the coordinate system of the window.
    public func quadrant(of point: NSPoint) -> Quadrant {
        let windowCenter = NSPoint(x: frame.width / 2, y: frame.height / 2)

        if round(point.x) == round(windowCenter.x) && round(point.y) == round(windowCenter.y) {
            return .center
        } else if point.x < windowCenter.x {
            if point.y < windowCenter.y {
                return .bottomLeft
            } else {
                return .topLeft
            }
        } else {
            if point.y < windowCenter.y {
                return .bottomRight
            } else {
                return .topRight
            }
        }
    }

    /// Returns the screen `Quadrant` the point is located in.
    ///
    /// - Parameter point: A point specifying a location in the coordinate system of the window.
    public func screenQuadrant(of point: NSPoint) -> Quadrant? {
        let pointInScreen = convertPoint(toScreen: point)
        return screen?.quadrant(of: pointInScreen)
    }
}
