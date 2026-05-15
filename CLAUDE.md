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
- Signed with **Developer ID Application: Oliver Hurst (WG8568VB25)** for distribution. The signing identity name and team ID are pinned in `project.yml`.
- The Developer ID cert + matching private key live in the **MBP login keychain only**. Builds that need to sign must run on the MBP (or any machine where the private key has been imported). The Studio can build ad-hoc for dev iteration but cannot produce a notarizable artifact.
- For distribution builds, the artifact must be notarized by Apple. Notary creds are stored as `APPLE_NOTARY_*` in secrets.json. Use `xcrun notarytool submit` on the signed `.dmg` and then `xcrun stapler staple` before uploading to GitHub Releases.
- Sandbox entitlements grant absolute-path read-write so the extension can see paths anywhere on disk
- Architecture mirrors [finder-move](https://github.com/ojhurst/finder-move). Keep them in sync if patterns change.


## No time estimates, no stamina commentary
Do not estimate how long something will take. Do not comment on James's energy, time of day, or how long the session has run. Do not suggest pausing, saving for tomorrow, or coming back fresh. James decides when he is done. Just do the next thing.
