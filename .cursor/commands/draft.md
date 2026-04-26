# /draft — Meeting to Develop (Notion)

회의 노트 또는 Notion 티켓을 자동 분석하여 `/orchestrate` 호환 개발 초안을 작성한다.

## 핵심 원칙

- **Meeting → Develop**: 회의 노트/요구사항만 있으면 자동으로 개발 초안이 분석된다
- **Notion 기반**: Notion 페이지를 읽고, 분석 초안을 Notion에 직접 작성한다
- **인터뷰 없음 (티켓 모드)**: Notion 페이지 ID/제목 지정 시 자동 분석
- **1 티켓 = 1 도메인**: 여러 도메인에 걸치면 분리를 제안한다
- **`/orchestrate` 호환**: 분석 초안 완료 후 바로 파이프라인 실행 가능

---

## 실행 모드

### 모드 A: 기존 Notion 페이지 분석 (주요 모드)

```
/draft DEVS-3                                    ← 이슈 트래킹 Unique ID (권장)
/draft 12345678-1234-1234-1234-123456789abc      ← Notion 페이지 UUID
/draft "목표 생성 기능 추가"                       ← 페이지 제목 검색
```

1. Notion MCP로 페이지 조회
2. 페이지 내용 자동 분석
3. 분석 초안을 Notion 페이지 하단에 append
4. (선택) Figma 디자인 연동

### 모드 B: 새 Notion 페이지 생성

```
/draft
```

인터뷰로 요구사항을 수집한 뒤 새 Notion 페이지를 생성한다.
하단 "부록: 모드 B 인터뷰 플로우" 참조.

---

## 모드 A: 기존 페이지 분석 플로우

### Phase 1: 입력 수집

#### 1-1. Notion 페이지 조회

**DEVS-N (Unique ID) 형식인 경우 (권장):**

`DEVS-{N}` 패턴 매칭 시 (대소문자 무시, 예: `DEVS-3`, `devs-3`):

1. 숫자 N을 추출한다
2. 이슈 트래킹 DB 전체를 검색한다:

```
mcp__notion__API-post-search(
  query: "",
  filter: { "property": "object", "value": "page" }
)
```

3. 결과에서 다음 조건으로 필터링:
   - `parent.database_id === "34ce8349-9ccf-807d-b092-c5a6621792af"` (이슈 트래킹 DB)
   - `properties.ID.unique_id.number === N`
4. 매칭된 페이지의 `page_id`로 상세 조회:

```
mcp__notion__API-retrieve-a-page(page_id: "{찾은 PAGE_ID}")
mcp__notion__API-get-block-children(block_id: "{찾은 PAGE_ID}")
```

5. 매칭 실패 시 → "DEVS-{N} 이슈를 찾을 수 없습니다" 안내

**페이지 UUID가 주어진 경우:**

```
mcp__notion__API-retrieve-a-page(page_id: "{PAGE_ID}")
mcp__notion__API-get-block-children(block_id: "{PAGE_ID}")
```

**페이지 제목이 주어진 경우:**

```
mcp__notion__API-post-search(query: "{페이지 제목}", filter: { "property": "object", "value": "page" })
```

검색 결과에서 가장 관련성 높은 페이지를 선택한다. 여러 개 매칭되면 사용자에게 확인.

**Notion MCP 미연결 fallback:**

Notion MCP를 사용할 수 없으면 사용자에게 직접 내용을 요청한다:

```
티켓 내용을 붙여넣어주세요. (제목 + 본문)
```

#### 1-2. 분석 입력 조립

```
분석 입력 = Notion 페이지 제목 + Notion 페이지 본문 (blocks)
```

- 페이지 properties에서 타입, 상태 등 메타데이터 추출
- 본문 blocks에서 텍스트 콘텐츠 추출
- **입력이 비어있으면 진행 불가** — "페이지 내용이 필요합니다" 안내

---

### Phase 2: AI 자동 분석

페이지 내용을 분석하여 다음 5가지를 자동 판별한다:

#### 2-1. Type 판별

| 순서 | 판별 기준 |
|------|----------|
| 1 | Notion property에 `타입` 필드 → 그대로 사용 |
| 2 | 제목/본문에 "버그", "bug", "fix", "오류" → bug |
| 3 | Figma 링크 포함 → feature |
| 4 | "추가", "신규", "새로운" → feature |
| 5 | "변경", "수정", "개선" → modify |
| 6 | "## 현재 동작" 또는 "## 변경 내용" → modify |
| 7 | 불확실 → 사용자에게 확인 |

