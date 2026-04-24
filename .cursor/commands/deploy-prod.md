# Deploy Prod

서비스를 **PROD 환경**에 배포합니다.
릴리스 태그를 생성하여 GitHub Actions의 PROD 배포 워크플로우를 트리거합니다.

## 인자

- `TICKET_ID` — (선택) Notion 티켓 ID
- `VERSION` — (선택) 릴리스 버전 (예: `1.2.0`). 미지정 시 이전 태그 기준 자동 증가

---

## 배포 흐름

```
/deploy-prod
    │
    ▼
Step 1: 배포 전 검증 (Pre-flight Check)
    ▼
Step 2: 릴리스 태그 생성
    ▼
Step 3: 배포 모니터링
    ▼
Step 4: 배포 결과 보고
    └── 완료
```

---

## Step 1: 배포 전 검증

- DEV 배포 성공 여부 확인
- 테스트 통과 확인
- 변경 내용 사용자 승인

---

## Step 2: 릴리스 태그 생성

```bash
cd {repo_path}
git tag -a v{VERSION} -m "Release v{VERSION}: {변경 요약}"
git push origin v{VERSION}
```

---

## Step 3: 배포 모니터링

```bash
cd {repo_path} && gh run list --limit 3
```

---

## Step 4: 배포 결과 보고

```markdown
## PROD 배포 결과

| Repo | 태그 | 워크플로우 | 상태 |
|------|------|-----------|------|
| DDD-12-GROWIT-BE | v1.2.0 | deploy-prod | ✅ 성공 |
| DDD-12-GROWIT-FE | v1.2.0 | deploy-prod | ✅ 성공 |
| DDD-12-GROWIT-APP | v1.2.0 | deploy-prod | ✅ 성공 |
```

---

## 체크리스트

- [ ] DEV 환경에서 정상 동작이 확인되었는가
- [ ] 사용자가 PROD 배포를 승인했는가
- [ ] 릴리스 태그가 올바르게 생성되었는가
- [ ] 배포 워크플로우가 성공적으로 완료되었는가
