
## 1\. 프로젝트 목표 (Goal)

본 프로젝트의 목표는 **IronRDP 라이브러리를 WebAssembly(WASM)로 컴파일**하여, 서버 측 렌더링이 아닌 **클라이언트(웹 브라우저)에서 직접 RDP 프로토콜을 처리**하는 것입니다.

이 문서는 그 첫 번째 단계로, IronRDP 공식 저장소에 포함된 `web-client` 예제를 성공적으로 빌드하고 실행하는 전 과정을 재현 가능하도록 기록합니다.

## 2\. 신규 아키텍처 (New Architecture)

이 접근 방식은 3가지 핵심 구성요소로 이루어집니다.

1.  **RDP 호스트 (Windows PC):**
      * 실제 RDP 세션을 제공하는 대상 서버. (TCP 3389 포트)
2.  **WebSocket 프록시 (Wsproxy):**
      * 브라우저는 보안상 TCP 소켓에 직접 접근할 수 없습니다. 이 프록시 서버는 브라우저의 `WebSocket(WSS/WS)` 연결을 받아 `TCP(RDP)` 연결로 변환해주는 '다리' 역할을 수행합니다.
      * `IronRDP/web-client` 예제는 자체 Rust 기반 `wsproxy` 서버를 포함하고 있습니다.
3.  **웹 클라이언트 (Browser):**
      * `React` 또는 `Vite` 기반의 프론트엔드 UI.
      * `IronRDP (WASM)` 모듈을 로드하여, RDP 프로토콜 처리, 그래픽 디코딩, 사용자 입력(키보드/마우스) 전송을 브라우저 내에서 직접 수행합니다.

**데이터 흐름:**
`[브라우저: React + IronRDP(WASM)]` ↔ `[WebSocket]` ↔ `[Wsproxy 서버]` ↔ `[TCP/3389]` ↔ `[Windows RDP 호스트]`

-----

## 3\. 1단계: 사전 준비 사항 (Prerequisites)

이전과 다른 **WASM 및 웹 툴체인**이 필요합니다.

### 3.1. Rust (WASM) 툴체인

1.  **WASM 컴파일 타겟 추가:**
      * Rust가 WebAssembly를 빌드할 수 있도록 타겟을 추가합니다.
    <!-- end list -->
    ```bash
    rustup target add wasm32-unknown-unknown
    ```
2.  **`wasm-pack` 설치:**
      * Rust 코드를 브라우저가 이해할 수 있는 WASM 모듈 및 JavaScript 바인딩 코드로 패키징하는 필수 도구입니다.
    <!-- end list -->
    ```bash
    cargo install wasm-pack
    ```

### 3.2. Web 툴체인

