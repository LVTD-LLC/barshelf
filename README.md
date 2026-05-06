# BarShelf

BarShelf is an open-source, free macOS menu bar manager experiment — a tiny native Bartender-style alternative.

## Current MVP

This first version is intentionally small and installable:

- runs as a native menu bar app
- adds a BarShelf separator and toggle item
- lets you hide icons using the proven separator/spacer pattern: hold `⌘` and drag menu bar icons into the hidden shelf, then collapse/expand the shelf
- includes a settings window for shelf width, auto-collapse delay, and an optional always-hidden separator
- packages as a `.dmg` on every GitHub release

## Important limitation

macOS does not provide a public API to directly hide, enumerate, or rearrange arbitrary third-party menu bar items. Commercial apps in this category rely on private APIs, Accessibility behavior, synthetic events, or visual overlay tricks.

BarShelf's MVP uses the safest open-source baseline first: user-arranged separators plus a collapsing spacer. It does not quit apps and does not require Accessibility permission.

## Install

Download the latest `BarShelf.dmg` from GitHub Releases, drag `BarShelf.app` into Applications, then launch it.

Usage: hold `Command (⌘)` and drag menu bar icons to the left of BarShelf's `│` separator, then click BarShelf to collapse/expand that hidden shelf.

## Build locally

```bash
swift build -c release
```

To create an app bundle locally on macOS:

```bash
./Scripts/build_app.sh
```

## Release

Create a GitHub release tag like `v0.1.0`. The release workflow builds on `macos-14`, creates `BarShelf.app`, packages `BarShelf.dmg`, and uploads it to the release assets.

## Roadmap

- Launch at login
- Keyboard shortcut
- Better notch/multi-display sizing
- Signed + notarized builds once Apple Developer credentials are available
- Optional advanced mode using private APIs / Accessibility for per-item control
- iOS research later, separately
