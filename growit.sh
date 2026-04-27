#!/bin/bash
#
# GROWIT 워크스페이스 부트스트랩
#
# 사용법:
#   1. growit-env.zip과 이 스크립트를 같은 폴더에 배치
#   2. chmod +x growit.sh && ./growit.sh
#
set -e

echo ""
echo "================================================"
echo "  🌱 GROWIT 워크스페이스 자동 설정"
echo "================================================"
echo ""

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE_DIR"

# ─────────────────────────────────────────────
# Step 1: growit-env 압축 해제
# ─────────────────────────────────────────────
echo "[1/6] growit-env 압축 해제..."

if [ -d "$BASE_DIR/growit-env" ]; then
  echo "  -> growit-env/ 이미 존재, 스킵"
elif [ -f "$BASE_DIR/growit-env.zip" ]; then
  unzip -q "$BASE_DIR/growit-env.zip" -d "$BASE_DIR"
  echo "  -> 압축 해제 완료"
else
  echo "  ❌ growit-env.zip을 찾을 수 없습니다."
  echo "     이 스크립트와 같은 폴더에 growit-env.zip을 배치하세요."
  exit 1
fi

ENV_DIR="$BASE_DIR/growit-env"
CONFIG="$ENV_DIR/config.json"

if [ ! -f "$CONFIG" ]; then
  echo "  ❌ growit-env/config.json이 없습니다."
  exit 1
fi

echo "  -> config.json 확인 완료"
echo ""

# ─────────────────────────────────────────────
# Step 2: 필수 도구 설치
# ─────────────────────────────────────────────
echo "[2/6] 필수 도구 확인..."

# Homebrew
if ! command -v brew &>/dev/null; then
  echo "  -> Homebrew 설치 중..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# git
if ! command -v git &>/dev/null; then
  echo "  -> git 설치 중..."
  brew install git
fi

# Node.js
if ! command -v node &>/dev/null; then
  echo "  -> Node.js 설치 중..."
  brew install node
fi

# yarn
if ! command -v yarn &>/dev/null; then
  echo "  -> yarn 설치 중..."
  npm install -g yarn
fi

# GitHub CLI
if ! command -v gh &>/dev/null; then
  echo "  -> GitHub CLI 설치 중..."
  brew install gh
fi

# Java 17
if ! java -version 2>&1 | grep -q "17"; then
  echo "  -> Java 17 설치 중..."
  brew install openjdk@17
  sudo ln -sfn "$(brew --prefix openjdk@17)/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk-17.jdk 2>/dev/null || true
fi

echo "  git:  $(git --version 2>/dev/null | head -c 30)"
echo "  node: $(node --version 2>/dev/null)"
echo "  yarn: $(yarn --version 2>/dev/null)"
echo "  gh:   $(gh --version 2>/dev/null | head -1 | head -c 30)"
echo "  java: $(java -version 2>&1 | head -1 | head -c 40)"
echo ""

# ─────────────────────────────────────────────
# Step 3: GitHub 인증
# ─────────────────────────────────────────────
echo "[3/6] GitHub 인증..."

GH_TOKEN=$(python3 -c "import json; print(json.load(open('$CONFIG'))['github']['token'])")

if [ -n "$GH_TOKEN" ]; then
  echo "$GH_TOKEN" | gh auth login --with-token 2>/dev/null
fi

if gh auth status &>/dev/null; then
  GH_USER=$(gh api user --jq '.login' 2>/dev/null)
  echo "  -> 인증 완료: $GH_USER"
else
  echo "  -> config.json 토큰 실패, 브라우저 인증 진행..."
  gh auth login --web --git-protocol https
  GH_USER=$(gh api user --jq '.login' 2>/dev/null)
  echo "  -> 인증 완료: $GH_USER"
fi
echo ""

# ─────────────────────────────────────────────
# Step 4: 레포 클론 + 의존성 설치
# ─────────────────────────────────────────────
echo "[4/6] 레포 클론..."

ORG=$(python3 -c "import json; print(json.load(open('$CONFIG'))['github']['org'])")
REPOS=$(python3 -c "import json; print(' '.join(json.load(open('$CONFIG'))['github']['repos']))")

# LEAD (이미 있을 수 있음)
if [ ! -d "$BASE_DIR/DDD-12-GROWIT-LEAD" ]; then
  echo "  -> DDD-12-GROWIT-LEAD 클론..."
  git clone "https://github.com/$ORG/DDD-12-GROWIT-LEAD.git" "$BASE_DIR/DDD-12-GROWIT-LEAD"
else
  echo "  -> DDD-12-GROWIT-LEAD 이미 존재"
fi

# BE, FE, APP
for repo in $REPOS; do
  TARGET="$BASE_DIR/$repo"
  if [ -d "$TARGET" ]; then
    echo "  -> $repo 이미 존재, pull..."
    (cd "$TARGET" && git checkout main 2>/dev/null && git pull origin main 2>/dev/null) || true
  else
    echo "  -> $repo 클론..."
    git clone "https://github.com/$ORG/$repo.git" "$TARGET"
  fi
done

echo ""
echo "  의존성 설치 중... (시간이 걸릴 수 있습니다)"

# BE: Gradle
if [ -f "$BASE_DIR/DDD-12-GROWIT-BE/gradlew" ]; then
  echo "  -> BE: gradle dependencies..."
  (cd "$BASE_DIR/DDD-12-GROWIT-BE" && chmod +x gradlew && ./gradlew dependencies --quiet 2>&1 | tail -1) || true
