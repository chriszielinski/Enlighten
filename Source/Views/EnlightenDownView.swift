//
//  EnlightenDownView.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 10/29/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa
import WebKit
import Down

/// A sizeable and self-fitting web view that renders a CommonMark Markdown string.
open class EnlightenDownView: DownView {

    // MARK: Public Stored Properties

    /// Whether a mouse drag event should move the window.
    public internal(set) var mouseDragShouldMoveWindow: Bool = false
    /// The maximum width the view can use.
    public var maxWidth: CGFloat {
        didSet { frame.size.width = maxWidth }
    }
    /// The maximum height the view can use.
    ///
    /// If the Markdown content exceeds this height, scrolling is enabled.
    public var maxHeight: CGFloat = 500 {
        didSet { frame.size.height = resolvedMaxHeight }
    }
    /// The minimum height the view can be.
    ///
    /// - Note: This is dependent on the CSS styling.
    open var minHeight: CGFloat = 35
    /// Whether the Markdown content should be center aligned.
    public var doesCenterAlignContent: Bool = false {
        didSet { setBodyTextAlignProperty() }
    }
    /// Whether document scrolling is enabled.
    ///
    /// This property is determined by the `maxHeight` property and the actual height of the rendered Markdown document.
    public internal(set) var isScrollingEnabled: Bool = true {
        didSet { setDocumentScrollProperty() }
    }
    /// Whether the final width of the HTML document has been determined.
    @objc
    dynamic open var isFinalWidth: Bool = false

    // MARK: Private Stored Properties

    /// The latest width of the widest top-level element in the body of the HTML document.
    ///
    /// This property is updated each layout cycle.
    private var cachedWidestElementWidth: CGFloat?
    /// The latest content size constrained to the minimum and maximum size requirements.
    private var cachedContentSize: NSSize = .zero
    private var isHandlingMouseDownEvent: Bool = false
    private var verticalContentInset: CGFloat = 0 {
        didSet { cachedContentSize.height -= (oldValue - verticalContentInset) }
    }

    // MARK: Overridden Properties

    override open var intrinsicContentSize: NSSize {
        guard cachedContentSize != .zero
            else { return NSSize(width: frame.width, height: minHeight) }

        return cachedContentSize
    }

    // MARK: - Initializers

    public override init(frame: CGRect,
                         markdownString: String,
                         openLinksInBrowser: Bool,
                         templateBundle: Bundle? = nil,
                         configuration: WKWebViewConfiguration?,
                         options: EnlightenMarkdownOptions = .default,
                         didLoadSuccessfully: DownViewClosure?) throws {
        maxWidth = frame.width
        var bundle = templateBundle

        if bundle == nil {
            let bundleURL = Bundle(for: EnlightenDownView.self)
                .url(forResource: Constants.enlightenDownViewBundleName, withExtension: "bundle")!
            bundle = Bundle(url: bundleURL)!
        }

        try super.init(frame: NSRect(origin: frame.origin, size: CGSize(width: frame.width, height: 1000)),
                       markdownString: markdownString,
                       openLinksInBrowser: openLinksInBrowser,
                       templateBundle: bundle,
                       configuration: configuration,
                       options: options,
                       didLoadSuccessfully: didLoadSuccessfully)

        if #available(macOS 10.15, *) {
            isHorizontalContentSizeConstraintActive = false
            isVerticalContentSizeConstraintActive = false
        }

        setValue(false, forKey: "drawsBackground")
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout Methods

    var resolvedMaxHeight: CGFloat {
        return verticalContentInset + maxHeight
    }

    open override func setFrameSize(_ newSize: NSSize) {
        if cachedContentSize != .zero {
            super.setFrameSize(cachedContentSize)
            subviews.first?.setFrameSize(cachedContentSize)
            return
        }

        super.setFrameSize(newSize)
    }

    /// Resets the size of the view to the maximum.
    ///
    /// - Parameter includingHeight: Whether to also reset the height to the maximum.
    func resetMaxSize(includingHeight: Bool = true) {
        cachedWidestElementWidth = nil
        let height = includingHeight ? resolvedMaxHeight : frame.height
        cachedContentSize = NSSize(width: maxWidth, height: height)

        setFrameSize(cachedContentSize)
    }

    /// Resizes the view to fit the cached content size.
    ///
    /// - Parameter includingWidth: Whether to resize the width of the view.
    func sizeToFit(includingWidth: Bool = true) {
        guard cachedContentSize != .zero
            else { return }

        if includingWidth {
            setFrameSize(cachedContentSize)
        } else {
            frame.size.height = cachedContentSize.height
        }
    }

    // MARK: - Javascript Methods

    /// Computes and resizes the view to best fit the document's content size, respecting the minimum and maximum
    /// allowed size.
    ///
    /// This method updates the values of the `cachedContentSize` and `isFinalWidth` properties.
    open func computeContentSize() {
        guard !isHandlingMouseDownEvent
            else { return }

        htmlScrollSize { [weak self] (size) in
            guard let downView = self
                else { return }

            var scrollSize = size

            #if WKLOG
            print("[EnlightenDownView.\(#function)] Frame size: \(downView.frame.size)")
            print("[EnlightenDownView.\(#function)] WKWebView Scroll Size: \(scrollSize)")
            #endif

            if scrollSize.height <= downView.resolvedMaxHeight {
                downView.isScrollingEnabled = false
            } else {
                downView.isScrollingEnabled = true
            }

            scrollSize.height = min(downView.resolvedMaxHeight, max(downView.minHeight, scrollSize.height))

            var needsToSetIsFinalWidth = false
            if downView.isFinalWidth {
                // To prevent recursive layout.
                scrollSize.width = downView.frame.width
            } else if let widestElementWidth = downView.cachedWidestElementWidth {
                if widestElementWidth < scrollSize.width {
                    downView.needsLayout = true
                }

                scrollSize.width = min(widestElementWidth, downView.maxWidth)
                needsToSetIsFinalWidth = true
            }

            #if WKLOG
            print("[EnlightenDownView.\(#function)] cachedContentSize: \(scrollSize)")
            #endif

            downView.cachedContentSize = scrollSize
            downView.sizeToFit(includingWidth: needsToSetIsFinalWidth)
            downView.isFinalWidth = needsToSetIsFinalWidth
        }
    }

