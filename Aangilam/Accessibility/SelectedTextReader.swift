import ApplicationServices
import AppKit

protocol SelectedTextReading: AnyObject {
    func isAccessibilityTrusted(prompt: Bool) -> Bool
    func readSelectedText() -> String?
}

final class SelectedTextReader: SelectedTextReading {
    /// Best-effort only. Do NOT use as a hard gate.
    /// Settings can show Aangilam ON while this is still false (stale TCC after re-sign),
    /// the same catch as Grist with CGPreflightScreenCaptureAccess.
    /// Never prompt from this check — that re-shows a system sheet every time.
    func isAccessibilityTrusted(prompt: Bool) -> Bool {
        _ = prompt
        return AXIsProcessTrusted()
    }

    func readSelectedText() -> String? {
        if let text = TextValidator.usableText(from: selectedTextFromSystemWideFocus()) {
            return text
        }
        if let text = TextValidator.usableText(from: selectedTextFromFrontmostApplication()) {
            return text
        }
        // VS Code, Cursor, Slack, Chrome often hide AX selected text.
        // Copy the selection, then restore the clipboard so the user never
        // pressed ⌘C and their clipboard is unchanged.
        return readByRestorableCopy()
    }

    private func readByRestorableCopy() -> String? {
        guard let front = NSWorkspace.shared.frontmostApplication,
              front.bundleIdentifier != Bundle.main.bundleIdentifier else {
            return nil
        }

        let pasteboard = NSPasteboard.general
        let saved = snapshot(pasteboard)
        let before = pasteboard.changeCount
        postCommandC(to: front.processIdentifier)

        var copied: String?
        let deadline = Date().addingTimeInterval(0.4)
        while Date() < deadline {
            if pasteboard.changeCount != before {
                copied = TextValidator.usableText(from: pasteboard.string(forType: .string))
                break
            }
            Thread.sleep(forTimeInterval: 0.02)
        }

        restore(saved, onto: pasteboard)
        return copied
    }

    private func snapshot(_ pasteboard: NSPasteboard) -> [[NSPasteboard.PasteboardType: Data]] {
        pasteboard.pasteboardItems?.map { item in
            var map: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    map[type] = data
                }
            }
            return map
        } ?? []
    }

    private func restore(_ snapshot: [[NSPasteboard.PasteboardType: Data]], onto pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        let items: [NSPasteboardItem] = snapshot.map { map in
            let item = NSPasteboardItem()
            for (type, data) in map {
                item.setData(data, forType: type)
            }
            return item
        }
        if !items.isEmpty {
            pasteboard.writeObjects(items)
        }
    }

    private func postCommandC(to pid: pid_t) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyC: CGKeyCode = 8
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: keyC, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: keyC, keyDown: false) else {
            return
        }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.postToPid(pid)
        up.postToPid(pid)
    }

    private func selectedTextFromSystemWideFocus() -> String? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedRef: CFTypeRef?
        let focusedStatus = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        )
        guard focusedStatus == .success, let focused = focusedRef else { return nil }
        return selectedText(from: focused as! AXUIElement)
    }

    private func selectedTextFromFrontmostApplication() -> String? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        var focusedRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedRef) == .success,
           let focused = focusedRef {
            if let text = selectedText(from: focused as! AXUIElement) {
                return text
            }
        }

        var windowRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowRef) == .success,
           let window = windowRef {
            var windowFocused: CFTypeRef?
            if AXUIElementCopyAttributeValue(window as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &windowFocused) == .success,
               let focused = windowFocused {
                if let text = selectedText(from: focused as! AXUIElement) {
                    return text
                }
            }
        }

        return nil
    }

    private func selectedText(from element: AXUIElement) -> String? {
        if let text = copyStringAttribute(element, kAXSelectedTextAttribute as CFString) {
            return text
        }

        if let value = copyStringAttribute(element, kAXValueAttribute as CFString),
           let range = selectedRange(from: element),
           range.location != NSNotFound,
           NSMaxRange(range) <= (value as NSString).length {
            let sliced = (value as NSString).substring(with: range)
            if let usable = TextValidator.usableText(from: sliced) {
                return usable
            }
        }

        if let parameterized = parameterizedSelectedString(from: element) {
            return parameterized
        }

        return nil
    }

    private func copyStringAttribute(_ element: AXUIElement, _ attribute: CFString) -> String? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard status == .success, let value else { return nil }
        if let string = value as? String {
            return string
        }
        if let attributed = value as? NSAttributedString {
            return attributed.string
        }
        return nil
    }

    private func selectedRange(from element: AXUIElement) -> NSRange? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &value)
        guard status == .success, let value else { return nil }
        var range = CFRange()
        if AXValueGetValue(value as! AXValue, .cfRange, &range) {
            return NSRange(location: range.location, length: range.length)
        }
        return nil
    }

    private func parameterizedSelectedString(from element: AXUIElement) -> String? {
        guard let range = selectedRange(from: element), range.length > 0 else { return nil }
        var cfRange = CFRangeMake(range.location, range.length)
        guard let axRange = AXValueCreate(.cfRange, &cfRange) else { return nil }
        var result: CFTypeRef?
        let status = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXStringForRangeParameterizedAttribute as CFString,
            axRange,
            &result
        )
        guard status == .success else { return nil }
        return result as? String
    }
}

final class StubSelectedTextReader: SelectedTextReading {
    var trusted = true
    var selectedText: String?

    func isAccessibilityTrusted(prompt: Bool) -> Bool {
        trusted
    }

    func readSelectedText() -> String? {
        TextValidator.usableText(from: selectedText)
    }
}
