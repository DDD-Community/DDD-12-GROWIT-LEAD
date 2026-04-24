# PR

영향 repo별로 **PR을 생성**하고 결과를 집계합니다.

> **위임 대상과 의존 순서는 `rules/delegation-matrix.md`(SSOT)를 따른다.**

## 인자

- `TICKET_ID` — (필수) 티켓 ID

---

## 흐름

```
/pr TICKET_ID
    │
    ▼
Step 1: 컨텍스트 로드 & 각 repo 변경 확인
    ▼
Step 2: Pre-flight (pr.md 존재 검증)
    ▼
Step 3: repo별 /pr 위임 (순차, BE → FE → APP)
    ▼
Step 4: PR 목록 집계 & Related PRs 상호 참조
    └── 완료
```

---

## Step 1: 컨텍스트 로드 & 변경 확인

```bash
cd {repo_path} && git status && git log main..HEAD --oneline
```

### 미커밋 변경 자동 커밋

미커밋 변경이 감지되면 자동으로 커밋한다:

```bash
cd {repo_path}
git add {변경 파일들}
git commit -m "{type}({domain}): {변경 요약}

Refs: {TICKET_ID}"
```

---

## Step 3: repo별 /pr 위임 (순차)

**의존 순서**: `BE → FE → APP`.

### PR Body 포맷

```markdown
## Summary
- Type: {feature | bug | modify}
- Branch: {execution.branchName}

## Changes
{변경 사항 요약}

## Related PRs
{다른 repo PR 링크}

## Test plan
{테스트 방법}
```

---

## Step 4: PR 목록 집계

```markdown
## PR 생성 완료 — {TICKET_ID}

| repo | PR | 링크 |
|------|----|------|
| DDD-12-GROWIT-BE | #{N} | https://github.com/DDD-Community/DDD-12-GROWIT-BE/pull/{N} |
| DDD-12-GROWIT-FE | #{N} | https://github.com/DDD-Community/DDD-12-GROWIT-FE/pull/{N} |
| DDD-12-GROWIT-APP | #{N} | https://github.com/DDD-Community/DDD-12-GROWIT-APP/pull/{N} |
```

---

## 체크리스트

- [ ] `.orchestrate/{TICKET_ID}/context.json` 로드 완료
- [ ] 모든 affected repo의 브랜치명이 일치
- [ ] 의존 순서(BE → FE → APP)로 PR 생성
- [ ] PR 간 Related PRs 상호 참조 추가
