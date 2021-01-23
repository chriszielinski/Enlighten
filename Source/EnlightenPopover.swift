//
//  EnlightenPopover.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 10/25/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

import Down

/// A sizeable, detachable, and fitting, popover that renders a Markdown string.
open class EnlightenPopover: NSPopover, NSPopoverDelegate {

    // MARK: Public Stored Properties

    /// The view relative to which the popover should be positioned.
    public weak var positioningView: NSView?
    /// The edge of `positioningView` the popover should prefer to be anchored to.
    public var preferredEdge: NSRectEdge?
    /// Whether the popover is fitted within `positioningView`'s window.
    public var fitInWindow: Bool = false
    /// The padding between the popover and window frame when `fitInWindow` is true.
    public var windowInnerPadding: CGFloat = 10
    /// Whether the popover is detachable.
    public var canDetach: Bool = false
    /// The maximum width of the popover.
    public var maxWidth: CGFloat {
        didSet { popoverContentViewController.downView.maxWidth = maxWidth }
    }

    // MARK: Public Computed Properties

    /// The popover's content view controller.
    public var popoverContentViewController: EnlightenPopoverContentViewController {
        // If this fails, we got bigger fish to fry. 🍳
        // swiftlint:disable:next force_cast
        return contentViewController as! EnlightenPopoverContentViewController
    }
    /// The popover's `EnlightenPopoverDelegate` delegate.
    public var enlightenPopoverDelegate: EnlightenPopoverDelegate? {
        get { return popoverContentViewController.enlightenPopoverDelegate }
        set { popoverContentViewController.enlightenPopoverDelegate = newValue }
    }
    /// The maximum height of the popover.
    ///
    /// Scrolling is enabled if the `EnlightenDownView` exceeds the maximum height.
    public var maxHeight: CGFloat {
        get { return popoverContentViewController.downView.maxHeight }
        set { popoverContentViewController.downView.maxHeight = newValue }
    }
    /// Whether the Markdown content should be center aligned.
    public var doesCenterAlignContent: Bool {
        get { return popoverContentViewController.doesCenterAlignContent }
        set { popoverContentViewController.doesCenterAlignContent = newValue }
    }

    // MARK: Internal Stored Properties

    /// When non-nil, this property stores the positioning rectangle of a popover awaiting presentation.
    var positioningRectForLoadingDownView: NSRect?
    var setMaxWidthAfterClosing: CGFloat?
    var setDoesCenterAlignAfterClosing: Bool?

    // MARK: Private Stored Properties

    /// The positioning rectangle in window coordinates.
    ///
    /// Only used if `fitInWindow` is true.
    private var positioningRectInWindow: CGRect = .zero
    /// When non-nil, this property stores the Markdown string used to update the `EnlightenDownView` once the popover
    /// is closed.
    private var popoverUpdateMarkdown: (EnlightenMarkdownOptions?, String)?
    /// The observation object observing the content view controller's `EnlightenDownView`'s `isWidthFinal` property.
    private var downViewIsWidthFinalObservation: NSKeyValueObservation!
    /// The observation object observing the popover's `isShown` property.
    private var popoverIsShownObservation: NSKeyValueObservation!
    /// The observation object observing the popover close button layer's `opacity` property.
    private var closeButtonOpacityObservation: NSKeyValueObservation?

    // MARK: Private Computed Properties

    /// Whether the popover needs to be shown.
    private var needsToShowPopover: Bool {
        return positioningRectForLoadingDownView != nil
    }

    // MARK: - Initializers

    /// Initializes a newly allocated Enlighten popover.
    ///
    /// - Parameters:
    ///   - markdownString: The Markdown string rendered in the popover.
    ///   - maxWidth: The maximum width of the popover.
    ///   - maxHeight: The maximum height of the popover.
    /// - Throws: Throws a `DownErrors` if loading the Markdown string fails.
    public init(markdownString: String,
                options: EnlightenMarkdownOptions = .default,
                maxWidth: CGFloat,
                maxHeight: CGFloat = 500) throws {
        self.maxWidth = maxWidth

        super.init()

        contentViewController = try EnlightenPopoverContentViewController(markdownString: markdownString,
                                                                          options: options,
                                                                          maxWidth: maxWidth,
                                                                          maxHeight: maxHeight)
        behavior = .transient

        downViewIsWidthFinalObservation = popoverContentViewController.downView
            .observe(\.isFinalWidth, changeHandler: didChangeIsWidthFinal)
        popoverIsShownObservation = observe(\.isShown, changeHandler: didChangeIsShown)
    }

