//
//  NSAppearance.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 10/29/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

extension NSAppearance.Name {
    /// Whether the receiver is a dark system appearance.
    @available(OSX 10.14, *)
    var isDark: Bool {
        switch self {
        case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
            return true
        default:
            return false
        }
    }
}
