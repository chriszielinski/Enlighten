//
//  EnlightenSpotlightController.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 10/29/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa
import CoreGraphics
import Down

/// The controller for a spotlight-based onboarding presentation.
open class EnlightenSpotlightController: NSViewController {

    // MARK: Controller Enumerations

    /// The shape of the followspot spotlight.
    public enum FollowspotShape: CaseIterable, CustomStringConvertible {
        /// No followspot.
        case none
        /// A circle.
        case circle
        /// An ellipse.
        case ellipse

        public var description: String {
            switch self {
            case .none:
                return "None"
            case .circle:
                return "Circle"
            case .ellipse:
                return "Ellipse"
            }
        }
    }

    @objc
    public enum NavigationDirection: Int, CustomStringConvertible {
        /// Navigating forward to the next stage.
        case forward
        /// Navigating backward to the previous stage.
        case backward
        /// The initial stage.
        case initial

        public var description: String {
            switch self {
            case .forward:
                return "Forward"
            case .backward:
                return "Backward"
            case .initial:
                return "Initial"
            }
        }
    }

    // MARK: Public Stored Properties

    weak public var delegate: EnlightenSpotlightControllerDelegate?

    /// Whether the spotlight focuses on the view.
    ///
    /// The spotlight _focus_ animation is the scaling of the spotlight iris on a particular view from a
    /// followspot (wider) to a profile spot (tighter).
    ///
    /// This property has a default value of `true`.
    ///
    /// - Note: The `followspotShape` must **not** be `.none` if this property is false.
    public var usesProfileSpot: Bool = true
    /// The shape of the followspot.
    ///
    /// This property has a default value of `.circle`.
    public var followspotShape: FollowspotShape = .circle
    /// The controller's background color.
    public var backgroundColor: NSColor = .spotlightControllerBackground
    /// The animation duration, in seconds, used to initially present the controller.
    ///
    /// - Note: Only used if `present(in:animating:)` is called with a true `animating` parameter.
    public var presentationAnimationDuration: TimeInterval = 0.25
    /// The duration, in seconds, of the followspot transition animation used when initially presenting the controller.
    ///
    /// - Note: Only used if `present(in:animating:)` is called with a true `animating` parameter,
    ///         `usesProfileSpot` is false, and `followspotShape` is **not** `.none`.
    public var presentationFollowspotTransitionAnimationDuration: TimeInterval = 1
    // swiftlint:disable:previous identifier_name

    /// The duration, in seconds, of the spotlight _focus_ animation.
    ///
    /// The spotlight _focus_ animation is the scaling of the spotlight iris on a particular view from a
    /// followspot (wider) to a profile spot (tighter), or vice versa.
    public var profileSpotFocusDuration: TimeInterval = 0.25
    /// The timing function of the spotlight _focus_ animation.
    ///
    /// The spotlight _focus_ animation is the scaling of the spotlight iris on a particular view from a
    /// followspot (wider) to a profile spot (tighter), or vice versa.
    ///
    /// By default, uses a ease-in-ease-out pacing.
    public var profileSpotFocusTimingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    /// The duration, in seconds, of the spotlight transition animation.
    ///
    /// The spotlight transition animation is the transitioning of the followspot from one view to the next.
    public var followspotTransitionDuration: TimeInterval = 0.5
    /// The timing function of the spotlight transition animation.
    ///
    /// The spotlight transition animation is the transitioning of the followspot from one view to the next.
    ///
    /// By default, uses a ease-in-ease-out pacing.
    public var followspotTransitionTimingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    /// Whether the controller is presenting.
    @objc
    dynamic public private(set) var isPresenting: Bool = false
    /// The most recent direction the user is navigating in.
    public private(set) var navigatingDirection: NavigationDirection = .initial

    public let popover: EnlightenPopover
    public let skipButton: NSButton

    // MARK: Public Computed Properties

    /// The currently focused iris.
    public var currentIris: EnlightenIris {
        return irises[currentIrisIndex]
    }
    /// The previously focused iris.
    public var previousIris: EnlightenIris? {
        // Only true when on the initial iris (meaning there is no previous iris).
        guard !isInitialIris
            else { return nil }
        return irises[previousIrisIndex]
    }
    /// The currently focused view.
    public var focusedView: NSView? {
        return currentIris.view
    }
    /// The previously focused view.
    public var previousFocusedView: NSView? {
        return previousIris?.view
    }
    /// Whether the controller is focused on the first iris with no previous iris (i.e. the controller is in its
    /// inital state).
    public var isInitialIris: Bool {
        return navigatingDirection == .initial
    }

