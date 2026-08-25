import AppKit
import SwiftUI

@MainActor
protocol PopupPresenting: AnyObject {
    var onClose: (() -> Void)? { get set }
    var onCopy: (() -> Void)? { get set }
    var onRetry: (() -> Void)? { get set }
    var onTranslateClipboard: (() -> Void)? { get set }
    var onRequestSettings: (() -> Void)? { get set }
    var onRequestAccessibility: (() -> Void)? { get set }
    var onRestartApp: (() -> Void)? { get set }
    var onChangeShortcut: (() -> Void)? { get set }
    var autoCloseEnabled: (() -> Bool)? { get set }
    var autoCloseInterval: (() -> TimeInterval)? { get set }
    func present(session: TranslationSessionState, copied: Bool)
    func close()
}

@MainActor
final class NullPopupPresenter: PopupPresenting {
    var onClose: (() -> Void)?
    var onCopy: (() -> Void)?
    var onRetry: (() -> Void)?
    var onTranslateClipboard: (() -> Void)?
    var onRequestSettings: (() -> Void)?
    var onRequestAccessibility: (() -> Void)?
    var onRestartApp: (() -> Void)?
    var onChangeShortcut: (() -> Void)?
    var autoCloseEnabled: (() -> Bool)?
    var autoCloseInterval: (() -> TimeInterval)?
    private(set) var lastSession: TranslationSessionState = .idle
    private(set) var lastCopied = false

    func present(session: TranslationSessionState, copied: Bool) {
        lastSession = session
        lastCopied = copied
    }

    func close() {
        lastSession = .idle
        onClose?()
    }
}

@MainActor
final class PopupController: NSObject, NSWindowDelegate, PopupPresenting {
    var onClose: (() -> Void)?
    var onCopy: (() -> Void)?
    var onRetry: (() -> Void)?
    var onTranslateClipboard: (() -> Void)?
    var onRequestSettings: (() -> Void)?
    var onRequestAccessibility: (() -> Void)?
    var onRestartApp: (() -> Void)?
    var onChangeShortcut: (() -> Void)?
    var autoCloseEnabled: (() -> Bool)?
    var autoCloseInterval: (() -> TimeInterval)?

    private var panel: NSPanel?
    private var hosting: NSHostingView<TranslationPopupView>?
    private var clickMonitor: Any?
    private var localKeyMonitor: Any?
    private var autoCloseTimer: Timer?
    private var model = PopupModel()

    func present(session: TranslationSessionState, copied: Bool) {
        model.session = session
        model.copied = copied
        model.displayMode = SettingsStore.shared.popupDisplayMode
        model.onCopy = { [weak self] in self?.onCopy?() }
        model.onRetry = { [weak self] in self?.onRetry?() }
        model.onTranslateClipboard = { [weak self] in self?.onTranslateClipboard?() }
        model.onOpenSettings = { [weak self] in self?.onRequestSettings?() }
        model.onOpenAccessibility = { [weak self] in self?.onRequestAccessibility?() }
        model.onRestartApp = { [weak self] in self?.onRestartApp?() }
        model.onChangeShortcut = { [weak self] in self?.onChangeShortcut?() }
        model.onDismiss = { [weak self] in self?.close() }

        if panel == nil {
            createPanel()
        }

        guard let panel else { return }
        if !panel.isVisible {
            positionOnRight(panel)
        }
        panel.makeKeyAndOrderFront(nil)
        restartAutoCloseIfNeeded(session: session)
        installClickOutsideMonitor()
        installEscapeMonitor()
    }

    func close() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
        panel?.orderOut(nil)
        if model.session != .idle {
            model.session = .idle
            onClose?()
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        close()
        return false
    }

    private func createPanel() {
        let hostingView = FirstMouseHostingView(rootView: TranslationPopupView(model: model))
        hostingView.sizingOptions = []
        self.hosting = hostingView

        let panel = TranslationPanel(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 440),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Aangilam"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.minSize = NSSize(width: 480, height: 300)
        panel.maxSize = NSSize(width: 960, height: 820)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.animationBehavior = .utilityWindow
        panel.delegate = self
        panel.contentView = hostingView
        panel.acceptsMouseMovedEvents = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        self.panel = panel
    }

    private func installEscapeMonitor() {
        if localKeyMonitor != nil { return }
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.close()
                return nil
            }
            return event
        }
    }

    private func positionOnRight(_ panel: NSPanel) {
        let size = panel.frame.size
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.visibleFrame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens.first
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        var origin = NSPoint(
            x: visible.maxX - size.width - 18,
            y: max(visible.minY + 18, min(mouse.y - size.height / 2, visible.maxY - size.height - 18))
        )
        if origin.x + size.width > visible.maxX {
            origin.x = visible.maxX - size.width - 12
        }
        if origin.x < visible.minX {
            origin.x = visible.minX + 12
        }
        if origin.y < visible.minY {
            origin.y = mouse.y + 18
        }
        if origin.y + size.height > visible.maxY {
            origin.y = visible.maxY - size.height - 12
        }
        panel.setFrameOrigin(origin)
    }

    private func installClickOutsideMonitor() {
        if clickMonitor != nil { return }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let panel = self.panel, panel.isVisible else { return }
            let location = event.locationInWindow
            let screenPoint: NSPoint
            if let window = event.window {
                screenPoint = window.convertToScreen(NSRect(origin: location, size: .zero)).origin
            } else {
                screenPoint = event.locationInWindow
            }
            if !panel.frame.contains(screenPoint) {
                DispatchQueue.main.async {
                    self.close()
                }
            }
        }
    }

    private func restartAutoCloseIfNeeded(session: TranslationSessionState) {
        autoCloseTimer?.invalidate()
        guard autoCloseEnabled?() == true else { return }
        guard case .translated = session else { return }
        let interval = autoCloseInterval?() ?? 15
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.close()
            }
        }
    }
}

final class TranslationPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override var acceptsFirstResponder: Bool { true }
}

final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var acceptsFirstResponder: Bool { true }
}

@MainActor
final class PopupModel: ObservableObject {
    @Published var session: TranslationSessionState = .idle
    @Published var copied = false
    @Published var displayMode: PopupDisplayMode = .originalAndTranslation
    var onCopy: (() -> Void)?
    var onRetry: (() -> Void)?
    var onTranslateClipboard: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onOpenAccessibility: (() -> Void)?
    var onRestartApp: (() -> Void)?
    var onChangeShortcut: (() -> Void)?
    var onDismiss: (() -> Void)?
}
