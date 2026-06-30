# Blender iPad (Unofficial)

An **unofficial**, community-modified build of [Blender](https://www.blender.org) that adds
**external keyboard, mouse/trackpad, and Apple Pencil** support so Blender becomes genuinely
usable on iPad.

> ⚠️ **This is not an official Blender release.** It is **not affiliated with, endorsed by, or
> supported by the Blender Foundation.** "Blender" is a registered trademark of the Blender
> Foundation; this project uses the name only to truthfully describe that it is a build *of*
> Blender. See [TRADEMARK.md](TRADEMARK.md). Do **not** report issues from this build to the
> Blender Foundation — open an issue here instead.

This build is based on Blender's experimental `ios` branch and adds the input handling that was
missing on iPad (external keyboard, mouse/trackpad, Apple Pencil), plus branding changes,
distributed as a patch on top of upstream.

- Upstream source: Blender `ios` branch — https://projects.blender.org/blender/blender
- Build it yourself: [BUILD.md](BUILD.md)

---

## ✨ What this adds

The official iOS branch boots Blender on iPad but leaves keyboard / mouse / pencil input largely
unimplemented. This build implements it so Blender is actually usable with external hardware.

### Input

- **External keyboard** — the full Blender shortcut set, including **typing numeric values during
  transforms** (e.g. `G` `X` `2` `Enter` to move exactly 2 units on X).
- **Mouse** — left / right / middle click & drag; **wheel = zoom**.
- **Viewport navigation without any add-on** — **middle-drag = orbit**, **`Shift` + middle-drag =
  pan** (routed through Blender's native depth-correct pan, so the grabbed point stays put).
- **Marquee / box select** with an accurate, drift-free pointer position.
- **UV / 2D editors** — middle-drag pan (matches the 3D viewport).
- **Magic Keyboard trackpad** — two-finger pinch / pan to zoom.
- **Apple Pencil** — real **pressure sensitivity** for texture painting and sculpting, with the
  first contact already pressured (no stray pressureless dab at the start, no stray line on lift).

### Beyond standard Blender — iPad-specific behavior

iOS apps have no window title bar or close button, so Blender's extra windows could otherwise trap
you with no way out. This build adds:

- **`Esc` closes the active secondary window** — Preferences, the "Save As" / file-browser window,
  etc. On desktop you'd click the window's close button; on iPad there isn't one, so `Esc` is the
  way out.
- **`Esc` closes the render window** — after an `F12` render, `Esc` dismisses the render result and
  returns you to the main editor. (On iOS the render opens as a separate top-level window that has
  no on-screen close control of its own.)

> Full technical write-up of every change (root cause + implementation) is in
> [docs/DEV_NOTES.md](docs/DEV_NOTES.md); the exact code diff is in
> [patches/blender-ipad.patch](patches/blender-ipad.patch).

## 📱 Requirements

- An iPad running a recent iPadOS (developed and tested on **iPadOS 26.5**).
- An external **keyboard + mouse**, or a Magic Keyboard with trackpad. (Apple Pencil optional.)
- A way to **sideload** an `.ipa` — see [INSTALL.md](INSTALL.md). This app is **not** on the
  App Store.

## 📥 Install

This app is distributed as an **unsigned `.ipa`** that you sideload onto your own iPad. There is
**no Mac required to install** — but a free Apple ID (and a one-time computer step for some
methods) is needed for signing.

👉 **Step-by-step guide: [INSTALL.md](INSTALL.md)** (English + 한국어)

Download the latest `.ipa` from the [Releases](../../releases) page.

| Method | Needs a Mac? | Re-sign interval | iPadOS 26.5 |
|---|---|---|---|
| **Sideloadly** (Win/Mac) | No (Windows works) | 7 days (free ID) / 1 year (paid) | ✅ |
| **AltStore / SideStore** | No (Windows works) | 7 days, auto-refresh | ✅ * |
| Apple Developer account ($99/yr) | No | 1 year | ✅ |
| TrollStore | — | permanent | ❌ (iOS ≤ 16 only) |

\* iPadOS 26 is very new — confirm your sideloading tool currently supports it.

## 🛠 Build from source

You do **not** need a local Mac if you use the GitHub Actions workflow (cloud macOS runner) —
see [.github/workflows/build-ipa.yml](.github/workflows/build-ipa.yml). To build locally on a
Mac, see **[BUILD.md](BUILD.md)**. The complete corresponding source is: Blender upstream `ios`
branch at the pinned commit + [patches/blender-ipad.patch](patches/blender-ipad.patch).

## 📄 License

Blender — and therefore this build — is licensed under the **GNU General Public License v2.0 or
later** (matching upstream Blender). The full text is in [LICENSE](LICENSE). As required by the GPL, the complete
corresponding source for the distributed binary is published here (upstream commit + patch), and
the modifications are documented in [CHANGES.md](CHANGES.md).

## 🙏 Credits

- The **Blender Foundation** and Blender contributors — for Blender itself and the experimental
  iOS branch. This project would not exist without their work.
- Input-backend, branding, and packaging changes for iPad in this repo are community
  contributions and are **not** the work of the Blender Foundation.
- **🤖 AI-assisted:** the iPad input code, build/packaging, documentation, and app icon in this
  repo were created with substantial help from AI (Anthropic's Claude). Everything is provided
  as-is under the GPL — review the code before relying on it.

## 🇰🇷 한국어 요약

iPad에서 외장 **키보드 · 마우스/트랙패드 · 애플펜슬**을 제대로 쓸 수 있게 만든 **비공식** 블렌더 빌드입니다.
공식 릴리스가 **아니며** 블렌더 재단과 **무관**합니다. 설치는 맥 없이도 가능하며(사이드로드), 자세한
방법은 [INSTALL.md](INSTALL.md)에 한국어로 정리돼 있습니다. 소스 빌드는 [BUILD.md](BUILD.md) 참고.

**추가 기능:** 외장 키보드 전체 단축키(변형 중 숫자값 입력 포함), 마우스 클릭·드래그, 휠=줌,
휠클릭드래그=회전 / `Shift`+휠클릭드래그=이동, 박스선택, UV·2D 에디터 이동, 트랙패드 핀치 줌,
애플펜슬 필압(텍스처 페인팅·스컬프팅). 그리고 **기존 블렌더에 없는 iPad 전용 기능 — iOS에는 창
닫기 버튼이 없어서, `Esc`로 보조 창(설정·저장)과 렌더 창을 닫을 수 있게 추가**했습니다.

> 🤖 이 프로젝트(코드·문서·아이콘)는 **AI(Anthropic Claude)의 도움으로 제작**되었습니다.
