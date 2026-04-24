# Settings

초기 워크스페이스 세팅을 자동화합니다.
`/settings`를 실행하면 모든 개발 환경이 한 번에 구성됩니다.

## 세팅 흐름

```
/settings
    │
    ▼
Step 1: GitHub Token 입력 & 검증
    ▼
Step 2: Figma MCP 서버 연결
    ▼
Step 3: Notion MCP 서버 연결
    ▼
Step 4: 기본 레포 클론
    ▼
Step 5: Cursor 워크스페이스 구성
    ▼
Step 6: AI 커맨드 동기화
    └── 완료
```

---

## Step 1: GitHub Token 입력 & 검증

### 1-1. GitHub CLI 인증 확인

먼저 `gh` CLI가 인증되어 있는지 확인한다:

```bash
gh auth status
```

- **인증됨** → Step 1 완료, Step 2로 진행
- **미인증** → 1-2로 진행

### 1-2. GitHub Token 입력

사용자에게 GitHub Personal Access Token (PAT)을 요청한다:

```
AskUserQuestion:
  question: "GitHub Personal Access Token을 입력해주세요. (repo, read:org 권한 필요)"
  header: "GitHub Token"
  options:
    - label: "토큰 생성 방법 안내"
      description: "https://github.com/settings/tokens/new 에서 생성"
    - label: "이미 gh auth login 완료"
      description: "gh CLI로 이미 인증한 경우"
```

### 1-3. Token 검증

```bash
# gh CLI로 인증
echo "{TOKEN}" | gh auth login --with-token

# 검증: DDD-Community org 접근 가능한지 확인
gh api repos/DDD-Community/DDD-12-GROWIT-FE --jq '.full_name'
```

- 성공 → `✅ GitHub 인증 완료 — DDD-Community 접근 확인`
- 실패 → 에러 메시지와 함께 재입력 요청

---

## Step 2: Figma MCP 서버 연결

### 2-1. Figma Token 입력

```
AskUserQuestion:
  question: "Figma Personal Access Token을 입력해주세요. (Figma > Settings > Personal access tokens)"
  header: "Figma Token"
  options:
    - label: "토큰 생성 방법 안내"
      description: "Figma 설정 > Account > Personal access tokens에서 생성"
    - label: "건너뛰기"
      description: "Figma MCP 연결을 나중에 설정합니다"
```

### 2-2. Figma MCP 설정

"건너뛰기"를 선택하지 않은 경우, `.mcp.json`에 Figma MCP 서버를 등록한다:

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

> Figma MCP는 `figma-developer-mcp` 패키지를 사용한다.
> `--figma-api-key`에 사용자가 입력한 토큰을 주입한다.

### 2-3. 검증

```bash
# MCP 서버가 정상적으로 등록되었는지 .mcp.json 확인
cat growit-lead/.mcp.json | python3 -c "import sys,json; d=json.load(sys.stdin); print('figma' in d.get('mcpServers',{}))"
```

- 성공 → `✅ Figma MCP 서버 등록 완료`

---

## Step 3: Notion MCP 서버 연결

### 3-1. Notion Integration Token 입력

```
AskUserQuestion:
  question: "Notion Integration Token을 입력해주세요. (Notion > Settings > Integrations > Internal integrations)"
  header: "Notion Token"
  options:
    - label: "토큰 생성 방법 안내"
      description: "https://www.notion.so/my-integrations 에서 Internal Integration 생성 후 토큰 복사"
    - label: "건너뛰기"
      description: "Notion MCP 연결을 나중에 설정합니다"
```

### 3-2. Notion MCP 설정

"건너뛰기"를 선택하지 않은 경우, `.mcp.json`에 Notion MCP 서버를 등록한다:

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

> Notion MCP는 `@notionhq/notion-mcp-server` 패키지를 사용한다.
> OPENAPI_MCP_HEADERS에 Notion Integration Token을 주입한다.

### 3-3. 검증

```bash
cat growit-lead/.mcp.json | python3 -c "import sys,json; d=json.load(sys.stdin); print('notion' in d.get('mcpServers',{}))"
```

- 성공 → `✅ Notion MCP 서버 등록 완료`

---

## Step 4: 기본 레포 클론

### 4-1. 레포 클론

3개 레포를 `~/Desktop/growit/` 하위에 클론한다:

