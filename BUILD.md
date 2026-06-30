# Building from source

This documents how the distributed `.ipa` is produced, satisfying the GPL requirement that the
**complete corresponding source** be available. The build = **Blender upstream `ios` branch at a
pinned commit** + this repo's [patch](patches/blender-ipad.patch) + [icon](ios/icon/).

> **Heads up:** compiling Blender for iOS is heavy and the experimental `ios` branch needs
> iOS-specific precompiled libraries and a working CMake/Xcode toolchain. The patch in this repo
> is small; getting the *base* iOS build to compile is the hard prerequisite and largely follows
> upstream's experimental iOS setup. See [docs/DEV_NOTES.md](docs/DEV_NOTES.md) for project-specific
> notes.

## Prerequisites

- **macOS** with **Xcode** + command line tools (required — Xcode is macOS-only).
  - To build **without a local Mac**, use the cloud macOS runner in
    [.github/workflows/build-ipa.yml](.github/workflows/build-ipa.yml) (experimental).
- ~50 GB free disk, plenty of RAM.
- `git`, `cmake`.

## Steps

```bash
# 1. Get the exact upstream source this build is based on (Blender uses git LFS)
git clone https://projects.blender.org/blender/blender.git
cd blender
git checkout d9b6fe34ddce527d93b97c0bf42ad92cebac4e4e   # the pinned 'ios'-branch commit
git lfs install && git lfs pull                          # pulls startup.blend etc.

# 2. Download Blender's precompiled iOS libraries (the key flag is --use-ios-libraries)
python3 ./build_files/utils/make_update.py --no-blender --use-ios-libraries

# 3. Apply this project's source patch
git apply /path/to/blender-ipad-unofficial/patches/blender-ipad.patch

# 4. Use the distinct (trademark-safe) app icon
cp /path/to/blender-ipad-unofficial/ios/icon/blender_icon.icns \
   release/ios/Blender.app/Assets/blender_icon.icns

# 5. Configure an iOS Xcode build. APPLE_TARGET_DEVICE=ios sets up the whole iOS toolchain
#    (cross-compile, arm64, SDK, deployment target). Do NOT also pass CMAKE_SYSTEM_NAME /
#    CMAKE_OSX_* by hand — that can break the iOS Python library detection.
cmake -S . -B ~/build_ios_xcode -G Xcode \
  -DAPPLE_TARGET_DEVICE=ios \
  -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO

# 6. Build + repackage into an .ipa (this step is known-good and scripted)
cd ~/build_ios_xcode
xcodebuild -scheme install -configuration Release \
  -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO

# repackage bin/Release/Blender.app -> ~/Blender-iPad-Unofficial.ipa
bash /path/to/blender-ipad-unofficial/build/build_and_package.sh
```

The result is an **unsigned** `~/Blender-iPad-Unofficial.ipa`. Distribution is by sideloading
(each user signs it with their own Apple ID) — see [INSTALL.md](INSTALL.md). Attach it to a
GitHub Release.

## Notes

- `APPLE_TARGET_DEVICE=ios` configures the whole iOS toolchain; overriding `CMAKE_SYSTEM_NAME`
  or `CMAKE_OSX_*` by hand can break iOS Python detection. The cloud CI
  ([.github/workflows/build-ipa.yml](.github/workflows/build-ipa.yml)) uses the same minimal
  config, adapted from https://github.com/Toemeler/blender-iOS-ipa.
- The patch touches input handling (`GHOST_WindowIOS.mm`), two editor files, the Apple CMake
  platform file, and the iOS `Info.plist` (branding). See [CHANGES.md](CHANGES.md).
- **App icon:** iOS ignores the bundle's `.icns`, so the build injects PNG icons + `CFBundleIcons`
  keys into the built `.app` as a post-build step via
  [build/apply_branding.sh](build/apply_branding.sh) (also re-asserts the bundle id / display
  name). `build_and_package.sh` and the CI both call it.
- Keep the pinned commit in sync with [CHANGES.md](CHANGES.md) if you rebase onto a newer upstream.
