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

## Figma 이미지/아이콘 처리 규칙 (FE/APP)

Figma 디자인에 포함된 이미지·아이콘은 반드시 **Figma MCP를 통해 다운로드**하여 사용한다. 임의로 대체하거나 생략하지 않는다.

### 워크플로우

1. **노드 탐색**: `mcp__figma__get_figma_data`로 디자인 트리를 탐색하여 이미지 노드(`type: IMAGE`, `type: IMAGE-SVG`)와 `imageRef` 값을 확인한다.
2. **이미지 다운로드**: `mcp__figma__download_figma_images`로 다운로드한다.
   - **래스터 이미지** (배경, 일러스트 등): `imageRef`를 포함하여 PNG로 다운로드
   - **벡터 아이콘** (SVG): `imageRef` 없이 `nodeId`만으로 SVG 다운로드
3. **FE 저장 경로**: `public/images/` 하위에 용도별 디렉토리로 저장
   ```
   public/images/
   ├── bg/          ← 배경 이미지
   ├── icons/       ← 아이콘 (SVG를 inline React 컴포넌트로 변환 권장)
   └── characters/  ← 캐릭터/일러스트
   ```
4. **코드 참조**: Next.js에서 `<Image src="/images/..." />` 또는 CSS `background-image: url(/images/...)` 사용

### 호출 예시

```
# 래스터 이미지 (imageRef 있는 경우)
mcp__figma__download_figma_images({
  fileKey: "...",
  nodes: [{ nodeId: "15:2590", fileName: "bg-character.png", imageRef: "f4b586..." }],
  localPath: "public/images/characters",
  pngScale: 2
})

# 벡터 SVG 아이콘 (imageRef 없는 경우)
mcp__figma__download_figma_images({
  fileKey: "...",
  nodes: [{ nodeId: "33:1222", fileName: "home-icon.svg" }],
  localPath: "public/images/icons"
})
```

### 주의사항

- Figma에 이미지가 있으면 **반드시 다운로드**하여 적용한다. placeholder나 CSS만으로 대체 금지.
- SVG 아이콘은 `public/`에 파일로 저장하거나, inline React 컴포넌트로 변환하여 `currentColor` 제어가 가능하게 한다.
- `pngScale: 2`를 기본으로 사용하여 Retina 대응한다.
- `claude.ai Figma MCP`에 권한 오류 발생 시 로컬 `mcp__figma__*` 도구를 사용한다.

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
