---
name: deploy-local
description: 로컬 개발 서버 전체 기동 (BE + FE, hot-reload)
context: fork
allowed-tools: Read, Grep, Glob, Bash
---
# Local

로컬 개발 서버를 전체 기동하여 실시간 반영(hot-reload) 환경을 구성한다.

## 인자

- `TARGET` — (선택) 특정 서비스만 실행. 미지정 시 **전체 기동**.
  - `be` — BE 서버
  - `fe` — FE 웹
  - `app` — RN 앱

---

## 서비스 매핑

| 서비스 | 경로 | 실행 명령 | 비고 |
|--------|------|----------|------|
| BE | `~/Desktop/growit/DDD-12-GROWIT-BE` | `npm run start:dev` | hot-reload |
| FE | `~/Desktop/growit/DDD-12-GROWIT-FE` | `npm run dev` | hot-reload |
| APP | `~/Desktop/growit/DDD-12-GROWIT-APP` | `npm run start` | Metro bundler |

---

## 흐름

```
/local [TARGET]
    │
    ▼
Step 1: 의존성 확인 (node_modules 존재 여부)
    ▼
Step 2: 포트 충돌 검사
    ▼
Step 3: 서비스 기동 (백그라운드)
    ▼
Step 4: 헬스체크 & 상태 보고
```

---

## Step 1: 의존성 확인

각 대상 repo에 `node_modules`가 있는지 확인한다. 없으면 `npm install`을 먼저 실행한다.

---

## Step 2: 포트 충돌 검사

대상 포트에 이미 실행 중인 프로세스가 있으면 **kill 후 재시작**한다.

---

## Step 3: 서비스 기동

각 서비스를 **백그라운드**로 실행한다.

```bash
LOG_DIR=~/Desktop/growit/.logs
mkdir -p "$LOG_DIR"
```

---

## Step 4: 헬스체크 & 상태 보고

```
🟢 로컬 서버 기동 완료

| 서비스 | 상태 | URL |
|--------|------|-----|
| BE | ✅ Running | http://localhost:{PORT} |
| FE | ✅ Running | http://localhost:{PORT} |
| APP | ✅ Running | Metro Bundler |
```

---

## 체크리스트

- [ ] node_modules 존재 확인 (없으면 npm install)
- [ ] 포트 충돌 검사 완료
- [ ] 대상 서비스 모두 백그라운드 실행
- [ ] 상태 테이블 보고
