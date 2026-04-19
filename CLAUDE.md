# finder-copy-path

> Inherits from the global CLAUDE.md (`~/.claude/CLAUDE.md`). This file covers repo-specific conventions only.

## What This Is
macOS Finder extension that adds an always-visible "Copy Path" item to the right-click menu.

## Tech Stack
- Swift, AppKit, FinderSync framework
- XcodeGen for project file generation
- Targets macOS 13+

## Build Number
- Stored in `build.txt` (plain integer, root of repo)
- Bump on every commit: `echo $(($(cat build.txt) + 1)) > build.txt`
- Commit message format: `Build X: short summary`
- Always announce after bumping

## Dev Workflow
1. Edit Swift sources in `CopyPathHelper/` or `CopyPathExtension/`
2. Regenerate Xcode project: `xcodegen generate`
3. Build: `xcodebuild -project CopyPathHelper.xcodeproj -scheme CopyPathHelper -configuration Release build`
4. Reinstall: `cp -R ~/Library/Developer/Xcode/DerivedData/CopyPathHelper-*/Build/Products/Release/CopyPathHelper.app /Applications/`
5. Re-launch the app once so macOS notices the new build, then reload the extension:
   ```bash
   pluginkit -e ignore -i com.ojhurst.CopyPathHelper.CopyPathExtension
   pluginkit -e use    -i com.ojhurst.CopyPathHelper.CopyPathExtension
   ```
6. Test by right-clicking a file in Finder

## Repo-Specific Conventions
- The extension is **ad-hoc signed** (`CODE_SIGN_IDENTITY: "-"`) — fine for personal install, would need a real Developer ID for distribution
- Sandbox entitlements grant absolute-path read-write so the extension can see paths anywhere on disk
- Architecture mirrors [finder-move](https://github.com/ojhurst/finder-move). Keep them in sync if patterns change.
