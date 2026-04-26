# CLAUDE.md — DDD-12-GROWIT-LEAD (Orchestrator)

## 역할

DDD-12-GROWIT-LEAD는 **오케스트레이터**입니다. 코드를 직접 작성하지 않고, 크로스 레포 작업을 조율합니다.

- 개발 파이프라인 실행 (research → plan → implement → review → pr → deploy)
- 배포 조율 (DEV/PROD)
- 프로젝트 지식 축적 (Wiki)

---

## 워크스페이스 구조

```
growit/
├── DDD-12-GROWIT-LEAD/              ← 이 repo. 오케스트레이터
├── DDD-12-GROWIT-FE/         ← FE: 프론트엔드 (Web)
├── DDD-12-GROWIT-BE/         ← BE: 백엔드
└── DDD-12-GROWIT-APP/        ← APP: React Native 앱
```

### 의존성 순서

```
BE → FE → APP
```

모든 위임(`/plan`, `/implement`, `/pr`, `/deploy-*`)은 이 순서를 엄격히 따릅니다.
`/research`만 병렬 실행을 허용합니다.

---

## 핵심 규칙 (Rules)

| 규칙 | 파일 | 용도 |
|------|------|------|
| **Workspace** | `.ai/rules/workspace.md` | 프로젝트별 책임, 위임 패턴, 서비스 아키텍처 |
| **Delegation Matrix** | `.ai/rules/delegation-matrix.md` | 위임 순서/대상/컨텍스트 주입의 **유일한 SSOT** |

> 위임 관련 의사결정 시 **반드시 delegation-matrix.md를 먼저 읽을 것.**

---

## 커맨드 (Skills)

### 파이프라인

| 커맨드 | 역할 | 위임 대상 |
|--------|------|----------|
| `/orchestrate` | 풀스택 구현 오케스트레이션 | 모든 affected repo |
| `/research` | 크로스 레포 리서치 (병렬) | 각 repo `.ai/commands/research.md` |
| `/plan` | 구현 계획 수립 (순차) | 각 repo `.ai/commands/plan.md` |
| `/implement` | 구현 실행 (순차) | 각 repo `.ai/commands/implement.md` |
| `/review` | 품질 게이트 리뷰 | 각 repo `/review` |
| `/pr` | PR 생성 & 집계 | 각 repo `/pr` |

### 배포

| 커맨드 | 역할 | 트리거 |
|--------|------|--------|
| `/deploy-dev` | PR → main 머지 → DEV 배포 | main push → GitHub Actions |
| `/deploy-prod` | 릴리스 태그 → PROD 배포 | tag push → GitHub Actions |
| `/deploy-local` | 로컬 개발 서버 전체 기동 | 수동 |

### 설정 & 지식

| 커맨드 | 역할 |
|--------|------|
| `/settings` | 초기 워크스페이스 세팅 (GitHub/Figma/Notion MCP + 레포 클론 + Cursor 워크스페이스) |
| `/wiki` | 프로젝트 지식 축적 & 관리 (learn/ingest/query/lint/status) |

---

## Wiki 시스템

프로젝트 지식을 축적하는 LLM Wiki. 작업할수록 지식이 쌓여 다음 작업이 빨라집니다.

```
.wiki/
├── index.md              ← 전체 페이지 인덱스 (탐색 시 먼저 읽기)
├── log.md                ← 변경 이력 (append-only)
├── overview.md           ← 프로젝트 현황 종합
├── architecture/         ← 아키텍처 패턴 & 구조
├── patterns/             ← 반복되는 코드/워크플로우 패턴
├── incidents/            ← 장애/버그 사후분석
├── decisions/            ← ADR (Architecture Decision Records)
├── domains/              ← 도메인별 지식 (엔티티, API)
└── skills/               ← 스킬 갭 트래킹
```

---

## Notion 연동 (티켓 관리)

- **티켓 관리**: Notion Database
- **MCP 도구**: Notion MCP (`@notionhq/notion-mcp-server`)
- `/settings`에서 Notion Integration Token을 등록하면 티켓 조회/수정 가능

---

## GitHub 연동

| Repo | GitHub |
|------|--------|
| DDD-12-GROWIT-FE | `DDD-Community/DDD-12-GROWIT-FE` |
| DDD-12-GROWIT-BE | `DDD-Community/DDD-12-GROWIT-BE` |
| DDD-12-GROWIT-APP | `DDD-Community/DDD-12-GROWIT-APP` |
| DDD-12-GROWIT-LEAD | `DDD-Community/DDD-12-GROWIT-LEAD` |

---

## 산출물 경로

| 산출물 | 경로 | git |
|--------|------|-----|
| 오케스트레이션 컨텍스트 | `.orchestrate/{TICKET_ID}/context.json` | gitignored |
| 리서치 결과 | `{repo}/.research/{TICKET_ID}/research.md` | gitignored |
| 구현 계획 | `{repo}/.plan/{TICKET_ID}/plan.md` | gitignored |
| Wiki | `.wiki/` | **커밋** |

---

## .ai 디렉토리 구조

```
.ai/
├── commands/           ← 슬래시 커맨드 정의 (SSOT)
│   ├── _meta.yaml       (도구 권한, description)
│   └── *.md             (커맨드별 워크플로우)
├── rules/              ← 프로젝트 규칙
│   ├── _meta.yaml
│   └── *.md
└── sync.sh → sync.py  ← .ai/ → .cursor/ + .claude/skills/ 동기화
```

동기화: `bash .ai/sync.sh`
- `.cursor/commands/` — Cursor IDE 커맨드
- `.cursor/rules/` — Cursor IDE 규칙
- `.claude/skills/` — Claude Code SKILL.md

---

## 브랜치 네이밍

```
{feat|fix|modify}/{TICKET_ID}-{kebab-summary}
```

모든 repo에서 **동일한 브랜치명** 사용.

---

## 커밋 규칙

- 커밋 메시지는 **영어**, conventional commit 형식
- `git add`는 파일 지정 (`-A`, `.` 금지)
