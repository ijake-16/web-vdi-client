use axum::{
    routing::get,
    Router,
};

// "Hello, World!"를 반환하는 간단한 핸들러
async fn root_handler() -> &'static str {
    "Hello from Axum Backend!"
}

#[tokio::main]
async fn main() {
    // 라우터 설정
    let app = Router::new().route("/", get(root_handler));

    // 3001번 포트에서 서버 실행 (React의 5173과 겹치지 않게)
    let listener = tokio::net::TcpListener::bind("127.0.0.1:3001")
        .await
        .unwrap();
    
    println!("Axum server listening on http://127.0.0.1:3001");

    // 서버 시작
    axum::serve(listener, app).await.unwrap();
}