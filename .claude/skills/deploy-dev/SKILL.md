---
name: deploy-dev
description: PR을 main에 머지하여 DEV 환경에 배포 (의존성 순서: BE→FE→APP)
context: fork
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---
# Deploy Dev

모든 서비스의 PR을 main에 머지하여 **DEV 환경**에 배포합니다.

## 인자

- `TICKET_ID` — (선택) Notion 티켓 ID. 제공 시 배포 후 Notion 상태 업데이트

---

## 배포 흐름

```
/deploy-dev
    │
    ▼
Step 1: PR 일괄 Mergeability 체크
    ▼
Step 2: 의존성 순서대로 PR 머지 (BE → FE → APP)
    ▼
Step 3: 배포 모니터링
    │  → GitHub Actions 워크플로우 상태 확인
    ▼
Step 4: 배포 결과 보고
    └── 완료
```

---

## Step 1: PR 일괄 Mergeability 체크

```bash
for repo in "${AFFECTED_REPOS[@]}"; do
  cd "${REPO_PATH[$repo]}"
  gh pr view "$PR_NUMBER" --json mergeable,mergeStateStatus,statusCheckRollup
done
```

---

## Step 2: PR 머지 (의존성 순서)

### 머지 순서 (delegation-matrix §2)

```
1. DDD-12-GROWIT-BE    (백엔드)
2. DDD-12-GROWIT-FE    (웹 프론트엔드)
3. DDD-12-GROWIT-APP   (모바일 앱)
```

```bash
cd {repo_path} && gh pr merge {PR_NUMBER} --squash --delete-branch
```

---

## Step 3: 배포 모니터링

```bash
cd {repo_path} && gh run list --limit 3 --branch main
```

---

## Step 4: 배포 결과 보고

```markdown
## DEV 배포 결과

| Repo | PR | 워크플로우 | 상태 |
|------|----|-----------|------|
| DDD-12-GROWIT-BE | #123 | deploy-dev | ✅ 성공 |
| DDD-12-GROWIT-FE | #45 | deploy-dev | ✅ 성공 |
| DDD-12-GROWIT-APP | #67 | deploy-dev | ✅ 성공 |
```

---

## 체크리스트

- [ ] 모든 PR이 mergeable임을 확인했는가
- [ ] 의존성 순서(BE → FE → APP)로 머지했는가
- [ ] GitHub Actions 워크플로우가 성공적으로 완료되었는가
- [ ] 배포 결과를 보고했는가