#### 2-2. Affected Repo 판별

| Repo | 판별 기준 |
|------|----------|
| **BE** | API, 엔드포인트, 로직, 서버, DB, 엔터티, 도메인 관련 |
| **FE** | UI, 화면, 페이지, 컴포넌트, 웹 관련 |
| **APP** | 모바일, 앱, 네이티브, 푸시 알림 관련 |

#### 2-3. 도메인 판별

GROWIT BE 도메인 목록에서 매칭:

| 도메인 | 키워드 |
|--------|--------|
| goal | 목표, 행성, 플래닛, 기간, 진행률 |
| todo | 할일, 투두, 루틴, 일정, 미션 |
| user | 회원, 로그인, 가입, 인증, OAuth, 프로필, 사주 |
| advice | 조언, 멘토, AI, 그로롱, 채팅, 운세 |
| retrospect | 회고, KPT, 되돌아보기, 분석 |
| mission | 미션, 보상, 달성 |
| resource | 명언, 초대, 알림, 디스코드 |

#### 2-4. 참고 링크 추출

본문에서 Figma URL을 자동 추출:
- `figma.com/design/` → 디자인 링크
- `figma.com/file/` → 기획 링크
- 없으면 TBD

#### 2-5. 도메인 상세 분석

**type이 feature 또는 modify (BE 포함)인 경우:**

코드베이스를 참조하여 DDD Aggregate Root 기반으로 분석:

1. **Aggregate Root**: 관련 엔터티, 필드, 타입, 관계
2. **Command**: Write API (POST/PUT/DELETE)
3. **Query (Read Model)**: Read API (GET)
4. **Business Rules**: 비즈니스 규칙, 유효성 검사
5. **Hotspot**: 성능/보안 주의사항
6. **Migration**: DB 스키마 변경 필요 여부

**분석 참조 소스:**
- BE: `com.growit.app.{domain}/` 패키지 구조
- 기존 Aggregate Root 목록 (architecture.md 참조)
- Flyway 마이그레이션 이력
- FE: FSD 계층 구조 (shared → feature → composite → app)
- APP: expo-router 스크린 구조

**type이 bug인 경우:**
- 도메인 분석 생략
- 증상 + 추정 원인 + 재현 경로로 정리

---

### Phase 3: 분석 초안 미리보기

분석 결과를 사용자에게 보여주고 확인을 받는다:

```markdown
## 📋 분석 초안

### 기본 정보
- **Type**: feature
- **Domain**: goal
- **Affected Repos**: BE, FE
- **Figma**: {URL 또는 TBD}

### 개발 사항 요약
{요구사항에서 추출한 핵심 요약}

### 도메인 분석 (BE)

#### Aggregate Root
| Entity | 변경 | 필드 | 비고 |
|--------|------|------|------|
| Goal | 수정 | newField: String | 새 필드 추가 |

#### API Endpoints
| Method | Path | 설명 |
|--------|------|------|
| POST | /goals | 목표 생성 |
| GET | /goals/{id} | 목표 조회 |

#### Business Rules
- {규칙 1}
- {규칙 2}

#### Migration
- V{next}__description.sql 필요 여부

### 영향도
- BE: {상세}
- FE: {상세}
- APP: {상세}
```

---

### Phase 4: Notion 페이지 업데이트

사용자가 확인하면 분석 초안을 기존 페이지 하단에 append한다.

#### 4-1. 본문에 분석 초안 Append

`mcp__notion__API-patch-block-children`로 페이지 하단에 블록을 추가한다:

```
mcp__notion__API-patch-block-children(
  block_id: "{PAGE_ID}",
  children: [
    { "type": "paragraph", "paragraph": { "rich_text": [{ "type": "text", "text": { "content": "---" } }] } },
    { "type": "paragraph", "paragraph": { "rich_text": [{ "type": "text", "text": { "content": "## 개발 초안 (AI 분석)" } }] } },
    { "type": "paragraph", "paragraph": { "rich_text": [{ "type": "text", "text": { "content": "타입: {type} | 도메인: {domain} | 영향: {repos}" } }] } },
    { "type": "paragraph", "paragraph": { "rich_text": [{ "type": "text", "text": { "content": "{분석 초안 본문}" } }] } }
  ]
)
```

**append할 내용 구조:**

