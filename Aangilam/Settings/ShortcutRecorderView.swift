import SwiftUI
import AppKit

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onRecorded: (KeyChord) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.onRecorded = onRecorded
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.onRecorded = onRecorded
        nsView.setRecording(isRecording)
    }
}

final class ShortcutRecorderNSView: NSView {
    var onRecorded: ((KeyChord) -> Void)?
    private var monitor: Any?

    override var acceptsFirstResponder: Bool { true }

    func setRecording(_ recording: Bool) {
        if recording {
            window?.makeFirstResponder(self)
            if monitor == nil {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    if event.keyCode == UInt16(kVKEscape) {
                        return event
                    }
                    if let chord = KeyChord.from(event: event) {
                        self?.onRecorded?(chord)
                        return nil
                    }
                    return nil
                }
            }
        } else if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

private let kVKEscape: Int = 53
