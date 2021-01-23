//
//  EnlightenHelpButton.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 10/29/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

import Down

/// A help button that displays a popover with app-specific help documentation rendered from a
/// CommonMark Markdown string.
open class EnlightenHelpButton: NSButton {

    // MARK: Public Stored Properties

    /// The `EnlightenPopover` owned by this help button.
    public var enlightenPopover: EnlightenPopover!

    /// The maximum width of the popover.
    @IBInspectable
    public var popoverWidth: CGFloat = 200 {
        didSet { enlightenPopover.maxWidth = popoverWidth }
    }
    /// The maximum height of the popover.
    ///
    /// Scrolling is enabled if the EnlightenDownView exceeds the maximum height.
    @IBInspectable
    public var popoverMaxHeight: CGFloat = 200 {
        didSet { enlightenPopover.maxHeight = popoverMaxHeight }
    }

    // MARK: Public Computed Properties

    /// The popover's `EnlightenPopoverDelegate` delegate.
    public var enlightenPopoverDelegate: EnlightenPopoverDelegate? {
        get { return enlightenPopover.enlightenPopoverDelegate }
        set { enlightenPopover.enlightenPopoverDelegate = newValue }
    }
    /// Whether the popover is detachable.
    public var canDetachPopover: Bool {
        get { return enlightenPopover.canDetach }
        set { enlightenPopover.canDetach = newValue }
    }
    /// Whether the Markdown content should be center aligned.
    public var doesCenterAlignContent: Bool {
        get { return enlightenPopover.doesCenterAlignContent }
        set { enlightenPopover.doesCenterAlignContent = newValue }
    }

    // MARK: - Initializers

    /// Initializes a newly allocated Enlighten help button.
    ///
    /// - Parameters:
    ///   - markdownString: The Markdown string rendered in the popover.
    ///   - maxWidth: The maximum width of the popover.
    ///   - maxHeight: The maximum height of the popover.
    /// - Throws: Throws a `DownErrors` if loading the Markdown string fails.
    public init(markdownString: String = "",
                options: EnlightenMarkdownOptions = .default,
                maxWidth: CGFloat? = nil,
                maxHeight: CGFloat? = nil) throws {
        super.init(frame: .zero)

        if let width = maxWidth {
            popoverWidth = width
        }

        if let maxHeight = maxHeight {
            popoverMaxHeight = maxHeight
        }

        try commonInit(markdownString: markdownString, options: options)
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)

        // Note: Will never fail because the Markdown string is empty, so no errors will/could ever be thrown.
        // swiftlint:disable:next force_try
        try! commonInit(markdownString: "", options: .default)
    }

    open func commonInit(markdownString: String, options: EnlightenMarkdownOptions) throws {
        enlightenPopover = try EnlightenPopover(markdownString: markdownString,
                                                options: options,
                                                maxWidth: popoverWidth,
                                                maxHeight: popoverMaxHeight)

        bezelStyle = .helpButton
        title = ""
        target = self
        action = #selector(helpButtonAction)
    }

    // MARK: - Markdown Update Methods

    /// Updates the popover content from a Markdown file.
    ///
    /// - Important: Errors thrown during the loading of the Markdown string are passed to the delegate's
    ///              `EnlightenPopoverDelegate.enlightenPopoverFailedToLoad(downError:)` method.
    ///
    /// - Parameters:
    ///   - markdownString: A string containing CommonMark Markdown.
    open func update(markdownString: String, options: EnlightenMarkdownOptions? = nil) {
        enlightenPopover.update(markdownString: markdownString, options: options)
    }

    /// Updates the popover content from a Markdown file.
    ///
    /// - Important: Asserts the existence of the Markdown file in 'Debug' builds only.
    ///              Fails silently in 'Release' builds.
    ///
    /// - Parameters:
    ///   - markdownFilename: The name of the Markdown file in the provided bundle to use for the popover content.
    ///   - bundle: The bundle that contains the Markdown file named `markdownName`.
    /// - Throws: Only throws an error if the Markdown file could not be read. Errors thrown during the loading of the
    ///           Markdown string are passed to the delegate's
    ///           `EnlightenPopoverDelegate.enlightenPopoverFailedToLoad(downError:)` method (i.e. **not** thrown here).
    open func update(markdownFilename: String,
                     in bundle: Bundle,
                     options: EnlightenMarkdownOptions? = nil) throws {
        let markdownString = try String(markdownFilename: markdownFilename, in: bundle)
        enlightenPopover.update(markdownString: markdownString, options: options)
    }

    // MARK: - Action Methods

    /// The help button's action method.
    @objc
    open func helpButtonAction() {
        if enlightenPopover.isShown {
            enlightenPopover.performClose(nil)
        } else {
            enlightenPopover.show(relativeTo: self)
        }
    }
}
