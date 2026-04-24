# Implement

구현 계획을 기반으로 **영향 repo별 구현**을 실행합니다.

> **위임 순서·대상·컨텍스트는 `rules/delegation-matrix.md`(SSOT)를 따른다.**

## 인자

- `TICKET_ID` — (필수) 티켓 ID

> `/plan`이 선행되어야 합니다.

---

## 흐름

```
/implement TICKET_ID
    │
    ▼
Step 1: 컨텍스트 & 계획 로드
    ▼
Step 2: Pre-flight (implement.md 존재 검증)
    ▼
Step 3: repo별 /implement 위임 (순차, BE → FE → APP)
    ▼
Step 4: 크로스 repo 정합성 검증
    ▼
Step 5: 구현 결과 집계
    └── 완료
```

---

## Step 3: repo별 /implement 위임 (순차)

**의존 순서**: `BE → FE → APP`.
각 repo 구현 완료 후 다음 repo로 진행. 병렬 실행 금지.

### 3-1. DDD-12-GROWIT-BE

BE 구현 완료 후 API 계약 산출물 갱신.

```bash
cd ~/Desktop/growit/DDD-12-GROWIT-BE && npm run build && npm test
```

### 3-2. DDD-12-GROWIT-FE

BE API 계약 산출물을 참조하여 FE 구현.

```bash
cd ~/Desktop/growit/DDD-12-GROWIT-FE && npm run build
```

### 3-3. DDD-12-GROWIT-APP

BE API 계약 산출물을 참조하여 APP 구현.

```bash
cd ~/Desktop/growit/DDD-12-GROWIT-APP && npm run build
```

---

## Step 4: 크로스 repo 정합성 검증

- BE API ↔ FE 연동 확인
- BE API ↔ APP 연동 확인
- 타입 정합성 (tsc --noEmit)

---

## Step 5: 구현 결과 집계

```markdown
## 구현 결과 — {TICKET_ID}

| Repo | 상태 | 변경 파일 | 빌드 | 테스트 |
|------|------|----------|------|--------|
| DDD-12-GROWIT-BE | ✅ 완료 | {N}개 | ✅ | ✅ |
| DDD-12-GROWIT-FE | ✅ 완료 | {N}개 | ✅ | N/A |
| DDD-12-GROWIT-APP | ✅ 완료 | {N}개 | ✅ | N/A |

### 다음 단계
→ `/review {TICKET_ID}` 또는 `/pr {TICKET_ID}`
```

---

## 체크리스트

- [ ] `.orchestrate/{TICKET_ID}/context.json`과 모든 영향 repo의 `.plan/{TICKET_ID}/plan.md`를 확인했는가
- [ ] 의존 순서(BE → FE → APP)로 순차 위임했는가
- [ ] 각 repo의 빌드/테스트 통과 확인
- [ ] API 정합성 검증 통과
- [ ] 구현 결과 집계 보고
