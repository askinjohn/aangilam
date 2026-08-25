import SwiftUI
import AppKit

struct AboutView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            Text("Aangilam")
                .font(.title.weight(.semibold))
            Text("Understand anything, instantly.")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(versionString)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("A lightweight macOS utility for instant text translation.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(32)
        .frame(width: 420)
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}

@MainActor
final class AboutWindowController {
    static let shared = AboutWindowController()
    private var window: NSWindow?

    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: AboutView())
            let window = NSWindow(contentViewController: hosting)
            window.title = "About Aangilam"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        SystemSettingsOpener.revealAppWindows()
        window?.makeKeyAndOrderFront(nil)
        window?.delegate = CloseRestoreDelegate.shared
    }
}

private final class CloseRestoreDelegate: NSObject, NSWindowDelegate {
    static let shared = CloseRestoreDelegate()
    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async {
            SystemSettingsOpener.restoreMenuBarModeIfIdle()
        }
    }
}
