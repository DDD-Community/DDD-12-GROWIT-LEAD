# Settings

`growit-env/config.json` 기반으로 전체 워크스페이스를 **자동** 세팅합니다.
사용자 입력 없이 저장된 키 정보로 즉시 연결합니다.

## 전제 조건 (사용자가 미리 준비)

```
어딘가/
├── DDD-12-GROWIT-LEAD/    ← 이 repo (git clone)
└── growit-env/            ← 팀원에게 zip으로 전달받아 압축 해제
    ├── config.json        (GitHub, Figma, Notion, SSH 모든 연결 정보)
    ├── ssh/bastion.pem    (Bastion SSH 키)
    ├── be/.env.development
    ├── fe/.env.development
    └── app/.env.development
```

---

## 세팅 흐름

```
/settings
    │
    ▼
Step 0: 필수 도구 검사 & 자동 설치
    ▼
Step 1: growit-env 검증 & config.json 로드
    ▼
Step 2: GitHub 인증 (config.json → gh auth)
    ▼
Step 3: 레포 클론 + 의존성 설치 (BE, FE, APP)
    ▼
Step 4: 환경변수 배포 (growit-env/{repo}/ → 각 repo)
    ▼
Step 5: MCP 서버 설정 (config.json → .mcp.json)
    ▼
Step 6: SSH 키 설정 & 터널 검증
    ▼
Step 7: Cursor 워크스페이스 구성 & 열기
    ▼
Step 8: 최종 결과 보고
    └── 완료
```

---

## Step 0: 필수 도구 검사 & 자동 설치

### 0-1. 검사 대상

| 도구 | 확인 명령 | 용도 |
|------|----------|------|
| **Homebrew** | `command -v brew` | macOS 패키지 매니저 |
| **git** | `command -v git` | 소스코드 관리 |
| **Node.js** | `command -v node` | FE/APP 런타임 |
| **npm** | `command -v npm` | 패키지 매니저 |
| **yarn** | `command -v yarn` | APP 패키지 매니저 (Expo) |
| **GitHub CLI** | `command -v gh` | GitHub 연동 |
| **Java 17** | `java -version 2>&1 \| grep "17"` | BE 빌드 |
| **Cursor** | `command -v cursor` | IDE (선택) |

### 0-2. 자동 설치

```bash
# Homebrew
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 필수 도구
for tool in git node gh; do
  command -v $tool &>/dev/null || brew install $tool
done

# yarn (APP은 Expo + yarn 사용)
if ! command -v yarn &>/dev/null; then
  npm install -g yarn
fi

# Java 17 (BE 빌드용)
if ! java -version 2>&1 | grep -q "17"; then
  brew install openjdk@17
  sudo ln -sfn $(brew --prefix openjdk@17)/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
fi
```

### 0-3. 검증

```bash
echo "=== 도구 확인 ==="
echo "git:    $(git --version 2>/dev/null || echo '❌')"
echo "node:   $(node --version 2>/dev/null || echo '❌')"
echo "npm:    $(npm --version 2>/dev/null || echo '❌')"
echo "yarn:   $(yarn --version 2>/dev/null || echo '❌')"
echo "gh:     $(gh --version 2>/dev/null | head -1 || echo '❌')"
echo "java:   $(java -version 2>&1 | head -1 || echo '❌')"
```

필수 도구 하나라도 없으�� 설치 안내 후 중단.

---

## Step 1: growit-env 검증 & config.json 로드

### 1-1. 폴더 찾기

```bash
BASE_DIR="$(cd "$(pwd)/.." && pwd)"
ENV_DIR="$BASE_DIR/growit-env"

if [ ! -d "$ENV_DIR" ]; then
  echo "❌ growit-env 폴더를 찾을 수 없습니다."
  echo "   예상 경로: $ENV_DIR"
  echo ""
  echo "해결: growit-env.zip을 DDD-12-GROWIT-LEAD와 같은 부모 폴더에 압축 해제하세요."
  exit 1
fi
```

### 1-2. config.json 로드 & 검증

```bash
CONFIG="$ENV_DIR/config.json"

if [ ! -f "$CONFIG" ]; then
  echo "❌ config.json이 없습니다: $CONFIG"
  exit 1
fi

# 필수 필드 검증
python3 -c "
import json, sys
with open('$CONFIG') as f:
    c = json.load(f)
required = ['github.token', 'figma.token', 'notion.token']
missing = []
if not c.get('github',{}).get('token'): missing.append('github.token')
if not c.get('figma',{}).get('token'): missing.append('figma.token')
if not c.get('notion',{}).get('token'): missing.append('notion.token')
if missing:
    print(f'❌ config.json 필수 필드 누락: {missing}')
    sys.exit(1)
print('✅ config.json 검증 완료')
"
```

---