```bash
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"  # ~/Desktop/growit

REPOS=(
  DDD-12-GROWIT-FE
  DDD-12-GROWIT-BE
  DDD-12-GROWIT-APP
)

for repo in "${REPOS[@]}"; do
  TARGET="$BASE_DIR/$repo"
  if [ -d "$TARGET" ]; then
    echo "✓ $repo already exists, skipping clone"
  else
    echo "→ Cloning $repo..."
    git clone "https://github.com/DDD-Community/$repo.git" "$TARGET"
  fi
done
```

### 4-2. 의존성 설치

각 레포에 `package.json`이 있으면 `npm install` 실행:

```bash
for repo in "${REPOS[@]}"; do
  TARGET="$BASE_DIR/$repo"
  if [ -f "$TARGET/package.json" ]; then
    echo "→ $repo: installing..."
    (cd "$TARGET" && npm install)
    echo "✓ $repo: done"
  fi
done
```

### 4-3. 클론 결과 보고

```
✅ 레포 클론 완료

| 레포 | 상태 | 경로 |
|------|------|------|
| DDD-12-GROWIT-FE | ✅ Cloned | ~/Desktop/growit/DDD-12-GROWIT-FE |
| DDD-12-GROWIT-BE | ✅ Cloned | ~/Desktop/growit/DDD-12-GROWIT-BE |
| DDD-12-GROWIT-APP | ✅ Cloned | ~/Desktop/growit/DDD-12-GROWIT-APP |
```

---

## Step 5: Cursor 워크스페이스 구성

### 5-1. 워크스페이스 파일 복사

```bash
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE_FILE="$BASE_DIR/growit.code-workspace"

if [ ! -f "$WORKSPACE_FILE" ]; then
  cp "$BASE_DIR/growit-lead/growit.code-workspace" "$WORKSPACE_FILE"
  echo "✅ growit.code-workspace 생성 완료"
else
  echo "✅ growit.code-workspace 이미 존재"
fi
```

### 5-2. Cursor로 열기 안내

```
✅ 워크스페이스 구성 완료

다음 명령어로 Cursor에서 워크스페이스를 여세요:
  cursor ~/Desktop/growit/growit.code-workspace

또는 Cursor에서 File > Open Workspace from File...
  ~/Desktop/growit/growit.code-workspace
```

---

## Step 6: AI 커맨드 동기화

`.ai/` → `.cursor/` + `.claude/skills/` 동기화를 실행한다:

```bash
cd ~/Desktop/growit/growit-lead && bash .ai/sync.sh
```

- `.cursor/commands/` — Cursor IDE 커맨드
- `.cursor/rules/` — Cursor IDE 규칙
- `.claude/skills/` — Claude Code SKILL.md

---

## 최종 결과 보고

```
🎉 GROWIT 워크스페이스 초기 세팅 완료!

| 항목 | 상태 | 비고 |
|------|------|------|
| GitHub 인증 | ✅ | DDD-Community 접근 확인 |
| Figma MCP | ✅/⏭️ | .mcp.json에 등록 |
| Notion MCP | ✅/⏭️ | .mcp.json에 등록 |
| 레포 클론 | ✅ | FE, BE, APP 3개 |
| 워크스페이스 | ✅ | growit.code-workspace |
| AI 커맨드 | ✅ | .claude/skills/ 동기화 |

다음 단계:
  1. cursor ~/Desktop/growit/growit.code-workspace
  2. /main  — 모든 레포 최신화
  3. /orchestrate TICKET_ID  — 개발 시작
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

- **GitHub Token 실패**: 3회 재시도 후 "수동으로 `gh auth login` 실행" 안내
- **Figma/Notion 건너뛰기**: `.mcp.json`에 해당 서버를 등록하지 않고 진행. 나중에 `/settings` 재실행으로 추가 가능
- **레포 이미 존재**: 클론 스킵, `git pull origin main`으로 최신화
- **npm install 실패**: 경고 표시 후 나머지 레포 계속 진행
- **이미 세팅 완료**: 각 Step에서 기존 상태를 감지하여 스킵 (멱등성)

---

## 체크리스트

- [ ] GitHub CLI 인증 완료 (DDD-Community 접근 확인)
- [ ] Figma MCP 서버 .mcp.json 등록 (또는 건너뛰기)
- [ ] Notion MCP 서버 .mcp.json 등록 (또는 건너뛰기)
- [ ] 3개 레포 클론 완료 (FE, BE, APP)
- [ ] 의존성 설치 완료
- [ ] growit.code-workspace 파일 생성
- [ ] AI 커맨드 동기화 (.ai/sync.sh)
- [ ] 최종 결과 보고