1.  **Node.js 및 npm:**
      * `web-client`의 JavaScript 의존성을 설치하고, 웹 서버를 실행하기 위해 필요합니다.
      * [Node.js LTS 버전](https://nodejs.org/)을 설치하거나 Homebrew를 사용합니다.
    <!-- end list -->
    ```bash
    brew install node
    ```

### 3.3. RDP 호스트 (Windows PC)

1.  **원격 데스크톱 활성화:** (`설정` \> `시스템` \> `원격 데스크톱`)
2.  **방화벽 허용:** "원격 데스크톱" (Private)
3.  **[필수] NLA 비활성화:**
      * WASM 클라이언트의 표준 RDP 인증을 위해 **네트워크 수준 인증(NLA)을 비활성화**해야 합니다. (이전 `STATUS_LOGON_FAILURE` 오류 해결 경험)
      * `설정` \> `원격 데스크톱` \> `고급 설정` \> **NLA 옵션 체크 해제**

-----

## 4\. 2단계: 빌드 및 실행 절차 (Step-by-Step)

이 과정은 **3개의 주요 서비스**를 동시에 실행해야 합니다:
1. **Devolutions Gateway** (WebSocket-to-TCP 프록시)
2. **Token Server** (자동 토큰 생성 서버)
3. **IronRDP Svelte Client** (웹 브라우저 클라이언트)

### 4.1. 소스 코드 준비

1.  **IronRDP 저장소 클론:**
    ```bash
    cd ~/Desktop/KAIST/2025Fall/CS408\ CS\ Project
    git clone https://github.com/Devolutions/IronRDP.git
    cd IronRDP
    ```

2.  **Rust 툴체인 버전 확인 및 설정:**
    IronRDP는 특정 Rust 버전을 요구합니다. `rust-toolchain.toml` 파일에 명시된 버전을 사용해야 합니다.
    ```bash
    # IronRDP 디렉토리에서 실행
    cat rust-toolchain.toml
    # channel = "1.88.0" 확인
    
    # 해당 버전 설치 및 설정
    rustup install 1.88.0
    rustup override set 1.88.0
    
    # 버전 확인
    rustc --version
    # 출력: rustc 1.88.0 ...
    ```

3.  **Node.js 버전 확인:**
    Vite는 Node.js 20.19+ 또는 22.12+ 버전을 요구합니다.
    ```bash
    node --version
    # v20.19.0 이상 또는 v22.12.0 이상이어야 함
    
    # 버전이 낮다면 nvm으로 업그레이드
    nvm install 22
    nvm use 22
    ```

### 4.2. Devolutions Gateway 설치 및 설정

Devolutions Gateway는 브라우저의 WebSocket 연결을 RDP 서버의 TCP 연결로 변환하는 프록시입니다.

#### 4.2.1. 저장소 클론 및 빌드

1.  **Gateway 클론:**
    ```bash
    cd ~/Desktop/KAIST/2025Fall/CS408\ CS\ Project
    git clone https://github.com/Devolutions/devolutions-gateway.git
    cd devolutions-gateway
    ```

2.  **Gateway 빌드 (Release 모드):**
    ```bash
    cargo build --bin devolutions-gateway --release
    ```
    빌드는 약 2-3분 소요됩니다. 완료되면 `target/release/devolutions-gateway` 바이너리가 생성됩니다.

#### 4.2.2. Provisioner 키 생성

Gateway는 토큰 서명/검증을 위한 RSA 키 쌍이 필요합니다.

```bash
# devolutions-gateway 디렉토리에서 실행
openssl genrsa -out provisioner.key 2048
openssl rsa -in provisioner.key -outform PEM -pubout -out provisioner.pem
```

생성된 파일:
- `provisioner.key`: 개인 키 (토큰 생성용)
- `provisioner.pem`: 공개 키 (토큰 검증용)

#### 4.2.3. Gateway 설정 파일 생성

1.  **기본 설정 파일 초기화:**
    ```bash
    DGATEWAY_CONFIG_PATH="$(pwd)" ./target/release/devolutions-gateway --config-init-only
    ```
    이 명령은 `gateway.json` 파일을 자동 생성합니다.

2.  **설정 파일 수정:**
    생성된 `gateway.json`을 다음과 같이 수정합니다:
    ```json
    {
      "Id": "d6d9d143-e947-4273-9bce-5b45c37ac56f",
      "ProvisionerPublicKeyFile": "provisioner.pem",
      "ProvisionerPrivateKeyFile": "provisioner.key",
      "TlsVerifyStrict": false,
      "WebApp": {
        "Enabled": false,
        "StaticRootPath": ".",
        "Authentication": "None"
      },
      "Listeners": [
        {
          "InternalUrl": "tcp://*:8181",
          "ExternalUrl": "tcp://*:8181"
        },
        {
          "InternalUrl": "http://*:7171",
          "ExternalUrl": "http://*:7171"
        }
      ],
      "__debug__": {
        "disable_token_validation": true
      }
    }
    ```

    **주요 설정 설명:**
    - `TlsVerifyStrict: false`: 개발 환경에서 TLS 인증서 검증 완화
    - `WebApp.Enabled: false`: 내장 웹앱 비활성화 (우리는 Svelte 클라이언트 사용)
    - `Listeners`: 포트 7171에서 HTTP WebSocket 수신
    - `__debug__.disable_token_validation`: 토큰 재사용 허용 (개발 편의)

#### 4.2.4. Gateway 실행 (터미널 1)

```bash
cd ~/Desktop/KAIST/2025Fall/CS408\ CS\ Project/devolutions-gateway
DGATEWAY_CONFIG_PATH="$(pwd)" nohup ./target/release/devolutions-gateway > gateway.log 2>&1 &

# 실행 확인
lsof -i :7171
# 출력: devolutio ... *:7171 (LISTEN)
```

### 4.3. Token Server 설치 및 실행

Token Server는 Gateway 인증에 필요한 토큰을 자동으로 생성합니다.

#### 4.3.1. Token Server 빌드 및 실행 (터미널 2)

```bash
cd ~/Desktop/KAIST/2025Fall/CS408\ CS\ Project/devolutions-gateway/tools/tokengen
DGATEWAY_CONFIG_PATH="../../" cargo run --release -- server &

# 실행 확인
lsof -i :8080
# 출력: tokengen ... localhost:http-alt (LISTEN)
```

Token Server는 `http://localhost:8080`에서 실행됩니다.

### 4.4. WASM 빌드 (Docker 사용)

WASM 빌드는 환경에 민감하므로 Docker를 사용하여 안정적으로 빌드합니다.

#### 4.4.1. Docker로 WASM 빌드

1.  **IronRDP 디렉토리로 이동:**
    ```bash
    cd ~/Desktop/KAIST/2025Fall/CS408\ CS\ Project/IronRDP
    ```

2.  **Docker를 사용한 WASM 빌드:**
    ```bash
    docker run --rm \
      -v "$(pwd)":/workspace \
      -w /workspace \
      rust:1.88.0 \
      bash -c "
        rustup target add wasm32-unknown-unknown && \
        cargo install wasm-pack --version 0.12.1 && \
        cd crates/ironrdp-web && \
        wasm-pack build --target web --out-dir pkg
      "
    ```

    **빌드 시간:** 약 5-10분 소요

3.  **빌드 결과 확인:**
    ```bash
    ls -lh crates/ironrdp-web/pkg/
    ```
    
    생성된 파일:
    - `ironrdp_web.js` (62KB)
    - `ironrdp_web_bg.wasm` (3.9MB)
    - `ironrdp_web.d.ts` (타입 정의)
    - `ironrdp_web_bg.wasm.d.ts`

### 4.5. Web Components 빌드

IronRDP Svelte 클라이언트는 2개의 웹 컴포넌트를 사용합니다.

#### 4.5.1. 의존성 설치

```bash
cd ~/Desktop/KAIST/2025Fall/CS408\ CS\ Project/IronRDP/web-client

# iron-remote-desktop 의존성 설치
cd iron-remote-desktop
npm install

# iron-remote-desktop-rdp 의존성 설치
cd ../iron-remote-desktop-rdp
npm install

# iron-svelte-client 의존성 설치
cd ../iron-svelte-client
npm install
```

#### 4.5.2. 환경 변수 설정

Token Server URL을 Svelte 클라이언트에 알려줍니다:

```bash
cd ~/Desktop/KAIST/2025Fall/CS408\ CS\ Project/IronRDP/web-client/iron-svelte-client
echo 'VITE_IRON_TOKEN_SERVER_URL=http://localhost:8080' > .env
```

### 4.6. Svelte 클라이언트 빌드 및 실행 (터미널 3)

#### 4.6.1. 웹 컴포넌트 빌드 및 클라이언트 실행

```bash
cd ~/Desktop/KAIST/2025Fall/CS408\ CS\ Project/IronRDP/web-client/iron-svelte-client

# WASM 없이 웹 컴포넌트만 빌드하고 개발 서버 시작
npm run dev-no-wasm
```

**이 명령이 수행하는 작업:**
1. `iron-remote-desktop` 웹 컴포넌트 빌드 (121KB)
2. `iron-remote-desktop-rdp` WASM 래퍼 빌드 (5.4MB)
3. 빌드된 파일을 `static/` 폴더에 복사
4. Vite 개발 서버 시작 (`http://localhost:5173`)

#### 4.6.2. 서버 시작 확인

```bash
# 새 터미널에서 확인
lsof -i :5173
# 출력: node ... *:5173 (LISTEN)
```

브라우저에서 `http://localhost:5173`을 열면 IronRDP 로그인 화면이 나타납니다.

### 4.7. RDP 연결 테스트

#### 4.7.1. 브라우저 접속

웹 브라우저를 열고 `http://localhost:5173`으로 이동합니다.

#### 4.7.2. 연결 정보 입력

로그인 폼에 다음 정보를 입력합니다:

| 필드 | 값 | 설명 |
|------|-----|------|
| **Hostname** | `10.10.0.3:3389` | RDP 서버 IP:포트<br/>예: `192.168.1.100:3389` |
| **Domain** | (비워둠) | Windows 도메인 (선택사항) |
| **Username** | `Administrator` | RDP 사용자명 |
| **Password** | `YourPassword` | RDP 비밀번호 |
| **Gateway Address** | `ws://localhost:7171/jet/rdp` | Devolutions Gateway WebSocket URL<br/>**반드시 `/jet/rdp` 경로 포함** |
| **AuthToken** | (비워둠) | 선택사항 (Token Server가 자동 생성) |
| **Pre Connection Blob** | (비워둠) | 선택사항 |
| **Desktop Width** | `1280` | 원격 데스크톱 해상도 너비 |
| **Desktop Height** | `720` | 원격 데스크톱 해상도 높이 |
| **KDC Proxy URL** | (비워둠) | Kerberos 관련 (선택사항) |
| **Use Pop Up** | ☐ 체크 해제 | 팝업 사용 안 함 |
| **Enable Clipboard** | ☑ 체크 | 클립보드 공유 활성화 |

**중요 참고사항:**
- **Gateway Address는 반드시 `ws://`로 시작**해야 합니다 (`http://` 아님)
- 경로 `/jet/rdp`는 필수입니다
- Hostname의 포트 번호는 RDP 서버의 포트 (기본값: 3389)

#### 4.7.3. 연결 실행

`Login` 버튼을 클릭합니다. 성공 시:
1. 브라우저에 Windows 데스크톱 화면이 나타남
2. 마우스/키보드 입력 가능
3. 클립보드 공유 작동 (체크 시)

### 4.8. 서비스 상태 확인

모든 서비스가 정상 실행 중인지 확인:

```bash
echo "=== Service Status Check ==="
lsof -i :7171 | grep -q devolutio && echo "✅ Gateway (7171)"
lsof -i :8080 | grep -q tokengen && echo "✅ Token Server (8080)"
lsof -i :5173 | grep -q node && echo "✅ Svelte Client (5173)"
```

-----

## 5\. 3단계: 트러블슈팅 (Troubleshooting)

### 5.1. 빌드 관련 오류

#### 오류: `rustc 1.90.0` 버전 불일치
```
error: The "wasm_js" backend requires the wasm_js feature for getrandom
```

**원인:** IronRDP는 `rust-toolchain.toml`에 명시된 정확한 Rust 버전이 필요합니다.

**해결:**
```bash
cd IronRDP
rustup install 1.88.0
rustup override set 1.88.0
rustc --version  # 1.88.0 확인
```

#### 오류: `wasm-pack not found`

**원인:** WASM 빌드 도구가 설치되지 않음.

**해결:**
```bash
cargo install wasm-pack --version 0.12.1
```

#### 오류: `npm install` - `EPERM: operation not permitted`

**원인:** Node.js/npm 권한 문제 또는 파일 시스템 잠금.

**해결:**
```bash
# node_modules 삭제 후 재설치
rm -rf node_modules package-lock.json
npm install
```

#### 오류: Node.js 버전 불일치
```
You are using Node.js 20.17.0. Vite requires Node.js version 20.19+ or 22.12+
```

**해결:**
```bash
nvm install 22
nvm use 22
node --version  # v22.x.x 확인
```

### 5.2. Gateway 관련 오류

#### 오류: Gateway 시작 실패 - `missing field ExternalUrl`

**원인:** `gateway.json` 설정에서 필수 필드 누락.

**해결:** `Listeners` 배열의 각 리스너에 `InternalUrl`과 `ExternalUrl` 모두 포함:
```json
"Listeners": [
  {
    "InternalUrl": "http://*:7171",
    "ExternalUrl": "http://*:7171"
  }
]
```

#### 오류: `standalone web application path must be specified manually`

**원인:** macOS에서는 WebApp 경로를 명시해야 함.

**해결:** `gateway.json`에 WebApp 설정 추가:
```json
"WebApp": {
  "Enabled": false,
  "StaticRootPath": ".",
  "Authentication": "None"
}
```

#### 오류: Gateway 로그 - `invalid config file ... missing field Authentication`

**원인:** WebApp이 활성화된 상태에서 Authentication 필드 누락.

**해결:** `"Authentication": "None"` 추가 (위 예제 참조)

### 5.3. Token Server 관련 오류

#### 오류: Token Server가 시작되지 않음

**원인:** `DGATEWAY_CONFIG_PATH` 환경 변수가 설정되지 않음.

**해결:**
```bash
cd devolutions-gateway/tools/tokengen
DGATEWAY_CONFIG_PATH="../../" cargo run --release -- server
```

#### 포트 충돌: `Address already in use (port 8080)`

**원인:** 다른 프로세스가 8080 포트를 사용 중.

**해결:**
```bash
# 프로세스 확인 및 종료
lsof -i :8080
kill -9 <PID>
```

### 5.4. Svelte 클라이언트 오류

#### 오류: `Failed to resolve import "../../../static/iron-remote-desktop-rdp"`

**원인:** WASM 또는 웹 컴포넌트가 빌드되지 않음.

**해결:**
```bash
cd IronRDP/web-client/iron-svelte-client
npm run dev-no-wasm
```
이 명령은 자동으로 웹 컴포넌트를 빌드하고 `static/` 폴더에 복사합니다.

#### 오류: `npm run dev-no-wasm` 실패

**원인:** 웹 컴포넌트 디렉토리에 의존성이 설치되지 않음.

**해결:**
```bash
cd IronRDP/web-client/iron-remote-desktop
npm install

cd ../iron-remote-desktop-rdp
npm install

cd ../iron-svelte-client
npm install
npm run dev-no-wasm
```

### 5.5. 연결 관련 오류

#### 오류: 브라우저 콘솔 - `WebSocket connection to 'ws://localhost:7171/jet/rdp' failed`

**원인 1:** Devolutions Gateway가 실행 중이지 않음.
```bash
lsof -i :7171  # 확인
```

**원인 2:** Gateway Address URL이 잘못됨.
- ✅ 올바른 형식: `ws://localhost:7171/jet/rdp`
- ❌ 잘못된 형식: `http://localhost:7171/jet/rdp` (http 사용)
- ❌ 잘못된 형식: `ws://localhost:7171` (경로 누락)

**원인 3:** Gateway 로그에 오류 확인:
```bash
tail -f devolutions-gateway/gateway.log
```

#### 오류: 연결 후 검은 화면만 나타남

**원인 1:** RDP 서버(Windows PC)가 응답하지 않음.
- RDP 서버의 IP 주소가 정확한지 확인
- RDP 서버의 방화벽이 3389 포트를 허용하는지 확인
- `ping <RDP_SERVER_IP>`로 네트워크 연결 확인

**원인 2:** NLA(Network Level Authentication)가 활성화됨.
- Windows 설정 > 원격 데스크톱 > "네트워크 수준 인증이 필요" 체크 해제

#### 오류: `STATUS_LOGON_FAILURE` 또는 인증 실패

**원인:** 사용자 이름 또는 비밀번호가 잘못됨.

**해결:**
1. Username 형식 확인:
   - 로컬 계정: `Administrator` 또는 `ComputerName\Username`
   - 도메인 계정: `DOMAIN\Username`
2. Windows에서 실제 계정 이름 확인:
   ```powershell
   whoami
   ```
3. 비밀번호에 특수문자가 있다면 URL 인코딩 필요 없음 (폼에 그대로 입력)

#### 오류: Token Server 연결 실패

**증상:** 브라우저 콘솔에 `Failed to fetch token from http://localhost:8080`

**원인:** `.env` 파일이 없거나 Token Server가 실행되지 않음.

**해결:**
```bash
# .env 파일 생성
cd IronRDP/web-client/iron-svelte-client
echo 'VITE_IRON_TOKEN_SERVER_URL=http://localhost:8080' > .env

# Token Server 실행 확인
lsof -i :8080

# 없다면 실행
cd ~/Desktop/KAIST/2025Fall/CS408\ CS\ Project/devolutions-gateway/tools/tokengen
DGATEWAY_CONFIG_PATH="../../" cargo run --release -- server &
```

### 5.6. 성능 관련 문제

#### 문제: 화면이 느리거나 버벅임

**해결:**
1. Desktop Width/Height를 낮춤 (예: 1024x576)
2. 브라우저 하드웨어 가속 활성화 확인
3. 네트워크 대역폭 확인 (`ping <RDP_SERVER>`)

#### 문제: 클립보드 공유가 작동하지 않음

**해결:**
1. "Enable Clipboard" 체크 확인
2. 브라우저 클립보드 권한 허용 (브라우저 주소창 자물쇠 아이콘)
3. RDP 서버에서 클립보드 리디렉션이 허용되는지 확인

### 5.7. 디버깅 팁

#### Gateway 로그 실시간 확인
```bash
tail -f ~/Desktop/KAIST/2025Fall/CS408\ CS\ Project/devolutions-gateway/gateway.log
```

#### 브라우저 개발자 도구 사용
1. F12를 눌러 개발자 도구 열기
2. **Console 탭**: JavaScript 오류 확인
3. **Network 탭**: WebSocket 연결 상태 확인
4. **Application 탭**: LocalStorage/환경 변수 확인

#### 모든 서비스 재시작
```bash
# 모든 관련 프로세스 종료
pkill -f devolutions-gateway
pkill -f tokengen
pkill -f "vite dev"

# 순서대로 재시작 (위 4.2 ~ 4.6 섹션 참조)
```

## 6\. 향후 계획 (Next Steps)

  * **1. Axum으로 프록시 교체:**
      * 현재 실행한 예제용 `wsproxy` 대신, 우리가 만든 `web-vdi-client` 모노레포의 `backend` 프로젝트(**Axum**)에 WebSocket-to-TCP 프록시 기능을 구현하여 대체합니다.
  * **2. 보안 및 기능 강화:**
      * Axum 프록시에 인증(Authentication), 로깅(Logging), 채널 제어(e.g., 클립보드) 기능을 추가하여 단순 프록시가 아닌 '보안 게이트웨이'로 발전시킵니다.
  * **3. UI 커스터마이징:**
      * 빌드된 `web-client`의 React 코드를 `frontend` 프로젝트로 가져와, 우리가 설계한 UX/UI에 맞게 수정합니다.