## Step 2: GitHub 인증

`config.json`의 `github.token`으로 자동 로그인. 사용자 입력 없음.

### 2-1. 토큰으로 인증

```bash
GH_TOKEN=$(python3 -c "import json; print(json.load(open('$CONFIG'))['github']['token'])")

# GH_TOKEN 환경변수 설정 (git clone 등에 사용)
export GH_TOKEN

# gh CLI에도 토큰 등록 (PR 생성, issue 관리 등에 필수)
echo "$GH_TOKEN" | gh auth login --with-token 2>/dev/null

# 검증
if gh auth status &>/dev/null; then
  echo "✅ GitHub 인증 완료: $(gh api user --jq '.login')"
else
  echo "❌ GitHub 인증 실패 — config.json의 github.token을 확인하세요"
  exit 1
fi
```

### 2-2. Organization 접근 확인

```bash
ORG=$(python3 -c "import json; print(json.load(open('$CONFIG'))['github']['org'])")
REPOS=$(python3 -c "import json; print(' '.join(json.load(open('$CONFIG'))['github']['repos']))")

for repo in $REPOS; do
  if gh api "repos/$ORG/$repo" --jq '.full_name' &>/dev/null; then
    echo "  ✅ $ORG/$repo 접근 확인"
  else
    echo "  ❌ $ORG/$repo 접근 불가"
  fi
done
```

---

## Step 3: 레포 클론 + 의존성 설치

### 3-1. 레포 클론

```bash
ORG=$(python3 -c "import json; print(json.load(open('$CONFIG'))['github']['org'])")
REPOS=$(python3 -c "import json; print(' '.join(json.load(open('$CONFIG'))['github']['repos']))")

## 레포별 기본 브랜치

`config.json`의 `github.default_branches`에서 레포별 기본 브랜치를 읽는다.

| Repo | 기본 브랜치 |
|------|-----------|
| DDD-12-GROWIT-BE | `main` |
| DDD-12-GROWIT-FE | `develop` |
| DDD-12-GROWIT-APP | `main` |

```bash
# 기본 브랜치 조회 함수
get_default_branch() {
  python3 -c "import json; print(json.load(open('$CONFIG')).get('github',{}).get('default_branches',{}).get('$1','main'))"
}

for repo in $REPOS; do
  TARGET="$BASE_DIR/$repo"
  DEFAULT_BRANCH=$(get_default_branch "$repo")
  if [ -d "$TARGET" ]; then
    echo "✓ $repo — 이미 존재, $DEFAULT_BRANCH pull"
    (cd "$TARGET" && git checkout "$DEFAULT_BRANCH" 2>/dev/null && git pull origin "$DEFAULT_BRANCH" 2>/dev/null)
  else
    echo "→ $repo 클론 중..."
    git clone "https://github.com/$ORG/$repo.git" "$TARGET"
    (cd "$TARGET" && git checkout "$DEFAULT_BRANCH" 2>/dev/null) || true
  fi
done
```

### 3-2. 의존성 설치

```bash
for repo in $REPOS; do
  TARGET="$BASE_DIR/$repo"

  # BE: Gradle 프로젝트
  if [ -f "$TARGET/gradlew" ]; then
    echo "→ $repo: gradle dependencies..."
    (cd "$TARGET" && chmod +x gradlew && ./gradlew dependencies --quiet 2>&1 | tail -3)
  fi

  # FE: npm 프로젝트 (루트에 package.json)
  if [ -f "$TARGET/package.json" ] && [ -f "$TARGET/package-lock.json" ]; then
    echo "→ $repo: npm install..."
    (cd "$TARGET" && npm install 2>&1 | tail -3)
  fi

  # APP: yarn 프로젝트 (서브디렉토리 growit-mobile/)
  if [ -f "$TARGET/growit-mobile/yarn.lock" ]; then
    echo "→ $repo: yarn install (growit-mobile/)..."
    (cd "$TARGET/growit-mobile" && yarn install 2>&1 | tail -3)
  fi
done
```

---

## Step 4: 환경변수 배포

`growit-env/{repo}/` → 각 repo 루트로 복사.

```bash
# BE
if [ -f "$ENV_DIR/be/.env.development" ]; then
  cp "$ENV_DIR/be/.env.development" "$BASE_DIR/DDD-12-GROWIT-BE/.env.development"
  echo "✅ BE .env.development 배포"
fi

# FE
if [ -f "$ENV_DIR/fe/.env.development" ]; then
  cp "$ENV_DIR/fe/.env.development" "$BASE_DIR/DDD-12-GROWIT-FE/.env.development"
  echo "✅ FE .env.development 배포"
fi

# APP
if [ -f "$ENV_DIR/app/.env.development" ]; then
  cp "$ENV_DIR/app/.env.development" "$BASE_DIR/DDD-12-GROWIT-APP/.env.development"
  echo "✅ APP .env.development 배포"
