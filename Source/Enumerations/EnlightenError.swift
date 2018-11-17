//
//  EnlightenError.swift
//  Enlighten 💡
//
//  Created by Chris Zielinski on 11/12/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Foundation

/// Errors thrown by the Enlighten library.
public enum EnlightenError: Error {
    /// An error thrown by the spotlight controller's validation method `SpotlightController.validateMarkdownStrings()`.
    ///
    /// - Parameters:
    ///   - markdownString: The Markdown string that threw the error.
    ///   - error: The error thrown during validation.
    case failedToValidate(markdownString: String, error: Error)
}
