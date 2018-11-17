//
//  EnlightenIris.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 11/5/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

/// A class that encapsulates the behavior of the spotlight for a particular view.
@objc
open class EnlightenIris: NSObject {

    // MARK: Static Public Stored Properties

    /// The default popover maximum width.
    public static var popoverMaxWidth: CGFloat = 300

    // MARK: Public Type Aliases

    /// A CommonMark Markdown filename.
    public typealias MarkdownFilename = String
    /// A closure that draws the contents of `view` that should be masked for the "focused" profile spot.
    ///
    /// Because the closure is not called until needed, it is executed on the same thread on which the image itself
    /// is drawn, which can be any thread of your app. Therefore, the closure must be safe to call from any thread.
    ///
    /// - Parameters:
    ///   - drawingRect: The destination rectangle in which to draw. The rectangle passed in is the `bounds` of `view`.
    ///                  The coordinates of this rectangle are specified in points.
    ///   - cgContext: The graphics context to use to draw.
    public typealias ProfileSpotDrawingHandler = (_ drawingRect: NSRect, _ cgContext: CGContext) -> Void
    /// A closure containing animations for a transaction group.
    ///
    /// - Parameters:
    ///   - animationContext: The thread’s current `NSAnimationContext` to configure properties of the animation.
    public typealias AnimationHandler = (_ animationContext: NSAnimationContext) -> Void

    // MARK: Public Stored Properties

    /// Whether the spotlight controller disables navigation until the focus animation finishes.
    ///
    /// This property has a default value of `false`.
    ///
    /// - Note: This property should only be `true` if the animation will take longer than the spotlight
    ///         controller's `EnlightenSpotlightController.profileSpotFocusDuration` instance property.
    public var doesWaitForFocusAnimationCompletion: Bool = false
    /// The view of the iris.
    public unowned var view: NSView
    /// The iris' stages, individually rendered in the popover.
    public var stages: [EnlightenIrisStage]
    /// The popover width.
    ///
    /// A non-nil value overrides the default `EnlightenIris.popoverMaxWidth`.
    public var popoverMaxWidth: CGFloat?
    /// The edge of `view` the popover should prefer to be anchored to.
    ///
    /// When `nil`, a heuristic is used to determine the best anchor edge for the view based on its
    /// location in the window.
    public var preferredPopoverEdge: NSRectEdge?
    /// Whether the Markdown content should be center aligned.
    ///
    /// This property has a default value of false.
    public var doesCenterAlignContent: Bool = false
    /// A closure for drawing a custom profile spot mask.
    ///
    /// By default, the `view`'s layer is used to create the image mask; however, in certain situations where the
    /// view is transparent, this may not be wanted (e.g. radio buttons).
    ///
    /// See `ProfileSpotDrawingHandler` for more information.
    public var profileSpotDrawingHandler: ProfileSpotDrawingHandler?
    /// A closure containing a group of animations to execute upon focusing on `view`.
    ///
    /// The closure is called regardless of the controller's configuration.
    public var focusAnimationGroup: AnimationHandler?
    /// A closure containing a group of animations to execute upon unfocusing `view`.
    ///
    /// The closure is called regardless of the controller's configuration.
    public var unfocusAnimationGroup: AnimationHandler?

    // MARK: Internal Stored Properties

    /// The index of the current Markdown string.
    ///
    /// Used for navigation.
    var currentStageIndex: Int = 0
    /// The latest computed best popover edge for this iris.
    var cachedBestPopoverEdge: NSRectEdge?

    // MARK: Internal Computed Properties

