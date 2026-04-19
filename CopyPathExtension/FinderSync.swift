import Cocoa
import FinderSync

class FinderSync: FIFinderSync {

    override init() {
        super.init()
        // Watch all mounted volumes so the menu item appears everywhere.
        let volumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: nil,
            options: [.skipHiddenVolumes]
        ) ?? []
        FIFinderSyncController.default().directoryURLs = Set(volumes)
    }

    // MARK: - Context Menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        // Only show on a right-click directly on selected items, not in empty space.
        guard menuKind == .contextualMenuForItems else { return nil }

        let menu = NSMenu(title: "")
        let item = NSMenuItem(
            title: "Copy Path",
            action: #selector(copyPath(_:)),
            keyEquivalent: ""
        )
        item.image = NSImage(systemSymbolName: "doc.on.clipboard",
                             accessibilityDescription: "Copy Path")
        menu.addItem(item)
        return menu
    }

    @objc func copyPath(_ sender: AnyObject?) {
        guard let urls = FIFinderSyncController.default().selectedItemURLs(),
              !urls.isEmpty else {
            return
        }

        // One path per line, no quoting. POSIX paths.
        let joined = urls.map { $0.path }.joined(separator: "\n")

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(joined, forType: .string)
    }
}