    public convenience init(options: EnlightenMarkdownOptions = .default,
                            maxWidth: CGFloat,
                            maxHeight: CGFloat = 500) {
        // Note: Will never fail because the Markdown string is empty, so no errors will ever be thrown.
        // swiftlint:disable:next force_try
        try! self.init(markdownString: "", options: options, maxWidth: maxWidth, maxHeight: maxHeight)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout Methods

    /// Resets the width of the popover's `EnlightenDownView`.
    ///
    /// Used during a Markdown string update.
    open func resetDownViewWidth() {
        popoverContentViewController.resetMaxSize(includingHeight: false)
    }

    /// Resets the width of the popover's content and `EnlightenDownView` to the original maximum width.
    ///
    /// Used during a Markdown string update.
    open func resetWidth() {
        popoverContentViewController.downView.maxWidth = maxWidth
        resetDownViewWidth()
        contentSize = popoverContentViewController.downView.frame.size
    }

    /// Resizes the popover's content size so that it is the minimum size needed to contain its `EnlightenDownView`.
    ///
    /// If the `fitInWindow` property is true, this method will attempt to fit the `EnlightenDownView` within the
    /// window frame.
    open func sizeToFit() {
        var newSize = popoverContentViewController.downView.intrinsicContentSize

        guard newSize != .zero
            else { return }

        let popoverArrowWidth: CGFloat = 14
        if fitInWindow,
            let edge = preferredEdge,
            let positioningView = positioningView,
            let window = positioningView.window {

            var newWidth: CGFloat?
            let padding = window.edgeInsetsFromWindow(of: positioningRectInWindow)
            switch edge {
            case .left where newSize.width + popoverArrowWidth >= padding.left:
                newWidth = padding.left - popoverArrowWidth - windowInnerPadding
            case .right where newSize.width + popoverArrowWidth >= padding.right:
                newWidth = padding.right - popoverArrowWidth - windowInnerPadding
            case .below, .above:
                if newSize.width >= window.frame.width {
                    newWidth = window.frame.width - (2 * windowInnerPadding)
                }
            default: ()
            }

            if let newWidth = newWidth {
                newSize.width = newWidth
                if newWidth != popoverContentViewController.downView.frame.width {
                    // The DownView's width is not equal to `newWidth`.
                    popoverContentViewController.downView.isFinalWidth = false
                    popoverContentViewController.downView.maxWidth = newWidth
                    popoverContentViewController.downView.needsLayout = true
                }
            }
        }

        contentSize = newSize

        /// Weird sizing behavior arises after numerous consecutive & interrrupted detatch/reattach cycles.
        /// This will resync the height.
        DispatchQueue.main.async {
            self.popoverContentViewController.downView.window?.setContentSize(self.contentSize)
        }
    }

    /// Updates the positioning rectangle of a shown popover.
    ///
    /// Note: The popover's position only needs to be updated programmatically if `show(relativeTo:in:preferredEdge:)`
    /// was used to present the popover.
    ///
    /// - Parameter positioningRect: The new positioning rectangle for the popover.
    open func updatePositionIfShown(to positioningRect: NSRect) {
        guard isShown, let positioningView = positioningView, let preferredEdge = preferredEdge
            else { return }
        positioningRectInWindow = positioningRect
        showLoaded(relativeTo: positioningRect, of: positioningView, preferredEdge: preferredEdge)
    }

    // MARK: - Presentation Methods

    /// Presents the popover if needed.
    ///
    /// This is determined by the `needsToShowPopover` property and ensures the Markdown has finished loading.
    ///
    open func showPopoverIfNeeded() {
        if !isShown,
            needsToShowPopover,
            !popoverContentViewController.downView.isLoading,
            let positioningRect = positioningRectForLoadingDownView,
            let positioningView = positioningView,
            let preferredEdge = preferredEdge {

            showLoaded(relativeTo: positioningRect, of: positioningView, preferredEdge: preferredEdge)
            positioningRectForLoadingDownView = nil
        }
    }

    /// Shows the popover anchored to the specified view. Uses a heuristic method to determine the best anchoring edge.
    ///
    /// - Parameter positioningView: The anchoring view.
    open func show(relativeTo positioningView: NSView) {
        show(relativeTo: positioningView.bounds,
             of: positioningView,
             preferredEdge: bestEdge(for: positioningView))
    }

    /// Shows the popover anchored to a positioning frame in a content view.
    ///
    /// If the popover's Markdown content is not loaded, will wait for it to finish before showing the popover.
    ///
    /// - Parameters:
    ///   - positioningRectInWindow: The rectangle within `contentView` relative to which the popover should be
    ///                              positioned.
    ///   - contentView: The window content view relative to which the popover should be positioned.
    ///   - preferredEdge: The edge of `positioningRectInWindow` the popover should prefer to be anchored to.
    open func show(relativeTo positioningRectInWindow: NSRect, in contentView: NSView, preferredEdge: NSRectEdge) {
        self.positioningRectInWindow = positioningRectInWindow
        self.positioningView = contentView
        self.preferredEdge = preferredEdge

        sizeToFit()

        if popoverContentViewController.downView.isLoading {
            positioningRectForLoadingDownView = positioningRectInWindow
        } else {
            showLoaded(relativeTo: positioningRectInWindow, of: contentView, preferredEdge: preferredEdge)
        }
    }

    /// Shows the popover anchored to the specified view.
    ///
    /// Unlike the other presentation methods, this one shows the popover regardless of the popover's content loading
    /// state .
    ///
    /// - Parameters:
    ///   - positioningRect: The rectangle within positioningView relative to which the popover should be positioned.
    ///   - positioningView: The view relative to which the popover should be positioned.
    ///   - preferredEdge: The edge of positioningView the popover should prefer to be anchored to.
    open func showLoaded(relativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge) {
        positioningRectForLoadingDownView = nil

        let currentFirstResponder = positioningView.window?.firstResponder
        super.show(relativeTo: positioningRect, of: positioningView, preferredEdge: preferredEdge)

        if let currentFirstResponder = currentFirstResponder {
            // Restore the original first responder. Necessary in case there are active selections in the view.
            // If we don't return first responder status to the original responder, it may draw itself inactive,
            // which we don't want.
            positioningView.window?.makeFirstResponder(currentFirstResponder)
        }
    }

    // MARK: - Markdown Methods

    /// Renders the given CommonMark Markdown string into HTML, updates the `EnlightenDownView` while keeping the style
    /// intact, and resizes the popover's content size.
    ///
    /// - Important: Errors thrown during the loading of the Markdown string are passed to the delegate's
    ///              `EnlightenPopoverDelegate.enlightenPopoverFailedToLoad(downError:)` method.
    ///
    /// - Parameters:
    ///   - markdownString: A string containing CommonMark Markdown.
    ///   - shouldCenterAlign: Whether the Markdown content should be center aligned.
    ///   - newMaxWidth: The new max width of the popover.
    ///   - waitForPopoverClosure: Whether to wait for the popover to close before updating.
    ///                            The default value is `false`.
    open func update(markdownString: String,
                     options: EnlightenMarkdownOptions? = nil,
                     shouldCenterAlign: Bool? = nil,
                     newMaxWidth: CGFloat? = nil,
                     waitForPopoverClosure: Bool = false) {
        var animationDuration: TimeInterval = 0

        if waitForPopoverClosure {
            guard !isShown else {
                popoverUpdateMarkdown = (options, markdownString)
                setDoesCenterAlignAfterClosing = shouldCenterAlign
                setMaxWidthAfterClosing = newMaxWidth
                return
            }
        } else if isShown {
            // The default animation duration.
            animationDuration = 0.25
        }

        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = animationDuration
            popoverContentViewController.downView.animator().alphaValue = 0
        }, completionHandler: {
            if let newMaxWidth = newMaxWidth {
                self.maxWidth = newMaxWidth
            }

            if self.isShown {
                self.resetDownViewWidth()
            } else {
                self.resetWidth()
            }

            if let shouldCenterAlign = shouldCenterAlign {
                self.doesCenterAlignContent = shouldCenterAlign
            }

            self.popoverContentViewController.update(markdownString: markdownString, options: options)
        })
    }

    // MARK: - Helper Methods

    /// A heuristic method for determining the best anchor edge for a view.
    ///
    /// The window quadrant the view is located in is used to determine the _best_ edge.
    ///
    /// - Parameter view: The anchoring view.
    /// - Returns: The best anchoring edge for the view.
    open func bestEdge(for view: NSView) -> NSRectEdge {
        guard let quadrant = view.window?.screenQuadrant(of: view.convert(view.bounds.center, to: nil))
            else { return .above }

        switch quadrant {
        case .center:
            return .below
        case .topRight:
            return .left
        case .topLeft:
            return .right
        case .bottomLeft:
            return .right
        case .bottomRight:
            return .left
        }
    }

    // MARK: - Popover Delegate Methods

    open func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return canDetach
    }

    open func popoverWillShow(_ notification: Notification) {
        if closeButtonOpacityObservation == nil,
            canDetach,
            let closeButton = contentViewController?.view.superview?.value(forKey: "closeButton") as? NSButton {
            closeButtonOpacityObservation = closeButton.layer?.observe(\.opacity, changeHandler: didChangeOpacity)
        }
    }

    open func popoverDidClose(_ notification: Notification) {
        popoverContentViewController.didClosePopover()
    }

    // MARK: - Overridden Methods

    /// Shows the popover anchored to the specified view.
    ///
    /// If the popover's Markdown content is not loaded, will wait for it to finish before showing the popover.
    ///
    /// - Parameters:
    ///   - positioningRect: The rectangle within positioningView relative to which the popover should be positioned.
    ///   - positioningView: The view relative to which the popover should be positioned.
    ///   - preferredEdge: The edge of positioningView the popover should prefer to be anchored to.
    override open func show(relativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge) {
        self.positioningRectInWindow = positioningView.convert(positioningRect, to: nil)
        self.positioningView = positioningView
        self.preferredEdge = preferredEdge

        sizeToFit()

        if popoverContentViewController.downView.isLoading {
            positioningRectForLoadingDownView = positioningRect
        } else {
            showLoaded(relativeTo: positioningRect, of: positioningView, preferredEdge: self.preferredEdge!)
        }
    }

    override open func close() {
        self.preferredEdge = nil

        super.close()
    }
}