    /// The current internal stage of the iris.
    ///
    /// The stage index origin is one (i.e. the first stage is stage 1).
    var currentStage: Int {
        return currentStageIndex + 1
    }
    /// The profile spot drawing handler for the iris.
    var resolvedProfileSpotDrawingHandler: ProfileSpotDrawingHandler? {
        return profileSpotDrawingHandler ?? (view as? EnlightenSpotlight)?.enlightenDrawProfileSpotMask
    }
    /// The focus animation group for the iris.
    var resolvedFocusAnimationGroup: AnimationHandler? {
        return focusAnimationGroup ?? (view as? EnlightenSpotlight)?.enlightenSpotlightFocusAnimation
    }
    /// The unfocus animation group for the iris.
    var resolvedUnfocusAnimationGroup: AnimationHandler? {
        return unfocusAnimationGroup ?? (view as? EnlightenSpotlight)?.enlightenSpotlightUnfocusAnimation
    }
    /// The popover max width for the current stage.
    var resolvedPopoverMaxWidth: CGFloat {
        return stages[currentStageIndex].popoverMaxWidth ?? popoverMaxWidth ?? EnlightenIris.popoverMaxWidth
    }
    /// The preferred popover edge for the current stage.
    var resolvedPreferredPopoverEdge: NSRectEdge? {
        return stages[currentStageIndex].preferredPopoverEdge ?? preferredPopoverEdge ?? cachedBestPopoverEdge
    }
    /// Whether to center align the Markdown content for the current stage.
    var resolvedDoesCenterAlignContent: Bool {
        return stages[currentStageIndex].doesCenterAlignContent ?? doesCenterAlignContent
    }
    /// Whether the iris has a focus animation group.
    var hasFocusAnimationGroup: Bool {
        return resolvedFocusAnimationGroup != nil
    }
    /// Whether the iris has a focus animation group and `shouldWaitForFocusAnimationCompletion` is `true`.
    var shouldWaitForFocusAnimationCompletion: Bool {
        return hasFocusAnimationGroup && doesWaitForFocusAnimationCompletion
    }
    /// Whether the iris has a next stage (i.e. a next Markdown string to render).
    ///
    /// Used for navigation.
    var hasNextStage: Bool {
        return stages.count > 1 && currentStageIndex + 1 < stages.count
    }
    /// Whether the iris has a previous stage (i.e. a previous Markdown string to render).
    ///
    /// Used for navigation.
    var hasPreviousStage: Bool {
        return stages.count > 1 && currentStageIndex > 0
    }
    /// Whether the current stage has a preferred popover edge.
    var hasPreferredPopoverEdge: Bool {
        return resolvedPreferredPopoverEdge != nil
    }
    /// The Markdown string to render in the popover for the current stage.
    var currentMarkdownString: String {
        return stages[currentStageIndex].markdownString
    }

    // MARK: - Initializers

    /// Initializes a new iris from the provided stages.
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
    public init(view: NSView,
                stages: [EnlightenIrisStage],
                popoverMaxWidth: CGFloat? = nil) {
        self.view = view
        self.stages = stages
        self.popoverMaxWidth = popoverMaxWidth
    }

    /// Initializes a new iris from the provided stage.
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
    public convenience init(view: NSView,
                            stage: EnlightenIrisStage,
                            popoverMaxWidth: CGFloat? = nil) {
        self.init(view: view, stages: [stage], popoverMaxWidth: popoverMaxWidth)
    }

    /// Initializes a new iris from CommonMark Markdown strings.
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
    ///   - markdownStrings: The CommonMark Markdown strings displayed as individual stages.
    ///   - popoverMaxWidth: The popover's maximum width. A non-nil value overrides the default
    ///                   `EnlightenIris.popoverMaxWidth`.
    public convenience init(view: NSView,
                            markdownStrings: [String],
                            popoverMaxWidth: CGFloat? = nil) {
        self.init(view: view,
                  stages: markdownStrings.map({ EnlightenIrisStage(markdownString: $0) }),
                  popoverMaxWidth: popoverMaxWidth)
    }

    /// Initializes a new iris from a CommonMark Markdown string.
    ///
    /// - Important: Errors thrown during the loading of the Markdown string are passed to the spotlight controller's
    ///              delegate's
    ///              `EnlightenSpotlightControllerDelegate.spotlightControllerFailedToLoad(markdownString:for:with:)`
    ///              method.
    ///
    /// - Note: If using this initializer directly, the iris must still be added to the controller.
    ///
    /// - Parameters:
    ///   - view: The view to spotlight for the stages of this iris.
    ///   - markdownString: The CommonMark Markdown string displayed.
    ///   - popoverMaxWidth: The popover's maximum width. A non-nil value overrides the default
    ///                   `EnlightenIris.popoverMaxWidth`.
    public convenience init(view: NSView, markdownString: String, popoverMaxWidth: CGFloat? = nil) {
        self.init(view: view, markdownStrings: [markdownString], popoverMaxWidth: popoverMaxWidth)
    }

