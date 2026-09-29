<!-- This file is loaded on demand from the main SKILL.md Deep Dives section -->

## Part 5: Common Runtime Issues Prevention

### Thread Safety with Send + Sync

**Thin Send/Sync for async**: Most async types are `!Send` by default. Use `Arc<T>` for shared state across tasks.

```rust
use std::sync::Arc;
use tokio::sync::{Mutex, RwLock};

// Rc/RefCell are !Send and !Sync — use only in single-threaded contexts
// BAD for async: Rc<String> cannot cross task boundaries

// GOOD: Arc for shared ownership across tasks
#[derive(Clone)]
struct SharedState {
    data: Arc<RwLock<Vec<String>>>,  // RwLock better for read-heavy workloads
}

// Arc<Mutex<T>> vs Arc<RwLock<T>>:
// - Mutex: single writer, any reader (but only one holder total)
// - RwLock: multiple readers OR single writer (better for read-heavy)
// In async: prefer tokio::sync::{Mutex, RwLock}, not std::sync::*
```

**Async-specific Send/Sync issues**:
```rust
use tokio::task::JoinSet;

// !Send futures: Cannot be sent to another thread
async fn non_send_task() {
    let data = std::rc::Rc::new(42);  // Rc is !Send
    // This future cannot be .spawn()ed on multi-threaded runtime
}

// JoinSet requires Send + 'static
let mut set = JoinSet::new();
set.spawn(async {
    // Must be Send + 'static
});

// select! cancellation: Ensure futures are cancel-safe
// Avoid holding locks across .await points when possible
select! {
    result = async_task => {
        // Handle result
    },
    _ = cancellation_token.cancelled() => {
        // Cleanup: ensure locks are released
    }
}
```

```rust
use std::sync::{Arc, Mutex};

// Shared state must be Send + Sync to cross thread boundaries
struct AppState {
    counter: Mutex<i32>,
}

// Derive automatically when possible
#[derive(Clone)]
struct CloneableState {
    data: Arc<Mutex<Vec<String>>>,
}

// Explicit bounds for generics
fn process_in_background<T: Send + 'static>(data: T) {
    std::thread::spawn(move || {
        // Process data
    });
}
```

### Avoiding Deadlocks

```rust
use std::sync::{Mutex, MutexGuard};

// Always acquire locks in consistent order
// BAD: Potential deadlock
// fn bad_example(m1: &Mutex<T>, m2: &Mutex<U>) { ... }

// GOOD: Always acquire in same order, use scoping
fn good_example(m1: &Mutex<i32>, m2: &Mutex<String>) {
    let _g1 = m1.lock().unwrap();
    let _g2 = m2.lock().unwrap();  // Always second
    
    // Work here
}  // Locks released in reverse order
```

### Testing: #[tokio::test] and rstest

```rust
// Basic async test
#[tokio::test]
async fn test_async_function() {
    let result = async_fn().await;
    assert_eq!(result, expected);
}

// Parametrized tests with rstest
use rstest::rstest;

#[rstest]
#[case(1, 2)]
#[case(5, 10)]
async fn test_with_cases(#[case] input: i32, #[case] expected: i32) {
    assert_eq!(process(input).await, expected);
}
```

### Async Best Practices

```rust
use tokio::time::{sleep, Duration};

// Use async-specific utilities
async fn fetch_with_timeout() -> Result<String, reqwest::Error> {
    Ok(
        tokio::time::timeout(
            Duration::from_secs(5),
            reqwest::get("https://example.com")
        )
        .await??  // ? for timeout error, ? for request error
        .text()
        .await?
    )
}

// NEVER block the async executor
async fn bad_example() {
    std::thread::sleep(Duration::from_secs(1));  // BAD: blocks executor
    // Use instead:
    sleep(Duration::from_secs(1)).await;  // GOOD: yields to executor
}
```