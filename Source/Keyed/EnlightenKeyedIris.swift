//
//  EnlightenKeyedIris.swift
//  Enlighten
//
//  Created by Chris Zielinski on 11/15/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

/// A class that encapsulates the behavior of the spotlight for a particular view.
///
/// Unlike its key-less variant `EnlightenIris`, the keyed `EnlightenKeyedIris` allows the presentation order of all
/// the irises to be specified by the order of an `EnlightenSpotlightControllerKeys` enumeration.
open class EnlightenKeyedIris<Key: EnlightenSpotlightControllerKeys>: EnlightenIris {

    // MARK: Public Stored Properties

    /// The key that specifies the presentation order of the iris.
    ///
    /// The keyed spotlight controller presents the irises in the order their keys have in the
    /// `EnlightenKeyedSpotlightController.presentationOrderKeys` instance property.
    public let presentationOrderKey: Key

    // MARK: - Initializers

    /// Initializes a new keyed iris from the provided stages.
    ///
    /// - Important: Errors thrown during the loading of the Markdown strings are passed to the spotlight controller's
    ///              delegate's
    ///              `EnlightenSpotlightControllerDelegate.spotlightControllerFailedToLoad(markdownString:for:with:)`
    ///              method.
    ///
    /// - Note: If using this initializer directly, the iris must still be added to the controller.
    ///
    /// - Parameters:
    ///   - view: The view to spotlight for the stages of this iris.
    ///   - stages: The stages of this iris.
    ///   - popoverMaxWidth: The popover's maximum width. A non-nil value overrides the default
    ///                   `EnlightenIris.popoverMaxWidth`.
    public init(presentationOrderKey key: Key,
                view: NSView,
                stages: [EnlightenIrisStage],
                popoverMaxWidth: CGFloat? = nil) {
        self.presentationOrderKey = key

        super.init(view: view, stages: stages, popoverMaxWidth: popoverMaxWidth)
    }

    /// Initializes a new keyed iris from the provided stage.
    ///
    /// - Important: Errors thrown during the loading of the Markdown strings are passed to the spotlight controller's
    ///              delegate's
    ///              `EnlightenSpotlightControllerDelegate.spotlightControllerFailedToLoad(markdownString:for:with:)`
    ///              method.
    ///
    /// - Note: If using this initializer directly, the iris must still be added to the controller.
    ///
    /// - Parameters:
    ///   - view: The view to spotlight for the stages of this iris.
    ///   - stage: The stage of this iris.
    ///   - popoverMaxWidth: The popover's maximum width. A non-nil value overrides the default
    ///                   `EnlightenIris.popoverMaxWidth`.
    public convenience init(presentationOrderKey key: Key,
                            view: NSView,
                            stage: EnlightenIrisStage,
                            popoverMaxWidth: CGFloat? = nil) {
        self.init(presentationOrderKey: key, view: view, stages: [stage], popoverMaxWidth: popoverMaxWidth)
    }

    /// Initializes a new keyed iris from CommonMark Markdown strings.
    ///
    /// - Important: Errors thrown during the loading of the Markdown strings are passed to the spotlight controller's
    ///              delegate's
    ///              `EnlightenSpotlightControllerDelegate.spotlightControllerFailedToLoad(markdownString:for:with:)`
    ///              method.
    ///
    /// - Note: If using this initializer directly, the iris must still be added to the controller.
    ///
    /// - Parameters:
    ///   - key: The value (enumeration case) of an enumeration that conforms to the
    ///          `EnlightenSpotlightControllerKeys` protocol to set as the presentation order key of the iris.
    ///   - view: The view to spotlight for the stages of this iris.
    ///   - markdownStrings: The CommonMark Markdown strings displayed as individual stages.
    ///   - popoverMaxWidth: The popover's maximum width. A non-nil value overrides the default
    ///                   `EnlightenIris.popoverMaxWidth`.
    public convenience init(presentationOrderKey key: Key,
                            view: NSView,
                            markdownStrings: [String],
                            popoverMaxWidth: CGFloat? = nil) {
        self.init(presentationOrderKey: key,
                  view: view,
                  stages: markdownStrings.map({ EnlightenIrisStage(markdownString: $0) }),
                  popoverMaxWidth: popoverMaxWidth)
    }

