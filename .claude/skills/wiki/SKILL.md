---
name: wiki
description: 프로젝트 지식 축적 & 관리 — learn(교훈 추출), ingest(소스 학습), query(질의), lint(건강성 ��사), status(현황)
context: fork
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---
# Wiki

프로젝트 지식을 축적하고 관리하는 LLM Wiki 시스템.

## 인자

- `ACTION` — **(필수)** `ingest` | `query` | `lint` | `learn` | `status`
- `SOURCE` — (선택) 학습 대상. TICKET_ID, PR URL 등
- `QUESTION` — (선택) query 시 질문 내용

---

## Wiki 구조

```
.wiki/
├── index.md              ← 전체 페이지 인덱스
├── log.md                ← 변경 이력 (append-only, 최신이 위)
├── overview.md           ← 프로젝트 현황 종합
├── architecture/         ← 아키텍처 패턴 & 구조
├── patterns/             ← 반복되는 코드/워크플로우 패턴
├── incidents/            ← 장애/버그 사후분석
├── decisions/            ← ADR (Architecture Decision Records)
├── domains/              ← 도메인별 지식
└── skills/               ← 스킬 갭 트래킹
```

---

## Action: `learn`

피처/배포/리뷰 완료 후 실행하여 교훈을 자동 추출.

1. 소스 수집 (PR, 리뷰, CI)
2. 교훈 추출 (패턴, 장애, 결정, 스킬 갭)
3. Wiki 페이지 생성/업데이트
4. index.md, log.md 업데이트

---

## Action: `query`

Wiki 기반 질의응답.

```
/wiki query "결제 도메인 구조는?"
```

---

## Action: `lint`

Wiki 건강성 검사 (고아 페이지, 깨진 링크, 오래된 페이지).

---

## Action: `status`

Wiki 현황 요약 (페이지 수, 최근 활동).