    // MARK: Internal Stored Properties

    let imageMaskView: ColoredView
    let animatableSpotlightView: AnimatableSpotlightView

    /// The irises that will be presented by the controller.
    var irises: [EnlightenIris] = []
    /// The window the controller is presenting in.
    var presentationWindow: NSWindow?

    /// The current iris index.
    var currentIrisIndex = 0
    /// The previous iris index.
    var previousIrisIndex = 0

    /// Whether there is an animation in progress.
    var isAnimating: Bool = false
    /// Whether the most recent Markdown string failed to render.
    var didFailToUpdateMarkdown: Bool = false
    /// The acitve local event monitors.
    var localEventMonitors: [Any?] = []
    /// The timestamp of the last key down event.
    ///
    /// This property is used to recognize "button mashing".
    var lastKeyDownEventTimestamp: TimeInterval?

    // MARK: Internal Computed Properties

    /// Whether the image mask view is being used.
    var usesImageMask: Bool {
        return usesProfileSpot || followspotShape == .none
    }
    /// Whether the followspot shape is an ellipse.
    var isFollowspotShapeEllipse: Bool {
        return followspotShape == .ellipse
    }
    /// The presentation window's content view.
    var contentView: NSView? {
        return presentationWindow?.contentView
    }
    /// The presentation window's content view's frame.
    var contentViewFrame: NSRect {
        return contentView?.frame ?? .zero
    }
    var focusedViewFollowspotRect: CGRect {
        return focusedView!.frameInWindow.circumscribingEllipse(eccentricity: isFollowspotShapeEllipse)
    }
    var previouslyFocusedViewFollowspotRect: CGRect {
        return previousFocusedView!.frameInWindow.circumscribingEllipse(eccentricity: isFollowspotShapeEllipse)
    }

    // MARK: - Initializers

    public init(markdownOptions: EnlightenMarkdownOptions = .default) {
        imageMaskView = ColoredView()
        imageMaskView.autoresizingMask = [.width, .height]

        animatableSpotlightView = AnimatableSpotlightView()
        animatableSpotlightView.autoresizingMask = [.width, .height]

        popover = EnlightenPopover(options: markdownOptions, maxWidth: 800)

        skipButton = NSButton(image: NSImage(named: NSImage.stopProgressFreestandingTemplateName)!,
                              target: nil,
                              action: nil)

        super.init(nibName: nil, bundle: nil)

        popover.enlightenPopoverDelegate = self
        popover.fitInWindow = true
        popover.behavior = .applicationDefined

        skipButton.isBordered = false
        skipButton.isHidden = true
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.target = self
        skipButton.action = #selector(skipButtonAction)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overridden Methods

    override open func viewWillLayout() {
        super.viewWillLayout()

        if #available(OSX 10.14, *) {
            skipButton.appearance = NSAppearance(named: .darkAqua)!
        } else {
            // Fallback on earlier versions
            skipButton.appearance = NSAppearance(named: .vibrantDark)!
        }
        imageMaskView.backgroundColor = backgroundColor
        animatableSpotlightView.spotlightBackgroundColor = backgroundColor
    }

    // MARK: - Presentation Methods

