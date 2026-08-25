import AppKit

enum SystemSettingsOpener {
    static func openAccessibility() {
        let urls = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy",
            "x-apple.systempreferences:com.apple.preference.security"
        ]
        for urlString in urls {
            if let url = URL(string: urlString), NSWorkspace.shared.open(url) {
                return
            }
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
    }

    static func revealAppWindows() {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    static func relaunchAangilam() {
        let path = Bundle.main.bundlePath
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-c", "sleep 0.4; /usr/bin/open '\(path)'"]
        try? task.run()
        NSApp.terminate(nil)
    }

    static func restoreMenuBarModeIfIdle() {
        let keepRegular = NSApp.windows.contains { window in
            guard window.isVisible else { return false }
            return ["Aangilam Settings", "About Aangilam", "Welcome to Aangilam"].contains(window.title)
        }
        if !keepRegular {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

enum InstanceGuard {
    static func terminateOtherInstances() {
        let mine = ProcessInfo.processInfo.processIdentifier
        let bundleID = Bundle.main.bundleIdentifier ?? "com.aangilam.app"
        func others() -> [NSRunningApplication] {
            let matches = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
                + NSWorkspace.shared.runningApplications.filter { $0.localizedName == "Aangilam" }
            var seen = Set<pid_t>()
            return matches.filter { app in
                app.processIdentifier != mine && seen.insert(app.processIdentifier).inserted
            }
        }
        for app in others() {
            app.forceTerminate()
        }
        let deadline = Date().addingTimeInterval(0.4)
        while Date() < deadline, !others().isEmpty {
            Thread.sleep(forTimeInterval: 0.02)
        }
    }
}
