//
//  EnlightenPopoverDelegate.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 11/7/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Foundation
import Down

/// A set of optional methods that Enlighten popover delegates can implement to receive events.
@objc
public protocol EnlightenPopoverDelegate: class {
    /// Invoked when a Markdown string fails to load, this method optionally returns a replacement.
    ///
    /// - Parameter downError: The `DownErrors` error that was thrown.
    /// - Returns: Optionally, a replacement Markdown string to use in place of the failed one.
    @objc
    optional func enlightenPopoverFailedToLoad(downError: Error) -> String?

    /// Invoked when an Enlighten URL scheme was clicked in the popover.
    ///
    /// 
    ///
    /// - Parameter url: The Enlighten URL that was clicked.
    @available(OSX 10.13, *)
    @objc
    optional func enlightenPopover(didClickEnlighten url: URL)
}