    /// Presents and begins the onboarding introduction.
    ///
    /// - Parameters:
    ///   - window: The window to present the controller in. When `nil`, resolves the window in the following order:
    ///     1. The application's main window.
    ///     2. The application's key window.
    ///     3. The first window in the array of the application’s window objects.
    ///   - animating: Whether to animate the addition of the controller to the view hierarchy.
    open func present(in window: NSWindow? = nil, animating: Bool = false) {
        guard !isPresenting,
            let presentationWindow = window ?? NSApp.mainWindow ?? NSApp.keyWindow ?? NSApp.windows.first,
            let contentView = presentationWindow.contentView
            else { return }

        reset()
        isPresenting = true

        self.presentationWindow = presentationWindow

        imageMaskView.frame = contentView.bounds
        animatableSpotlightView.frame = contentView.bounds

        contentView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangeContentViewFrame),
                                               name: NSView.frameDidChangeNotification,
                                               object: contentView)

        createLocalEventMonitors()
        presentationWindow.makeFirstResponder(contentView)
        presentationWindow.disableCursorRects()

        let iris = currentIris
        let completionHandler: () -> Void = {
            self.delegate?.spotlightControllerWillShow?(stage: iris.currentStage,
                                                        in: iris,
                                                        navigating: .initial)
            self.updateSpotlight()
        }
        if followspotShape == .none || usesProfileSpot {
            // Will only be animating the mask image change, or views will be added/removed during the animations.
            view = imageMaskView
            addSubviewToContentViewBelowSkipButton(view,
                                                   animating: animating,
                                                   animationCompletionHandler: completionHandler)
        } else {
            // Will only be using the spotlight transition view.
            view = animatableSpotlightView

            let animationDuration: TimeInterval = animating ? presentationFollowspotTransitionAnimationDuration : 0
            let spotlightRect = focusedViewFollowspotRect
            addSubviewToContentViewBelowSkipButton(view, animating: animating) {
                NSAnimationContext.runAnimationGroup({ (context) in
                    context.duration = animationDuration
                    context.timingFunction = self.followspotTransitionTimingFunction

                    self.animatableSpotlightView.spotlightLayer.spotlightFrame = spotlightRect
                }, completionHandler: completionHandler)
            }
        }
    }

    /// Animates the controller's dismissal.
    open func dismiss() {
        isPresenting = false
        popover.close()

        if let unfocusAnimationGroup = self.currentIris.resolvedUnfocusAnimationGroup {
            NSAnimationContext.runAnimationGroup(unfocusAnimationGroup,
                                                 completionHandler: nil)
        }

        NSAnimationContext.runAnimationGroup({ (context) in
            context.allowsImplicitAnimation = true
            context.duration = 1

            animatableSpotlightView.removeFromSuperview()
            imageMaskView.removeFromSuperview()
            skipButton.removeFromSuperview()
        }, completionHandler: {
            self.animatableSpotlightView.reset()
            self.imageMaskView.reset()

            self.delegate?.spotlightControllerDidDismiss?()
        })

        localEventMonitors.compactMap({ $0 }).forEach { NSEvent.removeMonitor($0) }
        localEventMonitors.removeAll()

        NotificationCenter.default.removeObserver(self,
                                                  name: NSView.frameDidChangeNotification,
                                                  object: contentView!)
        presentationWindow?.enableCursorRects()
        presentationWindow = nil
    }

    // MARK: - Configuration Methods

    /// Adds an iris to the controller.
    ///
    /// - Parameter iris: The iris to add.
    open func addSpotlight(iris: EnlightenIris) {
        irises.append(iris)
    }

    /// A convenience method for creating and adding an iris to the controller.
    ///
    /// - Important: Errors thrown during the loading of the Markdown string are passed to the spotlight controller's
    ///              delegate's
    ///              `EnlightenSpotlightControllerDelegate.spotlightControllerFailedToLoad(markdownString:for:with:)`
    ///              method.
    ///
    /// - Parameters:
    ///   - view: The view to spotlight.
    ///   - markdownString: The CommonMark Markdown string displayed.
    /// - Returns: The newly created spotlight iris.
    @discardableResult
    open func addSpotlight(view: NSView, markdownString: String) -> EnlightenIris {
        let iris = EnlightenIris(view: view, markdownString: markdownString)
        addSpotlight(iris: iris)
        return iris
    }

    /// A convenience method for creating and adding an iris to the controller.
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
    ///   - view: The view to spotlight.
    ///   - markdownFilename: The name of the CommonMark Markdown file in the provided bundle that will be displayed.
    ///   - bundle: The bundle that contains the Markdown file named `markdownFilename`.
    /// - Returns: The newly created spotlight iris.
    /// - Throws: Throws an error if the contents of the file `markdownFilename` cannot be read.
    @discardableResult
    open func addSpotlight(view: NSView,
                           markdownFilename: EnlightenIris.MarkdownFilename,
                           in bundle: Bundle) throws -> EnlightenIris {
        let iris = try EnlightenIris(view: view, markdownFilename: markdownFilename, in: bundle)
        addSpotlight(iris: iris)
        return iris
    }

    /// Returns the iris for a view, if it exists.
    ///
    /// - Parameter view: The view to return the iris for.
    /// - Returns: The iris for `view`, or `nil` if no iris for that view has been added to the controller.
    open func iris(for view: NSView) -> EnlightenIris? {
        return irises.first(where: { return $0.view == view })
    }
}

// MARK: - Spotlight Navigation Methods

extension EnlightenSpotlightController {
    /// Animates the change to the next stage of the controller.
    ///
    /// Unlike `showNextSpotlight`, this method ensures the controller is presented and not already animating a
    /// stage change.
    public func navigateForward() {
        guard isPresenting, !isAnimating
            else { return }

        isAnimating = true
        showNextSpotlight()
    }

