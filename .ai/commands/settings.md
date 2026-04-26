# Settings

초기 워크스페이스 세팅을 자동화합니다.
**비개발자도** `DDD-12-GROWIT-LEAD`를 클론하고 `/settings`만 입력하면 모든 개발 환경이 구성됩니다.

## 세팅 흐름

```
/settings
    │
    ▼
Step 0: 필수 도구 검사 & 자동 설치
    │  → git, node, npm, gh CLI 설치 여부 확인
    │  → 미설치 도구는 자동 설치 (Homebrew 경유)
    ▼
Step 1: GitHub 인증
    │  → gh auth login (브라우저 인증)
    ▼
Step 2: Figma MCP 서버 연결
    ▼
Step 3: Notion MCP 서버 연결
    ▼
Step 4: 기본 레포 클론 + 의존성 설치
    ▼
Step 5: Cursor 워크스페이스 구성
    ▼
Step 6: AI 커맨드 동기화
    ▼
Step 7: 최종 결과 보고 & 다음 단계 안내
    └── 완료
```

---

## Step 0: 필수 도구 검사 & 자동 설치

> **비개발자 핵심 단계.** 개발에 필요한 도구가 모두 설치되어 있는지 확인하고, 없으면 자동 설치한다.

### 0-1. 검사 대상

아래 도구를 순서대로 확인한다:

| 도구 | 확인 명령 | 용도 |
|------|----------|------|
| **Homebrew** | `command -v brew` | macOS 패키지 매니저 (다른 도구 설치에 필요) |
| **git** | `command -v git` | 소스코드 버전 관리 |
| **Node.js** | `command -v node` | JavaScript 런타임 |
| **npm** | `command -v npm` | Node.js 패키지 매니저 |
| **GitHub CLI** | `command -v gh` | GitHub 연동 (PR, 이슈 등) |
| **Cursor** | `command -v cursor` | AI 코드 에디터 |

### 0-2. 검사 & 설치 로직

```bash
MISSING=()

# 1) Homebrew
if ! command -v brew &>/dev/null; then
  MISSING+=("Homebrew")
fi

# 2) git
if ! command -v git &>/dev/null; then
  MISSING+=("git")
fi

# 3) Node.js + npm
if ! command -v node &>/dev/null; then
  MISSING+=("node")
fi

# 4) GitHub CLI
if ! command -v gh &>/dev/null; then
  MISSING+=("gh")
fi

# 5) Cursor (선택)
if ! command -v cursor &>/dev/null; then
  MISSING+=("cursor (선택)")
fi
```

### 0-3. 미설치 도구가 있는 경우

미설치 도구 목록을 사용자에게 보여주고 설치를 진행한다:

```
AskUserQuestion:
  question: "다음 도구가 설치되어 있지 않습니다. 자동으로 설치할까요?\n\n미설치: {MISSING 목록}\n\n(Homebrew를 통해 설치됩니다)"
  header: "도구 설치"
  options:
    - label: "자동 설치 (Recommended)"
      description: "필요한 도구를 Homebrew로 자동 설치합니다"
    - label: "직접 설치할게요"
      description: "설치 방법을 안내받고 직접 설치합니다"
```

### 0-4. 자동 설치 실행

"자동 설치"를 선택한 경우:

```bash
# Homebrew 설치 (없는 경우)
if ! command -v brew &>/dev/null; then
  echo "→ Homebrew 설치 중..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon Mac의 경우 PATH 설정
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# git 설치 (보통 macOS에 기본 포함)
if ! command -v git &>/dev/null; then
  echo "→ git 설치 중..."
  brew install git
fi

# Node.js + npm 설치
if ! command -v node &>/dev/null; then
  echo "→ Node.js 설치 중..."
  brew install node
fi

# GitHub CLI 설치
if ! command -v gh &>/dev/null; then
  echo "→ GitHub CLI 설치 중..."
  brew install gh
fi
```

### 0-5. "직접 설치" 선택 시 안내

```markdown
## 필수 도구 설치 가이드

### 1. Homebrew (macOS 패키지 매니저)
터미널에서 실행:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

### 2. Node.js
https://nodejs.org 에서 LTS 버전 다운로드 & 설치
또는: brew install node

### 3. GitHub CLI
brew install gh
또는: https://cli.github.com 에서 다운로드

### 4. Cursor (AI 코드 에디터)
https://cursor.com 에서 다운로드 & 설치

설치 완료 후 /settings를 다시 실행해주세요.
```

