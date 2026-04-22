# Copy Path for Finder

A tiny macOS Finder extension that adds a **"Copy Path"** option to the right-click menu — always visible, no Option key required.

macOS already has this hidden behind holding Option while the menu is open. Nobody knows that. This extension puts it where it belongs.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![License: MIT](https://img.shields.io/badge/License-MIT-green)

## How it works

1. **Right-click** any file or folder in Finder
2. Click **"Copy Path"**
3. The full POSIX path is on your clipboard, ready to paste

If multiple files are selected, all paths are copied, one per line.

### Cloud folders (Google Drive, iCloud Drive, Dropbox, OneDrive)

The right-click item intentionally does not appear inside cloud FileProvider mounts — Apple reserves those folders for the provider's own FinderSync extension. Inside a cloud folder, use macOS's built-in shortcut instead:

- Select a file
- Press **Option + Command + C**

Same result. This is a platform limitation, not a bug.

## Install

### From source (requires Xcode)

```bash
git clone https://github.com/ojhurst/finder-copy-path.git
cd finder-copy-path
brew install xcodegen  # if you don't have it
xcodegen generate
xcodebuild -project CopyPathHelper.xcodeproj -scheme CopyPathHelper -configuration Release build
```

Copy the built app to `/Applications`:

```bash
cp -R ~/Library/Developer/Xcode/DerivedData/CopyPathHelper-*/Build/Products/Release/CopyPathHelper.app /Applications/
```

Launch it, then enable the extension:

```bash
open /Applications/CopyPathHelper.app
pluginkit -e use -i com.ojhurst.CopyPathHelper.CopyPathExtension
```

### Verify it's running

```bash
pluginkit -m -p com.apple.FinderSync
```

You should see `+  com.ojhurst.CopyPathHelper.CopyPathExtension` in the output.

## Uninstall

```bash
pluginkit -e ignore -i com.ojhurst.CopyPathHelper.CopyPathExtension
rm -rf /Applications/CopyPathHelper.app
```

## How it's built

- **CopyPathHelper** — A minimal container app with no UI. Hides from the Dock. Exists only to host the extension.
- **CopyPathExtension** — A [Finder Sync Extension](https://developer.apple.com/documentation/findersync) that watches all mounted volumes and adds the context menu item whenever files are right-clicked.

Built with Swift, uses XcodeGen for project generation. Same architecture as [finder-move](https://github.com/ojhurst/finder-move).

## License

[MIT](LICENSE) — do whatever you want with it.