// MARK: - Observation Methods

extension EnlightenPopover {
    func didChangeIsWidthFinal(of downView: EnlightenDownView, observedChange: NSKeyValueObservedChange<Bool>) {
        if downView.isFinalWidth {
            sizeToFit()
            showPopoverIfNeeded()

            // Does nothing if the `DownView` was not part of an animated update.
            downView.animator().alphaValue = 1
        }
    }

    func didChangeIsShown(of popover: EnlightenPopover,
                          observedChange: NSKeyValueObservedChange<Bool>) {
        if let (options, markdownString) = popoverUpdateMarkdown, !isShown {
            popoverUpdateMarkdown = nil
            update(markdownString: markdownString,
                   options: options,
                   shouldCenterAlign: setDoesCenterAlignAfterClosing ?? false,
                   newMaxWidth: setMaxWidthAfterClosing,
                   waitForPopoverClosure: false)
        }
    }

    func didChangeOpacity(of closeButtonLayer: CALayer,
                          observedChange: NSKeyValueObservedChange<Float>) {
        let wasAnimated = animates
        animates = false

        if closeButtonLayer.opacity == 1 {
            popoverContentViewController.didDetachFromPopover()
            sizeToFit()
            animates = wasAnimated
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self] in
                if closeButtonLayer.opacity == 0 {
                    self?.popoverContentViewController.didReattachPopover()
                    self?.sizeToFit()
                    self?.animates = wasAnimated
                } else {
                    /// The layer opacity is being reanimated to a non-zero value, so no need to call
                    /// `popoverCloseButtonFinished(restoreAnimates:)`.
                }
            }
        }
    }
}