    /// Updates the `cachedWidestElementWidth` property.
    open func cacheWidthOfWidestElement() {
        self.cachedWidestElementWidth = nil

        widthOfWidestElement { [weak self] (width) in
            self?.cachedWidestElementWidth = width + Constants.CSS.bodyLeftAndRightMargin

            #if WKLOG
            print("[EnlightenDownView.\(#function)] cachedWidestElementWidth: \(self?.cachedWidestElementWidth ?? 0)")
            #endif
        }
    }

    /// Sets the document body’s `margin-top` CSS property to a specified px value.
    open func setBodyTopMargin(to pxValue: CGFloat) {
        if verticalContentInset == 0 {
            verticalContentInset = pxValue / 2
        }

        evaluateJavaScript(Constants.Javascript.script(bodyTopMargin: pxValue))
    }

    /// Removes any previous values set by `setBodyTopMargin(to:)`.
    open func resetBodyTopMargin() {
        if verticalContentInset != 0 {
            verticalContentInset = 0
        }

        evaluateJavaScript(Constants.Javascript.script(bodyTopMargin: nil))
    }

    /// Sets the document body’s `text-align` CSS property to match the behavior of the
    /// `doesCenterAlignContent` property.
    open func setBodyTextAlignProperty() {
        evaluateJavaScript(Constants.Javascript.script(bodyTextAlign: doesCenterAlignContent ? .center : .none))
    }

    /// Sets the CSS overflow property to match the behavior of the `isScrollingEnabled` property.
    open func setDocumentScrollProperty() {
        let overflowValue: Constants.CSS.Property.Value.Overflow = isScrollingEnabled ? .none : .hidden
        evaluateJavaScript(Constants.Javascript.script(documentOverflow: overflowValue))
    }

    /// Sets the CSS color scheme according to the receiver's effective appearance.
    open func setPreferredColorScheme() {
        let method: Constants.Javascript.Method
        if #available(OSX 10.14, *) {
            method = effectiveAppearance.name.isDark
                ? .switchToDarkMode
                : .switchToLightMode
        } else {
            method = .switchToLightMode
        }
        evaluateJavaScript(method: method)
    }

    /// Gets the scroll size of the HTML document and passes it in to a closure.
    ///
    /// - Parameter completionHandler: A closure to invoke with the resulting size.
    public func htmlScrollSize(completionHandler: @escaping (NSSize) -> Void) {
        evaluateJavaScript(method: .htmlScrollSize) { (values) in
            guard let sizeValues = values as? [CGFloat],
                sizeValues.count == 2
                else { return }
            completionHandler(NSSize(width: sizeValues[0], height: sizeValues[1]))
        }
    }

    /// Gets the width of the widest top-level element in the body of the document and passes it in to a closure.
    ///
    /// - Parameter completionHandler: A closure to invoke with the resulting width.
    public func widthOfWidestElement(completionHandler: @escaping (CGFloat) -> Void) {
        evaluateJavaScript(method: .getWidthOfWidestElement) { (value) in
            guard let width = value as? CGFloat
                else { return }
            completionHandler(width)
        }
    }

    /// Executes a JavaScript method.
    ///
    /// - Parameters:
    ///   - method: The method to execute.
    ///   - completionHandler: A closure to invoke when method execution completes. The returned value is passed to
    ///                        this closure.
    func evaluateJavaScript(method: Constants.Javascript.Method, completionHandler: ((Any) -> Void)? = nil) {
        evaluateJavaScript(method.rawValue) { [weak self] (value, error) in
            guard let isLoading = self?.isLoading,
                !isLoading, error == nil,
                let value = value
                else { return }
            completionHandler?(value)
        }
    }

    // MARK: - Overridden Methods

    override open func layout() {
        super.layout()

        guard !isHandlingMouseDownEvent
            else { return }

        setPreferredColorScheme()
        setBodyTextAlignProperty()
        cacheWidthOfWidestElement()
        computeContentSize()
    }

    // MARK: Responder Methods

    override open func mouseDown(with event: NSEvent) {
        isHandlingMouseDownEvent = true
        defer { isHandlingMouseDownEvent = false }

        // Because this is a web view, we need to use some black magic to distinguish text selection from a window
        // drag (or anything else). We use the cursor to do this.
        // If it's an I-beam cursor, we assume text selection; otherwise, a possible window drag and pass it on to the
        // superview—in this case the `NSPopoverFrame`.
        if NSCursor.current != .iBeam, NSCursor.current != .pointingHand {
            superview?.mouseDown(with: event)
        }

        super.mouseDown(with: event)
    }

    override open func mouseDragged(with event: NSEvent) {
        // See documentation inside `mouseDown(with:)`.
        guard NSCursor.current == .iBeam else {
            if mouseDragShouldMoveWindow {
                window?.performDrag(with: event)
            }
            return
        }

        super.mouseDragged(with: event)
    }
}
