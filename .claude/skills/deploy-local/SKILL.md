---
name: deploy-local
description: 로컬 개발 서버 전체 기동 (BE + FE, hot-reload)
context: fork
allowed-tools: Read, Grep, Glob, Bash
---
# Deploy Local

로컬 개발 서버를 전체 기동한다. SSH 포트포워딩 → BE → FE → APP 순서로 실행.
**`growit-env/config.json`을 설정 소스로 사용한다.**

## 인자

- `TARGET` — (선택) 특정 서비스만 실행. 미지정 시 **전체 기동**.
  - `be` — BE 서버만
  - `fe` — FE 웹만
  - `app` — APP만
  - `tunnel` — SSH 터널만

---

## 서비스 매핑

| 서비스 | 경로 | 실행 명령 | 포트 | 비고 |
|--------|------|----------|------|------|
| SSH Tunnel | — | SSH 포트포워딩 | 5433→RDS:5432 | Bastion 경유 |
| BE | `DDD-12-GROWIT-BE` | `./gradlew :app:bootRun` | 8080 | Spring Boot (env vars from .env.development) |
| FE | `DDD-12-GROWIT-FE` | `npm run dev` | 3000 | Next.js (turbopack) |
| APP | `DDD-12-GROWIT-APP/growit-mobile` | `yarn start` | 8081 | Expo (Metro bundler) |

---

## 흐름

```
/deploy-local [TARGET]
    │
    ▼
Step 1: 사전 검증 (growit-env, 환경변수, 의존성)
    ▼
Step 2: SSH 포트포워딩 (config.json → RDS 접근)
    ▼
Step 3: 포트 충돌 검사 & 정리
    ▼
Step 4: 서비스 기동 (BE → FE → APP)
    ▼
Step 5: 헬스체크 & 상태 보고
```

---

## Step 1: 사전 검증

### 1-1. 경로 설정

```bash
BASE_DIR="$(cd "$(pwd)/.." && pwd)"
ENV_DIR="$BASE_DIR/growit-env"
CONFIG="$ENV_DIR/config.json"
LOG_DIR="$BASE_DIR/.logs"
mkdir -p "$LOG_DIR"
```

### 1-2. growit-env 확인

```bash
if [ ! -f "$CONFIG" ]; then
  echo "❌ growit-env/config.json을 찾을 수 없습니다."
  echo "   /settings를 먼저 실행하세요."
  exit 1
fi
```

### 1-3. 환경변수 확인 & 복사

```bash
# BE
if [ ! -f "$BASE_DIR/DDD-12-GROWIT-BE/.env.development" ]; then
  if [ -f "$ENV_DIR/be/.env.development" ]; then
    cp "$ENV_DIR/be/.env.development" "$BASE_DIR/DDD-12-GROWIT-BE/.env.development"
    echo "→ BE .env.development 복사"
  else
    echo "❌ BE 환경변수 없음. /settings를 먼저 실행하세요."
    exit 1
  fi
fi

# FE
if [ ! -f "$BASE_DIR/DDD-12-GROWIT-FE/.env.development" ]; then
  if [ -f "$ENV_DIR/fe/.env.development" ]; then
    cp "$ENV_DIR/fe/.env.development" "$BASE_DIR/DDD-12-GROWIT-FE/.env.development"
    echo "→ FE .env.development 복사"
  fi
fi
```

### 1-4. 의존성 확인

```bash
# BE: gradlew 실행 가능 여부
if [ -f "$BASE_DIR/DDD-12-GROWIT-BE/gradlew" ]; then
  chmod +x "$BASE_DIR/DDD-12-GROWIT-BE/gradlew"
fi

# FE: node_modules
if [ ! -d "$BASE_DIR/DDD-12-GROWIT-FE/node_modules" ]; then
  echo "→ FE node_modules 없음, npm install 실행..."
  (cd "$BASE_DIR/DDD-12-GROWIT-FE" && npm install 2>&1 | tail -3)
fi

# APP: node_modules (서브디렉토리)
if [ ! -d "$BASE_DIR/DDD-12-GROWIT-APP/growit-mobile/node_modules" ]; then
  echo "→ APP node_modules 없음, yarn install 실행..."
  (cd "$BASE_DIR/DDD-12-GROWIT-APP/growit-mobile" && yarn install 2>&1 | tail -3)
fi
```

---

## Step 2: SSH 포트포워딩

`growit-env/config.json`의 `ssh` 섹션을 읽어 SSH 터널을 생성한다.

