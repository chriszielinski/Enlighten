//
//  ColoredView.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 10/31/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

class ColoredView: NSView, Resettable {
    var backgroundColor: NSColor? {
        didSet {
            if let backgroundColor = backgroundColor {
                layer!.backgroundColor = backgroundColor.cgColor
            }
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func commonInit() {
        wantsLayer = true
        layer!.autoresizingMask = [.layerHeightSizable, .layerWidthSizable]
    }

    func reset() {
        wantsLayer = false
        layer = nil
        commonInit()
    }

    override func updateLayer() {
        super.updateLayer()

        if let color = backgroundColor?.cgColor {
            layer?.backgroundColor = color
        }
    }
}
