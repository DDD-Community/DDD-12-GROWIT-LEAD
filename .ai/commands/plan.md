# Plan

리서치 결과를 기반으로 **영향 repo별 구현 계획**을 수립합니다.

> **위임 순서·대상·컨텍스트는 `rules/delegation-matrix.md`(SSOT)를 따른다.**

## 인자

- `TICKET_ID` — (필수) 티켓 ID

> `/research`가 선행되어야 합니다.

---

## 흐름

```
/plan TICKET_ID
    │
    ▼
Step 1: 컨텍스트 & 리서치 결과 로드
    ▼
Step 2: Pre-flight (plan.md 존재 검증)
    ▼
Step 3: repo별 /plan 위임 (순차, BE → FE → APP)
    ▼
Step 4: 전체 실행 순서도 작성
    ▼
Step 5: 크로스 repo 정합성 검증
    ▼
Step 6: 통합 계획 보고
    └── 완료
```

---

## Step 3: repo별 /plan 위임 (순차)

**의존 순서**: `BE → FE → APP`.
후행 repo는 선행 repo의 `.plan/{TICKET}/` 산출물을 컨텍스트로 읽는다.

### BE → FE API 계약

BE repo의 `/plan`은 API 계약 산출물을 생성한다:
- `.plan/{TICKET_ID}/api-contract.md` — 엔드포인트/DTO/에러 정의

FE/APP repo의 `/plan`은 이 파일을 읽어 연동 계획을 수립한다.

---

## Step 5: 크로스 repo 정합성 검증

- BE ↔ FE API 계약 일치 여부
- BE ↔ APP API 계약 일치 여부
- FE와 APP의 공통 로직 정합성

---

## 체크리스트

- [ ] `.orchestrate/{TICKET_ID}/context.json`과 각 repo의 `.research/{TICKET_ID}/research.md`를 확인했는가
- [ ] 의존 순서(BE → FE → APP)로 순차 위임했는가
- [ ] BE가 `.plan/{TICKET}/api-contract.md`를 산출했는가
- [ ] FE/APP plan이 BE 계약 산출물을 consume했는가
- [ ] 통합 계획 보고 완료
