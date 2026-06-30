# Changes from upstream Blender

Blender is licensed under **GPL-2.0-or-later**. Per the GNU GPL (v2 §2(b): modified files must
carry prominent notices stating they were changed), this file documents that the program has been
modified and lists all changes.

## Base

- **Upstream:** Blender, official repository `https://projects.blender.org/blender/blender.git`
- **Branch:** `ios` (experimental)
- **Pinned commit:** `d9b6fe34ddce527d93b97c0bf42ad92cebac4e4e`
  ("iOS: Correct Info.plist CFBundleVersion version string", 2025-09-10)

All modifications below are provided as [patches/blender-ipad.patch](patches/blender-ipad.patch),
which applies cleanly on top of that commit.

## Modified files & what changed

### Input backend (the core of this project)
- `intern/ghost/intern/GHOST_WindowIOS.mm`
  - External **mouse** (GCMouse) buttons, movement, and wheel.
  - External **keyboard** (GCKeyboard) full key events, including UTF-8 text so numeric input
    during transforms works.
  - An `IndirectPointer` `UIPanGestureRecognizer` for accurate absolute pointer positions
    (fixes box-select drift and drives orbit/pan).
  - **Orbit** (middle-drag) via a 2-finger trackpad-scroll GHOST event; **pan** (Shift+middle)
    routed to Blender's native depth-correct pan modal.
  - **Pinch / two-finger trackpad zoom** (Magic Keyboard trackpad).
  - **Apple Pencil** tablet data (pressure / tilt) wired through the pan gesture recognizer so
    the first contact is already a pressured stylus dab; hover events suppressed during a pencil
    touch.
  - Render/secondary window teardown so **`Esc` closes the render window** (toplevel `UIWindow`
    hidden + main window reactivated in the destructor).

### Editor / window-manager glue (iOS-guarded)
- `source/blender/editors/space_view3d/view3d_navigate_view_move.cc` — let a real `MIDDLEMOUSE`
  press start the native grab-pan modal (depth/zoom correct).
- `source/blender/editors/interface/view2d/view2d_ops.cc` — enable middle-click-drag pan in UV /
  2D editors.
- `build_files/cmake/platform/platform_apple.cmake` — Apple/iOS build configuration.

### Branding (this distribution)
- `release/ios/Blender.app/Info.plist`
  - `CFBundleDisplayName` → **Blender iPad**
  - `CFBundleIdentifier` → `com.unofficial.blenderipad`
  - file-type UTI → `com.unofficial.blenderipad.file`
  - info string marked as an unofficial build, not affiliated with the Blender Foundation
- `release/ios/Blender.app/Assets/blender_icon.icns` — replaced with a distinct icon (the
  official Blender logo is not used). Source: [ios/icon/](ios/icon/) (`make_icon.swift`).

> The `.icns` is a binary asset shipped in [ios/icon/](ios/icon/) rather than in the text patch.
> Because iOS ignores `.icns`, PNG icons and `CFBundleIcons` keys are injected into the built
> `.app` post-build by [build/apply_branding.sh](build/apply_branding.sh).

## Development note

These modifications were developed with substantial **AI assistance** (Anthropic's Claude) —
the input backend code, build/packaging scripts, CI, documentation, and app icon. Treat the
code as community-contributed and review it before relying on it.