    /// Animates the change to the previous stage of the controller.
    ///
    /// Unlike `showPreviousSpotlight`, this method ensures the controller is presented and not already animating a
    /// stage change.
    public func navigateBackward() {
        guard isPresenting, !isAnimating
            else { return }

        isAnimating = true
        showPreviousSpotlight()
    }

    /// Animates the change to the next stage of the controller.
    ///
    /// - Note: This method should _rarely_ be called. The use of `navigateForward` is preferred.
    public func showNextSpotlight() {
        navigatingDirection = .forward

        if currentIris.hasNextStage {
            // Plus one because the internal index has not been incremented yet.
            delegate?.spotlightControllerWillShow?(stage: currentIris.currentStage + 1,
                                                   in: currentIris,
                                                   navigating: .forward)

            if let nextMarkdownString = currentIris.nextMarkdownString() {
                // Only need to update the popover.
                updatePopover(markdownString: nextMarkdownString)

                // Slight delay to prevent skipping stages.
                DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .milliseconds(500)) {
                    self.isAnimating = false
                }
                return
            }
        }

        guard currentIrisIndex + 1 < irises.count
            else { return dismiss() }

        previousIrisIndex = currentIrisIndex
        currentIrisIndex += 1

        currentIris.reset()

        delegate?.spotlightControllerWillShow?(stage: currentIris.currentStage,
                                               in: currentIris,
                                               navigating: .forward)

        updateSpotlight()
    }

    /// Animates the change to the previous stage of the controller.
    ///
    /// - Note: This method should _rarely_ be called. The use of `navigateForward` is preferred.
    public func showPreviousSpotlight() {
        navigatingDirection = .backward

        if currentIris.hasPreviousStage {
            // Minus one because the internal index has not been decremented yet.
            delegate?.spotlightControllerWillShow?(stage: currentIris.currentStage - 1,
                                                   in: currentIris,
                                                   navigating: .backward)

            if let previousMarkdownString = currentIris.previousMarkdownString() {
                // Only need to update the popover.
                updatePopover(markdownString: previousMarkdownString)

                // Slight delay to prevent skipping stages.
                DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .milliseconds(500)) {
                    self.isAnimating = false
                }
                return
            }
        }

        guard currentIrisIndex > 0 else {
            isAnimating = false
            return
        }

        previousIrisIndex = currentIrisIndex
        currentIrisIndex = max(0, currentIrisIndex - 1)

        delegate?.spotlightControllerWillShow?(stage: currentIris.currentStage,
                                               in: currentIris,
                                               navigating: .backward)

        updateSpotlight()
    }

    /// Animates the spotlight to match the controller's internal state.
    ///
    /// This method performs the transitions to the next (or previous) spotlight iris as specified by the internal
    /// state.
    func updateSpotlight() {
        if popover.isShown, previousFocusedView != focusedView {
            popover.close()
        }

        if isInitialIris {
            animateFocusingSpotlight()
        } else {
            animateUnfocusingSpotlight { self.animateFocusingSpotlight() }
        }
    }
}

// MARK: - Skip Button Methods

public extension EnlightenSpotlightController {
    /// Adds the skip button to the view hierarchy.
    func showSkipButton() {
        guard skipButton.superview == nil
            else { return }

        addSubviewToContentViewBelowSkipButton(skipButton)

        NSLayoutConstraint.activate([
            skipButton.topAnchor.constraint(equalTo: contentView!.topAnchor, constant: 8),
            contentView!.trailingAnchor.constraint(equalTo: skipButton.trailingAnchor, constant: 8)
            ])

        NSAnimationContext.runAnimationGroup { (context) in
            context.allowsImplicitAnimation = true
            context.duration = 1

            skipButton.isHidden = false
        }
    }

    /// The skip button's action method.
    @objc
    func skipButtonAction() {
        dismiss()
    }
}

// MARK: - Popover Methods

