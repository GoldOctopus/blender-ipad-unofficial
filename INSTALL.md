# Installing on your iPad

This app is **not on the App Store**. You install it by **sideloading** an unsigned `.ipa`.
Download the latest `Blender-iPad-Unofficial.ipa` from the
[**Releases**](../../releases) page first.

> **No Mac is required.** Windows or Linux works for the one-time signing step. There is,
> however, no way to do everything with a free Apple ID from the iPad *alone* — you need a
> computer at least once (or a paid Apple Developer account).

---

## ⚠️ Read this first (applies to every method)

1. **Enable Developer Mode** (required on iPadOS 16 and later, including iPadOS 26):
   `Settings → Privacy & Security → Developer Mode → On`, then restart.
2. **Free Apple ID signing expires after 7 days.** The app stops opening after a week and must be
   re-signed/re-installed. A **paid Apple Developer account ($99/yr)** lasts **1 year**.
   AltStore/SideStore can re-sign automatically.
3. **Free Apple ID = max 3 sideloaded apps** at a time.
4. **Trust the certificate** after installing:
   `Settings → General → VPN & Device Management →` tap your developer profile → **Trust**.
5. This build's identifier is `com.unofficial.blenderipad`, so it installs **alongside** any
   other Blender app. Delete older copies if you don't want duplicates.
6. iPadOS 26 is very new — make sure your chosen tool already supports it before you start.

---

## Method A — Sideloadly (simplest)

Works on **Windows and macOS**. Good if you just want it installed.

1. Install **Sideloadly** from https://sideloadly.io and **iTunes** (Windows) / nothing extra
   (macOS).
2. Connect the iPad by USB and trust the computer.
3. Open Sideloadly, drag in `Blender-iPad-Unofficial.ipa`.
4. Enter your **Apple ID** (a free one works; a throwaway Apple ID is fine and safer).
5. Click **Start**. Sideloadly signs and installs it.
6. On the iPad, enable Developer Mode (step above) and **Trust** the certificate.
7. Launch **Blender iPad**.

Re-run these steps every 7 days (free Apple ID) to refresh.

## Method B — AltStore / SideStore (auto-refresh)

Best if you don't want to re-install manually every week.

- **AltStore** (https://altstore.io) — install **AltServer** on your computer (required on both
  Windows and macOS); it re-signs over Wi-Fi while your computer is on the same network.
- **SideStore** (https://sidestore.io) — after a **one-time pairing** (done with a computer), it
  re-signs **on the iPad itself**, no computer needed afterward.

Steps (high level): install AltServer/SideStore → in the app, tap **+** and choose the downloaded
`.ipa` → sign in with your Apple ID → enable Developer Mode + Trust → done. The app auto-refreshes
before the 7 days expire as long as the requirements (server online / SideStore pairing) are met.

## Method C — Paid Apple Developer account

If you have a paid account ($99/yr), sign with it (via Sideloadly, AltStore, or Xcode/Apple
Configurator). The install lasts **1 year** and there's no 3-app limit. Best for a stable setup.

> **TrollStore is not an option** here — it permanently installs apps with no expiry, but only on
> **iOS 14–16.x**. It does **not** work on iPadOS 26.

---

## Troubleshooting

- **"Unable to install" / "could not be verified"** → you skipped *Trust the certificate* (step
  4) or *Developer Mode* (step 1).
- **App opens then immediately closes / won't open after a week** → the 7-day free signature
  expired. Re-sign/re-install.
- **"Maximum number of apps installed"** → free Apple IDs allow only 3 sideloaded apps; remove
  one.
- **Install fails over USB** → unplug/replug, make sure no other tool is holding the USB device
  connection, and retry.

---

# 🇰🇷 한국어 설치 가이드

이 앱은 **앱스토어에 없습니다.** 서명되지 않은 `.ipa`를 **사이드로드**해서 설치합니다.
먼저 [**Releases**](../../releases)에서 최신 `Blender-iPad-Unofficial.ipa`를 받으세요.

> **맥은 필요 없습니다.** 윈도우/리눅스로도 1회 서명이 가능합니다. 다만 무료 애플 ID 방식은
> **아이패드 한 대만으로는** 안 되고, 최소 한 번은 컴퓨터가 필요합니다(또는 유료 개발자 계정).

## ⚠️ 먼저 확인 (모든 방법 공통)

1. **개발자 모드 켜기** (iPadOS 16 이상, 26 포함 **필수**):
   `설정 → 개인정보 보호 및 보안 → 개발자 모드 → 켬` 후 재시동.
2. **무료 애플 ID 서명은 7일 후 만료** — 일주일 지나면 앱이 안 열려서 재설치/재서명해야 합니다.
   **유료 개발자 계정($99/년)은 1년** 유효. AltStore/SideStore는 자동 재서명.
3. 무료 애플 ID는 **동시에 앱 3개까지**.
4. 설치 후 **인증서 신뢰**: `설정 → 일반 → VPN 및 기기 관리 →` 개발자 프로필 → **신뢰**.
5. 이 빌드의 식별자는 `com.unofficial.blenderipad`라 기존 블렌더 앱과 **별개로** 설치됩니다.
   중복이 싫으면 옛 버전 삭제하세요.
6. iPadOS 26은 매우 최신이라, 쓰려는 도구가 26을 지원하는지 먼저 확인하세요.

## 방법 A — Sideloadly (가장 간단)

**윈도우/맥** 모두 가능. 그냥 설치만 하면 될 때 추천.

1. https://sideloadly.io 에서 **Sideloadly** 설치 (윈도우는 **iTunes**도).
2. 아이패드 USB 연결 + 컴퓨터 신뢰.
3. Sideloadly에 `Blender-iPad-Unofficial.ipa`를 끌어다 놓기.
4. **애플 ID** 입력 (무료 ID 가능, 버리는 용 ID 권장).
5. **Start** → 서명·설치.
6. 아이패드에서 개발자 모드 켜고 인증서 **신뢰**.
7. **Blender iPad** 실행. 7일마다 반복.

## 방법 B — AltStore / SideStore (자동 갱신)

매주 수동 설치가 귀찮을 때.

- **AltStore** — 컴퓨터(윈도우/맥 모두)에 **AltServer** 설치 필요, 같은 와이파이에서 자동 재서명.
- **SideStore** — **1회 페어링**(컴퓨터로) 후엔 **아이패드 자체에서** 재서명(이후 컴퓨터 불필요).

설치 → 앱에서 **+** 로 받은 `.ipa` 선택 → 애플 ID 로그인 → 개발자 모드+신뢰 → 끝. 조건만 맞으면
7일 전에 자동 갱신됩니다.

## 방법 C — 유료 개발자 계정

유료 계정이면 그것으로 서명 — **1년** 유효, 3개 제한 없음. 안정적으로 쓰려면 이게 최고.

> **TrollStore는 불가** — 영구 설치지만 **iOS 14~16.x 전용**, iPadOS 26은 안 됩니다.

## 문제 해결

- **"설치할 수 없음 / 확인할 수 없음"** → 인증서 신뢰(4) 또는 개발자 모드(1) 빠짐.
- **앱이 켜졌다 꺼짐 / 일주일 뒤 안 열림** → 7일 무료 서명 만료 → 재설치.
- **"앱 최대 개수"** → 무료 ID는 3개 제한 → 하나 지우기.
- **USB 설치 실패** → 케이블 뽑았다 끼우고, 다른 프로그램이 USB 연결을 잡고 있지 않은지 확인 후 재시도.
