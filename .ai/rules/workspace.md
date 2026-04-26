# Workspace Architecture Rules

## SSOT 원칙

각 프로젝트는 자기 도메인 커맨드/규칙만 소유하고, `DDD-12-GROWIT-LEAD`가 오케스트레이터 역할을 합니다.

### 프로젝트별 책임

| 프로젝트 | `.ai/` 범위 | 소유 커맨드 |
|---------|------------|-----------|
| `DDD-12-GROWIT-LEAD` | 워크스페이스 오케스트레이션 | `/settings`, `/orchestrate`, `/research`, `/plan`, `/implement`, `/review`, `/pr`, `/deploy-dev`, `/deploy-prod` |
| `DDD-12-GROWIT-BE` | BE 구현 관련 | `/research`, `/plan`, `/implement`, `/debug`, `/pr` |
| `DDD-12-GROWIT-FE` | FE 구현 관련 | `/research`, `/plan`, `/implement`, `/debug`, `/pr` |
| `DDD-12-GROWIT-APP` | APP 구현 관련 | `/research`, `/plan`, `/implement`, `/debug`, `/pr` |

> **위임 순서·대상·컨텍스트 주입 규칙은 `rules/delegation-matrix.md` 하나에서만 관리합니다.**

### 서비스 분류

| 서비스 | 영향 repo | 설명 |
|--------|----------|------|
| **backend** | `DDD-12-GROWIT-BE` | API 서버 |
| **frontend** | `DDD-12-GROWIT-FE` | 웹 프론트엔드 |
| **app** | `DDD-12-GROWIT-APP` | React Native 모바일 앱 |

### 위임 패턴

`DDD-12-GROWIT-LEAD`의 커맨드는 직접 구현하지 않고 **각 프로젝트 커맨드를 순서대로 위임**합니다.

```
/orchestrate TICKET_ID
    │
    ├── Phase 0: 티켓 파싱 & 타입/서비스 판별 & context.json 저장
    ├── Phase 1: 타입별 워크플로우
    │   ├── feature/modify: /research (병렬) → /plan → /implement → /review
    │   │     의존 순서: BE → FE → APP
    │   └── bug: /debug (원인 repo) → 수정 → /review
    ├── Phase 2: PR 리뷰 & 승인 대기
    ├── Phase 3: 테스트 & 검증
    └── Phase 4: 결과 기록
    → 별도: /deploy-dev → /deploy-prod
```
