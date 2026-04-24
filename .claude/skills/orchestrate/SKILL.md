---
name: orchestrate
description: 풀스택 구현 오케스트레이션 (BE→FE→APP → 리뷰→테스트→PR)
context: fork
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---
# Orchestrate

풀스택 구현 오케스트레이션. 티켓 기반으로 자동화 파이프라인을 실행합니다.

```
Feature:  요구사항 분석 → BE→FE→APP → 리뷰
Bug:      증상 + 재현 경로 → 코드베이스 분석(/debug) → 수정 → 리뷰
Modify:   현재→변경 + 영향 분석 → 수정 → 리뷰
```

> **위임 순서·대상·컨텍스트는 `rules/delegation-matrix.md`(SSOT)를 따른다.**

## 인자

- `TICKET_ID` — (필수) 티켓 ID

---

## Phase 0: 티켓 파싱 & 컨텍스트 저장

### 0-1. 티켓 로딩 & 타입 판별

| 순서 | 판별 기준 |
|------|----------|
| 1 | `타입:` 필드 명시 → 그대로 사용 |
| 2 | 제목에 "버그", "bug", "fix" → bug |
| 3 | Figma 링크 존재 → feature |
| 4 | `## 현재 동작` / `## 변경 내용` 존재 → modify |
| 5 | 불확실 → 사용자에게 확인 |

### 0-2. 서비스 판별 & 영향 repo 판정

`rules/delegation-matrix.md §3 포함 규칙`에 따라 `affectedRepos`를 결정한다.

### 0-3. 컨텍스트 번들 저장

**저장 경로**: `growit-lead/.orchestrate/{TICKET_ID}/context.json`

```typescript
interface OrchestrationContext {
  ticket: {
    id: string;
    title: string;
    type: 'feature' | 'bug' | 'modify';
    summary: string;
    notes: string;
  };
  execution: {
    scope: 'full-stack' | 'be-only' | 'fe-only' | 'app-only';
    affectedRepos: Array<'be' | 'fe' | 'app'>;
    branchName: string;
  };
}
```

### 0-4. 사용자 확인

파싱 결과·실행 계획을 사용자에게 보고하고 확인을 받는다.

---

## Phase 1: 타입별 워크플로우 실행

### Feature 워크플로우

**의존 순서**: `BE → FE → APP`

| Step | 병렬 허용 | 실행 |
|------|----------|------|
| `/research` | **✅ 모든 affected repo 병렬** | 각 repo에 동시 위임 |
| `/plan` | ❌ 순차 | BE → FE → APP 순 |
| `/implement` | ❌ 순차 | 동일 순서 |
| `/review` | ❌ 순차 | 각 repo 구현 완료 후 실행 |
| `/pr` | ❌ 순차 | 리뷰 통과 후 레포별 PR 생성 |

### Bug 워크플로우

`/debug` → 수정 → `/review` → `/pr`

### Modify 워크플로우

`/research` → `/plan`(multi-repo일 때) → `/implement` → `/review` → `/pr`

---

## Phase 2: PR 리뷰 & 승인 대기

PR 목록 취합 및 리뷰 프로세스.

---

## Phase 3: 테스트 & 검증

각 repo에서 빌드/테스트 통과 확인.

---

## Phase 4: 결과 기록

구현 결과 요약 및 보고.

---

## 체크리스트

- [ ] 티켓 파싱 & 타입/서비스 판별
- [ ] `.orchestrate/{TICKET_ID}/context.json` 저장
- [ ] Pre-flight: 모든 affected repo의 위임 커맨드 파일 존재 확인
- [ ] 사용자 확인 받음
- [ ] 모든 `/review` 품질 게이트를 통과