fi

# FE: npm
if [ -f "$BASE_DIR/DDD-12-GROWIT-FE/package.json" ]; then
  echo "  -> FE: npm install..."
  (cd "$BASE_DIR/DDD-12-GROWIT-FE" && npm install 2>&1 | tail -1) || true
fi

# APP: yarn (서브디렉토리)
if [ -f "$BASE_DIR/DDD-12-GROWIT-APP/growit-mobile/yarn.lock" ]; then
  echo "  -> APP: yarn install..."
  (cd "$BASE_DIR/DDD-12-GROWIT-APP/growit-mobile" && yarn install 2>&1 | tail -1) || true
fi

echo ""

# ─────────────────────────────────────────────
# Step 5: 환경 설정 (env, MCP, SSH)
# ─────────────────────────────────────────────
echo "[5/6] 환경 설정..."

# 환경변수 배포
if [ -f "$ENV_DIR/be/.env.development" ]; then
  cp "$ENV_DIR/be/.env.development" "$BASE_DIR/DDD-12-GROWIT-BE/.env.development"
  echo "  -> BE .env.development 배포"
fi

if [ -f "$ENV_DIR/fe/.env.development" ]; then
  cp "$ENV_DIR/fe/.env.development" "$BASE_DIR/DDD-12-GROWIT-FE/.env.development"
  echo "  -> FE .env.development 배포"
fi

if [ -f "$ENV_DIR/app/.env.development" ]; then
  cp "$ENV_DIR/app/.env.development" "$BASE_DIR/DDD-12-GROWIT-APP/.env.development"
  echo "  -> APP .env.development 배포"
fi

# MCP 설정 (.mcp.json)
python3 -c "
import json, os

config_path = '$CONFIG'
lead_dir = '$BASE_DIR/DDD-12-GROWIT-LEAD'

with open(config_path) as f:
    config = json.load(f)

figma_token = config['figma']['token']
notion_token = config['notion']['token']
notion_version = config['notion'].get('version', '2022-06-28')

mcp = {
    'mcpServers': {
        'figma': {
            'command': 'npx',
            'args': ['-y', 'figma-developer-mcp', f'--figma-api-key={figma_token}', '--stdio']
        },
        'notion': {
            'command': 'npx',
            'args': ['-y', '@notionhq/notion-mcp-server'],
            'env': {
                'OPENAPI_MCP_HEADERS': json.dumps({
                    'Authorization': f'Bearer {notion_token}',
                    'Notion-Version': notion_version
                })
            }
        }
    }
}

mcp_path = os.path.join(lead_dir, '.mcp.json')
with open(mcp_path, 'w') as f:
    json.dump(mcp, f, indent=2)
print('  -> .mcp.json 생성 완료')
"

# SSH 키 권한
PEM_PATH="$ENV_DIR/$(python3 -c "import json; print(json.load(open('$CONFIG'))['ssh']['bastion']['key'])")"
if [ -f "$PEM_PATH" ]; then
  chmod 400 "$PEM_PATH"
  echo "  -> SSH 키 권한 설정 (400)"
fi

# SSH 터널 테스트
BASTION_HOST=$(python3 -c "import json; print(json.load(open('$CONFIG'))['ssh']['bastion']['host'])" 2>/dev/null)
if [ -n "$BASTION_HOST" ] && [ -f "$PEM_PATH" ]; then
  BASTION_USER=$(python3 -c "import json; print(json.load(open('$CONFIG'))['ssh']['bastion']['user'])")
  ssh -i "$PEM_PATH" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$BASTION_USER@$BASTION_HOST" "echo ok" 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "  -> Bastion SSH 연결 확인"
  else
    echo "  -> Bastion SSH 연결 실패 (나중에 /deploy-local에서 재시도)"
  fi
fi

echo ""

# ─────────────────────────────────────────────
# Step 6: 워크스페이스 파일 생성
# ─────────────────────────────────────────────
echo "[6/6] 워크스페이스 구성..."

WORKSPACE_FILE="$BASE_DIR/growit.code-workspace"

if [ ! -f "$WORKSPACE_FILE" ]; then
  cat > "$WORKSPACE_FILE" <<'EOF'
{
  "folders": [
    { "path": "DDD-12-GROWIT-LEAD" },
    { "path": "DDD-12-GROWIT-BE" },
    { "path": "DDD-12-GROWIT-FE" },
    { "path": "DDD-12-GROWIT-APP" }
  ],
  "settings": {
    "notebook.defaultFormatter": "esbenp.prettier-vscode"
  }
}
EOF
  echo "  -> growit.code-workspace 생성"
else
  echo "  -> growit.code-workspace 이미 존재"
fi

# AI 커맨드 동기화
if [ -f "$BASE_DIR/DDD-12-GROWIT-LEAD/.ai/sync.py" ]; then
  (cd "$BASE_DIR/DDD-12-GROWIT-LEAD" && python3 .ai/sync.py 2>/dev/null)
  echo "  -> AI 커맨드 동기화 완료"
fi

echo ""
echo "================================================"
echo "  설정 완료!"
echo "================================================"
echo ""
echo "  Cursor에서 워크스페이스 파일을 선택해서 시작하세요:"
echo ""
echo "    $WORKSPACE_FILE"
echo ""
echo "  또는 터미널에서:"
echo "    cursor $WORKSPACE_FILE"
echo ""
echo "  로컬 서버 기동:"
echo "    /deploy-local"
echo ""
echo "================================================"
