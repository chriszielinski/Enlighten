//
//  Constants.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 10/29/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Foundation

public struct Constants {
    public typealias CSS = CSSConstants
    typealias Javascript = JavascriptConstants

    /// The library's custom URL scheme.
    public static let urlScheme: String = "enlighten"
    /// The name of the Enlighten spotlight controller's background color in the asset catalog.
    public static let spotlightControllerBackgroundColorName = "EnlightenSpotlightControllerBackground"
    /// The name of the `DownView` template bundle.
    static let enlightenDownViewBundleName: String = "EnlightenDownView"
}

public struct CSSConstants {
    public typealias Property = CSSProperty

    /// The left margin of the document's body.
    static let bodyLeftMargin: CGFloat = 13
    /// The right margin of the document's body.
    static let bodyRightMargin: CGFloat = 13
    /// The sum of the left and right margin of the document's body.
    static let bodyLeftAndRightMargin: CGFloat = bodyLeftMargin + bodyRightMargin
}

public struct CSSProperty {
    public typealias Value = CSSPropertyValue

    /// The CSS overflow property of the root document.
    static let documentOverflow: String = "document.documentElement.style.overflow"
    /// The CSS `margin-top` property of the document's body.
    static let bodyTopMargin: String = "document.body.style.marginTop"
    /// The CSS `text-align` property of the document's body.
    static let bodyTextAlign: String = "document.body.style.textAlign"
}

public struct CSSPropertyValue {
    /// The values of the CSS overflow property.
    enum Overflow: String {
        case none = ""
        case hidden
    }

    /// The values of the CSS overflow property.
    public enum TextAlign: String {
        case none = ""
        case center
    }
}

struct JavascriptConstants {
    enum Method: String {
        /// The method that returns the width of the widest top-level element in the body of the document.
        case getWidthOfWidestElement = "getWidthOfWidestElement()"
        /// The method that returns the scroll size of the document.
        case htmlScrollSize = "htmlScrollSize()"
        /// The method that switches the CSS style to a dark appearance.
        case switchToDarkMode = "switchToDarkMode()"
        /// The method that switches the CSS style to a light appearance.
        case switchToLightMode = "switchToLightMode()"
    }

    /// Returns the Javascript that sets the document's overflow property to a specified value.
    ///
    /// - Parameter documentOverflow: The value to set the overflow property to.
    /// - Returns: The Javascript that sets the document's overflow property to `documentOverflow`.
    static func script(documentOverflow: Constants.CSS.Property.Value.Overflow) -> String {
        return Constants.CSS.Property.documentOverflow + " = '\(documentOverflow.rawValue)'"
    }

    /// Returns the Javascript that sets the document body's text align property to a specified value.
    ///
    /// - Parameter bodyTextAlign: The value to set the 'text-align' property to.
    /// - Returns: The Javascript that sets the document body's text align property to `bodyTextAlign`.
    static func script(bodyTextAlign: Constants.CSS.Property.Value.TextAlign) -> String {
        return Constants.CSS.Property.bodyTextAlign + " = '\(bodyTextAlign.rawValue)'"
    }

    /// Returns the Javascript that sets the document body's `margin-top` property to a specified value.
    ///
    /// - Parameter bodyTopMargin: The value to set the `margin-top` property to. When `nil`, removes the property
    ///                            value.
    /// - Returns: The Javascript that sets the document body's `margin-top` property to `bodyTopMargin`.
    static func script(bodyTopMargin: CGFloat?) -> String {
        var javascript = Constants.CSS.Property.bodyTopMargin

        if let value = bodyTopMargin {
            javascript += " = '\(value)px'"
        } else {
            javascript += " = ''"
        }

        return javascript
    }
}
