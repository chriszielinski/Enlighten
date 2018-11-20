//
//  NSView.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 10/30/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa
import Down

public extension NSView {
    /// Sets the receiver's tooltip to the style-stripped Markdown string.
    ///
    /// - Parameter markdownString: The CommonMark Markdown string to use for the tooltip.
    /// - Throws: A `DownErrors` error.
    func enlightenTooltip(markdownString: String) throws {
        guard !markdownString.isEmpty
            else { return }

        let attributedString = try Down(markdownString: markdownString).toAttributedString()
        toolTip = attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Sets the receiver's tooltip to the style-stripped Markdown content of a Markdown file.
    ///
    /// - Parameters:
    ///   - markdownFilename: The name of the CommonMark Markdown file in the provided bundle to use for the tooltip.
    ///   - bundle: The bundle that contains the Markdown file named `markdownFilename`.
    /// - Throws: An error if the contents of the file `markdownName` cannot be read, and a `DownErrors` error if
    ///           the CommonMark Markdown string fails to load.
    func enlightenTooltip(markdownFilename: String, in bundle: Bundle) throws {
        try enlightenTooltip(markdownString: try String(markdownFilename: markdownFilename, in: bundle))
    }
}

extension NSView {
    /// Returns the receiver's frame in the receiver's window's coordinate system.
    var frameInWindow: NSRect {
        return convert(bounds, to: nil)
    }

    /// An image whose alpha channel is used to mask the view's content.
    var maskImage: NSImage? {
        get { return layer?.mask?.contents as? NSImage }
        set {
            if !wantsLayer {
                wantsLayer = true
            }

            let maskLayer = layer!.mask ?? CALayer()
            if layer!.mask == nil {
                maskLayer.autoresizingMask = [.layerHeightSizable, .layerWidthSizable]
                maskLayer.frame.size = layer!.bounds.size
                layer!.mask = maskLayer
            }

            layer!.mask!.contents = newValue
        }
    }

    /// Returns the edge insets of the receiver in its window.
    ///
    /// - Returns: The edge insets of the receiver in its window.
    func edgeInsetsFromWindow() -> NSEdgeInsets {
        guard let window = self.window
            else { return NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) }
        return window.edgeInsetsFromWindow(of: convert(bounds, to: nil))
    }

    /// Returns the window `Quadrant` the point is located in.
    ///
    /// - Parameter point: A point specifying a location in the coordinate system of the window.
    public var windowQuadrant: Quadrant? {
        return window?.quadrant(of: convert(bounds.center, to: nil))
    }
}
