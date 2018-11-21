//
//  EnlightenSpotlightControllerDelegate.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 11/11/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Foundation

@objc
public protocol EnlightenSpotlightControllerDelegate: class {
    /// Invoked before the controller shows a stage (Markdown string).
    ///
    /// - Parameters:
    ///   - stage: The stage of the iris that will be shown. The stage index origin is one (i.e. the first
    ///            stage is stage 1).
    ///   - iris: The iris that the Markdown string belongs to.
    ///   - navigating: The direction of navigation, either forwards (showing the next stage) or backwards
    ///                 (showing the previous stage).
    @objc
    optional func spotlightControllerWillShow(stage: Int,
                                              in iris: EnlightenIris,
                                              navigating: EnlightenSpotlightController.NavigationDirection)

    /// Invoked when the controller has finished dismissing.
    @objc
    optional func spotlightControllerDidDismiss()

    /// Invoked when a Markdown string fails to load, this method optionally returns a replacement.
    ///
    /// If the delegate does not implement this method or returns nil, the spotlight stage is skipped.
    ///
    /// - Note: This delegate method should not be necessary if appropriate testing procedures are employed to ensure
    ///         that all Markdown strings load successfully (i.e.
    ///         `EnlightenSpotlightController.validateMarkdownStrings()` testing method).
    ///
    /// - Parameters:
    ///   - markdownString: The Markdown string that failed to load.
    ///   - iris: The iris that the Markdown string belongs to.
    ///   - downError: The error that was thrown.
    /// - Returns: Optionally, a replacement Markdown string to use in place of the failed one.
    @objc
    optional func spotlightControllerFailedToLoad(markdownString: String,
                                                  for iris: EnlightenIris,
                                                  with error: Error) -> String?
}
