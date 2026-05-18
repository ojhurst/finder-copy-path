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
        let W: CGFloat = 480
        let H: CGFloat = 460

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
        title.frame = NSRect(x: 0, y: 410, width: W, height: 28)
        content.addSubview(title)

        // Subtitle — shorter so it fits one line at this width
        let subtitle = NSTextField(labelWithString:
            "Turn on the Copy Path extension to finish setup.")
        subtitle.font = NSFont.systemFont(ofSize: 13)
        subtitle.alignment = .center
        subtitle.textColor = .secondaryLabelColor
        subtitle.frame = NSRect(x: 20, y: 380, width: W - 40, height: 18)
        content.addSubview(subtitle)

        // Screenshot — wrapped in a labeled "example card" so it reads as
        // documentation rather than an interactive control.
        let imageTop: CGFloat = 360
        if let path = Bundle.main.path(forResource: "onboarding-target", ofType: "png"),
           let image = NSImage(contentsOfFile: path),
           image.size.width > 0,
           image.size.height > 0 {
            Trace.write("delegate: loaded onboarding image \(image.size.width)x\(image.size.height)")

            let imgW: CGFloat = 420
            let imgH = (imgW * image.size.height / image.size.width).rounded()

            // Card label — sits above the image, makes it clear this is an example
            let labelH: CGFloat = 18
            let cardPad: CGFloat = 10
            let cardW = imgW + cardPad * 2
            let cardH = imgH + labelH + cardPad * 2
            let cardX = (W - cardW) / 2
            let cardY = imageTop - cardH

            let card = NSView(frame: NSRect(x: cardX, y: cardY, width: cardW, height: cardH))
            card.wantsLayer = true
            card.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            card.layer?.borderColor = NSColor.separatorColor.cgColor
            card.layer?.borderWidth = 1
            card.layer?.cornerRadius = 8

            let label = NSTextField(labelWithString: "Example — find this row in System Settings")
            label.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
            label.alignment = .center
            label.textColor = .secondaryLabelColor
            label.frame = NSRect(x: cardPad, y: cardH - cardPad - labelH, width: imgW, height: labelH)
            card.addSubview(label)

            let imgView = NSImageView(frame: NSRect(x: cardPad, y: cardPad, width: imgW, height: imgH))
            imgView.image = image
            imgView.imageScaling = .scaleProportionallyDown
            imgView.imageAlignment = .alignCenter
            imgView.alphaValue = 0.92  // subtle dim to feel like documentation
            card.addSubview(imgView)

            content.addSubview(card)
        } else {
            Trace.write("delegate: onboarding image missing or invalid — skipped")
        }

        // Instructions — explanatory, since the image already shows what to flip
        let instructions = NSTextField(wrappingLabelWithString:
            "Click below, find the row above, click its ⓘ icon, then flip the toggle on.")
        instructions.font = NSFont.systemFont(ofSize: 13)
        instructions.alignment = .center
        instructions.textColor = .secondaryLabelColor
        instructions.frame = NSRect(x: 40, y: 130, width: W - 80, height: 40)
        content.addSubview(instructions)

        // Action button
        let button = NSButton(title: "Open System Settings",
                              target: self,
                              action: #selector(openSettings))
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.keyEquivalent = "\r"
        button.frame = NSRect(x: (W - 200) / 2, y: 75, width: 200, height: 32)
        content.addSubview(button)

        // Footer
        let status = NSTextField(labelWithString: "Once it's on, right-click any file in Finder to test.")
        status.font = NSFont.systemFont(ofSize: 12)
        status.alignment = .center
        status.textColor = .tertiaryLabelColor
        status.frame = NSRect(x: 0, y: 38, width: W, height: 18)
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