### 0-6. 설치 후 검증

모든 도구가 설치되었는지 최종 확인:

```bash
echo "=== 도구 설치 확인 ==="
echo "git:    $(git --version 2>/dev/null || echo '❌ 미설치')"
echo "node:   $(node --version 2>/dev/null || echo '❌ 미설치')"
echo "npm:    $(npm --version 2>/dev/null || echo '❌ 미설치')"
echo "gh:     $(gh --version 2>/dev/null | head -1 || echo '❌ 미설치')"
echo "cursor: $(command -v cursor &>/dev/null && echo '✅ 설치됨' || echo '⏭️ 미설치 (선택)')"
```

모든 필수 도구가 설치되었으면 Step 1로 진행. 하나라도 실패하면 재안내.

---

## Step 1: GitHub 인증

### 1-1. GitHub CLI 인증 상태 확인

```bash
gh auth status 2>&1
```

- **이미 인증됨** → Step 1 완료, Step 2로 진행
- **미인증** → 1-2로 진행

### 1-2. 인증 방법 선택

```
AskUserQuestion:
  question: "GitHub 로그인이 필요합니다. 어떤 방식으로 로그인할까요?"
  header: "GitHub 인증"
  options:
    - label: "브라우저로 로그인 (Recommended)"
      description: "브라우저가 열리고 GitHub에 로그인하면 자동으로 인증됩니다. 가장 쉬운 방법입니다."
    - label: "토큰으로 로그인"
      description: "GitHub Personal Access Token을 직접 입력합니다. (개발자용)"
```

### 1-3a. 브라우저 인증 (비개발자 권장)

```bash
gh auth login --web --git-protocol https
```

> 실행하면 브라우저가 열리고, 코드를 입력하라는 안내가 나옵니다.
> 사용자가 브라우저에서 GitHub에 로그인하고 코드를 입력하면 자동 인증됩니다.

### 1-3b. 토큰 인증 (개발자용)

```
AskUserQuestion:
  question: "GitHub Personal Access Token을 입력해주세요.\n\n토큰 생성: https://github.com/settings/tokens/new\n필요 권한: repo, read:org"
  header: "GitHub Token"
  options:
    - label: "토큰 생성 페이지 열기"
      description: "브라우저에서 토큰 생성 페이지를 엽니다"
```

```bash
echo "{TOKEN}" | gh auth login --with-token
```

### 1-4. 인증 검증

```bash
# DDD-Community org 접근 가능한지 확인
gh api repos/DDD-Community/DDD-12-GROWIT-FE --jq '.full_name' 2>&1
```

- 성공 → `✅ GitHub 인증 완료 — DDD-Community 접근 확인`
- 실패 → 에러 메시지 표시 후 재시도 안내

---

## Step 2: Figma MCP 서버 연결

### 2-1. Figma Token 입력

```
AskUserQuestion:
  question: "Figma 연결을 설정합니다.\n\nFigma에서 디자인을 AI가 읽을 수 있게 해줍니다.\n토큰 생성: Figma 앱 → 좌상단 프로필 → Settings → Personal access tokens → Generate new token"
  header: "Figma 연결"
  options:
    - label: "토큰 입력"
      description: "Other를 선택해서 Figma Personal Access Token을 붙여넣어주세요"
    - label: "건너뛰기"
      description: "나중에 설정합니다. /settings를 다시 실행하면 됩니다."
```

### 2-2. Figma MCP 설정

"건너뛰기"를 선택하지 않은 경우, `.mcp.json`에 Figma MCP 서버를 등록한다.

현재 `.mcp.json`을 읽고 `mcpServers` 객체에 `figma` 키를 추가/갱신:

```json
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "figma-developer-mcp", "--figma-api-key={FIGMA_TOKEN}", "--stdio"]
    }
  }
}
```

> `.mcp.json`은 항상 **기존 내용을 보존하면서 병합**한다. 기존에 notion 등 다른 MCP가 있으면 유지.

### 2-3. 검증

```bash
python3 -c "
import json
with open('.mcp.json') as f:
    d = json.load(f)
print('✅ Figma MCP 등록 완료' if 'figma' in d.get('mcpServers', {}) else '❌ 등록 실패')
"
```

---

## Step 3: Notion MCP 서버 연결

### 3-1. Notion Integration Token 입력

