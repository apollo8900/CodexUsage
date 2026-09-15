# CodexUsage

**macOS 메뉴바에서 ChatGPT (`CG`), Claude (`CL`), Gemini (`GM`)의 5시간 / 7일 남은 사용량을 한눈에 확인할 수 있는 경량 앱입니다.**

```text
CG 5h:66%/7d:74%  |  CL 5h:100%/7d:100%  |  GM 5h:27%/7d:72%
```

> **비공식 프로젝트** — CodexUsage는 독립 오픈소스 프로젝트이며 OpenAI, Anthropic 또는 Google과 제휴하거나 공식적으로 지원받는 프로젝트가 아닙니다.

---

# 🇰🇷 한국어

## 2자 약칭 (Abbreviation)
- **`CG`**: **C**hat**G**PT (OpenAI Codex)
- **`CL`**: **CL**aude (Antigravity Claude Opus / Sonnet)
- **`GM`**: **G**e**M**ini (Antigravity Gemini Flash / Pro)

## 주요 기능

- **ChatGPT (`CG`)**: OpenAI Codex CLI 세션 로컬 5시간 / 7일 잔여량 및 리셋 시간 표시
- **Claude (`CL`)**: Google Antigravity IDE 연동 Claude 5시간 / 7일 실시간 잔여량 및 리셋 시간 표시
- **Gemini (`GM`)**: Google Antigravity IDE 연동 Gemini 5시간 / 7일 실시간 잔여량 및 리셋 시간 표시
- **메뉴바 표시 모드 선택**:
  - `All (CG · CL · GM)`: 3개 모델 사용량을 메뉴바에 모두 표시 (기본값)
  - `ChatGPT (CG) Only`: ChatGPT 사용량만 표시
  - `Claude (CL) Only`: Claude 사용량만 표시
  - `Gemini (GM) Only`: Gemini 사용량만 표시
- **터미널 CLI 확인 (`--check`)**: 앱 실행 없이 터미널에서 즉시 3개 모델 사용량 출력
- **30초마다 자동 갱신** 및 `Refresh Now (⌘R)` 수동 갱신
- 별도의 API Key나 추가 로그인 불필요
- Swift 기반의 초경량 네이티브 macOS 앱

표시되는 퍼센트는 **사용한 양이 아니라 남은 양**입니다.

```text
5h:35% → 5시간 사용량 35% 남음
7d:72% → 7일(주간) 사용량 72% 남음
```

## 요구사항

- macOS 13 Ventura 이상
- Google Antigravity IDE (Gemini 및 Claude 사용량 확인 시)
- OpenAI Codex CLI (ChatGPT 사용량 확인 시)

## 설치 및 빌드

저장소를 Clone 합니다:

```bash
git clone https://github.com/apollo8900/CodexUsage.git
cd CodexUsage
```

빌드합니다:

```bash
./build.sh
```

실행합니다:

```bash
open CodexUsage.app
```

터미널에서 즉시 확인하려면:

```bash
./CodexUsage.app/Contents/MacOS/CodexUsage --check
```
또는
```bash
swift run CodexUsage --check
```

## 동작 방식

### 1. Google Antigravity (Gemini & Claude)
- Mac 로컬에서 실행 중인 Antigravity 프로세스(`language_server_macos_x64`)와 통신하여 실시간 할당량 요약(`RetrieveUserQuotaSummary`)을 조회합니다.
- **Gemini (`GM`)**: Gemini Flash/Pro 모델의 5시간 및 주간 잔여량과 리셋 일시를 조회합니다.
- **Claude (`CL`)**: Claude Opus/Sonnet 모델의 5시간 및 주간 잔여량과 리셋 일시를 조회합니다.

### 2. OpenAI Codex (ChatGPT)
- Codex CLI가 로컬에 기록한 세션 데이터(`~/.codex/sessions/`)에서 최신 `rate_limits`를 읽어 남은 사용량(`100 - used_percent`)을 계산합니다.

---

# 🇺🇸 English

## Abbreviations
- **`CG`**: **C**hat**G**PT (OpenAI Codex)
- **`CL`**: **CL**aude (Antigravity Claude Opus / Sonnet)
- **`GM`**: **G**e**M**ini (Antigravity Gemini Flash / Pro)

## Features

- **ChatGPT (`CG`)**: 5-hour and 7-day remaining quota and reset times from local Codex sessions
- **Claude (`CL`)**: Real-time 5-hour and 7-day remaining quota for Claude models via Antigravity
- **Gemini (`GM`)**: Real-time 5-hour and 7-day remaining quota for Gemini models via Antigravity
- **Customizable Menu Bar Display**:
  - `All (CG · CL · GM)`: Show all 3 models in the menu bar simultaneously (Default)
  - `ChatGPT (CG) Only`
  - `Claude (CL) Only`
  - `Gemini (GM) Only`
- **CLI Mode (`--check`)**: Quick inspection directly in terminal for all 3 models
- **Auto-refreshes every 30 seconds** or on-demand (`⌘R`)
- No API keys or extra login credentials required
- Lightweight native macOS menu bar app written in Swift

The percentages represent **remaining quota**, not consumed quota.

## Requirements

- macOS 13 Ventura or later
- Google Antigravity IDE (for Gemini and Claude quota)
- OpenAI Codex CLI (for ChatGPT quota)

## Installation & Build

Clone the repository:

```bash
git clone https://github.com/apollo8900/CodexUsage.git
cd CodexUsage
```

Build:

```bash
./build.sh
```

Run:

```bash
open CodexUsage.app
```

Check directly via terminal:

```bash
./CodexUsage.app/Contents/MacOS/CodexUsage --check
```

## How It Works

- **Google Antigravity (Gemini & Claude)**: Connects to the local Antigravity Language Server to fetch live quota statistics via `RetrieveUserQuotaSummary` for Gemini (`GM`) and Claude (`CL`).
- **OpenAI Codex (ChatGPT)**: Reads local session snapshots from `~/.codex/sessions/` to calculate remaining usage (`CG`).

---

## Disclaimer

CodexUsage is an **unofficial, independent open-source project**.
It is not affiliated with, endorsed by, or sponsored by Google or OpenAI.
All trademarks belong to their respective owners.