extension EnlightenSpotlightController {
    /// Updates the popover with a new CommonMark Markdown string.
    ///
    /// - Parameters:
    ///   - markdownString: A string containing CommonMark Markdown.
    ///   - waitForPopoverClosure: Whether to wait for the popover to close before updating the Markdown string.
    ///                            The default value is `false`.
    func updatePopover(markdownString: String, waitForPopoverClosure: Bool = false) {
        didFailToUpdateMarkdown = false

        // If only trying to update the content of a shown popover, but the stage has a different preferred edge.
        if !waitForPopoverClosure,
            let preferredEdge = currentIris.resolvedPreferredPopoverEdge,
            popover.preferredEdge != preferredEdge {
            popover.close()
            popover.preferredEdge = preferredEdge
            // Setting this property will cause the popover to be shown after it finished loading.
            popover.positioningRectForLoadingDownView = usesImageMask ? focusedView!.bounds : focusedViewFollowspotRect
            popover.update(markdownString: markdownString,
                           shouldCenterAlign: currentIris.resolvedDoesCenterAlignContent,
                           newMaxWidth: currentIris.resolvedPopoverMaxWidth,
                           waitForPopoverClosure: true)
        } else {
            popover.update(markdownString: markdownString,
                           shouldCenterAlign: currentIris.resolvedDoesCenterAlignContent,
                           newMaxWidth: currentIris.resolvedPopoverMaxWidth,
                           waitForPopoverClosure: waitForPopoverClosure)
        }
    }
}

// MARK: - Animation Methods

extension EnlightenSpotlightController {
    /// Updates the popover with the next Markdown string, animates the spotlight change from followspot to
    /// profile spot, and presents the popover.
    func animateFocusingSpotlight() {
        // Update the popover with the new content, waiting for it to close if necessary.
        updatePopover(markdownString: currentIris.currentMarkdownString, waitForPopoverClosure: true)

        if usesProfileSpot && followspotShape != .none {
            // If focusing on the view, update the mask image with the focused mask.
            // Note: `imageMaskView` is not currently in the view hierarchy.
            assert(imageMaskView.superview == nil || isInitialIris)
            imageMaskView.maskImage = createProfileSpotImageMask(for: currentIris)
        }

        if let focusAnimationGroup = currentIris.resolvedFocusAnimationGroup {
            let doesWaitForFocusAnimationCompletion = currentIris.doesWaitForFocusAnimationCompletion
            NSAnimationContext.runAnimationGroup({ context in
                focusAnimationGroup(context)

                let durationInMilliseconds: DispatchTimeInterval = .milliseconds(Int(1000 * context.duration))
                DispatchQueue.main.asyncAfter(deadline: .now() + durationInMilliseconds) { [weak self] in
                    if doesWaitForFocusAnimationCompletion {
                        self?.isAnimating = false
                    }
                }
            })
        }

        NSAnimationContext.runAnimationGroup({ (context) in
            context.allowsImplicitAnimation = true
            context.duration = profileSpotFocusDuration
            context.timingFunction = profileSpotFocusTimingFunction

            if followspotShape == .none {
                // Did not animate the spotlight transition, so just animate the mask image change.
                imageMaskView.maskImage = createProfileSpotImageMask(for: currentIris)
            } else if usesProfileSpot {
                // Animate the change from spotlight mask to image mask.
                addSubviewToContentViewBelowSkipButton(imageMaskView)
                animatableSpotlightView.removeFromSuperview()
            }
        }, completionHandler: showPopover)
    }

    /// Presents the popover.
    ///
    /// This method should only be called by `animateFocusingSpotlight` at the conclusion of a stage change.
    func showPopover() {
        defer {
            if !currentIris.shouldWaitForFocusAnimationCompletion {
                isAnimating = false
            }
        }

        // Make sure the controller was not dismissed during animation, and updating the Markdown string did not fail.
        guard isPresenting, !didFailToUpdateMarkdown
            else { return }

        if !currentIris.hasPreferredPopoverEdge {
            currentIris.cachedBestPopoverEdge = bestPopoverEdge(for: focusedView!)
        }

        // Okay to force unwrap here because we just set it above if it didn't have one.
        let preferredEdge = currentIris.resolvedPreferredPopoverEdge!
        if usesImageMask {
            popover.show(relativeTo: focusedView!.bounds, of: focusedView!, preferredEdge: preferredEdge)
        } else {
            popover.show(relativeTo: focusedViewFollowspotRect, in: contentView!, preferredEdge: preferredEdge)
        }
    }

