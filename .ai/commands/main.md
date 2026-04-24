# Main

모든 repo의 현재 브랜치를 main으로 전환하고 최신 상태로 pull한다.

## 대상 레포

| # | 레포 | 경로 |
|---|------|------|
| 1 | growit-lead | `~/Desktop/growit/growit-lead` |
| 2 | DDD-12-GROWIT-BE | `~/Desktop/growit/DDD-12-GROWIT-BE` |
| 3 | DDD-12-GROWIT-FE | `~/Desktop/growit/DDD-12-GROWIT-FE` |
| 4 | DDD-12-GROWIT-APP | `~/Desktop/growit/DDD-12-GROWIT-APP` |

---

## 흐름

```
/main
  │
  ▼
Step 1: 각 repo 상태 확인 (uncommitted changes 체크)
  ▼
Step 2: main 체크아웃 & pull (병렬)
  ▼
Step 3: 결과 보고
```

---

## Step 1: 상태 확인

각 repo에서 uncommitted changes가 있는지 확인한다.

```bash
cd <repo-path> && git status --porcelain
```

- 변경사항이 있는 repo는 **skip** 처리하고 사용자에게 알린다.
- 변경사항이 없는 repo만 Step 2로 진행한다.

---

## Step 2: main 체크아웃 & pull

변경사항이 없는 repo에 대해 **병렬로** 실행한다:

```bash
cd <repo-path> && git checkout main && git pull origin main
```

---

## Step 3: 결과 보고

```
✅ 전체 레포 main 최신화 완료

| 레포 | 상태 | 비고 |
|------|------|------|
| growit-lead | ✅ Updated | abc1234 ← latest commit msg |
| DDD-12-GROWIT-BE | ✅ Updated | def5678 ← latest commit msg |
| DDD-12-GROWIT-FE | ⏭️ Skipped | uncommitted changes 존재 |
| DDD-12-GROWIT-APP | ✅ Updated | ghi9012 ← latest commit msg |
```

---

## 주의사항

- uncommitted changes가 있는 repo는 절대 checkout하지 않는다 (작업 손실 방지).
- `git pull`은 항상 `origin main`을 명시한다.
- 에러 발생 시 해당 repo만 실패로 보고하고 나머지는 계속 진행한다.
