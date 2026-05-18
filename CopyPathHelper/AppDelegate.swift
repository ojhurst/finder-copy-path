import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Trace.write("delegate: did-finish-launching fired")
        NSApp.setActivationPolicy(.regular)
        presentOnboardingWindow()
        NSApp.activate(ignoringOtherApps: true)
        Trace.write("delegate: window presented")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Onboarding window

    private func presentOnboardingWindow() {
        let W: CGFloat = 520
        let H: CGFloat = 500

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: W, height: H),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Copy Path"
        window.isReleasedWhenClosed = false
        window.center()

        let content = NSView(frame: NSRect(x: 0, y: 0, width: W, height: H))

        // Title
        let title = NSTextField(labelWithString: "One more step")
        title.font = NSFont.systemFont(ofSize: 22, weight: .semibold)
        title.alignment = .center
        title.frame = NSRect(x: 0, y: 450, width: W, height: 28)
        content.addSubview(title)

        // Subtitle
        let subtitle = NSTextField(labelWithString:
            "Click below to open System Settings, then follow these two steps:")
        subtitle.font = NSFont.systemFont(ofSize: 13)
        subtitle.alignment = .center
        subtitle.textColor = .secondaryLabelColor
        subtitle.frame = NSRect(x: 20, y: 420, width: W - 40, height: 18)
        content.addSubview(subtitle)

        // Composed two-step diagram — wrapped in a labeled "example card" so
        // users read it as documentation, not as clickable UI.
        let imageTop: CGFloat = 395
        if let path = Bundle.main.path(forResource: "onboarding-target", ofType: "png"),
           let image = NSImage(contentsOfFile: path),
           image.size.width > 0,
           image.size.height > 0 {
            Trace.write("delegate: loaded onboarding image \(image.size.width)x\(image.size.height)")

            let imgW: CGFloat = 460
            let imgH = (imgW * image.size.height / image.size.width).rounded()

            let labelH: CGFloat = 18
            let cardPad: CGFloat = 12
            let cardW = imgW + cardPad * 2
            let cardH = imgH + labelH + cardPad * 2
            let cardX = (W - cardW) / 2
            let cardY = imageTop - cardH

            let card = NSView(frame: NSRect(x: cardX, y: cardY, width: cardW, height: cardH))
            card.wantsLayer = true
            card.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            card.layer?.borderColor = NSColor.separatorColor.cgColor
            card.layer?.borderWidth = 1
            card.layer?.cornerRadius = 10

            let label = NSTextField(labelWithString: "Example — what System Settings will look like")
            label.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
            label.alignment = .center
            label.textColor = .secondaryLabelColor
            label.frame = NSRect(x: cardPad, y: cardH - cardPad - labelH, width: imgW, height: labelH)
            card.addSubview(label)

            let imgView = NSImageView(frame: NSRect(x: cardPad, y: cardPad, width: imgW, height: imgH))
            imgView.image = image
            imgView.imageScaling = .scaleProportionallyDown
            imgView.imageAlignment = .alignCenter
            imgView.alphaValue = 0.95
            card.addSubview(imgView)

            content.addSubview(card)
        } else {
            Trace.write("delegate: onboarding image missing or invalid — skipped")
        }

        // Action button
        let button = NSButton(title: "Open System Settings",
                              target: self,
                              action: #selector(openSettings))
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.keyEquivalent = "\r"
        button.frame = NSRect(x: (W - 200) / 2, y: 70, width: 200, height: 32)
        content.addSubview(button)

        // Footer
        let status = NSTextField(labelWithString: "Once it's on, right-click any file in Finder to test.")
        status.font = NSFont.systemFont(ofSize: 12)
        status.alignment = .center
        status.textColor = .tertiaryLabelColor
        status.frame = NSRect(x: 0, y: 35, width: W, height: 18)
        content.addSubview(status)

        window.contentView = content
        window.makeKeyAndOrderFront(nil)
        onboardingWindow = window
    }

    @objc private func openSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.ExtensionsPreferences",
            "x-apple.systempreferences:",
        ]
        for raw in candidates {
            if let url = URL(string: raw), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}

enum Trace {
    static func write(_ msg: String) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let url = home.appendingPathComponent("copypath-trace.log")
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(msg)\n"
        guard let data = line.data(using: .utf8) else { return }
        if let fh = try? FileHandle(forWritingTo: url) {
            try? fh.seekToEnd()
            try? fh.write(contentsOf: data)
            try? fh.close()
        } else {
            try? data.write(to: url)
        }
    }
}
