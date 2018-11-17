//
//  AnimatableSpotlightView.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 11/5/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

class AnimatableSpotlightView: NSView, Resettable {
    var spotlightLayer: AnimatableSpotlightLayer {
        // If this fails, we got bigger fish to fry. 🍳
        // swiftlint:disable:next force_cast
        return layer as! AnimatableSpotlightLayer
    }
    var spotlightBackgroundColor: NSColor? {
        didSet {
            if let color = spotlightBackgroundColor {
                spotlightLayer.spotlightBackgroundColor = color
            }
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        wantsLayer = true
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        // Forces the creation of a new backing layer.
        wantsLayer = false
        layer = nil
        wantsLayer = true
    }

    override func makeBackingLayer() -> CALayer {
        return AnimatableSpotlightLayer()
    }

    override func layout() {
        super.layout()

        if let color = spotlightBackgroundColor {
            spotlightLayer.spotlightBackgroundColor = color
        }
    }
}
