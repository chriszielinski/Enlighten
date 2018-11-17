//
//  CustomView.swift
//  Demo
//
//  Created by Chris Zielinski on 11/7/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa
import Enlighten

class CustomView: NSView, EnlightenSpotlight {

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        commonInit()
    }

    func commonInit() {
        wantsLayer = true
        layer!.backgroundColor = NSColor.red.cgColor
    }

    func enlightenSpotlightFocusAnimation(using animationContext: NSAnimationContext) {
        animationContext.allowsImplicitAnimation = true
        animationContext.duration = 3
        layer!.backgroundColor = NSColor.blue.cgColor
    }

    func enlightenSpotlightUnfocusAnimation(using animationContext: NSAnimationContext) {
        animationContext.allowsImplicitAnimation = true
        animationContext.duration = 3
        layer!.backgroundColor = NSColor.red.cgColor
    }
}
