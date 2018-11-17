//
//  AnimatedTyper.swift
//  Demo
//
//  Created by Chris Zielinski on 11/7/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

class AnimatedTyper {
    let typingMillisecondDelay: Int = 200

    unowned var textView: NSTextView
    var string: String
    var isActive: Bool = false

    private var originalTextViewContents: NSAttributedString?
    private var currentCharacterIndex: String.Index
    private var timer: Timer?

    init(textView: NSTextView, string: String) {
        self.textView = textView
        self.string = string
        currentCharacterIndex = string.startIndex
    }

    func start() {
        timer?.invalidate()

        defer {
            isActive = true
        }

        if isActive {
            type()
        } else {
            originalTextViewContents = NSAttributedString(attributedString: textView.attributedString())
            textView.setSelectedRange(NSRange(location: 0, length: textView.string.count))
            textView.window?.makeFirstResponder(textView)
            scheduleTimer(for: #selector(clearContents), delay: 1)
        }
    }

    func clear() {
        timer?.invalidate()

        if textView.string != originalTextViewContents?.string {
            currentCharacterIndex = textView.string.endIndex
            delete()
        } else {
            // `clearContents` has not been called yet.
            textView.setSelectedRange(NSRange(location: 0, length: 0))
            restoreOriginalContents()
        }
    }

    private func scheduleTimer(for selector: Selector, delay: TimeInterval? = nil) {
        timer?.invalidate()
        let timeInterval = delay ?? Double(typingMillisecondDelay + Int.random(in: 0..<typingMillisecondDelay)) / 1000
        timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                     target: self,
                                     selector: selector,
                                     userInfo: nil,
                                     repeats: false)
    }

    @objc
    func type() {
        guard currentCharacterIndex < string.endIndex
            else { return }

        textView.insertText(String(string[currentCharacterIndex]),
                            replacementRange: NSRange(location: textView.string.count, length: 0))
        currentCharacterIndex = string.index(after: currentCharacterIndex)
        scheduleTimer(for: #selector(type))
    }

    @objc
    func delete() {
        guard currentCharacterIndex > string.startIndex
            else { return restoreOriginalContents() }

        currentCharacterIndex = textView.string.index(before: currentCharacterIndex)
        textView.textStorage?.mutableString.deleteCharacters(in: NSRange(location: currentCharacterIndex.encodedOffset,
                                                                         length: 1))

        scheduleTimer(for: #selector(delete))
    }

    func restoreOriginalContents() {
        // Restore the original contents if the text view doesn't already have it.
        if let originalTextViewContents = originalTextViewContents,
            textView.string != originalTextViewContents.string {
            textView.textStorage?.setAttributedString(originalTextViewContents)
        }

        textView.window?.makeFirstResponder(nil)
        isActive = false
    }

    @objc
    func clearContents() {
        textView.delete(nil)
        type()
    }
}
