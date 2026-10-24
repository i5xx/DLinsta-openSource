# DLInsta — Instagram Downloader Tweak (reconstructed)

A Theos/Logos source project that reconstructs the behavior of `DLInsta.dylib`
(an Instagram photo/video downloader tweak). This is a **functional replica** — the
original shipped with obfuscated symbol names; this build uses clear names instead.

## What it does
- Long-press on a feed **photo** or **video** cell → DLInsta options (Save to Photos / Share / Copy Link).
- Direct messages (DM) thread → a "DL" nav button downloads the latest media.
- Optional Face ID / passcode gate before revealing the download action.
- Saves to the Photos library (via Photos framework), shows progress HUD, allows sharing.

Mirrors the original binary's structure:
`SafeGetters` → `DLGetSafe` · `DLTMore`/`DLTTrim` → `DLManager` · MBProgressHUD (bundled, minimal).

## Build
Requirements: macOS + Xcode + [Theos](https://theos.dev) + an iOS SDK.

```
cd DLInsta
make package            # builds .deb
make package install    # installs to a jailbroken device over SSH
```

## Install (jailbroken device)
```
dpkg -i com.dlinsta.tweak_1.0.0_iphoneos-arm64.deb
sbreload                # or: killall -9 SpringBoard; then relaunch Instagram
```

## Notes / limitations
- Instagram **does not export** these private classes; the feed hook targets
  (`IGFeedItemPhotoCell`, `IGFeedVideoCell`) are **INFERRED** community-standard names.
  If a given Instagram version renamed them, adjust the `%hook` classes and the media
  key names in `DLManager.m` (`mediaURLFromObject:` / `videoURLFromObject:`).
- CONFIRMED hooks from the original that are kept here: `IGDirectThreadViewController`,
  and the DM/voice/visual download flow. The like-button / story / reel double-tap hooks
  are documented in `../REPORT.md` but not all re-implemented in this first build.
- The original also had a license (`email`/`token`) gate; that is intentionally omitted
  (local Face ID gate used instead).