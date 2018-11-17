//
//  NSRect.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 10/29/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

extension NSRect {
    /// Returns the center point of the rectangle.
    public var center: NSPoint {
        return NSPoint(x: origin.x + (width / 2), y: origin.y + (height / 2))
    }

    /// Returns a circumscribing ellipse.
    ///
    /// - Parameter eccentricity: Whether the circumscribing ellipse allows eccentricity. When `false`, the returning
    ///                           circumscribing ellipse will be perfectly circular; otherwise, elliptical.
    /// - Returns: Returns a circumscribing ellipse.
    public func circumscribingEllipse(eccentricity: Bool) -> NSRect {
        if eccentricity {
            let squareRootTwo = CGFloat(2.0.squareRoot())
            let horizontalRadius = width / squareRootTwo
            let verticalRadius = height / squareRootTwo
            let newOrigin = CGPoint(x: origin.x - horizontalRadius + (width / 2),
                                    y: origin.y - verticalRadius + (height / 2))
            return CGRect(origin: newOrigin, size: CGSize(width: 2 * horizontalRadius, height: 2 * verticalRadius))
        } else {
            let diameter = (pow(width, 2) + pow(height, 2)).squareRoot()
            let newOrigin = CGPoint(x: origin.x - (diameter / 2) + (width / 2),
                                    y: origin.y - (diameter / 2) + (height / 2))
            return CGRect(origin: newOrigin, size: CGSize(width: diameter, height: diameter))
        }
    }
}
