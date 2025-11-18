# Web VDI/RBI R&D - WASM 아키텍처 통합 계획서

## 1. 프로젝트 목표 (Goal)

`IronRDP` 라이브러리의 WASM 아키텍처 검증(1단계)을 바탕으로, `web-vdi-client` 모노레포 내에 **자체 개발한 Axum 게이트웨이**와 **React 클라이언트**를 통합하여, 보안과 성능이 최적화된 엔드-투-엔드(E2E) 웹 VDI 솔루션을 구현한다.

---

## 2. R&D 1단계: 아키텍처 검증 (요약)

**성공적으로 검증 완료.**

* **기술 검증:** `IronRDP`의 WASM 컴파일(`wasm-pack`) 및 브라우저 내 실행이 **가능함**을 확인함.
* **아키텍처 검증:** `WebSocket-to-TCP` 프록시 아키텍처가 **정상 동작함**을 확인함.
* **주요 사항 재확인:** `NLA(네트워크 수준 인증)` 비활성화가 WASM 클라이언트 연결의 **필수 전제조건**임을 재확인함.
* **결론:** `IronRDP/web-client` 예제를 통해 기술적 실현 가능성을 모두 검증. 이제 이 로직을 우리의 `web-vdi-client` 모노레포로 이식 및 통합할 준비가 완료됨.

---

## 3. R&D 2단계: 솔루션 통합 실행 계획 (구체화)

1단계에서 검증한 개념을 실제 솔루션으로 구현합니다.

### 3.1. `backend`: Axum 게이트웨이 개발 (Wsproxy 대체)

**목표:** `IronRDP` 예제의 `wsproxy`를 대체할, 자체 `Axum` 기반의 고성능, 보안 WebSocket-to-TCP 게이트웨이를 `backend` 프로젝트에 구현한다.

**Action Items:**

1.  **WebSocket 엔드포인트 생성:**
    * `main.rs`에 `/ws` 라우트(route)를 추가한다.
    * `axum::extract::ws::WebSocketUpgrade`를 사용해 클라이언트의 HTTP GET 요청을 WebSocket 연결로 업그레이드하는 핸들러를 작성한다.

2.  **RDP 호스트 TCP 연결:**
    * WebSocket 연결이 성공적으로 수립되면, 핸들러 내에서 `tokio::net::TcpStream::connect`를 호출하여 **RDP 호스트(e.g., `192.168.x.x:3389`)**로 TCP 연결을 시도한다. (호스트 정보는 초기 WS 메시지나 URL 쿼리로 받을 수 있음)

3.  **양방향 트래픽 중계 (Proxying):**
    * `WebSocket` 스트림과 `TcpStream`을 각각 `split` (읽기/쓰기)한다.
    * `tokio::spawn`을 사용해 **2개의 비동기 태스크**를 생성한다.
        * **Task 1 (Client → Host):** `WebSocket`에서 메시지(RDP 패킷)를 `read`하여 `TcpStream`으로 `write`한다.
        * **Task 2 (Host → Client):** `TcpStream`에서 데이터(그래픽 업데이트)를 `read`하여 `WebSocket`으로 `write`한다.
    * `tokio::io::copy_bidirectional` 사용을 고려하여 중계 로직을 효율화한다.

4.  **[보안 R&D] DLP 로직 후크(Hook) 구현:**
    * (3.1.3)의 단순 `copy` 대신, `read()` 루프를 직접 구현한다.
    * `TCP -> WS` 방향으로 `read`한 패킷을 `write`하기 전에, 이 패킷이 **RDP 가상 채널(e.g., `CLIPRDR`)**의 데이터인지 식별하는 로직을 추가할 위치를 확보한다.
    * *초기 버전에서는 식별/차단 없이 로깅(logging)만 구현하여 트래픽 분석의 기반을 마련한다.*

### 3.2. `frontend`: React + WASM 클라이언트 개발

**목표:** `IronRDP` 예제의 `client` 로직을 `frontend` React 프로젝트로 이식하고, UI/UX 연구 과제를 해결할 기반을 마련한다.

**Action Items:**

1.  **WASM 빌드 환경 통합:**
    * WASM으로 컴파일할 `ironrdp-wasm` Rust 라이브러리 크레이트를 `frontend` 내(또는 루트)에 생성한다.
    * `frontend/package.json`의 `scripts`에 `wasm-pack build` 명령어를 추가하여 `npm run build` 시 React 앱과 WASM이 함께 빌드되도록 파이프라인을 구축한다.

2.  **WASM 모듈 로더 구현:**
    * React 앱이 시작될 때, `import("ironrdp-wasm")`을 통해 `.wasm` 파일과 JS 바인딩 코드를 **비동기적**으로 로드하는 `WasmLoader` 서비스(또는 Context)를 구현한다.

3.  **핵심 컴포넌트 설계:**
    * **`<LoginScreen />`:**
        * `Axum 게이트웨이 주소 (ws://...)`
        * `RDP 호스트 IP`
        * `Username / Password`
        * ...를 입력받아 `RdpClient` 컴포넌트로 전달한다.
    * **`<RdpViewport />`:**
        * 메인 `<canvas>` 엘리먼트를 렌더링한다.
        * WASM 모듈로부터 **그래픽 업데이트 이벤트**(e.g., `onBitmapUpdate`)를 수신하고, `canvas.getContext('2d').putImageData()`를 호출하여 화면을 실시간으로 그린다.

4.  **[UI/UX R&D] 양방향 이벤트 핸들러 구현:**
    * **React → WASM (입력):**
        * `<RdpViewport />` 컴포넌트가 `onKeyDown`, `onKeyUp`, `onMouseMove`, `onMouseDown` 등 **브라우저 이벤트를 캡처**한다.
        * 캡처된 이벤트를 RDP 형식(e.g., Scancode, X/Y 좌표)으로 변환하여 로드된 WASM 모듈의 함수(e.g., `client.send_key_event(...)`)로 전달한다.
    * **WASM → React (출력):**
        * (3.2.3)에서 구현한 `canvas` 렌더링 로직.
        * (추후) `onClipboardData` 이벤트를 수신하여 React 상태(state)로 관리, "클립보드 UX" 연구의 기반을 마련한다.

### 3.3. 통합 테스트 및 고도화

1.  `npm run dev` (Frontend)와 `cargo run` (Backend)을 동시에 실행한다.
2.  브라우저에서 React UI에 접속하여, Axum 게이트웨이를 통해 RDP 호스트에 E2E 연결이 성공하는지 테스트한다.
3.  **[R&D]** `3.1.4`와 `3.2.4`에서 확보한 R&D 후크(hook)를 기반으로 **클립보드 제어(DLP)** 및 **키보드 매핑(UX)** 문제 해결을 시작한다.