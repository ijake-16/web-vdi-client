
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

이 과정은 **2개의 터미널**을 동시에 사용하여 각각 '프록시 서버'와 '웹 서버'를 실행해야 합니다.

### 4.1. 소스 코드 준비

1.  회원님이 이전에 오디오 버그 수정을 위해 fork 했던 `IronRDP` 저장소를 클론합니다.
    ```bash
    # "YOUR_GITHUB_USERNAME"을 실제 아이디로 변경하세요.
    git clone https://github.com/YOUR_GITHUB_USERNAME/IronRDP.git
    cd IronRDP
    ```
2.  `web-client` 예제 디렉토리로 이동합니다.
    ```bash
    cd web-client
    ```

### 4.2. (터미널 1) WebSocket 프록시 서버 빌드 및 실행

1.  `wsproxy` 디렉토리로 이동합니다.
    ```bash
    cd wsproxy
    ```
2.  프록시 서버를 빌드하고 실행합니다.
      * 이 서버는 기본적으로 `127.0.0.1:8080`에서 WebSocket 연결을 수신 대기합니다.
    <!-- end list -->
    ```bash
    # 빌드 및 실행
    cargo run
    ```
3.  서버가 `Listening on 127.0.0.1:8080` 메시지를 출력하며 대기하는지 확인합니다. 이 터미널은 계속 실행 상태로 둡니다.

### 4.3. (터미널 2) WASM + React 클라이언트 빌드 및 실행

1.  **별도의 새 터미널 창**을 엽니다.
2.  `web-client/client` 디렉토리로 이동합니다.
    ```bash
    # (IronRDP 루트 디렉토리에서 시작한다고 가정)
    cd web-client/client
    ```
3.  `npm` 의존성을 설치합니다.
    ```bash
    npm install
    ```
4.  **WASM 및 JS 빌드:**
      * `npm run build` 스크립트가 `wasm-pack`을 호출하여 Rust 코드를 WASM으로 컴파일하고, `vite`를 사용해 React 앱을 빌드합니다.
    <!-- end list -->
    ```bash
    npm run build
    ```
5.  **웹 서버 실행:**
      * 빌드된 결과물(`dist` 폴더)을 서빙하기 위해 개발 서버를 실행합니다.
    <!-- end list -->
    ```bash
    npm run dev
    ```
6.  서버가 `http://localhost:5173` (또는 다른 포트)에서 실행되는지 확인합니다.

### 4.4. 연결 테스트

1.  웹 브라우저를 열고 `http://localhost:5173` (터미널 2에 표시된 주소)로 접속합니다.
2.  IronRDP 웹 클라이언트 UI가 나타나면, 다음과 같이 연결 정보를 입력합니다.
      * **WebSocket Proxy:** `ws://127.0.0.1:8080` (터미널 1이 리스닝 중인 주소)
      * **Server:** `192.168.x.x` (연결할 **Windows PC의 실제 IP 주소**. Meshnet IP가 아닌 내부망 IP 또는 RDP가 가능한 IP)
      * **Username:** `YOUR_PC\Username`
      * **Password:** `YourPassword`
3.  `Connect` 버튼을 클릭하여 브라우저 화면에 Windows 데스크톱이 나타나는지 확인합니다.

-----

## 5\. 3단계: 예상 문제 및 트러블슈팅 (Troubleshooting)

  * **오류:** `wasm-pack not found`

      * **원인:** WASM 패키징 도구가 설치되지 않음.
      * **해결:** `cargo install wasm-pack` 실행.

  * **오류:** `npm install` 실패

      * **원인:** Node.js 또는 npm 버전이 호환되지 않음.
      * **해결:** Node.js를 최신 LTS 버전으로 업데이트.

  * **오류:** 브라우저 콘솔(F12)에 `WebSocket connection failed`

      * **원인 1:** 터미널 1의 `wsproxy` 서버가 실행 중이지 않음.
      * **원인 2:** WebSocket 주소(`ws://127.0.0.1:8080`)를 잘못 입력함.

  * **오류:** `wsproxy` 터미널(터미널 1)에 `Connection timed out` 또는 `Connection refused`

      * **원인 1:** `Server` 필드에 입력한 RDP 호스트(Windows PC)의 IP 주소가 잘못됨.
      * **원인 2:** Windows PC의 방화벽이 3389 포트를 차단하고 있음.
      * **원인 3:** Windows PC의 NLA가 비활성화되지 않음.

  * **오류:** 브라우저 콘솔에 `CORS policy` 오류

      * **원인:** 웹 서버와 WebSocket 서버의 출처(origin)가 달라 발생.
      * **해결:** `wsproxy` 서버 코드 또는 `Vite` 설정에서 CORS를 허용하도록 수정 필요. (이 경우 `wsproxy` 예제에 이미 반영되어 있을 가능성이 높음)

## 6\. 향후 계획 (Next Steps)

  * **1. Axum으로 프록시 교체:**
      * 현재 실행한 예제용 `wsproxy` 대신, 우리가 만든 `web-vdi-client` 모노레포의 `backend` 프로젝트(**Axum**)에 WebSocket-to-TCP 프록시 기능을 구현하여 대체합니다.
  * **2. 보안 및 기능 강화:**
      * Axum 프록시에 인증(Authentication), 로깅(Logging), 채널 제어(e.g., 클립보드) 기능을 추가하여 단순 프록시가 아닌 '보안 게이트웨이'로 발전시킵니다.
  * **3. UI 커스터마이징:**
      * 빌드된 `web-client`의 React 코드를 `frontend` 프로젝트로 가져와, 우리가 설계한 UX/UI에 맞게 수정합니다.