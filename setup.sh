#!/bin/bash
set -e

ORG="DDD-Community"
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

REPOS=(
  DDD-12-GROWIT-FE
  DDD-12-GROWIT-BE
  DDD-12-GROWIT-APP
)

echo "=== GROWIT Workspace Setup ==="
echo "Base directory: $BASE_DIR"
echo ""

# 1. Clone repos
for repo in "${REPOS[@]}"; do
  TARGET="$BASE_DIR/$repo"
  if [ -d "$TARGET" ]; then
    echo "✓ $repo already exists, skipping clone"
  else
    echo "→ Cloning $repo..."
    git clone "https://github.com/$ORG/$repo.git" "$TARGET"
  fi
done

# 2. Copy workspace file
WORKSPACE_FILE="$BASE_DIR/growit.code-workspace"
if [ ! -f "$WORKSPACE_FILE" ]; then
  echo ""
  echo "→ Creating growit.code-workspace..."
  cp "$BASE_DIR/growit-lead/growit.code-workspace" "$WORKSPACE_FILE"
  echo "✓ Workspace file created"
else
  echo ""
  echo "✓ growit.code-workspace already exists"
fi

# 3. Install dependencies
echo ""
echo "=== Installing dependencies ==="

for repo in "${REPOS[@]}"; do
  TARGET="$BASE_DIR/$repo"
  if [ -f "$TARGET/package.json" ]; then
    echo "→ $repo: installing..."
    (cd "$TARGET" && npm install)
    echo "✓ $repo: done"
  fi
done

echo ""
echo "=== Setup Complete ==="
echo ""
echo "다음 명령어로 Cursor에서 워크스페이스를 여세요:"
echo "  cursor $WORKSPACE_FILE"
echo ""
echo "또는 Cursor에서 File > Open Workspace from File... 로 열기:"
echo "  $WORKSPACE_FILE"