```bash
python3 -c "
import json, subprocess, os, sys

config_path = '$CONFIG'
env_dir = '$ENV_DIR'

with open(config_path) as f:
    config = json.load(f)

ssh_config = config.get('ssh')
if not ssh_config:
    print('ℹ️ config.json에 ssh 설정 없음 — 터널 스킵')
    sys.exit(0)

bastion = ssh_config['bastion']
key_path = os.path.join(env_dir, bastion['key'])

if not bastion.get('host'):
    print('ℹ️ Bastion host 미설정 — 터널 스킵')
    print('   BE가 로컬 DB를 사용하는지 확인하세요.')
    sys.exit(0)

if not os.path.exists(key_path):
    print(f'⚠️ SSH 키 없음: {key_path} — 터널 스킵')
    sys.exit(0)

os.chmod(key_path, 0o400)

for tunnel in ssh_config.get('tunnels', []):
    local_port = tunnel['local_port']
    remote_host = tunnel['remote_host']
    remote_port = tunnel['remote_port']
    name = tunnel['name']

    # 이미 활성인지 확인
    result = subprocess.run(['lsof', '-i', f':{local_port}'], capture_output=True, text=True)
    if 'ssh' in result.stdout:
        print(f'✅ {name}: 터널 이미 활성 (localhost:{local_port})')
        continue

    # 기존 점유 프로세스 kill
    if result.stdout.strip():
        pids = set()
        for line in result.stdout.strip().split(chr(10))[1:]:
            parts = line.split()
            if len(parts) > 1:
                pids.add(parts[1])
        for pid in pids:
            subprocess.run(['kill', '-9', pid])
        print(f'→ {name}: 포트 {local_port} 기존 프로세스 종료')

    # SSH 터널 생성 (백그라운드)
    cmd = [
        'ssh', '-f', '-N', '-L',
        f'{local_port}:{remote_host}:{remote_port}',
        '-i', key_path,
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'ServerAliveInterval=60',
        '-p', str(bastion['port']),
        f\"{bastion['user']}@{bastion['host']}\"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        print(f'✅ {name}: 터널 생성 (localhost:{local_port} → {remote_host}:{remote_port})')
    else:
        print(f'❌ {name}: 터널 실패 — {result.stderr.strip()}')
        print(f'   네트워크/VPN 상태를 확인하세요.')
"
```

---

## Step 3: 포트 충돌 검사

```bash
PORTS=(8080 3000 8081)
SERVICE_NAMES=("BE" "FE" "APP")

for i in "${!PORTS[@]}"; do
  PORT=${PORTS[$i]}
  NAME=${SERVICE_NAMES[$i]}
  PID=$(lsof -ti :$PORT 2>/dev/null)
  if [ -n "$PID" ]; then
    echo "⚠️ $NAME 포트 $PORT 사용 중 (PID: $PID) — 종료합니다"
    kill -9 $PID 2>/dev/null
  fi
done
```

---

## Step 4: 서비스 기동

### 4-1. BE 기동 (Spring Boot)

> **중요:** `SPRING_PROFILES_ACTIVE`는 비워둔다 (기본 `application.yml` 사용).
> `application.yml`은 `${SPRING_DATASOURCE_URL}` 등 환경변수를 참조하며,
> `.env.development`의 `SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5433/postgres`로
> SSH 터널을 통해 RDS에 연결된다.
>
> `application-local.yml` (profile=local)은 로컬 Docker PostgreSQL용 (localhost:5432, DB명 growit_dev).
> SSH 터널을 사용할 때는 local 프로필을 **사용하지 않는다.**

```bash
BE_DIR="$BASE_DIR/DDD-12-GROWIT-BE"

if [ -f "$BE_DIR/gradlew" ]; then
  echo "→ BE 서버 기동 중..."

  # .env.development를 환경변수로 export
  set -a
  source "$BE_DIR/.env.development"
  set +a

  # SPRING_PROFILES_ACTIVE가 비어있으면 기본 application.yml 사용 (env var 기반)
  # local 프로필은 사용하지 않음 (hardcoded DB URL 충돌 방지)

  # Gradle bootRun (백그라운드)
  (cd "$BE_DIR" && ./gradlew :app:bootRun > "$LOG_DIR/be.log" 2>&1) &
  BE_PID=$!
  echo "  PID: $BE_PID, 로그: .logs/be.log"
fi
```

### 4-2. FE 기동 (Next.js)

```bash
FE_DIR="$BASE_DIR/DDD-12-GROWIT-FE"

if [ -d "$FE_DIR" ]; then
  echo "→ FE 서버 기동 중..."
  (cd "$FE_DIR" && npm run dev > "$LOG_DIR/fe.log" 2>&1) &
  FE_PID=$!
  echo "  PID: $FE_PID, 로그: .logs/fe.log"
fi
```

