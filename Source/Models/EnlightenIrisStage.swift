//
//  EnlightenIrisStage.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 11/17/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Foundation

open class EnlightenIrisStage {
    /// The popover width.
    ///
    /// A non-nil value overrides the iris' popover max width.
    public var popoverMaxWidth: CGFloat?
    /// The edge of the stage's `view` the popover should prefer to be anchored to.
    ///
    /// When `nil`, the `EnlightenIris.preferredPopoverEdge` is used.
    public var preferredPopoverEdge: NSRectEdge?
    /// Whether the Markdown content of this stage should be center aligned.
    ///
    /// This property has a default value of `nil` and takes precedence over the iris' value.
    public var doesCenterAlignContent: Bool?
    /// The CommonMark Markdown string displayed in the popover for the stage.
    public var markdownString: String

    public init(markdownString: String, popoverMaxWidth: CGFloat? = nil, preferredPopoverEdge: NSRectEdge? = nil) {
        self.preferredPopoverEdge = preferredPopoverEdge
        self.markdownString = markdownString
    }
}
