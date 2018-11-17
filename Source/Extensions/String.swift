//
//  String.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 11/7/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Foundation

extension String {
    /// Initializes a `String` from a Markdown file in a `Bundle`.
    ///
    /// - Warning: Asserts the existence of the Markdown file in 'Debug' builds, while failing silently in 'Release'
    ///            builds (by returning an empty string).
    ///
    /// - Parameters:
    ///   - markdownFilename: The filename of the Markdown file in `bundle`.
    ///   - bundle: The `Bundle` that contains the Markdown file.
    /// - Throws: Throws an error if the contents of the file `markdownName` cannot be read.
    init(markdownFilename: String, in bundle: Bundle) throws {
        var markdownString = ""

        if let url = bundle.url(forResource: markdownFilename, withExtension: "md") {
            markdownString = try String(contentsOf: url)
        } else {
            assertionFailure()
        }

        self = markdownString
    }
}
