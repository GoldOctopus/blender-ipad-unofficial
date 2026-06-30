# Blender iPad 키보드/마우스 지원 — 작업 인수인계 문서

> iPad Pro에서 Blender(실험적 `ios` 브랜치)에 외장 키보드/마우스 지원을 직접 C++로 구현한 프로젝트.
> 챗에서 진행하던 작업을 코드 에디터로 옮기기 위한 전체 정리 문서.
> 작성 시점: 2026-06-29

---

## 0. 한 줄 요약

공식 Blender iOS 브랜치는 키보드/마우스가 미구현(TODO) 상태로 자금 부족으로 보류됨. 이 프로젝트는 GHOST 입력 백엔드(`GHOST_WindowIOS.mm`)를 직접 수정해서 **외장 키보드 전체 단축키 + 마우스 클릭/휠/이동 + 2차 창 입력/ESC 닫기**를 구현했고, **뷰 회전/팬은 Python 애드온**으로 처리한다. 공식 빌드가 하나도 못 하는 것들을 다 동작시킨 상태.

---

## 1. 환경 / 계정 정보

| 항목 | 값 |
|---|---|
| 빌드 머신 | **Intel Mac** (Apple Silicon 아님 — 이게 빌드를 어렵게 만든 핵심) |
| Xcode | 16.4.0 (`/Applications/Xcode 16.4.app`) — iOS 컴포넌트(~30GB) 설치 필수 |
| 타깃 기기 | iPad Pro 11" M5, iPadOS 26.5 |
| 기기 UDID | `00008142-000431690CD8401C` |
| Apple ID | yjo4001@gmail.com |
| Team ID | 83SYMW3AT4 |
| 사이드로드 | Sideloadly (https://sideloadly.io), Developer Mode ON, **7일마다 재서명 필요** |
| 소스 위치 | `~/blender` |
| 빌드 디렉토리 | `~/build_ios_xcode` |
| 출력 앱 | `~/build_ios_xcode/bin/Release/Blender.app` |
| IPA | `~/Blender.ipa` (~232MB) |

사용자는 C++ 전문가가 아님 → 어시스턴트가 정확한 코드/스크립트를 주고, 사용자가 빌드/테스트 후 결과 보고하는 방식으로 진행해왔음.

---

## 2. 빌드 방법 (Phase 1 — 완료, 재현 가능)

공식 `ios` 브랜치는 Blender 팀이 자금 부족으로 **보류(on hold)** 상태, Android 우선으로 선회. App Store 배포 없음 → 소스 빌드 + 사이드로드가 유일한 길.

### 2-1. 의존성 빌드 (수 시간 소요)

```bash
# 빌드 툴 설치
brew install autoconf bison dos2unix flex fmt git git-lfs libtool yasm automake

# 소스 + iOS 브랜치
git clone https://projects.blender.org/blender/blender.git
cd blender
git checkout ios

# 의존성 직접 컴파일 (macOS x64 라이브러리)
make deps
```

**핵심 함정 — CMake 버전:** CMake 4.x는 옛날 `cmake_minimum_required` (3.5 미만) 지원을 제거해서 alembic 등에서 `CMP0042` 정책 에러로 막힘. 환경변수(`CMAKE_POLICY_VERSION_MINIMUM=3.5`)로는 alembic을 못 넘김.
→ **해결: CMake를 3.31.12로 다운그레이드** (cmake.org에서 `cmake-3.31.12-macos-universal.dmg`):
```bash
sudo "/Applications/CMake.app/Contents/bin/cmake-gui" --install
brew uninstall cmake          # brew 4.x가 PATH 선점하면 제거
hash -r
cmake --version               # 3.31.12 확인 필수
```

### 2-2. iOS 라이브러리 + cmake 패치

`make deps`는 macOS x64만 만듦. iOS arm64 라이브러리는 **별도로 클론**:
```bash
cd ~/blender/lib
git clone --depth 1 https://projects.blender.org/blender/lib-ios_arm64.git ios_arm64
```

호스트 python 심볼릭 링크:
```bash
ln -s ~/blender/lib/macos_x64/python ~/blender/lib/macos_arm64/python
```

`build_files/cmake/platform/platform_apple.cmake`에서 `FATAL_ERROR` → `WARNING` 변경 (사전 컴파일 라이브러리 git 체크를 우회). 대략 57번째 줄 근처와 177번째 줄(IOS build requires...) 양쪽.

### 2-3. Xcode 제너레이터로 빌드

`make`가 아니라 **Xcode 제너레이터** 사용 (이게 iOS 빌드의 정석):
```bash
cmake -G Xcode -S . -B ../build_ios_xcode
```

### 2-4. 빌드 / 패키징 / 설치 루프 (★ 매번 반복하는 핵심 사이클 ★)

```bash
# 1) 빌드
cd ~/build_ios_xcode
xcodebuild -scheme install -configuration Release -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO 2>&1 | tee ~/build.log
# 에러 확인: grep -n "error:" ~/build.log | head -30

# 2) .ipa 재패키징 (★ 빌드 후 반드시! 안 하면 옛날 앱이 설치됨 ★)
cd ~/build_ios_xcode/bin/Release
rm -rf Payload ~/Blender.ipa && mkdir -p Payload && cp -R Blender.app Payload/ && zip -r ~/Blender.ipa Payload && rm -rf Payload

# 3) Sideloadly로 ~/Blender.ipa 설치
```

**주의:** 빌드(xcodebuild)는 `build_ios_xcode/bin/Release/Blender.app`만 갱신. 설치는 `~/Blender.ipa`라서 **2단계(재패키징)를 빠뜨리면 변경사항이 기기에 안 들어감.** 디버깅 중 "로그가 안 떠"의 가장 흔한 원인이 이거였음.

---

## 3. 핵심 소스 파일

| 파일 | 역할 |
|---|---|
| `~/blender/intern/ghost/intern/GHOST_WindowIOS.mm` | **메인 수정 대상.** 모든 입력 핸들러가 여기 있음 |
| `GHOST_SystemIOS.mm` / `.hh` | 시스템 레벨, 윈도우 관리. `current_active_window_`(public), `hasDialogWindow()` |
| `GHOST_WindowCocoa.mm` / `GHOST_SystemCocoa.mm` | macOS 참고용 청사진 (윈도우 닫기 등 패턴 참조) |
| `GHOST_System.hh` | `getWindowManager()` (line 220, public, inline) |
| `GHOST_Types.h` | `GHOST_kKeyEsc=0x1B`, `GHOST_kKeyF11`, `GHOST_kEventWindowClose`(370), 트랙패드 서브타입(669~) |

### 중요한 제약/사실
- **이 파일은 MRC(manual reference counting)로 컴파일됨** → `__weak` 금지, `__unsafe_unretained` 사용
- **`GCKeyCode` 상수는 컴파일타임 상수가 아님** → `switch` 불가, **if/else 체인 사용**
- 백업 파일 존재: `GHOST_WindowIOS.mm.backup` ~ `.backup7`

### 주요 GHOST 이벤트 생성자 (확인됨)
```cpp
GHOST_EventKey(msec, type, window, GHOST_TKey, is_repeat, utf8_buf)  // utf8 nullptr 가능
GHOST_EventButton(msec, type, window, GHOST_kButtonMaskLeft/Right/Middle, GHOST_TABLET_DATA_NONE)
GHOST_EventWheel(msec, window, GHOST_kEventWheelAxisVertical/Horizontal, int32_t value)
GHOST_EventCursor(msec, GHOST_kEventCursorMove, window, x, y, GHOST_TABLET_DATA_NONE)
GHOST_EventTrackpad(msec, window, subtype, x, y, deltaX, deltaY, isDirectionInverted, numFingers)
GHOST_Event(msec, GHOST_kEventWindowClose, window)   // 단순 이벤트
```

---

## 4. 구현 내용 (Phase 2 — 동작 중)

공식 iOS 백엔드는 키보드/마우스가 전부 미구현 TODO였음 (issue/PR 다 설계 제안뿐, 머지된 코드 없음. event_simulate는 iPad가 못 주는 런치 플래그 필요). 그래서 전부 손으로 구현.

### `GHOST_WindowIOS.mm` 내 주요 구조 (라인 번호는 대략값, 변할 수 있음)

- **라인 ~28**: `#define IOS_INPUT_LOGGING` — 디버그 로그 토글. **현재 켜짐.** 끄면 모든 `IOS_INPUT_LOG`가 no-op. (최종 릴리스 시 다시 주석 처리)
- **라인 ~1306 `ghost_key_from_gckeycode()`**: GCKeyCode → GHOST_TKey 변환. **if/else 체인** (switch 아님). A-Z, 0-9, 특수키, 화살표, 수정자(L/R Shift/Ctrl/Alt/GUI→OS), 문장부호, F1-F12, ESC(`GCKeyCodeEscape`→`GHOST_kKeyEsc`)
- **라인 ~868 `handleHover:`**: 마우스 이동. **이게 원래부터 잘 되던 기능 — 절대 깨면 안 됨.** hover_point를 `mouse_cursor_x/y`에 항상 저장. `DRAG_HOVER_ACCURATE` 패치로 드래그 중에도 CURSOR_MOVE emit (박스선택 정확도용)
- **라인 ~1360 `externalMouseChange:`**: 마우스 연결 시 핸들러 등록
  - leftButton/rightButton/middleButton `pressedChangedHandler` → `mouse_left/middle/right_pressed` 플래그 설정 + `getActiveWindow()`로 EventButton
  - `mouseMovedHandler` → 버튼 눌림 시 델타 누적해서 EventCursor (드래그 구동 — 빼면 박스선택/회전팬 깨짐)
  - `scroll.yAxis.valueChangedHandler` → EventWheel (마우스 휠 줌)
- **라인 ~444 `scroll_gesture_recognizer`**: 별도 UIPanGestureRecognizer, `allowedTouchTypes=@[]`, `allowedScrollTypesMask=UIScrollTypeMaskAll`. 마우스 휠은 GameController가 아니라 UIKit HID 경로로 와서 이게 필요. `handleScroll:`에서 EventWheel/EventTrackpad
- **라인 ~?  externalKeyboardChange: → keyChangedHandler**: 키보드. ESC 처리 분기 포함 (아래 ESC 항목)

### 멤버 변수 (GHOST_WindowIOS.mm 헤더 영역, 라인 ~246-274)
```
last_scroll_y/x, scroll_accum_y      // 휠 스크롤 (사용 중)
external_keyboard_connected           // 사용 중
external_mouse_connected              // 사용 중
mouse_left/middle/right_pressed       // 버튼 상태 (애드온이 회전/팬에 사용)
mouse_cursor_x/y                      // 드래그 커서 추적 (사용 중)
mouse_pos_valid                       // ★ 죽은 변수 (대입만 하고 안 읽음) — 유일하게 안전히 제거 가능
```

---

## 5. 적용된 C++ 패치 순서 (`patches/` 폴더)

현재 빌드에 들어가 있는 패치들. 처음부터 다시 빌드한다면 이 순서로 적용:

1. **`add_mouse_input.py`** — 키보드 + 좌/우/중 클릭 + 마우스 이동(hover) 기본 구현
2. **`add_mouse_wheel.py`** — GCMouse scroll 핸들러
3. **`add_wheel_gesture.py`** — UIKit 휠 스크롤 제스처 (실제 휠은 이 경로로 옴)
4. **`fix_weak_mrc.py`** — `__weak` → `__unsafe_unretained` (MRC 컴파일 에러 수정)
5. **`fix_drag_any_button.py`** — 중간/우클릭 눌림 추적 (드래그용)
6. **`fix_drag_hybrid.py`** + **`fix_drag_use_hover.py`** — 드래그 hover/델타 하이브리드
7. **`fix_active_window_input.py`** — ★중요★ 키보드/버튼을 `getActiveWindow()`로 전송 → 2차 창(렌더/설정/저장)에서 입력 동작. `#include "GHOST_WindowManager.hh"` 추가 필요 (incomplete type 에러 방지)
8. **`fix_esc_close_window.py`** — ESC로 2차 창 닫기 (windows>1이면 활성 창에 `GHOST_kEventWindowClose`)
9. **`fix_drag_hover_accurate.py`** — 드래그 중 hover가 CURSOR_MOVE emit (박스선택 정확도 개선)

> 주의: 이 패치들은 이미 코드에 적용된 상태. 패치 파일은 "어떻게 만들어졌는지" 기록 + 재현용. 코드 에디터로 옮기면 패치 스크립트 대신 소스를 직접 편집하면 됨.

### ESC 2차 창 닫기 로직 (현재 keyChangedHandler 안)
```cpp
if (ghost_key == GHOST_kKeyEsc && pressed) {
    // 진단 로그
    if (sys->getWindowManager()->getWindows().size() > 1) {
        GHOST_IWindow *close_win = sys->getWindowManager()->getActiveWindow();
        if (close_win) {
            sys->pushEvent(new GHOST_Event(..., GHOST_kEventWindowClose, close_win));
            return;   // ESC 소비 (메인으로 안 샘)
        }
    }
}
```
설정창/저장창은 닫힘. **렌더창은 안 닫힘** (별도 처리 필요 — 6번 항목 참조).

---

## 6. 애드온 (`addons/` 폴더)

### `mmb_orbit_pan_v3.py` — ★ 실사용 중, Blender Preferences에 정식 설치됨 ★
- **중간버튼(휠클릭) 드래그 = 뷰 회전 (orbit)**
- **Shift + 중간버튼 드래그 = 뷰 이동 (pan)**
- 자동 시작 (`bpy.app.timers`로 등록 직후 모달 실행 — START 버튼 안 눌러도 됨)
- 회전: 쿼터니언 (글로벌 Z축 yaw + 뷰 로컬 X축 pitch), `_orbit_sensitivity = 0.005`
- 팬: `bpy_extras.view3d_utils.region_2d_to_location_3d`로 정확한 커서-고정 패닝 (아주 미세한 드리프트는 있으나 수용됨)

**왜 애드온인가:** iPad Blender의 뷰 회전은 두 손가락 트랙패드 팬으로 처리됨 (GHOST_EventTrackpad Scroll). GCMouse 중간버튼 + 키맵(Middle=Rotate)이 있어도 C++로는 회전이 안 일어남. 여러 방법(커서이동/트랙패드 변환) 다 실패. → **C++로 입력만 받고, 동작은 애드온 모달이 직접 `region_3d` 조작.** 이게 통했음.

핵심 발견: 2차 창 떠 있을 땐 애드온 모달이 입력을 못 받음 (모달이 막힘). 그래서 ESC 2차 창 닫기는 애드온이 아니라 C++로 해야 했음.

---

## 7. 진단/미적용 파일 (`diagnostics/` 폴더)

참고용. 현재 빌드에 안 들어간 것들:
- **`input_diagnostic.py`, `mmb_diag.py`, `esc_diag.py`** — 입력 수신 여부 확인용 진단 애드온
- **`esc_close.py`** — ESC 2차 창 닫기를 애드온으로 시도 (실패 — 2차 창 떠 있으면 애드온이 ESC 못 받음)
- **`fix_wheelclick_rotate.py`** — 휠클릭을 트랙패드 이벤트로 변환 시도 (실패 — 회전 안 됨, 되돌림)
- **`fix_esc_close_render.py`** — 렌더창 닫기에 F11 합성 추가 (실패 — 렌더창이 입력 불능 상태로 망가짐, 되돌림)
- **`fix_boxselect_hover_only.py`** + **`revert_boxselect_hover_only.py`** — 박스선택을 hover만으로 (실패 — 드래그 자체가 작동 안 함, 되돌림)

---

## 8. 현재 상태 종합

### ✅ 완성 (공식 빌드는 하나도 못 하는 것들)
- 외장 키보드 **전체 단축키** (G/S/R 등 + 수정자)
- 좌/우/중 클릭, 마우스 이동
- 마우스 휠 스크롤 = 줌
- **휠클릭 드래그 = 회전, Shift+휠클릭 = 팬** (애드온)
- **2차 창(설정/저장)에서 마우스+키보드 입력**
- **ESC로 2차 창(설정/저장) 닫기**
- 메인 뷰 ESC 정상 (트랜스폼 취소 등)

### ⚠️ 한계로 수용 (OS 레벨 제약)
- **박스선택(좌클릭 드래그) 정밀도**: 끝점이 약간 틀어짐. 원인 = iOS GCMouse가 드래그 중 정확한 절대위치를 충분히 자주 안 줌. hover(정확하나 띄엄띄엄) + 델타(자주 오나 누적 오차) 하이브리드가 최선. hover만으론 드래그가 작동 안 하고, 델타만으론 더 틀어짐. → 정밀 선택은 클릭/터치로 보완
- **렌더창 ESC 닫기 안 됨**: 렌더창은 numWindows=2지만 `GHOST_kEventWindowClose`로 안 닫힘 (특수 임시 윈도우). F11 합성은 창을 망가뜨림. 11" 매직키보드는 F열 자체가 없음. → 렌더 디스플레이 모드를 "이미지 에디터"/"기존 창 유지"로 바꾸면 별도 렌더창 자체를 안 띄울 수 있음 (미시도)

### 🔜 남은 작업
1. **C++ 정리 (최소)**: 코드는 이미 깔끔. 안전하게 제거 가능한 건 죽은 변수 `mouse_pos_valid` 하나뿐. 나머지는 다 동작에 필요(얽혀 있음)
2. **디버그 로그 정리**: `IOS_INPUT_LOGGING` 끄기 (최종). 단, 박스선택 추가 디버깅에 필요하면 켜둠. 시끄러운 로그: `HOVER fired`, `MOUSEMOVED L=M=R`
3. **박스선택 정밀도 추가 시도** (선택): OS 한계라 큰 개선은 어려움. 가능한 방향 = UIKit pointer(`_UIHIDInputEventMouseWithin`)의 절대위치를 드래그 중에도 받기 (C++, 복잡). 현재는 GCMouse 델타에 의존
4. **렌더창**: 렌더 디스플레이 설정으로 우회 (별도 창 안 띄우기)

---

## 9. 디버깅 노하우

- **로그 확인**: Mac Console.app → 기기에서 "조영광의 iPad" 선택 → 필터에 고유 단어 (예: `gccode`, `MIDDLE`, `ESC STATE`). 시스템 로그(`pointeruid`, `backboardd`)와 안 섞이게 고유 키워드 사용
- **파이썬 `print()`는 iPad Blender에서 Mac Console에 안 잡힘** → 애드온 디버깅은 패널 UI나 동작 결과로 판단. C++ `NSLog`(IOS_INPUT_LOG)는 잡힘
- **zsh `!` 문제**: 터미널 명령에 `!`(`s->mouse...`의 `!` 등)가 들어가면 히스토리 확장으로 깨짐. → 패치는 **파일로 만들어서** `python3 ~/Downloads/script.py`로 실행 (heredoc/`-c`의 `"""`도 zsh에서 깨짐)
- **로그가 안 뜰 때**: ① IOS_INPUT_LOGGING 주석 확인 ② **빌드 후 .ipa 재패키징 했는지** (가장 흔함) ③ Console 일시정지 해제 ④ 키보드/마우스 연결 알림이 떠야 핸들러 등록됨 (뺐다 꽂기)

---

## 10. 핵심 진단 결과 기록 (다시 알아내지 않게)

- **2차 창 입력 원인**: 우리 핸들러가 고정 메인 `window`로 전송 → 2차 창은 활성 윈도우가 됨 → `getActiveWindow()`로 바꿔 해결. 터치는 원래 활성 뷰로 가서 2차 창에서 됐었음
- **ESC 상태**: 2차 창 열림 시 `numWindows=2`, 단 `hasDialog=0` (생성자가 `is_dialog_` 안 set). → windows>1을 신호로 사용
- **ESC 키 확인**: `gccode=41 ghost=27`, `GHOST_kKeyEsc=0x1B=27` 일치. C++ 전송은 완벽, 안 닫히는 건 Blender 쪽 처리
- **회전이 트랙패드 경로**: 두 손가락 팬 = `GHOST_EventTrackpad(GHOST_kTrackpadEventScroll)`. 마우스 중간버튼은 이 경로를 안 탐 → 애드온으로 우회
- **드래그 중 hover**: 호출되긴 함 (`btn_pressed=1` 확인) 단 띄엄띄엄 → 정확한 위치 소스로 쓸 수 있으나 드래그 구동엔 부족
- **박스선택 정밀도**: 애드온화해도 입력 소스(부정확한 델타 커서)가 같아서 개선 안 됨 — 애드온화 무의미 확인

---

## 11. 디렉토리 구조

```
blender_ipad_handoff/
├── README.md              ← 이 문서
├── addons/
│   └── mmb_orbit_pan_v3.py    ← 실사용 애드온 (Preferences에 설치됨)
├── patches/                   ← 적용된 C++ 패치 (재현/기록용)
│   ├── add_mouse_input.py
│   ├── add_mouse_wheel.py
│   ├── add_wheel_gesture.py
│   ├── fix_weak_mrc.py
│   ├── fix_drag_any_button.py
│   ├── fix_drag_hybrid.py
│   ├── fix_drag_use_hover.py
│   ├── fix_active_window_input.py
│   ├── fix_esc_close_window.py
│   └── fix_drag_hover_accurate.py
└── diagnostics/               ← 진단 + 미적용/되돌린 시도 (참고)
    ├── input_diagnostic.py
    ├── mmb_diag.py
    ├── esc_diag.py
    ├── esc_close.py
    ├── fix_wheelclick_rotate.py
    ├── fix_esc_close_render.py
    ├── fix_boxselect_hover_only.py
    └── revert_boxselect_hover_only.py
```

---

## 12. 코드 에디터로 옮긴 뒤 추천 첫 작업

1. `~/blender/intern/ghost/intern/GHOST_WindowIOS.mm`를 에디터로 열기 (이게 모든 입력 코드의 중심)
2. 위 4번 "주요 구조" 섹션을 지도 삼아 핸들러들 위치 파악
3. 빌드/패키징/설치 사이클(2-4)을 스크립트 하나로 묶어두면 반복이 편함:
   ```bash
   #!/bin/bash
   set -e
   cd ~/build_ios_xcode
   xcodebuild -scheme install -configuration Release -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO 2>&1 | tee ~/build.log
   cd ~/build_ios_xcode/bin/Release
   rm -rf Payload ~/Blender.ipa && mkdir -p Payload && cp -R Blender.app Payload/ && zip -r ~/Blender.ipa Payload && rm -rf Payload
   echo "빌드+패키징 완료. Sideloadly로 ~/Blender.ipa 설치하세요."
   ```
4. 남은 작업(8번 🔜) 중 우선순위 정해서 진행

> **참고:** §8의 남은 작업과 이후 보고된 이슈는 **전부 §13에서 해결됨** (2026-07-01).

---

## 13. 2026-07-01 전면 업데이트 — 입력/창 이슈 전부 해결

§8의 남은 작업 + 이후 보고 이슈를 **모두 해결**. 메인 파일은 여전히 `~/blender/intern/ghost/intern/GHOST_WindowIOS.mm`, 일부는 Blender 소스도 수정. 디버그 로그(`IOS_INPUT_LOGGING`, line ~31)는 **릴리스용으로 꺼둠**(재활성화하려면 주석 해제).

### 13-1. 최종 입력 아키텍처 (확정)
- **외장 키보드** → GCKeyboard `keyChangedHandler`. ghost_key 변환 + **printable 키는 `ghost_key_to_utf8()`로 `utf8_buf` 채워 전달**(숫자/문장부호/문자, shift 반영).
- **외장 마우스 버튼/휠** → GCMouse `pressedChangedHandler`(버튼), `scroll.yAxis`(휠=줌).
- **마우스 드래그(정확 절대좌표)** → `allowedTouchTypes=@[UITouchTypeIndirectPointer]`인 `indirect_pan_gesture_recognizer` → `handleIndirectPan:`. 좌·중 버튼 드래그 모두 firing.
  - **좌버튼 드래그 = 박스선택**: 정확 절대 CURSOR_MOVE → 네이티브 박스선택(드리프트 없음).
  - **중간버튼 드래그 = 회전**: `GHOST_EventTrackpad`(Scroll, `numFingers=2, inverted=true`) → `view3d.rotate`(트랙패드 경로).
  - **Shift+중간버튼 = 팬**: 정확 CURSOR_MOVE → **네이티브 `view3d.move` 모달**(가드 완화로 MIDDLEMOUSE에 모달 뜨게 함). 깊이/줌 정확 점 고정. (스칼라 튜닝 불가였음.)
- **마우스 hover** → `handleHover:` → 정확 CURSOR_MOVE. **단, 펜 닿는 중(`current_pencil_touch != nil`)엔 hover 억제**(획 중 stale hover가 브러시 튕기던 버그).
- **애플펜슬** → 터치 제스처(`handleTap`/`handlePan`) + tablet_data. **`handlePan`이 펜을 제스처에서 직접 감지**(`GHOSTUIPanGestureRecognizer`가 자기 `touchesBegan`에서 펜 UITouch 잡음) → 첫 dab부터 stylus 필압.
- **트랙패드 핀치 줌** → `handleZoom:` → Magnify(원복 상태).

### 13-2. 박스선택 정밀도 ✅
GCMouse raw(비가속) 델타 → iOS 가속 포인터와 어긋남. `UITouchTypeIndirectPointer` 전용 recognizer가 좌버튼 드래그 중 정확 절대좌표 제공.

### 13-3. 회전/팬 (애드온 → 순수 C++) ✅
- 회전: 두손가락 회전(`handlePan2f`)과 동일 파라미터. (예전 `fix_wheelclick_rotate.py` 실패는 `numFingers=1`/`inverted=false` 오류.)
- 팬: 트랙패드 팬은 줌 의존 증폭(`view3d_navigate_view_move.cc` `2*xy-prev_xy`+zfac)이라 스칼라 불가 → **네이티브 `view3d.move` 모달**. `viewmove_invoke`(view3d_navigate_view_move.cc:108) iOS 가드를 `event->type != MIDDLEMOUSE && !two_finger`로 완화. **애드온 불필요.**

### 13-4. G/S/R 숫자 입력 ✅
`utf8_buf=nullptr` → numinput이 문자 못 받음. `ghost_key_to_utf8()`로 채워 전달.

### 13-5. UV/2D 에디터 팬 ✅
2D에서 MIDDLEMOUSE press가 `view2d.pan` 모달을 띄우는데(iOS 가드가 File/Asset만 예외) 멈춤. `view2d_ops.cc` `view_pan_invoke` iOS 가드를 **전 space로 확대** → numFingers=2 TRACKPADPAN이 2D 팬 구동.

### 13-6. 줌 감도 / 펜슬 ✅
- 줌: `handleZoom` 댐핑(`PINCH_ZOOM_SCALE`)은 손가락 핀치 줌까지 느려져서 **제거(원복)**.
- 펜 끝→시작 선: `handleHover`가 펜 터치 중 CURSOR_MOVE 발행 → 펜 터치 중 hover 억제로 해결.
- 펜 시작점 점("마우스 클릭"): `handlePan` Began 때 `current_pencil_touch`가 아직 nil → 시작 LB-DOWN이 mouse 타입(풀필압). recognizer가 자기 `touchesBegan`에서 펜 직접 잡아 해결.

### 13-7. 렌더창 ESC 닫기 ✅
os_log 진단으로 확정: `wm_window_close`는 렌더창도 끝까지 완료(Blender는 닫음). 차이 = 렌더창 **parent=NULL(toplevel)**, 설정창 parent=메인. **`~GHOST_WindowIOS` 소멸자**가 ① parent 있을 때만 메인 복귀, ② `[rootWindow release]`만 → toplevel 렌더창 **visible UIWindow가 화면에 잔존**. 해결: 소멸자에서 **parent 없으면 남은 창(메인) `requestToActivateWindow`, release 전에 `rootWindow.hidden = YES`**. (우회책: Preferences ▸ Interface ▸ Temporary Editors ▸ "Render In: Image Editor".)

### 13-8. 수정한 Blender 소스 (GHOST 외)
- `source/blender/editors/space_view3d/view3d_navigate_view_move.cc` — 팬 모달 iOS 가드 완화. 백업 `.backup_ios`.
- `source/blender/editors/interface/view2d/view2d_ops.cc` — 2D 팬 가드 확대. 백업 `.backup_ios`.

### 13-9. GHOST_WindowIOS.mm 백업 이력
`.backup8`(박스선택 전)·`.backup9`(회전 전)·`.backup10~13`(팬 튜닝)·`.backup14`(5이슈)·`.backup15~21`(팬 재설계/펜슬/렌더). 번호 큰 게 최신.

### 13-10. 새 디버깅 도구 / 함정
- **기기 로그 CLI 직접 읽기**: `idevicesyslog`(libimobiledevice, brew 설치됨) 백그라운드 캡처 → 직접 분석. iOS C++ 로그는 `os_log(OS_LOG_DEFAULT, "...%{public}d", ...)`(NSLog 대신, idevicesyslog에 잡힘).
- **★ Sideloadly 설치 중엔 idevicesyslog 반드시 끄기**: 둘 다 usbmuxd/lockdown 점유 → **LOCKDOWN_E_MUX_ERROR** 충돌. 캡처는 정상 종료(SIGTERM)로, 꼬이면 케이블 재연결 또는 `sudo killall usbmuxd`.
- 빌드+패키징은 워크스페이스 `build_and_package.sh` 한 방.