### 4-3. APP 기동 (Expo Metro bundler) — TARGET에 app 포함 시에만

> APP은 `DDD-12-GROWIT-APP/growit-mobile/` 서브디렉토리에서 실행.
> `yarn start` (= `expo start`) 사용.

```bash
APP_DIR="$BASE_DIR/DDD-12-GROWIT-APP/growit-mobile"

if [ -d "$APP_DIR" ]; then
  echo "→ APP Metro bundler 기동 중..."
  (cd "$APP_DIR" && yarn start > "$LOG_DIR/app.log" 2>&1) &
  APP_PID=$!
  echo "  PID: $APP_PID, 로그: .logs/app.log"
fi
```

---

## Step 5: 헬스체크 & 상태 보고

### 5-1. BE 헬스체크 (최대 60초 대기 — Spring Boot 기동이 느림)

```bash
echo "→ BE 헬스체크 대기 중..."
for i in $(seq 1 60); do
  if curl -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo "✅ BE 헬스체크 통과"
    break
  fi
  if [ $i -eq 60 ]; then
    echo "⚠️ BE 60초 내 응답 없음 — 로그 확인: tail -f .logs/be.log"
  fi
  sleep 1
done
```

### 5-2. FE 헬스체크

```bash
echo "→ FE 헬스체크 대기 중..."
for i in $(seq 1 15); do
  if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ FE 헬스체크 통과"
    break
  fi
  if [ $i -eq 15 ]; then
    echo "⚠️ FE 15초 내 응답 없음 — 로그 확인: tail -f .logs/fe.log"
  fi
  sleep 1
done
```

### 5-3. 상태 보고

```
🟢 로컬 개발 서버 기동 완료

| 서비스 | 상태 | URL | 로그 |
|--------|------|-----|------|
| SSH Tunnel | ✅/⚠️ | localhost:5433 → RDS | — |
| BE | ✅/⚠️ | http://localhost:8080 | .logs/be.log |
| FE | ✅/⚠️ | http://localhost:3000 | .logs/fe.log |
| APP | ✅/⏭️ | Expo Metro Bundler | .logs/app.log |

💡 유용한 명령어:
  - BE 로그: tail -f ~/Desktop/growit/.logs/be.log
  - FE 로그: tail -f ~/Desktop/growit/.logs/fe.log
  - APP 로그: tail -f ~/Desktop/growit/.logs/app.log
  - 터널 상태: lsof -i :5433
  - 전체 중지: kill $(lsof -ti :8080,:3000,:8081,:5433) 2>/dev/null
```

---

## 프로필 전략 요약

```
SSH 터널 사용 (기본):
  .env.development → SPRING_PROFILES_ACTIVE= (비어있음)
  application.yml이 ${SPRING_DATASOURCE_URL} 읽음 → localhost:5433 (터널) → RDS

로컬 Docker PostgreSQL 사용:
  SPRING_PROFILES_ACTIVE=local 설정
  application-local.yml 적용 → localhost:5432/growit_dev (hardcoded)
  이 경우 SSH 터널 불필요
```

---

## 에지 케이스

- **growit-env/config.json 없음**: `/settings` 먼저 실행 안내
- **SSH 터널 실패**: 네트워크/VPN 확인 안내, BE 기동은 계속 시도 (실패 시 로그에 DB 연결 에러)
- **Bastion host 미설정**: 터널 스킵, 로컬 DB 사용 안내
- **포트 이미 사용 중**: 기존 프로세스 kill 후 재시작
- **gradlew 권한 없음**: `chmod +x` 자동 실행
- **node_modules 없음**: `npm install` / `yarn install` 자동 실행
- **BE 기동 느림 (60초+)**: 로그 확인 안내
- **SPRING_PROFILES_ACTIVE=local 사용 시**: SSH 터널 불필요, localhost:5432 Docker DB 사용
- **TARGET 지정 시**: 해당 서비스만 기동

---

## 체크리스트

- [ ] growit-env/config.json 존재 확인
- [ ] 환경변수 파일 존재 확인 (없으면 growit-env에서 복사)
- [ ] 의존성 확인 (node_modules, gradlew 권한)
- [ ] SSH 포트포워딩 활성화 (config.json 기반)
- [ ] 포트 충돌 검사 및 정리 (8080, 3000, 8081)
- [ ] BE 기동 (.env.development export → gradlew bootRun)
- [ ] FE 기동 (npm run dev)
- [ ] APP 기동 (yarn start in growit-mobile/)
- [ ] 헬스체크 통과 확인
- [ ] 상태 테이블 보고
