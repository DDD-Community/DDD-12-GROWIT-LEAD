# Delegation Matrix (SSOT)

> **모든 오케스트레이터 커맨드(`/orchestrate`, `/research`, `/plan`, `/implement`, `/pr`)는 본 문서를 유일한 위임 규칙으로 사용합니다.**

---

## 1. Repo 경로 매핑

| Repo Key | 로컬 경로 | GitHub | 역할 |
|---------|----------|--------|------|
| `be` | `~/Desktop/growit/DDD-12-GROWIT-BE` | `DDD-Community/DDD-12-GROWIT-BE` | 백엔드 API |
| `fe` | `~/Desktop/growit/DDD-12-GROWIT-FE` | `DDD-Community/DDD-12-GROWIT-FE` | 웹 프론트엔드 |
| `app` | `~/Desktop/growit/DDD-12-GROWIT-APP` | `DDD-Community/DDD-12-GROWIT-APP` | React Native 앱 |

---

## 2. 의존성 순서

```
BE → FE → APP
```

- `BE`는 FE/APP에 선행 (API 계약이 FE/APP에서 참조됨).
- `FE`는 APP에 선행 (공통 로직/타입이 있을 수 있음).
- APP은 독립적으로 배포 가능.

> **순서 요약**: server → web → mobile

**예외:** `/research`는 읽기 전용이므로 **병렬 실행을 허용**한다. `/plan`, `/implement`, `/pr`, `/deploy-*`는 위 순서를 엄격히 따른다.

---

## 3. 포함 규칙 (repo가 워크플로우에 들어갈지 판단)

### Feature

| Repo | 포함 조건 |
|------|----------|
| `be` | API/서버 로직 변경이 필요한 경우 |
| `fe` | 웹 UI 변경이 필요한 경우 |
| `app` | 모바일 UI 변경이 필요한 경우 |

### Bug

| Repo | 포함 조건 |
|------|----------|
| `be` | 추정 원인이 BE 레이어 |
| `fe` | 추정 원인이 FE 레이어 |
| `app` | 추정 원인이 APP 레이어 |

### Modify

| Repo | 포함 조건 |
|------|----------|
| `be` | 영향 범위에 BE 명시 |
| `fe` | 영향 범위에 FE 명시 |
| `app` | 영향 범위에 APP 명시 |

> **판별 결과는 `.orchestrate/{TICKET_ID}/context.json`의 `execution.affectedRepos`에 저장된다.**

---

## 4. 단계별 위임 대상

| 단계 | be | fe | app |
|------|----|----|-----|
| `/research` | `{repo}/.ai/commands/research.md` | 동일 | 동일 |
| `/plan` | `{repo}/.ai/commands/plan.md` | 동일 | 동일 |
| `/implement` | `{repo}/.ai/commands/implement.md` | 동일 | 동일 |
| `/debug` (Bug 전용) | `{repo}/.ai/commands/debug.md` | 동일 | 동일 |
| `/pr` | `{repo}/.ai/commands/pr.md` | 동일 | 동일 |

### Pre-flight (위임 전 필수 검증)

```bash
test -f {repo_path}/.ai/commands/{command}.md || \
  { echo "ERROR: {repo}/.ai/commands/{command}.md not found"; exit 1; }
```

---

## 5. 컨텍스트 주입 규칙

> 모든 값은 `.orchestrate/{TICKET_ID}/context.json`에서 읽는다.

| 단계 | be | fe | app |
|------|----|----|-----|
| `/research` | `domain` 전체 | `design`, `planning.userFlow` | `design`, `planning.userFlow` |
| `/plan` | `domain`, `planning.constraints` | `design`, `planning`, BE API 산출물 | `design`, `planning`, BE API 산출물 |
| `/implement` | `domain.entities/commands/queries` | `design`, `planning.userFlow`, BE API | `design`, `planning.userFlow`, BE API |
| `/pr` | `ticket.type`, `ticket.summary` | 동일 | 동일 |

---

## 6. 브랜치 네이밍 (단일 패턴)

```
{prefix}/{TICKET_ID}-{kebab-summary}
```

| 타입 | prefix |
|------|--------|
| feature | `feat` |
| bug | `fix` |
| modify | `modify` |

- 모든 repo에서 **동일한 브랜치명**을 사용한다.

---

## 7. 산출물 경로 표준

| 산출물 | 경로 | 커밋 여부 |
|--------|------|----------|
| 오케스트레이션 컨텍스트 | `growit-lead/.orchestrate/{TICKET_ID}/context.json` | **커밋 금지** |
| 각 repo 리서치 | `{repo}/.research/{TICKET_ID}/research.md` | 커밋 금지 |
| 각 repo 계획 | `{repo}/.plan/{TICKET_ID}/plan.md` | 커밋 금지 |

### 멱등성/재실행

- `/research` 재실행: 기존 파일 **append** (시간 헤더 추가).
- `/plan` 재실행: 기존 파일 **overwrite** (이전 계획은 history/에 백업).
- `/implement` 재실행: git 상태에서 시작.