```markdown
---

## 개발 초안 (AI 분석) — {YYYY-MM-DD HH:mm}

### 입력
- 타입: {type}
- 도메인: {domain}
- 영향 Repo: {BE, FE, APP}
- 기획: {Figma URL 또는 TBD}
- 디자인: {Figma URL 또는 TBD}

### 한줄 요약
{개발 사항 핵심 요약}

### AI 도메인 분석

#### Aggregates
{Entity별 필드 테이블}

#### API Endpoints
{Command + Query 엔드포인트 테이블}

#### Business Rules
{Policy 목록}

#### Migration
{필요한 Flyway 마이그레이션}

### 영향도
- BE: {상세}
- FE: {상세}
- APP: {상세}

### 비고
{추가 맥락, 주의사항}
```

#### 4-2. Properties 업데이트 (이슈 트래킹 DB 소속인 경우)

페이지가 "이슈 트래킹" Database 소속이면 properties를 업데이트한다:

```
mcp__notion__API-patch-page(
  page_id: "{PAGE_ID}",
  properties: {
    "상태": { "status": { "name": "미해결" } },
    "우선순위": { "select": { "name": "{높음|보통|낮음}" } }
  }
)
```

**우선순위 판별 기준:**

| 우선순위 | 조건 |
|----------|------|
| 높음 | 장애/버그, 핵심 기능 블로커, 마감 임박 |
| 보통 | 일반 기능 개발, 개선 |
| 낮음 | 리팩토링, 부가 기능, 기술 부채 |

> Database 소속이 아닌 단독 페이지면 이 단계를 스킵.

---

### Phase 5: 로컬 산출물 저장

분석 결과를 `.draft/` 에 로컬 저장한다:

```bash
mkdir -p .draft/{PAGE_ID}
```

**`.draft/{PAGE_ID}/draft.md`** — 분석 초안 전문 (Notion에 올린 것과 동일)
**`.draft/{PAGE_ID}/context.json`** — 구조화된 메타데이터:

```json
{
  "notion": {
    "pageId": "{PAGE_ID}",
    "title": "{페이지 제목}",
    "url": "https://notion.so/{PAGE_ID}"
  },
  "ticket": {
    "type": "feature",
    "domain": "goal",
    "summary": "{한줄 요약}"
  },
  "execution": {
    "affectedRepos": ["be", "fe"],
    "branchName": "feat/GROWIT-{N}-{kebab-summary}"
  },
  "analysis": {
    "aggregates": [],
    "endpoints": [],
    "migrations": [],
    "businessRules": []
  }
}
```

---

## 전체 실행 흐름

```
/draft {PAGE_ID 또는 제목}
  │
  ├── Phase 1: Notion 페이지 조회 (MCP)
  ├── Phase 2: AI 자동 분석
  │     ├── type 판별 (feature/modify/bug)
  │     ├── affected repos 판별 (BE/FE/APP)
  │     ├── domain 판별 (goal/todo/user/...)
  │     ├── Figma 링크 추출
  │     ├── 개발 사항 요약
  │     └── 도메인 분석 (Aggregate/API/Rules/Migration)
  ├── Phase 3: 분석 초안 미리보기 → 사용자 확인
  ├── Phase 4: Notion 페이지에 초안 append (MCP)
  ├── Phase 5: 로컬 .draft/ 저장
  └── 완료 → /orchestrate {PAGE_ID} 으로 개발 시작

후속 작업 (사람):
  ├── 분석 초안 리뷰 + 필요 시 수정
  ├── Figma 기획/디자인 작업 (TBD 링크 채우기)
  └── /orchestrate {PAGE_ID} 실행
```

---

## 이슈 트래킹 Database 연동

### Database 정보

| 항목 | 값 |
|------|-----|
| **DB 이름** | 이슈 트래킹 |
| **DB ID** | `34ce83499ccf807db092c5a6621792af` |
| **ID Prefix** | DEVS |

### Database Schema

| Property | Type | 옵션 | 용도 |
|----------|------|------|------|
| `이슈` | title | (필수) | 이슈 제목 — `[{domain}] {한줄 요약}` |
| `상태` | status | 백로그, 미해결, 진행 중, 검토 중, 테스트 중, 수정하지 않기로 결정함, 해결 | 새 이슈 → `백로그` |
| `우선순위` | select | 높음, 보통, 낮음 | 인터뷰 or 분석에서 결정 |
| `배정 대상` | people | - | (선택) 사용자 지정 시 설정 |
| `마감일` | date | - | (선택) 사용자 지정 시 설정 |
| `ID` | unique_id | DEVS-N (자동) | Notion 자동 부여 |
| `생성 일시` | created_time | (자동) | Notion 자동 부여 |