    /// Initializes a new iris from CommonMark Markdown files.
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
    ///   - view: The view to spotlight for the stages of this iris.
    ///   - markdownFilenames: The names of the CommonMark Markdown files in the provided bundle that will be displayed
    ///                        as individual stages.
    ///   - bundle: The bundle that contains the Markdown files in `markdownFilenames`.
    ///   - popoverMaxWidth: The popover's maximum width. A non-nil value overrides the default
    ///                   `EnlightenIris.popoverMaxWidth`.
    /// - Throws: Throws an error if the contents of a file in `markdownFilenames` cannot be read.
    public convenience init(view: NSView,
                            markdownFilenames: [MarkdownFilename],
                            in bundle: Bundle,
                            popoverMaxWidth: CGFloat? = nil) throws {
        self.init(view: view,
                  markdownStrings: try markdownFilenames.map({ try String(markdownFilename: $0, in: bundle) }),
                  popoverMaxWidth: popoverMaxWidth)
    }

    /// Initializes a new iris from a CommonMark Markdown file.
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
    ///   - view: The view to spotlight for the stages of this iris.
    ///   - markdownFilename: The name of the CommonMark Markdown file in the provided bundle that will be displayed.
    ///   - bundle: The bundle that contains the Markdown file named `markdownFilename`.
    ///   - popoverMaxWidth: The popover's maximum width. A non-nil value overrides the default
    ///                   `EnlightenIris.popoverMaxWidth`.
    /// - Throws: Throws an error if the contents of the file `markdownFilename` cannot be read.
    public convenience init(view: NSView,
                            markdownFilename: MarkdownFilename,
                            in bundle: Bundle,
                            popoverMaxWidth: CGFloat? = nil) throws {
        try self.init(view: view, markdownFilenames: [markdownFilename], in: bundle, popoverMaxWidth: popoverMaxWidth)
    }

    // MARK: - Public Configuration Methods

    /// Adds additional stages to the iris.
    ///
    /// - Important: Errors thrown during the loading of the Markdown strings are passed to the spotlight controller's
    ///              delegate's
    ///              `EnlightenSpotlightControllerDelegate.spotlightControllerFailedToLoad(markdownString:for:with:)`
    ///              method.
    ///
    /// - Parameter stages: The stages to add.
    public func addAdditional(stages: [EnlightenIrisStage]) {
        self.stages.append(contentsOf: stages)
    }

    /// Adds an additional stage to the iris.
    ///
    /// - Important: Errors thrown during the loading of the Markdown strings are passed to the spotlight controller's
    ///              delegate's
    ///              `EnlightenSpotlightControllerDelegate.spotlightControllerFailedToLoad(markdownString:for:with:)`
    ///              method.
    ///
    /// - Parameter stage: The stage to add.
    public func addAdditional(stage: EnlightenIrisStage) {
        stages.append(stage)
    }

    /// Adds additional stages for CommonMark Markdown strings to the iris.
    ///
    /// - Important: Errors thrown during the loading of the Markdown strings are passed to the spotlight controller's
    ///              delegate's
    ///              `EnlightenSpotlightControllerDelegate.spotlightControllerFailedToLoad(markdownString:for:with:)`
    ///              method.
    ///
    /// - Parameter markdownStrings: The Markdown strings to render in the popover as additional individual stages.
    public func addAdditionalStages(using markdownStrings: [String]) {
        stages.append(contentsOf: markdownStrings.map({ EnlightenIrisStage(markdownString: $0) }))
    }

