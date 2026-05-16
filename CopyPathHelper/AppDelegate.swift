import Cocoa
import FinderSync

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private var onboardingWindow: NSWindow?
    private var statusLabel: NSTextField?
    private var enableButton: NSButton?
    private var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if FIFinderSyncController.isExtensionEnabled {
            // Already wired up — nothing to do, exit silently so the user never sees a flash.
            NSApp.setActivationPolicy(.accessory)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NSApp.terminate(nil)
            }
            return
        }

        NSApp.setActivationPolicy(.regular)
        presentOnboardingWindow()
        NSApp.activate(ignoringOtherApps: true)
        startPolling()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    // MARK: - Onboarding window

    private func presentOnboardingWindow() {
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
        content.autoresizingMask = [.width, .height]

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
        enableButton = button

        let status = NSTextField(labelWithString: "Waiting for you to enable…")
        status.font = NSFont.systemFont(ofSize: 12)
        status.alignment = .center
        status.textColor = .tertiaryLabelColor
        status.frame = NSRect(x: 0, y: 22, width: 480, height: 18)
        content.addSubview(status)
        statusLabel = status

        window.contentView = content
        window.makeKeyAndOrderFront(nil)
        onboardingWindow = window
    }

    @objc private func openSettings() {
        FIFinderSyncController.showExtensionManagementInterface()
    }

    // MARK: - Polling for enable

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if FIFinderSyncController.isExtensionEnabled {
                self.pollTimer?.invalidate()
                self.handleExtensionEnabled()
            }
        }
    }

    private func handleExtensionEnabled() {
        statusLabel?.stringValue = "Enabled. You're all set — right-click any file."
        statusLabel?.textColor = .systemGreen
        enableButton?.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.onboardingWindow?.close()
        }
    }
}
