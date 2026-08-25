import AppKit

protocol ClipboardAccessing: AnyObject {
    func readString() -> String?
    func writeString(_ string: String)
    func snapshotChangeCount() -> Int
}

final class ClipboardManager: ClipboardAccessing {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func readString() -> String? {
        TextValidator.usableText(from: pasteboard.string(forType: .string))
    }

    func writeString(_ string: String) {
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    func snapshotChangeCount() -> Int {
        pasteboard.changeCount
    }
}

final class InMemoryClipboard: ClipboardAccessing {
    var stored: String?
    private(set) var changeCount = 0

    func readString() -> String? {
        TextValidator.usableText(from: stored)
    }

    func writeString(_ string: String) {
        stored = string
        changeCount += 1
    }

    func snapshotChangeCount() -> Int {
        changeCount
    }
}
