//
//  EnlightenSpotlight.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 11/5/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

@objc
public protocol EnlightenSpotlight {
    /// Draws the contents of the receiver that should be masked for the "focused" profile spot.
    ///
    /// By default, the view's layer is used to create the image mask; however, in certain situations where the view
    /// is transparent, this may not be wanted (e.g. radio buttons).
    ///
    /// Because the method is not called until needed, it is executed on the same thread on which the image itself
    /// is drawn, which can be any thread of your app. Therefore, the method must be safe to call from any thread.
    ///
    /// - Parameters:
    ///   - drawingRect: The destination rectangle in which to draw. The rectangle passed in is the `bounds` of `view`.
    ///                  The coordinates of this rectangle are specified in points.
    ///   - cgContext: The graphics context to use to draw.
    @objc
    optional func enlightenDrawProfileSpotMask(drawingRect: NSRect, in cgContext: CGContext)

    /// The group of animations to execute upon focusing on the receiver.
    ///
    /// The method is called regardless of the controller's configuration.
    ///
    /// - Parameters:
    ///   - animationContext: The thread’s current `NSAnimationContext` to configure properties of the animation.
    @objc
    optional func enlightenSpotlightFocusAnimation(using animationContext: NSAnimationContext)

    /// The group of animations to execute upon unfocusing the receiver.
    ///
    /// The method is called regardless of the controller's configuration.
    ///
    /// - Parameters:
    ///   - animationContext: The thread’s current `NSAnimationContext` to configure properties of the animation.
    @objc
    optional func enlightenSpotlightUnfocusAnimation(using animationContext: NSAnimationContext)
}