    /// Initializes a new keyed iris from a CommonMark Markdown string.
    ///
    /// - Important: Errors thrown during the loading of the Markdown string are passed to the spotlight controller's
    ///              delegate's
    ///              `EnlightenSpotlightControllerDelegate.spotlightControllerFailedToLoad(markdownString:for:with:)`
    ///              method.
    ///
    /// - Note: If using this initializer directly, the iris must still be added to the controller.
    ///
    /// - Parameters:
    ///   - key: The value (enumeration case) of an enumeration that conforms to the
    ///          `EnlightenSpotlightControllerKeys` protocol to set as the presentation order key of the iris.
    ///   - view: The view to spotlight for the stages of this iris.
    ///   - markdownString: The CommonMark Markdown string displayed.
    ///   - popoverMaxWidth: The popover's maximum width. A non-nil value overrides the default
    ///                   `EnlightenIris.popoverMaxWidth`.
    public convenience init(presentationOrderKey key: Key,
                            view: NSView,
                            markdownString: String,
                            popoverMaxWidth: CGFloat? = nil) {
        self.init(presentationOrderKey: key,
                  view: view,
                  markdownStrings: [markdownString],
                  popoverMaxWidth: popoverMaxWidth)
    }

    /// Initializes a new keyed iris from CommonMark Markdown files.
    ///
    /// - Important: Errors thrown during the loading of the Markdown strings are passed to the spotlight controller's
    ///              delegate's
    ///              `EnlightenSpotlightControllerDelegate.spotlightControllerFailedToLoad(markdownString:for:with:)`
    ///              method.
    ///
    /// - Warning: Asserts the existence of the Markdown files in 'Debug' builds, while failing silently in 'Release'
    ///            builds (by returning an empty string).
    ///
    /// - Note: If using this initializer directly, the iris must still be added to the controller.
    ///
    /// - Parameters:
    ///   - key: The value (enumeration case) of an enumeration that conforms to the
    ///          `EnlightenSpotlightControllerKeys` protocol to set as the presentation order key of the iris.
    ///   - view: The view to spotlight for the stages of this iris.
    ///   - markdownFilenames: The names of the CommonMark Markdown files in the provided bundle that will be displayed
    ///                        as individual stages.
    ///   - bundle: The bundle that contains the Markdown files in `markdownFilenames`.
    ///   - popoverMaxWidth: The popover's maximum width. A non-nil value overrides the default
    ///                   `EnlightenIris.popoverMaxWidth`.
    /// - Throws: Throws an error if the contents of a file in `markdownFilenames` cannot be read.
    public convenience init(presentationOrderKey key: Key,
                            view: NSView,
                            markdownFilenames: [MarkdownFilename],
                            in bundle: Bundle,
                            popoverMaxWidth: CGFloat? = nil) throws {
        self.init(presentationOrderKey: key,
                  view: view,
                  markdownStrings: try markdownFilenames.map({ try String(markdownFilename: $0, in: bundle) }),
                  popoverMaxWidth: popoverMaxWidth)
    }

    /// Initializes a new keyed iris from a CommonMark Markdown file.
    ///
    /// - Important: Errors thrown during the loading of the Markdown string are passed to the spotlight controller's
    ///              delegate's
    ///              `EnlightenSpotlightControllerDelegate.spotlightControllerFailedToLoad(markdownString:for:with:)`
    ///              method.
    ///
    /// - Warning: Asserts the existence of the Markdown file in 'Debug' builds, while failing silently in 'Release'
    ///            builds (by returning an empty string).
    ///
    /// - Note: If using this initializer directly, the iris must still be added to the controller.
    ///
    /// - Parameters:
    ///   - key: The value (enumeration case) of an enumeration that conforms to the
    ///          `EnlightenSpotlightControllerKeys` protocol to set as the presentation order key of the iris.
    ///   - view: The view to spotlight for the stages of this iris.
    ///   - markdownFilename: The name of the CommonMark Markdown file in the provided bundle that will be displayed.
    ///   - bundle: The bundle that contains the Markdown file named `markdownFilename`.
    ///   - popoverMaxWidth: The popover's maximum width. A non-nil value overrides the default
    ///                   `EnlightenIris.popoverMaxWidth`.
    /// - Throws: Throws an error if the contents of the file `markdownFilename` cannot be read.
    public convenience init(presentationOrderKey key: Key,
                            view: NSView,
                            markdownFilename: MarkdownFilename,
                            in bundle: Bundle,
                            popoverMaxWidth: CGFloat? = nil) throws {
        try self.init(presentationOrderKey: key,
                      view: view,
                      markdownFilenames: [markdownFilename],
                      in: bundle,
                      popoverMaxWidth: popoverMaxWidth)
    }
}
