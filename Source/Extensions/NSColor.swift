//
//  NSColor.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 10/30/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

extension NSColor {
    /// The background color of the Enlighten spotlight controller.
    public static var spotlightControllerBackground: NSColor = {
        if #available(OSX 10.13, *) {
            return NSColor(named: Constants.spotlightControllerBackgroundColorName,
                           bundle: Bundle(for: EnlightenSpotlightController.self))!
        } else {
            return NSColor.black.withAlphaComponent(0.7)
        }
    }()

    /// - Returns: The hexadecimal web color code with a leading number sign (#).
    var webColor: String? {
        return rgbHexTriplet(using: .sRGB)
    }

    /// Converts the receiver to a hexadecimal color code in the specified color space.
    ///
    /// - Authors:
    ///  * [Bijan Rahnema](https://github.com/gobijan)
    ///  * [Chris Zielinski](https://github.com/chriszielinski)
    ///
    /// - SeeAlso: [GithubGist](https://gist.github.com/gobijan/d724de27e2aff8131676)
    ///
    /// - Returns: The hexadecimal color code with a leading number sign (#).
    func rgbHexTriplet(using colorSpace: NSColorSpace) -> String? {
        guard let color = self.usingColorSpace(colorSpace)
            else { return nil }

        // Get the red, green, and blue components of the color
        var rValue: CGFloat = 0
        var gValue: CGFloat = 0
        var bValue: CGFloat = 0

        var rInt, gInt, bInt: Int
        var rHex, gHex, bHex: String

        color.getRed(&rValue, green: &gValue, blue: &bValue, alpha: nil)

        // Convert the components to numbers (unsigned decimal integer) between 0 and 255
        rInt = Int((rValue * 255.99999))
        gInt = Int((gValue * 255.99999))
        bInt = Int((bValue * 255.99999))

        // Convert the numbers to hex strings
        rHex = String(format: "%02X", rInt)
        gHex = String(format: "%02X", gInt)
        bHex = String(format: "%02X", bInt)
        return String(format: "#%@%@%@", rHex, gHex, bHex)
    }
}
