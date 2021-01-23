//
//  EnlightenPopoverContentViewController.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 10/29/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa
import WebKit
import Down

/// A view controller that manages a `EnlightenDownView` for the content of a popover.
open class EnlightenPopoverContentViewController: NSViewController {

    // MARK: Public Stored Properties

    /// The progress indicator shown when loading the web view resources takes longer than `progressIndicatorDelay`.
    public let progressIndicator: NSProgressIndicator

    /// The popover's `EnlightenPopoverDelegate` delegate.
    public weak var enlightenPopoverDelegate: EnlightenPopoverDelegate?
    /// The duration, in seconds, to delay showing the progress indicator.
    public var progressIndicatorDelay: TimeInterval = 0.5
    /// Whether the content is detached from the popover.
    public private(set) var isDetachedFromPopover: Bool = false {
        didSet { downView.mouseDragShouldMoveWindow = isDetachedFromPopover }
    }

    // MARK: Public Computed Properties

    /// The `EnlightenDownView` owned by the view controller.
    public var downView: EnlightenDownView {
        // If this fails, we got bigger fish to fry. 🍳
        // swiftlint:disable:next force_cast
        return view as! EnlightenDownView
    }

    /// Whether the Markdown content should be center aligned.
    public var doesCenterAlignContent: Bool {
        get { return downView.doesCenterAlignContent }
        set { downView.doesCenterAlignContent = newValue }
    }

    // MARK: Internal Stored Properties

    /// The timer that calls the progress indicator presentation method.
    var progressIndicatorTimer: Timer?

    // MARK: - Initializers

    /// Initializes a newly allocated Enlighten popover content view controller.
    ///
    /// - Parameters:
    ///   - markdownString: The Markdown string rendered in the `EnlightenDownView`.
    ///   - maxWidth: The maximum width of the `EnlightenDownView`.
    ///   - maxHeight: The maximum height of the `EnlightenDownView`.
    /// - Throws: Throws a `DownErrors` if loading the Markdown string fails.
    public init(markdownString: String,
                options: EnlightenMarkdownOptions = .default,
                maxWidth: CGFloat,
                maxHeight: CGFloat = 500) throws {
        progressIndicator = NSProgressIndicator()

        super.init(nibName: nil, bundle: nil)

        let configuration = WKWebViewConfiguration()
        if #available(OSX 10.13, *) {
            configuration.setURLSchemeHandler(self, forURLScheme: Constants.urlScheme)
        }

        view = try EnlightenDownView(frame: NSRect(origin: .zero, size: CGSize(width: maxWidth, height: 0)),
                                     markdownString: markdownString,
                                     openLinksInBrowser: true,
                                     configuration: configuration,
                                     options: options,
                                     didLoadSuccessfully: didDownViewLoadSuccessfully)
        downView.maxHeight = maxHeight

        progressIndicator.style = .spinning
        progressIndicator.controlSize = .small
        progressIndicator.isIndeterminate = true
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout Methods

    /// Resets the size of the view to the maximum.
    ///
    /// - Parameter includingHeight: Whether to also reset the height to the maximum.
    open func resetMaxSize(includingHeight: Bool) {
        downView.resetMaxSize(includingHeight: includingHeight)
    }

    // MARK: - Progress Indicator Methods

    /// Shows the progress indicator, if the view controller's view is in the view hierarchy.
    @objc
    open func showProgressIndicator() {
        if progressIndicator.superview == nil, let superview = view.superview {
            progressIndicator.startAnimation(nil)
            superview.animator().addSubview(progressIndicator)

            NSLayoutConstraint.activate([
                progressIndicator.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
                progressIndicator.centerYAnchor.constraint(equalTo: superview.centerYAnchor)
                ])
        }
    }

    /// Starts the timer that presents the progress indicator after `progressIndicatorDelay`.
    open func delayShowingProgressIndicator() {
        if let progressIndicatorTimer = progressIndicatorTimer, progressIndicatorTimer.isValid {
            return
        }

        progressIndicatorTimer?.invalidate()
        progressIndicatorTimer = Timer.scheduledTimer(timeInterval: progressIndicatorDelay,
                                                      target: self,
                                                      selector: #selector(showProgressIndicator),
                                                      userInfo: nil,
                                                      repeats: false)
    }

    /// Hides the progress indicator, if it is in the view hierarchy, and invalidates the progress indicator
    /// presentation timer.
    open func hideProgressIndicator() {
        progressIndicatorTimer?.invalidate()
        progressIndicator.animator().removeFromSuperview()
        progressIndicator.stopAnimation(nil)
    }

    // MARK: - Markdown Methods

    /// Renders the given CommonMark Markdown string into HTML and updates the `EnlightenDownView` while keeping the
    /// style intact.
    ///
    /// - Important: Errors thrown during the loading of the Markdown string are passed to the delegate's
    ///              `EnlightenPopoverDelegate.enlightenPopoverFailedToLoad(downError:)` method.
    ///
    /// - Parameters:
    ///   - markdownString: A string containing CommonMark Markdown.
    open func update(markdownString: String, options: EnlightenMarkdownOptions? = nil) {
        downView.isFinalWidth = false

        delayShowingProgressIndicator()

        do {
            try downView.update(markdownString: markdownString,
                                options: options,
                                didLoadSuccessfully: didDownViewLoadSuccessfully)
        } catch {
            if let replacementString = enlightenPopoverDelegate?.enlightenPopoverFailedToLoad?(downError: error) {
                update(markdownString: replacementString, options: options)
            } else {
                hideProgressIndicator()
            }
        }
    }

    /// Called when the Markdown string was loaded successfully.
    open func didDownViewLoadSuccessfully() {
        if isDetachedFromPopover {
            downView.setBodyTopMargin(to: 23)
        }

        hideProgressIndicator()
        downView.layout()
    }

    // MARK: - Popover Notification Methods

    /// Invoked when the popover has been released to a detached state.
    open func didDetachFromPopover() {
        isDetachedFromPopover = true
        downView.setBodyTopMargin(to: 23)
    }

    open func didReattachPopover() {
        isDetachedFromPopover = false
        downView.resetBodyTopMargin()
    }

    /// Invoked when the popover did close.
    open func didClosePopover() {
        isDetachedFromPopover = false
        downView.resetBodyTopMargin()
        downView.needsLayout = true
    }
}

// MARK: - URL Scheme Handler Methods

@available(OSX 10.13, *)
extension EnlightenPopoverContentViewController: WKURLSchemeHandler {
    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        // Note: Since the URL isn't actually loading a resource, we fail with an irrelevant error.
        urlSchemeTask.didFailWithError(NSError(domain: "Ignore", code: 0))

        if let url = urlSchemeTask.request.url {
            enlightenPopoverDelegate?.enlightenPopover?(didClickEnlighten: url)
        }
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}
