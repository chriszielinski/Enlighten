//
//  EnlightenKeyedSpotlightController.swift
//  Enlighten
//
//  Created by Chris Zielinski on 11/15/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

/// The controller for a spotlight-based onboarding presentation.
///
/// Unlike its key-less variant `EnlightenSpotlightController`, the keyed `EnlightenKeyedSpotlightController` allows
/// the presentation order of the irises to be specified by the case order of an
/// `EnlightenSpotlightControllerKeys`-conforming enumeration.
open class EnlightenKeyedSpotlightController<Key: EnlightenSpotlightControllerKeys>: EnlightenSpotlightController {

    // MARK: Public Stored Properties

    /// The order to present the irises in.
    ///
    /// The dictionary maps `Key`s to their presentation order index.
    public let presentationOrderKeys: [Key: Int]

    // MARK: Internal Computed Properties

    /// The keyed irises that will be presented by the controller.
    ///
    /// - Note: The keyed irises are only in presentation order after presentation begins (i.e. they are sorted right
    ///         before the controller begins presentation).
    var keyedIrises: [EnlightenKeyedIris<Key>] {
        get {
            // swiftlint:disable:next force_cast
            return irises as! [EnlightenKeyedIris<Key>]
        }
        set { irises = newValue }
    }

    // MARK: - Initializers

    /// Initializes a new keyed spotlight controller.
    ///
    /// Unlike the key-less variant, the keyed controller allows the presentation order of the irises to be specified.
    ///
    /// - Important: Ensure the only irises added to this _keyed_ spotlight controller are of the type
    ///              `EnlightenKeyedIris`.
    ///
    /// - Warning: A fatal error will be thrown if an instance of `EnlightenIris` is added to a **keyed** controller.
    ///
    /// - Parameter keys: The type of an enumeration that conforms to the `EnlightenSpotlightControllerKeys` protocol.
    ///                   The keyed irises will be presented in the order of the enumeration cases.
    public init(keys: Key.Type, markdownOptions: EnlightenMarkdownOptions = .default) {
        let keyValueTuples = keys.allCases.enumerated().map({ ($0.element, $0.offset) })
        self.presentationOrderKeys = Dictionary(uniqueKeysWithValues: keyValueTuples)

        super.init(markdownOptions: markdownOptions)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Presentation Methods

    override open func present(in window: NSWindow? = nil, animating: Bool = false) {
        sortIrises()

        super.present(in: window, animating: animating)
    }

    // MARK: - Configuration Methods

    override open func addSpotlight(iris: EnlightenIris) {
        guard iris is EnlightenKeyedIris<Key>
            else { fatalError("Attempting to add a key-less iris to the keyed spotlight controller") }
        super.addSpotlight(iris: iris)
    }

    override open func addSpotlight(view: NSView, markdownString: String) -> EnlightenIris {
        fatalError("Attempting to create and add a key-less iris to the keyed spotlight controller."
            + " Use `addSpotlight(key:view:markdownString:)` instead.")
    }

    override open func addSpotlight(view: NSView,
                                    markdownFilename: EnlightenIris.MarkdownFilename,
                                    in bundle: Bundle) throws -> EnlightenIris {
        fatalError("Attempting to create and add a key-less iris to the keyed spotlight controller."
            + " Use `addSpotlight(key:view:markdownFilename:in:)` instead.")
    }

    /// Adds a keyed iris to the controller.
    ///
    /// - Parameter keyedIris: The keyed iris to add.
    open func addSpotlight(keyedIris: EnlightenKeyedIris<Key>) {
        irises.append(keyedIris)
    }

    /// A convenience method for creating and adding a keyed iris to the controller.
    ///
    /// - Important: Errors thrown during the loading of the Markdown string are passed to the spotlight controller's
    ///              delegate's
    ///              `EnlightenSpotlightControllerDelegate.spotlightControllerFailedToLoad(markdownString:for:with:)`
    ///              method.
    ///
    /// - Parameters:
    ///   - presentationOrderKey: The presentation order key for the new keyed iris.
    ///   - view: The view to spotlight.
    ///   - markdownString: The CommonMark Markdown string displayed.
    /// - Returns: The newly created spotlight iris.
    @discardableResult
    public func addSpotlight(presentationOrderKey key: Key,
                             view: NSView,
                             markdownString: String) -> EnlightenKeyedIris<Key> {
        let keyedIris = EnlightenKeyedIris(presentationOrderKey: key,
                                           view: view,
                                           markdownStrings: [markdownString])
        addSpotlight(keyedIris: keyedIris)
        return keyedIris
    }

    /// A convenience method for creating and adding a keyed iris to the controller.
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
    ///   - presentationOrderKey: The presentation order key for the new keyed iris.
    ///   - view: The view to spotlight.
    ///   - markdownFilename: The name of the CommonMark Markdown file in the provided bundle that will be displayed.
    ///   - bundle: The bundle that contains the Markdown file named `markdownFilename`.
    /// - Returns: The newly created spotlight iris.
    /// - Throws: Throws an error if the contents of the file `markdownFilename` cannot be read.
    @discardableResult
    open func addSpotlight(presentationOrderKey key: Key,
                           view: NSView,
                           markdownFilename: EnlightenIris.MarkdownFilename,
                           in bundle: Bundle) throws -> EnlightenKeyedIris<Key> {
        let keyedIris = try EnlightenKeyedIris(presentationOrderKey: key,
                                               view: view,
                                               markdownFilename: markdownFilename,
                                               in: bundle)
        addSpotlight(keyedIris: keyedIris)
        return keyedIris
    }

    /// Returns the keyed iris for a view, if it exists.
    ///
    /// - Parameter view: The view to return the keyed iris for.
    /// - Returns: The keyed iris for `view`, or `nil` if no iris for that view has been added to the controller.
    open func keyedIris(for view: NSView) -> EnlightenKeyedIris<Key>? {
        return keyedIrises.first(where: { return $0.view == view })
    }

    /// Returns the keyed iris for a presentation order key, if it exists.
    ///
    /// - Parameter presentationOrderKey: The presentation order key to return the keyed iris for.
    /// - Returns: The keyed iris for `presentationOrderKey`, or `nil` if no iris for that key has been added to the
    ///            controller.
    open func keyedIris(for presentationOrderKey: Key) -> EnlightenKeyedIris<Key>? {
        return keyedIrises.first(where: { return $0.presentationOrderKey == presentationOrderKey })
    }
}

// MARK: - Helper Methods

extension EnlightenKeyedSpotlightController {
    /// Sorts the irises in place, using the ordered keys as the comparison between elements.
    func sortIrises() {
        keyedIrises.sort { (lhsIris, rhsIris) -> Bool in
            // Note: Force unwrapping here is okay because of the type-saftey provided by the keyed irises.
            return presentationOrderKeys[lhsIris.presentationOrderKey]!
                < presentationOrderKeys[rhsIris.presentationOrderKey]!
        }
    }
}