    /// Animates the spotlight change from profile spot to followspot and the spotlight transition to the
    /// next (or previous) stage.
    ///
    /// - Parameter completionHandler: A closure called when the "unfocus" animations are completed.
    func animateUnfocusingSpotlight(completionHandler: @escaping () -> Void) {
        guard isPresenting, let currentlyfocusedView = previousFocusedView
            else { return }

        if let unfocusAnimationGroup = self.previousIris?.resolvedUnfocusAnimationGroup {
            NSAnimationContext.runAnimationGroup(unfocusAnimationGroup,
                                                 completionHandler: nil)
        }

        // If the `followspotShape` is `.none`, then there's no animated spotlight transition, so just call the
        // completion handler.
        guard followspotShape != .none
            else { return completionHandler() }

        NSAnimationContext.runAnimationGroup({ (context) in
            context.allowsImplicitAnimation = true
            context.duration = profileSpotFocusDuration

            if usesProfileSpot {
                // Crossfade animated switch from focused mask to spotlight mask.
                imageMaskView.maskImage = createFollowspotImageMask(for: currentlyfocusedView)
            }
            // Note: If `usesProfileSpot` is false, then this animation group will finish immediately (and not use the
            //       animation duration since no new values were set) and call the completion handler.
        }, completionHandler: {
            self.animateSpotlightTransition(completionHandler: completionHandler)
        })
    }

    /// Animates the spotlight transition from the currently focused view to the next (or previous) view.
    ///
    /// - Parameter completionHandler: A closure called when the transition animations are completed.
    func animateSpotlightTransition(completionHandler: @escaping () -> Void) {
        // The current spotlight rect (which is the previous one as we're within an unfocus operation).
        let currentSpotlightRect = previouslyFocusedViewFollowspotRect
        let nextSpotlightRect = focusedViewFollowspotRect

        // Prepare animated spotlight transition by focusing on the current view.
        animatableSpotlightView.spotlightLayer.focus(on: currentSpotlightRect)

        if usesProfileSpot {
            // Remove the image mask view.
            imageMaskView.removeFromSuperviewWithoutNeedingDisplay()
            // Add the animatable spotlight view for the upcoming transition.
            // Note: The image mask and animatable spotlight view have the same spotlight, so this switch is visually
            //       unnoticeable.
            addSubviewToContentViewBelowSkipButton(animatableSpotlightView)
            // Reset the image mask.
            imageMaskView.maskImage = nil
        }

        /// For some reason beyond my comprehension, the layer's `display` is called initally without a presentation
        /// layer when `usesProfileSpot` is true, which causes it to draw the spotlight rect at it's final location
        /// (the model's value). This property prevents that from happening.
        animatableSpotlightView.spotlightLayer.isAnimating = true

        // The spotlight transition animation from the current spotlight frame to the following one.
        CATransaction.begin()
        CATransaction.setAnimationDuration(self.followspotTransitionDuration)
        CATransaction.setAnimationTimingFunction(self.followspotTransitionTimingFunction)
        CATransaction.setCompletionBlock({
            self.animatableSpotlightView.spotlightLayer.isAnimating = false
            completionHandler()
        })

        animatableSpotlightView.spotlightLayer.spotlightFrame = nextSpotlightRect

        CATransaction.commit()
    }
}

// MARK: - Resettable

extension EnlightenSpotlightController: Resettable {
    func reset() {
        currentIrisIndex = 0
        previousIrisIndex = 0
        navigatingDirection = .initial

        currentIris.reset()
    }
}

// MARK: - Enlighten Popover Delegate

extension EnlightenSpotlightController: EnlightenPopoverDelegate {
    public func enlightenPopoverFailedToLoad(downError: Error) -> String? {
        let backupString = delegate?.spotlightControllerFailedToLoad?(markdownString: currentIris.currentMarkdownString,
                                                                      for: currentIris,
                                                                      with: downError)
        if let backupString = backupString {
            currentIris.stages[currentIris.currentStageIndex].markdownString = backupString
            updatePopover(markdownString: backupString)
        } else {
            didFailToUpdateMarkdown = true

            switch navigatingDirection {
            case .forward, .initial:
                showNextSpotlight()
            case .backward:
                showPreviousSpotlight()
            }
        }

        return nil
    }
}

// MARK: - Image Mask Creation Methods

extension EnlightenSpotlightController {
    /// Creates a profile spot image mask for an iris.
    ///
    /// - Parameter iris: The iris to create the image mask for.
    /// - Returns: The profile spot image mask.
    func createProfileSpotImageMask(for iris: EnlightenIris) -> NSImage {
        let spotlightView = iris.view

        var viewMaskImageDrawingHandler: (NSRect) -> Bool
        if let drawingHandler = iris.resolvedProfileSpotDrawingHandler {
            viewMaskImageDrawingHandler = { (drawingRect) -> Bool in
                drawingHandler(drawingRect, NSGraphicsContext.current!.cgContext)
                return true
            }
        } else {
            if !spotlightView.wantsLayer {
                spotlightView.wantsLayer = true
            }

            spotlightView.layer!.setNeedsDisplay()
            viewMaskImageDrawingHandler = { (_) -> Bool in
                spotlightView.layer!.render(in: NSGraphicsContext.current!.cgContext)
                return true
            }
        }

        let viewMaskImage = NSImage(size: spotlightView.bounds.size,
                                    flipped: true,
                                    drawingHandler: viewMaskImageDrawingHandler)
        let maskImage = NSImage(size: contentViewFrame.size, flipped: false) { (drawingRect) -> Bool in
            drawingRect.fill()
            viewMaskImage.draw(in: spotlightView.frameInWindow,
                               from: .zero,
                               operation: .destinationOut,
                               fraction: 1,
                               respectFlipped: true,
                               hints: nil)
            return true
        }

        return maskImage
    }

