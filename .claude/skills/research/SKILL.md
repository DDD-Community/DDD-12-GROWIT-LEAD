---
name: research
description: 크로스 레포 리서치 오케스트레이션 (BE→FE→APP 순서 위임)
context: fork
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---
# Research

티켓 기반으로 **영향 repo에 `/research`를 위임**합니다.
DDD-12-GROWIT-LEAD의 `/research`는 크로스 레포 오케스트레이터이며, 실제 코드 분석은 각 repo에 위임합니다.

> **위임 순서·대상·컨텍스트는 `rules/delegation-matrix.md`(SSOT)를 따른다.**

## 인자

- `TICKET_ID` — (필수) 티켓 ID

---

## 흐름

```
/research TICKET_ID
    │
    ▼
Step 1: 컨텍스트 로드 (.orchestrate/{TICKET_ID}/context.json)
    │  없으면 /orchestrate Phase 0 수행
    ▼
Step 2: Pre-flight (위임 대상 커맨드 파일 존재 검증)
    ▼
Step 3: 브랜치 생성 (각 affected repo)
    ▼
Step 4: repo별 /research 위임 (병렬 허용)
    ▼
Step 5: 결과 집계
    └── 완료
```

---

## Step 1: 컨텍스트 로드

`DDD-12-GROWIT-LEAD/.orchestrate/{TICKET_ID}/context.json`을 읽는다.
파일이 없으면 `/orchestrate {TICKET_ID}` Phase 0만 수행.

---

## Step 2: Pre-flight

각 affected repo의 `research.md` 존재를 검증.

---

## Step 3: 브랜치 생성

각 affected repo에서 브랜치 생성 & 로컬 checkout.

> 브랜치명: `{prefix}/{TICKET_ID}-{kebab-summary}` (delegation-matrix §6)

```bash
cd {repo_path} && git checkout -b {execution.branchName}
```

---

## Step 4: repo별 /research 위임 (병렬)

> 읽기 전용 단계이므로 모든 affected repo를 병렬로 실행한다.

각 repo는 `.research/{TICKET_ID}/research.md`를 산출물로 남긴다.

---

## Step 5: 결과 집계

```markdown
## 리서치 결과 요약

**티켓**: {TICKET_ID} — {제목}

| Repo | Branch | 리서치 결과 요약 |
|------|--------|-----------------|
| DDD-12-GROWIT-BE | {branchName} | {요약} |
| DDD-12-GROWIT-FE | {branchName} | {요약} |
| DDD-12-GROWIT-APP | {branchName} | {요약} |

### 다음 단계
→ `/plan {TICKET_ID}` 으로 구현 계획을 수립합니다.
```

---

## 체크리스트

- [ ] `.orchestrate/{TICKET_ID}/context.json`을 로드했는가
- [ ] Pre-flight에서 모든 위임 대상 `research.md` 존재를 검증했는가
- [ ] 각 affected repo에서 브랜치를 생성했는가
- [ ] 모든 affected repo에 **병렬로** `/research`를 위임했는가
- [ ] 각 repo가 `.research/{TICKET_ID}/research.md`를 남겼는가
- [ ] 결과 요약을 보고했는가
