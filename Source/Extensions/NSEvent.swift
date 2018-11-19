//
//  NSEvent.swift
//  Enlighten
//
//  Created by Chris Zielinski on 11/18/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

extension NSEvent.EventTypeMask {
    /// All the mouse-type events.
    static let mouse: NSEvent.EventTypeMask = [.mouseMoved,
                                               .mouseExited,
                                               .mouseEntered,
                                               .leftMouseUp,
                                               .otherMouseUp,
                                               .rightMouseUp,
                                               .leftMouseDown,
                                               .otherMouseDown,
                                               .rightMouseDown,
                                               .leftMouseDragged,
                                               .otherMouseDragged,
                                               .rightMouseDragged]
}

extension NSEvent {
    /// Whether the event is a mouse event inside the title bar.
    var isMouseInsideTitleBar: Bool {
        guard NSEvent.EventTypeMask.mouse.contains(NSEvent.EventTypeMask(type: type)),
            let window = window
            else { return false }
        return locationInWindow.y > window.contentLayoutRect.height
    }
}