    /// Adds an additional stage for a CommonMark Markdown string to the iris.
    ///
    /// - Important: Errors thrown during the loading of the Markdown string are passed to the spotlight controller's
    ///              delegate's
    ///              `EnlightenSpotlightControllerDelegate.spotlightControllerFailedToLoad(markdownString:for:with:)`
    ///              method.
    ///
    /// - Parameter markdownString: The Markdown string to render in the popover.
    public func addAdditionalStage(using markdownString: String) {
        addAdditionalStages(using: [markdownString])
    }

    /// Adds additional stages from the contents of CommonMark Markdown files to the iris.
    ///
    /// - Important: Errors thrown during the loading of the Markdown strings are passed to the spotlight controller's
    ///              delegate's
    ///              `EnlightenSpotlightControllerDelegate.spotlightControllerFailedToLoad(markdownString:for:with:)`
    ///              method.
    ///
    /// - Warning: Asserts the existence of the Markdown files in 'Debug' builds, while failing silently in 'Release'
    ///            builds (by returning an empty string).
    ///
    /// - Parameters:
    ///   - markdownFilename: The names of the CommonMark Markdown files in the provided bundle to add as additional
    ///                       individual stages.
    ///   - bundle: The bundle that contains the files in `markdownFilenames`.
    /// - Throws: Throws an error if the contents of a file in `markdownFilenames` cannot be read.
    public func addAdditionalStages(from markdownFilenames: [MarkdownFilename], in bundle: Bundle) throws {
        addAdditionalStages(using: try markdownFilenames.map({ try String(markdownFilename: $0, in: bundle) }))
    }

    /// Adds an additional stage from the contents of a CommonMark Markdown file to the iris.
    ///
    /// - Important: Errors thrown during the loading of the Markdown string are passed to the spotlight controller's
    ///              delegate's
    ///              `EnlightenSpotlightControllerDelegate.spotlightControllerFailedToLoad(markdownString:for:with:)`
    ///              method.
    ///
    /// - Warning: Asserts the existence of the Markdown file in 'Debug' builds, while failing silently in 'Release'
    ///            builds (by returning an empty string).
    ///
    /// - Parameters:
    ///   - markdownFilename: The name of the CommonMark Markdown file in the provided bundle to add.
    ///   - bundle: The bundle that contains the file named `markdownFilename`.
    /// - Throws: Throws an error if the contents of the file `markdownFilename` cannot be read.
    public func addAdditionalStage(from markdownFilename: MarkdownFilename, in bundle: Bundle) throws {
        try addAdditionalStages(from: [markdownFilename], in: bundle)
    }
}

// MARK: - Stage Retrieval Methods

public extension EnlightenIris {
    /// Returns the stage for a one-based stage index.
    ///
    /// - Note: The stage indices are one-based (e.g. the first stage's index is 1).
    ///
    /// - Parameter index: The one-based stage index to retrieve.
    /// - Returns: Returns the stage for `index`.
    func stage(index: Int) -> EnlightenIrisStage? {
        guard index > 0 && index <= stages.count
            else { return nil }
        return stages[index - 1]
    }
}

// MARK: - Internal Markdown Methods

extension EnlightenIris {
    /// Increments the current Markdown string index and returns the next Markdown string, if there is one.
    ///
    /// - Returns: The Markdown string for the next index, or `nil`.
    func nextMarkdownString() -> String? {
        currentStageIndex += 1

        if currentStageIndex < stages.count {
            return stages[currentStageIndex].markdownString
        } else {
            return nil
        }
    }

    /// Decrements the current Markdown string index and returns the previous Markdown string, if there is one.
    ///
    /// - Returns: The Markdown string for the previous index, or `nil`.
    func previousMarkdownString() -> String? {
        currentStageIndex -= 1

        if currentStageIndex >= 0 {
            return stages[currentStageIndex].markdownString
        } else {
            return nil
        }
    }
}

// MARK: - Internal State Methods

extension EnlightenIris {
    /// Resets the iris' internal navigation state.
    ///
    /// Must be called prior to a forward revisit.
    func reset() {
        currentStageIndex = 0
        cachedBestPopoverEdge = nil
    }
}