```
AskUserQuestion:
  question: "Notion 연결을 설정합니다.\n\nNotion에서 티켓/문서를 AI가 읽고 수정할 수 있게 해줍니다.\n\n토큰 생성 방법:\n1. https://www.notion.so/my-integrations 접속\n2. '새 API 통합' 클릭\n3. 이름 입력 (예: growit-ai) → 제출\n4. '내부 통합 시크릿' 복사\n5. Notion 워크스페이스에서 연결할 페이지/DB에 통합 추가\n   (페이지 우상단 ··· → 연결 → growit-ai 선택)"
  header: "Notion 연결"
  options:
    - label: "토큰 입력"
      description: "Other를 선택해서 Notion Integration Token (ntn_으로 시작)을 붙여넣어주세요"
    - label: "건너뛰기"
      description: "나중에 설정합니다. /settings를 다시 실행하면 됩니다."
```

### 3-2. Notion MCP 설정

"건너뛰기"를 선택하지 않은 경우, `.mcp.json`에 Notion MCP 서버를 등록한다.

기존 `.mcp.json`을 읽고 `mcpServers`에 `notion` 키를 추가/갱신:

```json
{
  "mcpServers": {
    "notion": {
      "command": "npx",
      "args": ["-y", "@notionhq/notion-mcp-server"],
      "env": {
        "OPENAPI_MCP_HEADERS": "{\"Authorization\": \"Bearer {NOTION_TOKEN}\", \"Notion-Version\": \"2022-06-28\"}"
      }
    }
  }
}
```

### 3-3. 검증

```bash
python3 -c "
import json
with open('.mcp.json') as f:
    d = json.load(f)
print('✅ Notion MCP 등록 완료' if 'notion' in d.get('mcpServers', {}) else '❌ 등록 실패')
"
```

---

## Step 4: 기본 레포 클론 + 의존성 설치

### 4-1. 레포 클론

DDD-12-GROWIT-LEAD의 부모 디렉토리(`~/Desktop/growit/`)에 3개 레포를 클론한다:

```bash
BASE_DIR="$(cd "$(pwd)/.." && pwd)"

REPOS=(
  DDD-12-GROWIT-FE
  DDD-12-GROWIT-BE
  DDD-12-GROWIT-APP
)

for repo in "${REPOS[@]}"; do
  TARGET="$BASE_DIR/$repo"
  if [ -d "$TARGET" ]; then
    echo "✓ $repo — 이미 존재, pull로 최신화"
    (cd "$TARGET" && git pull origin main 2>/dev/null || git pull 2>/dev/null || echo "⚠️ pull 실패 (오프라인?)")
  else
    echo "→ $repo 클론 중..."
    git clone "https://github.com/DDD-Community/$repo.git" "$TARGET"
  fi
done
```

### 4-2. 의존성 설치

```bash
for repo in "${REPOS[@]}"; do
  TARGET="$BASE_DIR/$repo"
  if [ -f "$TARGET/package.json" ]; then
    echo "→ $repo: 의존성 설치 중..."
    (cd "$TARGET" && npm install 2>&1 | tail -1)
    echo "✓ $repo: 완료"
  else
    echo "⏭️ $repo: package.json 없음, 스킵"
  fi
done
```

### 4-3. 결과 보고

```
✅ 레포 클론 & 의존성 설치 완료

| 레포 | 상태 | 경로 |
|------|------|------|
| DDD-12-GROWIT-FE | ✅ | ~/Desktop/growit/DDD-12-GROWIT-FE |
| DDD-12-GROWIT-BE | ✅ | ~/Desktop/growit/DDD-12-GROWIT-BE |
| DDD-12-GROWIT-APP | ✅ | ~/Desktop/growit/DDD-12-GROWIT-APP |
```

---

## Step 5: Cursor 워크스페이스 구성

### 5-1. 워크스페이스 파일 복사

```bash
BASE_DIR="$(cd "$(pwd)/.." && pwd)"
WORKSPACE_FILE="$BASE_DIR/growit.code-workspace"

if [ ! -f "$WORKSPACE_FILE" ]; then
  cp "$(pwd)/growit.code-workspace" "$WORKSPACE_FILE"
  echo "✅ growit.code-workspace 생성 완료: $WORKSPACE_FILE"
else
  echo "✅ growit.code-workspace 이미 존재"
fi
```

### 5-2. Cursor 설치 확인 & 안내

```bash
if command -v cursor &>/dev/null; then
  echo "✅ Cursor가 설치되어 있습니다."
  echo "→ 다음 명령어로 워크스페이스를 열 수 있습니다:"
  echo "  cursor $WORKSPACE_FILE"
else
  echo "⚠️ Cursor가 설치되어 있지 않습니다."
  echo "→ https://cursor.com 에서 다운로드하세요."
  echo "→ 설치 후 Cursor > File > Open Workspace from File..."
  echo "  $WORKSPACE_FILE"
fi
```

