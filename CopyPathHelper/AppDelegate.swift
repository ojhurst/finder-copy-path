import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("CopyPath: applicationDidFinishLaunching fired")
        print("CopyPath: stdout marker — did finish launching")

        NSApp.setActivationPolicy(.regular)
        presentOnboardingWindow()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Onboarding window

    private func presentOnboardingWindow() {
        NSLog("CopyPath: building onboarding window")

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Copy Path"
        window.isReleasedWhenClosed = false
        window.center()

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 380))

        let icon = NSImageView(frame: NSRect(x: 200, y: 270, width: 80, height: 80))
        icon.image = NSApp.applicationIconImage
        icon.imageScaling = .scaleProportionallyUpOrDown
        content.addSubview(icon)

        let title = NSTextField(labelWithString: "Almost ready")
        title.font = NSFont.systemFont(ofSize: 22, weight: .semibold)
        title.alignment = .center
        title.frame = NSRect(x: 0, y: 232, width: 480, height: 28)
        content.addSubview(title)

        let subtitle = NSTextField(wrappingLabelWithString:
            "Enable the Copy Path extension in System Settings to finish setup.")
        subtitle.font = NSFont.systemFont(ofSize: 13)
        subtitle.alignment = .center
        subtitle.textColor = .secondaryLabelColor
        subtitle.frame = NSRect(x: 60, y: 195, width: 360, height: 32)
        content.addSubview(subtitle)

        let instructions = NSTextField(wrappingLabelWithString:
            "1.  Click the button below\n2.  Find Copy Path in the list\n3.  Toggle it on")
        instructions.font = NSFont.systemFont(ofSize: 13)
        instructions.alignment = .left
        instructions.frame = NSRect(x: 150, y: 110, width: 220, height: 70)
        content.addSubview(instructions)

        let button = NSButton(title: "Open System Settings",
                              target: self,
                              action: #selector(openSettings))
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.keyEquivalent = "\r"
        button.frame = NSRect(x: 140, y: 60, width: 200, height: 32)
        content.addSubview(button)

        let status = NSTextField(labelWithString: "After enabling, right-click any file to test.")
        status.font = NSFont.systemFont(ofSize: 12)
        status.alignment = .center
        status.textColor = .tertiaryLabelColor
        status.frame = NSRect(x: 0, y: 22, width: 480, height: 18)
        content.addSubview(status)

        window.contentView = content
        window.makeKeyAndOrderFront(nil)
        onboardingWindow = window

        NSLog("CopyPath: onboarding window presented")
    }

    @objc private func openSettings() {
        // x-apple.systempreferences:com.apple.ExtensionsPreferences works on macOS 13+.
        let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences")!
        NSWorkspace.shared.open(url)
    }
}