> 모드 B에서 새 이슈 생성 시 이 DB에 페이지를 추가한다.
> 모드 A Phase 4-2에서 기존 이슈의 `상태`, `우선순위`를 업데이트한다.

---

## Notion MCP 도구 레퍼런스

| 용도 | MCP 도구 |
|------|---------|
| 페이지 검색 | `mcp__notion__API-post-search` |
| 페이지 조회 | `mcp__notion__API-retrieve-a-page` |
| 페이지 본문 조회 | `mcp__notion__API-get-block-children` |
| 본문 append | `mcp__notion__API-patch-block-children` |
| 페이지 properties 수정 | `mcp__notion__API-patch-page` |
| 새 페이지 생성 | `mcp__notion__API-post-page` |

---

## GROWIT 도메인 참조 (BE Aggregate Root)

| Domain | Aggregate Root | 하위 Aggregate |
|--------|---------------|----------------|
| goal | Goal | Planet, GoalAnalysis |
| todo | ToDo | Routine |
| user | User | UserToken, Promotion, UserAdviceStatus, UserStats |
| advice | ChatAdvice, MentorAdvice | Grorong |
| retrospect | Retrospect | GoalRetrospect |
| mission | Mission | - |
| resource | Saying | - |

---

## 에지 케이스

- **페이지 내용이 부족한 경우**: 판별 불가 항목은 사용자에게 확인 요청
- **Bug 타입**: 도메인 상세 분석 생략, 증상/원인/재현 경로로 정리
- **FE-only**: BE 도메인 분석 경량화
- **APP-only**: 모바일 특화 분석 (스크린 구조, 네이티브 기능)
- **다중 도메인 감지**: "이 요구사항은 2개 이상의 도메인에 걸칩니다. 분리를 권장합니다" 안내
- **이미 초안이 있는 경우**: 기존 초안 유지 + 새 분석을 별도 타임스탬프 섹션으로 append

---

## 부록: 모드 B 인터뷰 플로우

`/draft` 단독 실행 시 (페이지 ID 없음), 인터뷰로 요구사항을 수집한다.

### Step 0: 티켓 타입

```
어떤 유형의 작업인가요?
- feature: 신규 기능 추가
- modify: 기존 기능 변경/개선
- bug: 버그 수정
```

### Step 1: 도메인

```
어떤 도메인인가요?
- goal: 목표 관리
- todo: 할 일 관리
- user: 회원/인증
- advice: AI 조언
- retrospect: 회고
- mission: 미션
- resource: 리소스/알림
```

### Step 2: 구현 내용 상세

```
구현하고자 하는 내용을 상세히 설명해주세요.
```

### Step 3: 우선순위

```
우선순위를 선택해주세요.
- 높음: 장애/버그, 핵심 기능 블로커, 마감 임박
- 보통: 일반 기능 개발, 개선
- 낮음: 리팩토링, 부가 기능, 기술 부채
```

### Step 4: 영향도 & 참고 링크

```
영향을 미치는 영역을 선택해주세요. (복수 선택 가능)
- BE (API/로직)
- FE (웹 UI)
- APP (모바일)

참고 Figma 링크가 있나요? (없으면 생략)
```

### Step 5: 마감일 (선택)

```
마감일이 있나요? (없으면 생략)
- 예: 2026-05-01
```

### Step 6: 이슈 트래킹 DB에 새 페이지 생성

수집된 정보로 Phase 2~5를 동일하게 실행하되, Phase 4에서 **이슈 트래킹 Database**에 새 페이지를 생성한다.

> Database ID: `34ce83499ccf807db092c5a6621792af` (이슈 트래킹)

```
mcp__notion__API-post-page(
  parent: { "database_id": "34ce83499ccf807db092c5a6621792af" },
  properties: {
    "이슈": { "title": [{ "text": { "content": "[{domain}] {한줄 요약}" } }] },
    "상태": { "status": { "name": "백로그" } },
    "우선순위": { "select": { "name": "{높음|보통|낮음}" } },
    "마감일": { "date": { "start": "{YYYY-MM-DD}" } }  // 마감일 있을 때만
  },
  children: [
    // 분석 초안 블록들
  ]
)
```

**생성 후:** 생성된 페이지의 ID(DEVS-N)를 사용자에게 안내하고, 로컬 `.draft/` 산출물의 context.json에 기록한다.
