//
//  AnimatableSpotlightLayer.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 11/5/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

class AnimatableSpotlightLayer: CAShapeLayer {

    /// The initial spotlight frame.
    public static var initialSpotlightFrame: CGRect = CGRect(origin: CGPoint(x: -100, y: -100),
                                                             size: CGSize(width: 100, height: 100))

    /// The spotlight frame.
    ///
    /// This property is implicitly animated. Use `focus(on:)` to avoid implicit animation.
    @NSManaged
    dynamic var spotlightFrame: CGRect
    /// Whether the `spotlightFrame` property is being animated.
    ///
    /// For some reason beyond my comprehension, the layer's `display` is sometimes called initally without a
    /// presentation layer, which causes it to draw the spotlight frame at it's final location (the model's value).
    /// So, when `isAnimating` is true and the layer does not have a presentation layer, it will not update the
    /// spotlight frame on display.
    var isAnimating: Bool = false

    var spotlightBackgroundColor: NSColor {
        get { return NSColor(cgColor: fillColor!)! }
        set { fillColor = newValue.cgColor }
    }

    override init() {
        super.init()

        needsDisplayOnBoundsChange = true
        fillRule = .evenOdd
        fillColor = NSColor.clear.cgColor
        autoresizingMask = [.layerHeightSizable, .layerWidthSizable]
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Sets the spotlight focus and forces a re-display.
    ///
    /// - Parameter spotlightFrame: The rectangle to focus the spotlight on.
    func focus(on spotlightFrame: CGRect) {
        // Note: Neccessary to package inside a CATransaction because `spotlightFrame` is implicitly animatable.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setAnimationDuration(0)

        self.spotlightFrame = spotlightFrame
        CATransaction.commit()

        setNeedsDisplay()
        displayIfNeeded()
    }

    override func display() {
        super.display()

        // See `isAnimating` documentation.
        guard (isAnimating && presentation() != nil) || !isAnimating else {
            return
        }

        let mutablePath = CGMutablePath()
        mutablePath.addEllipse(in: presentation()?.spotlightFrame ?? spotlightFrame)
        mutablePath.addRect(bounds)

        // Smoothly update the spotlight.
        let animation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.path))
        animation.fromValue = path
        animation.toValue = mutablePath
        path = mutablePath
        add(animation, forKey: #keyPath(CAShapeLayer.path))
    }

    override class func needsDisplay(forKey key: String) -> Bool {
        return key == #keyPath(spotlightFrame)
            ? true
            : super.needsDisplay(forKey: key)
    }

    override class func defaultValue(forKey key: String) -> Any? {
        return key == #keyPath(spotlightFrame)
            ? AnimatableSpotlightLayer.initialSpotlightFrame
            : super.defaultValue(forKey: key)
    }

    override func action(forKey key: String) -> CAAction? {
        guard key == #keyPath(spotlightFrame)
            else { return super.action(forKey: key) }

        let basicAnimation = CABasicAnimation(keyPath: key)
        basicAnimation.fromValue = presentation()?.value(forKey: key) ?? spotlightFrame
        return basicAnimation
    }
}