fi
```

### .gitignore 확인

```bash
for repo in DDD-12-GROWIT-BE DDD-12-GROWIT-FE DDD-12-GROWIT-APP; do
  GITIGNORE="$BASE_DIR/$repo/.gitignore"
  if [ -f "$GITIGNORE" ] && ! grep -q "\.env" "$GITIGNORE"; then
    echo "⚠️ $repo/.gitignore에 .env 패턴 추가 권장"
  fi
done
```

---

## Step 5: MCP 서버 설정

`config.json`에서 Figma/Notion 토큰을 읽어 `.mcp.json` 생성.

```python
import json

config_path = "$CONFIG"
with open(config_path) as f:
    config = json.load(f)

figma_token = config["figma"]["token"]
notion_token = config["notion"]["token"]
notion_version = config["notion"].get("version", "2022-06-28")

mcp = {
    "mcpServers": {
        "figma": {
            "command": "npx",
            "args": ["-y", "figma-developer-mcp", f"--figma-api-key={figma_token}", "--stdio"]
        },
        "notion": {
            "command": "npx",
            "args": ["-y", "@notionhq/notion-mcp-server"],
            "env": {
                "OPENAPI_MCP_HEADERS": json.dumps({
                    "Authorization": f"Bearer {notion_token}",
                    "Notion-Version": notion_version
                })
            }
        }
    }
}

with open(".mcp.json", "w") as f:
    json.dump(mcp, f, indent=2)
```

### MCP 검증

```bash
FIGMA_TOKEN=$(python3 -c "import json; print(json.load(open('$CONFIG'))['figma']['token'])")
NOTION_TOKEN=$(python3 -c "import json; print(json.load(open('$CONFIG'))['notion']['token'])")

# Figma
FIGMA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Figma-Token: $FIGMA_TOKEN" "https://api.figma.com/v1/me")
[ "$FIGMA_STATUS" = "200" ] && echo "✅ Figma 연결 확인" || echo "❌ Figma 토큰 만료 (config.json 갱신 필요)"

# Notion
NOTION_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $NOTION_TOKEN" -H "Notion-Version: 2022-06-28" "https://api.notion.com/v1/users/me")
[ "$NOTION_STATUS" = "200" ] && echo "✅ Notion 연결 확인" || echo "❌ Notion 토큰 만료 (config.json 갱신 필요)"
```

---

## Step 6: SSH 키 설정 & 터널 검증

### 6-1. PEM 권한 설정

```bash
PEM_PATH="$ENV_DIR/$(python3 -c "import json; print(json.load(open('$CONFIG'))['ssh']['bastion']['key'])")"

if [ -f "$PEM_PATH" ]; then
  chmod 400 "$PEM_PATH"
  echo "✅ SSH 키 권한 설정 완료"
else
  echo "⚠️ SSH 키 없음: $PEM_PATH — SSH 터널 기능 비활성"
fi
```

### 6-2. Bastion 연결 테스트

```bash
BASTION_HOST=$(python3 -c "import json; print(json.load(open('$CONFIG'))['ssh']['bastion']['host'])")
BASTION_USER=$(python3 -c "import json; print(json.load(open('$CONFIG'))['ssh']['bastion']['user'])")

if [ -n "$BASTION_HOST" ] && [ -f "$PEM_PATH" ]; then
  ssh -i "$PEM_PATH" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$BASTION_USER@$BASTION_HOST" "echo ok" 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "✅ Bastion SSH 연결 성공"
  else
    echo "⚠️ Bastion SSH 연결 실패 — 네트워크/VPN 확인"
  fi
fi
```

### 6-3. SSH 터널 생성 테스트

```bash
python3 -c "
import json, subprocess, os

with open('$CONFIG') as f:
    config = json.load(f)

bastion = config['ssh']['bastion']
key_path = os.path.join('$ENV_DIR', bastion['key'])

if not os.path.exists(key_path):
    print('⚠️ SSH 키 없음 — 터널 스킵')
    exit(0)

