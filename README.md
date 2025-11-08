# Web VDI & RBI Project

## 1. 프로젝트 목표 (Objective)

기존의 복잡하고 무거운 상용 VDI/RBI 솔루션의 높은 기술/비용 장벽 문제를 해결합니다.

**Rust**와 WebAssembly(WASM)를 활용하여, 별도 설치가 필요 없는 경량의 고성능·보안 브라우저 기반 원격 클라이언트(VDI)를 구축하고, 나아가 원격 브라우저 격리(RBI) 솔루션으로 확장하는 것을 목표로 합니다.

## 2. 핵심 기능 (Key Features)

* **제로-클라이언트 (Zero-Client):** 별도 프로그램 설치 없이, 최신 웹 브라우저만으로 VDI/RBI 환경에 즉시 접근합니다.
* **고성능 WASM 엔진:** RDP 프로토콜 처리를 Rust(`IronRDP`)로 구현하고 WASM으로 컴파일하여, 브라우저에서 네이티브에 가까운 속도로 실행합니다.
* **보안 게이트웨이:** 모든 트래픽은 암호화된 WebSocket(WSS)을 통해 전송되며, Rust(Axum) 기반 백엔드 게이트웨이가 TCP 연결을 안전하게 중계합니다.
* **유연한 확장성:** VDI(원격 데스크톱)에서 RBI(원격 브라우저 격리)로 손쉽게 확장 가능한 아키텍처를 지향합니다.

## 3. 핵심 아키텍처 (Architecture)



본 프로젝트는 RDP 핵심 로직(`IronRDP`)을 서버가 아닌 클라이언트 브라우저(WASM)에서 직접 실행합니다. 브라우저의 보안 제약(TCP 직접 접근 불가)을 해결하기 위해, Axum 백엔드 서버가 **'WebSocket-to-TCP' 프록시** 역할을 수행합니다.

1.  **Client (React + IronRDP WASM):** 브라우저가 RDP 패킷을 직접 처리하고, WebSocket을 통해 프록시로 전송합니다.
2.  **Backend (Axum Gateway):** WebSocket 트래픽을 수신하여 순수 TCP 패킷으로 변환, 실제 RDP 호스트(Windows PC)로 중계합니다.
3.  **Host (Windows PC):** RDP 세션을 제공합니다.

## 4. 기술 스택 (Tech Stack)

* **Core Logic:** IronRDP (Rust-based RDP Library)
* **Client Engine:** WebAssembly (WASM)
* **Frontend:** React / Vite
* **Backend Gateway:** Axum (Rust)
* **Protocol:** WebSocket (WSS) / TCP

## 5. 개발 계획 (Roadmap)

* **1단계: Web VDI 구현**
    * `IronRDP/web-client` 예제 분석 및 재현 가능한 빌드 환경 구축.
    * `Axum` 기반의 자체 WebSocket-to-TCP 프록시 게이트웨이 구현.
* **2단계: RBI 솔루션으로 확장**
    * RDP의 RemoteApp 기능을 활용, 원격 데스크톱 전체가 아닌 '격리된 단일 웹 브라우저'만 스트리밍하는 RBI 기능 구현.
* **3단계: 보안 및 고급 기능**
    * Axum 게이트웨이에 사용자 인증, 세션 로깅 기능 추가.
    * 클립보드, 파일 전송 등 RDP 가상 채널을 제어/감사하는 보안 정책(DLP) 연구.