    /// Creates a followspot image mask for a view.
    ///
    /// - Parameter view: The view to create the image mask for.
    /// - Returns: The followspot image mask.
    func createFollowspotImageMask(for view: NSView) -> NSImage {
        let spotlightRect = view.frameInWindow.circumscribingEllipse(eccentricity: isFollowspotShapeEllipse)

        return NSImage(size: contentViewFrame.size, flipped: false) { (drawingRect) -> Bool in
            let cgContext = NSGraphicsContext.current!.cgContext

            drawingRect.fill()
            cgContext.addEllipse(in: spotlightRect)
            cgContext.setBlendMode(.clear)
            cgContext.fillEllipse(in: spotlightRect)
            return true
        }
    }
}

// MARK: - Notification Center Observation Methods

extension EnlightenSpotlightController {
    @objc
    func didChangeContentViewFrame() {
        if followspotShape == .none || usesProfileSpot {
            imageMaskView.maskImage = createProfileSpotImageMask(for: currentIris)
        } else {
            // Otherwise, we're not using an image mask.
            let spotlightRect = focusedViewFollowspotRect
            animatableSpotlightView.spotlightLayer.spotlightFrame = spotlightRect

            if popover.isShown {
                // Need to update the position of the popover ourselves because the positioning view is the window's
                // content view.
                popover.updatePositionIfShown(to: spotlightRect)
            }
        }
    }
}

// MARK: - Local Event Monitor Methods

extension EnlightenSpotlightController {
    @objc
    func ignoreEvent(_ event: NSEvent) -> NSEvent? {
        // Ignore all events for the popover window.
        guard event.window != popover.contentViewController?.view.window
            else { return nil }

        // Forward all events that don't belong to the presentation window.
        guard event.window == presentationWindow
            else { return event }

        // Forward `.appKitDefined` event types and any events inside the window's title bar.
        guard event.type != .appKitDefined,
            !event.isMouseInsideTitleBar
            else { return event }
        return nil
    }

    @objc
    func handle(mouseDown event: NSEvent) -> NSEvent? {
        // Make sure the app is active.
        guard NSApp.isActive else {
            return event
        }

        if event.window == presentationWindow {
            // Make sure the mouse down event is not for the title bar, nor the window
            // edge (drag), nor the skip button. Otherwise, forward it.
            guard skipButton.hitTest(event.locationInWindow) == nil,
                !event.isMouseInsideTitleBar
                else { return event }
        }

        if event.clickCount >= 2 {
            showSkipButton()
        }

        navigateForward()

        return nil
    }

    @objc
    func handle(keyDown event: NSEvent) -> NSEvent? {
        defer {
            lastKeyDownEventTimestamp = event.timestamp
        }

        var isButtonSmashing = false
        if let lastTimestamp = lastKeyDownEventTimestamp, lastTimestamp.distance(to: event.timestamp) < 0.5 {
            isButtonSmashing = true
        }

        if event.isARepeat || isAnimating || isButtonSmashing {
            showSkipButton()
        }

        if let specialKey = event.specialKey {
            switch specialKey {
            case .leftArrow, .delete, .backTab, .downArrow:
                navigateBackward()
                return nil
            case .rightArrow, .carriageReturn, .upArrow, .tab:
                navigateForward()
                return nil
            default: ()
            }
        } else if event.charactersIgnoringModifiers == " " {
            navigateForward()
            return nil
        } else if event.keyCode == 53 {
            // Escape key pressed.
            showSkipButton()
            return nil
        } else if event.modifierFlags.isDisjoint(with: .deviceIndependentFlagsMask) {
            // Ignore other single key presses.
            return nil
        }

        return event
    }
}

// MARK: - Helper Methods