for tunnel in config['ssh']['tunnels']:
    local_port = tunnel['local_port']
    remote_host = tunnel['remote_host']
    remote_port = tunnel['remote_port']
    name = tunnel['name']

    # 이미 활성인지 확인
    result = subprocess.run(['lsof', '-i', f':{local_port}'], capture_output=True, text=True)
    if 'ssh' in result.stdout:
        print(f'✅ {name}: 터널 이미 활성 (localhost:{local_port})')
        continue

    # 터널 생성
    cmd = [
        'ssh', '-f', '-N', '-L',
        f'{local_port}:{remote_host}:{remote_port}',
        '-i', key_path,
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'ServerAliveInterval=60',
        '-p', str(bastion['port']),
        f\"{bastion['user']}@{bastion['host']}\"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        print(f'✅ {name}: 터널 생성 (localhost:{local_port} → {remote_host}:{remote_port})')
    else:
        print(f'⚠️ {name}: 터널 실패 — {result.stderr.strip()}')
"
```

---

## Step 7: Cursor 워크스페이스 구성 & 열기

### 7-1. 워크스페이스 파일 생성/확인

```bash
WORKSPACE_FILE="$BASE_DIR/growit.code-workspace"

if [ ! -f "$WORKSPACE_FILE" ]; then
  cp "$(pwd)/growit.code-workspace" "$WORKSPACE_FILE" 2>/dev/null || cat > "$WORKSPACE_FILE" <<'EOF'
{
  "folders": [
    { "path": "DDD-12-GROWIT-LEAD" },
    { "path": "DDD-12-GROWIT-BE" },
    { "path": "DDD-12-GROWIT-FE" },
    { "path": "DDD-12-GROWIT-APP" }
  ],
  "settings": {}
}
EOF
  echo "✅ growit.code-workspace 생성"
fi
```

### 7-2. AI 커맨드 동기화

```bash
cd "$(pwd)" && python3 .ai/sync.py 2>/dev/null
echo "✅ AI 커맨드 동기화 완료"
```

### 7-3. Cursor로 워크스페이스 열기

```bash
if command -v cursor &>/dev/null; then
  echo ""
  echo "→ Cursor에서 워크스페이스를 엽니다..."
  cursor "$WORKSPACE_FILE"
else
  echo ""
  echo "ℹ️ Cursor가 설치되어 있지 않습니다."
  echo "   https://cursor.com 에서 설�� 후:"
  echo "   cursor $WORKSPACE_FILE"
fi
```

---

## Step 8: 최종 결과 보고

```
🎉 GROWIT 워크스페��스 세팅 완료!

| 항목 | 상태 |
|------|------|
| 필수 도구 | ✅ git, node, npm, gh, java |
| GitHub 인증 | ✅ {username} @ DDD-Community |
| 레포 클론 | ✅ BE, FE, APP |
| 환경변수 배포 | ✅ .env.development → ��� repo |
| Figma MCP | ✅/❌ |
| Notion MCP | ✅/❌ |
| SSH 키 | ✅/⚠️ |
| SSH 터널 | ✅/⚠️ localhost:5433 → RDS |
| 워크스페이스 | ✅ Cursor 열림 |

📋 다음 단계:
  /deploy-local  → 로컬 서버 전체 기동
  /orchestrate   → 풀스택 개발 시작
```

---

## 전체 자동화 요약 (사용자 액션 단 3개)

```
1. git clone https://github.com/DDD-Community/DDD-12-GROWIT-LEAD.git
2. growit-env.zip 압축 해제 (같은 부모 폴더에)
3. cd DDD-12-GROWIT-LEAD && /settings 실행
   → GitHub 인증 자동
   → 3개 레포 클론 자동
   → 환경변수 배포 자동
   → MCP 연결 자동
   → SSH 터널 자동
   → Cursor 워크스페이스 열림
```

---

## 에지 케이스

- **growit-env 폴더 없음**: 에러 + "��원에게 zip 요청" 안내
- **config.json 필드 누락**: 누락 필드 명시 후 중단
- **GitHub 토큰 만료**: 인증 실패 시 재발급 안내 (https://github.com/settings/tokens)
- **Figma/Notion 토큰 만료**: 경고만 표시, 나머지 계속 진행
- **SSH 키 없음**: 터널 단계 스킵, 로컬 DB 사용 안내
- **Bastion 연결 실패**: 경고 표시, 나머지 계속 진행
- **레포 이미 존재**: 클론 스킵, `git pull` 최신화
- **Cursor 미설치**: 경로 안내만 출력, 중단하지 않음
- **npm install 실패**: 경고 후 계속 진행
- **포트 이미 사용 중 (5433)**: 기존 터널 활성 상태로 판단, 재생성하지 않음

---

## 체크리스트

- [ ] 필수 도구 설치 확인 (git, node, npm, gh, java)
- [ ] growit-env/config.json 로드 & 검증
- [ ] GitHub 토큰으로 자동 인증
- [ ] 3개 레포 클론 + 의존성 설치
- [ ] 환경변수 파일 각 repo에 복사
- [ ] .mcp.json 생성 (Figma + Notion)
- [ ] MCP 연결 검증
- [ ] SSH 키 권한 설정 (chmod 400)
- [ ] Bastion SSH 연결 테스트
- [ ] SSH ��널 생성
- [ ] growit.code-workspace 생성
- [ ] AI 커맨드 동기화
- [ ] Cursor 워크스페이스 열기
- [ ] 최종 결과 보고
