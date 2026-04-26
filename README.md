# GROWIT Lead

GROWIT 전체 서비스의 시스템 아키텍처 문서 및 멀티 레포 워크스페이스 설정을 관리합니다.

## 새 PC 세팅 (Quick Start)

```bash
# 1. 이 레포 클론
mkdir -p ~/Desktop/growit && cd ~/Desktop/growit
git clone https://github.com/DDD-Community/DDD-12-GROWIT-LEAD.git

# 2. Claude Code에서 /settings 실행 (모든 초기 세팅 자동화)
cd DDD-12-GROWIT-LEAD
claude
# → /settings 입력

# 3. Cursor에서 워크스페이스 열기
cursor ~/Desktop/growit/growit.code-workspace
```

## /settings 자동 세팅 항목

1. GitHub Token 입력 & 검증
2. Figma MCP 서버 연결
3. Notion MCP 서버 연결
4. 기본 레포 3개 클론 (FE, BE, APP)
5. Cursor 워크스페이스 파일 생성

## 레포 구성

| 레포 | 설명 | GitHub |
|---|---|---|
| `DDD-12-GROWIT-FE` | 프론트엔드 (Web) | `DDD-Community/DDD-12-GROWIT-FE` |
| `DDD-12-GROWIT-BE` | 백엔드 | `DDD-Community/DDD-12-GROWIT-BE` |
| `DDD-12-GROWIT-APP` | 모바일 앱 (React Native) | `DDD-Community/DDD-12-GROWIT-APP` |
| `DDD-12-GROWIT-LEAD` | 아키텍처 문서 + 워크스페이스 설정 | `DDD-Community/DDD-12-GROWIT-LEAD` |

## 파일 구조

```
DDD-12-GROWIT-LEAD/
├── .ai/                    # AI 커맨드/룰 SSOT
│   ├── commands/           # /orchestrate, /settings 등
│   ├── rules/              # workspace 규칙
│   └── sync.sh             # .cursor/ + .claude/ 생성
├── growit.code-workspace   # Cursor 멀티루트 워크스페이스
├── setup.sh                # 레포 클론 스크립트
├── CLAUDE.md               # AI 오케스트레이터 설정
└── README.md
```