extension EnlightenSpotlightController {
    /// Adds a subview—below the skip button, if it is in the view hierarchy—to the presentation window's content view.
    /// Optionally, animating the insertion.
    ///
    /// - Parameters:
    ///   - subview: The view to add to the presentation window's content view.
    ///   - animating: Whether to animate the insertion.
    ///   - animationCompletionHandler: A closure called when the animation is completed.
    func addSubviewToContentViewBelowSkipButton(_ subview: NSView,
                                                animating: Bool = false,
                                                animationCompletionHandler: (() -> Void)? = nil) {
        let position: NSWindow.OrderingMode
        let relativeView: NSView?

        if skipButton.superview == nil {
            position = .above
            relativeView = nil
        } else {
            position = .below
            relativeView = skipButton
        }

        if animating {
            subview.alphaValue = 0
            contentView?.addSubview(subview, positioned: position, relativeTo: relativeView)

            NSAnimationContext.runAnimationGroup({ (context) in
                context.allowsImplicitAnimation = true
                context.duration = presentationAnimationDuration

                subview.animator().alphaValue = 1
            }, completionHandler: animationCompletionHandler)
        } else {
            contentView?.addSubview(subview, positioned: position, relativeTo: relativeView)
            animationCompletionHandler?()
        }
    }

    func createLocalEventMonitors() {
        let ignoreEventMask = NSEvent.EventTypeMask.any.symmetricDifference([.leftMouseDown, .keyDown])
        addLocalMonitorForEvents(matching: ignoreEventMask, handler: ignoreEvent(_:))
        addLocalMonitorForEvents(matching: .leftMouseDown, handler: handle(mouseDown:))
        addLocalMonitorForEvents(matching: .keyDown, handler: handle(keyDown:))
    }

    func addLocalMonitorForEvents(matching mask: NSEvent.EventTypeMask,
                                  handler block: @escaping (NSEvent) -> NSEvent?) {
        localEventMonitors.append(NSEvent.addLocalMonitorForEvents(matching: mask, handler: block))
    }

    /// A heuristic method for determining the best anchor edge for a view.
    ///
    /// The edge insets of the view within its window are used to determine the _best_ edge.
    ///
    /// - Parameter anchoringView: The anchoring view.
    /// - Returns: The best anchoring edge for the view.
    func bestPopoverEdge(for anchoringView: NSView) -> NSRectEdge {
        // swiftlint:disable:previous cyclomatic_complexity

        guard let quadrant = anchoringView.windowQuadrant,
            let window = anchoringView.window
            else { return .above }

        let preferVertical: CGFloat = 15
        let padding = anchoringView.edgeInsetsFromWindow()

        assert(padding.bottom + anchoringView.frame.height + padding.top == window.frame.size.height)
        assert(padding.left + anchoringView.frame.width + padding.right == window.frame.size.width)

        var bestEdge: NSRectEdge
        switch quadrant {
        case .center:
            if padding.top > padding.bottom + preferVertical {
                // More room below the view.
                bestEdge = .below
            } else {
                // More room above the view.
                bestEdge = .above
            }
        case .topRight:
            if padding.left > padding.bottom + preferVertical {
                // More room left of the view.
                bestEdge = .left
            } else {
                // More room below the view.
                bestEdge = .below
            }
        case .topLeft:
            if padding.right > padding.bottom + preferVertical {
                // More room right of the view.
                bestEdge = .right
            } else {
                // More room below the view.
                bestEdge = .below
            }
        case .bottomLeft:
            if padding.right > padding.top + preferVertical {
                // More room right of the view.
                bestEdge = .right
            } else {
                // More room above the view.
                bestEdge = .above
            }
        case .bottomRight:
            if padding.left > padding.top + preferVertical {
                // More room left of the view.
                bestEdge = .left
            } else {
                // More room above the view.
                bestEdge = .above
            }
        }

        if usesImageMask && anchoringView.isFlipped {
            bestEdge = bestEdge.inFlippedCoordinateSystem
        }

        return bestEdge
    }
}

// MARK: - Testing Methods

extension EnlightenSpotlightController {
    /// Validates that each Markdown string in the controller can be loaded.
    ///
    /// - Throws: A `EnlightenError.failedToValidate(markdownString:error:)` error if a Markdown string cannot
    ///           be loaded.
    open func validateMarkdownStrings() throws {
        #if DEBUG
        for iris in irises {
            for stage in iris.stages {
                do {
                    try popover.popoverContentViewController.downView.update(markdownString: stage.markdownString)
                } catch {
                    throw EnlightenError.failedToValidate(markdownString: stage.markdownString, error: error)
                }
            }
        }
        #endif
    }
}