---

## Step 6: AI 커맨드 동기화

`.ai/` → `.cursor/` + `.claude/skills/` 동기화:

```bash
cd "$(pwd)" && python3 .ai/sync.py
```

---

## Step 7: 최종 결과 보고 & 다음 단계 안내

### 결과 테이블

```
🎉 GROWIT 워크스페이스 초기 세팅 완료!

| 항목 | 상태 | 비고 |
|------|------|------|
| 필수 도구 | ✅ | git, node, npm, gh 설치됨 |
| GitHub 인증 | ✅ | DDD-Community 접근 확인 |
| Figma MCP | ✅/⏭️ | .mcp.json에 등록 |
| Notion MCP | ✅/⏭️ | .mcp.json에 등록 |
| 레포 클론 | ✅ | FE, BE, APP 3개 |
| 의존성 설치 | ✅ | npm install 완료 |
| 워크스페이스 | ✅ | growit.code-workspace |
| AI 커맨드 | ✅ | .claude/skills/ 동기화 |
```

### 다음 단계 안내

```
📋 다음 단계:

1. Cursor에서 워크스페이스 열기:
   cursor ~/Desktop/growit/growit.code-workspace

2. 모든 레포 최신화:
   /main

3. 개발 시작:
   /orchestrate TICKET_ID

💡 도움이 필요하면:
   - /settings  → 세팅 재실행 (건너뛴 항목 추가 가능)
   - /wiki query "질문"  → 프로젝트 지식 검색
```

---

## .mcp.json 최종 구조 예시

모든 MCP가 연결된 상태:

```json
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "figma-developer-mcp", "--figma-api-key=figd_xxxxx", "--stdio"]
    },
    "notion": {
      "command": "npx",
      "args": ["-y", "@notionhq/notion-mcp-server"],
      "env": {
        "OPENAPI_MCP_HEADERS": "{\"Authorization\": \"Bearer ntn_xxxxx\", \"Notion-Version\": \"2022-06-28\"}"
      }
    }
  }
}
```

---

## 에지 케이스

- **Homebrew 설치 실패 (macOS 아닌 경우)**: Linux/Windows는 별도 안내. Node.js는 공식 사이트, gh는 `apt`/`winget` 안내
- **gh auth login 브라우저 안 열림**: `gh auth login` 수동 실행 안내. 터미널에 표시되는 코드를 https://github.com/login/device 에 직접 입력
- **GitHub Token 실패**: "토큰이 만료되었거나 권한이 부족합니다" 안내 → 토큰 재생성 가이드
- **Figma/Notion 건너뛰기**: `.mcp.json`에 해당 서버를 등록하지 않고 진행. `/settings` 재실행으로 언제든 추가
- **레포 클론 실패 (private repo)**: "GitHub 인증을 먼저 확인하세요" 안내 → Step 1 재실행
- **레포 이미 존재**: 클론 스킵, `git pull origin main`으로 최신화
- **npm install 실패**: 경고 표시 후 나머지 레포 계속 진행. "나중에 해당 레포에서 npm install 실행" 안내
- **이미 세팅 완료**: 각 Step에서 기존 상태를 감지하여 스킵 (멱등성). 부분만 재설정 가능
- **Apple Silicon Mac**: Homebrew 경로가 `/opt/homebrew/`인 점 반영. `eval "$(/opt/homebrew/bin/brew shellenv)"` 실행
- **Cursor 미설치**: 필수가 아님. "VS Code에서도 워크스페이스를 열 수 있습니다" 안내

---

## 체크리스트

- [ ] 필수 도구 검사 완료 (git, node, npm, gh)
- [ ] 미설치 도구 자동 설치 또는 안내 완료
- [ ] GitHub CLI 인증 완료 (DDD-Community 접근 확인)
- [ ] Figma MCP 서버 .mcp.json 등록 (또는 건너뛰기)
- [ ] Notion MCP 서버 .mcp.json 등록 (또는 건너뛰기)
- [ ] 3개 레포 클론 완료 (FE, BE, APP)
- [ ] 의존성 설치 완료
- [ ] growit.code-workspace 파일 생성
- [ ] AI 커맨드 동기화 (.ai/sync.sh)
- [ ] 최종 결과 보고 & 다음 단계 안내
