# Async and Concurrency

> Loaded on demand from `SKILL.md` — one rule per `## <rule-id>` section.


## async-bounded-channel

> Use bounded channels to apply backpressure and prevent unbounded memory growth

### Why It Matters

Unbounded channels grow without limit when producers outpace consumers. In production, this leads to memory exhaustion. Bounded channels apply backpressure—producers wait when the channel is full, naturally throttling the system. This prevents OOM and makes resource usage predictable.

### Bad

```rust
use tokio::sync::mpsc;

// Unbounded channel - can grow forever
let (tx, mut rx) = mpsc::unbounded_channel::<Message>();

// Fast producer, slow consumer = unbounded memory growth
tokio::spawn(async move {
    loop {
        let msg = generate_message();
        tx.send(msg).unwrap();  // Never blocks, never fails (until OOM)
    }
});

tokio::spawn(async move {
    while let Some(msg) = rx.recv().await {
        slow_process(msg).await;  // Can't keep up
    }
});
// Memory grows unboundedly until crash
```

### Good

```rust
use tokio::sync::mpsc;

// Bounded channel - backpressure when full
let (tx, mut rx) = mpsc::channel::<Message>(100);  // Max 100 items

// Producer waits when channel full
tokio::spawn(async move {
    loop {
        let msg = generate_message();
        // Blocks if channel is full - natural backpressure
        tx.send(msg).await.unwrap();
    }
});

tokio::spawn(async move {
    while let Some(msg) = rx.recv().await {
        slow_process(msg).await;
    }
});
// Memory usage capped at ~100 messages
```

### Choosing Buffer Size

```rust
// Too small: frequent blocking, reduced throughput
let (tx, rx) = mpsc::channel::<Item>(1);

// Too large: delayed backpressure, memory waste
let (tx, rx) = mpsc::channel::<Item>(1_000_000);

// Guidelines:
// - Start with expected burst size
// - Measure actual usage in production
// - Err on the smaller side initially

// Small items, high throughput
let (tx, rx) = mpsc::channel::<u64>(1000);

// Large items, moderate throughput  
let (tx, rx) = mpsc::channel::<LargeStruct>(100);

// Low latency requirement
let (tx, rx) = mpsc::channel::<Command>(10);
```

### Handling Full Channel

```rust
use tokio::sync::mpsc;
use tokio::time::{timeout, Duration};

let (tx, mut rx) = mpsc::channel::<Message>(100);

// Option 1: Wait indefinitely (default)
tx.send(msg).await?;

// Option 2: Try send, fail if full
match tx.try_send(msg) {
    Ok(()) => println!("Sent"),
    Err(TrySendError::Full(msg)) => {
        println!("Channel full, dropping message");
    }
    Err(TrySendError::Closed(msg)) => {
        println!("Receiver dropped");
    }
}

// Option 3: Timeout
match timeout(Duration::from_secs(1), tx.send(msg)).await {
    Ok(Ok(())) => println!("Sent"),
    Ok(Err(_)) => println!("Channel closed"),
    Err(_) => println!("Timeout - channel full for too long"),
}

// Option 4: send with permit reservation
let permit = tx.reserve().await?;
permit.send(msg);  // Guaranteed to succeed
```

### Channel Types

```rust
// mpsc: many producers, single consumer
let (tx, rx) = mpsc::channel::<Message>(100);
let tx2 = tx.clone();  // Can clone sender

// oneshot: single value, one producer, one consumer
let (tx, rx) = oneshot::channel::<Response>();
tx.send(response);  // Can only send once

// broadcast: multiple consumers, each gets all messages
let (tx, _) = broadcast::channel::<Event>(100);
let mut rx1 = tx.subscribe();
let mut rx2 = tx.subscribe();

// watch: single latest value, multiple consumers
let (tx, rx) = watch::channel::<State>(initial);
// Receivers see latest value, not all values
```

### Worker Pool Pattern

```rust
async fn process_with_workers(items: Vec<Item>) -> Vec<Result> {
    let (tx, rx) = mpsc::channel(100);
    let rx = Arc::new(Mutex::new(rx));
    
    // Spawn worker pool
    let workers: Vec<_> = (0..4).map(|_| {
        let rx = rx.clone();
        tokio::spawn(async move {
            loop {
                let item = {
                    let mut rx = rx.lock().await;
                    rx.recv().await
                };
                match item {
                    Some(item) => process(item).await,
                    None => break,
                }
            }
        })
    }).collect();
    
    // Send items
    for item in items {
        tx.send(item).await.unwrap();
    }
    drop(tx);  // Signal workers to stop
    
    futures::future::join_all(workers).await;
}
```

### See Also

- [async-mpsc-queue](#async-mpsc-queue) - Multi-producer patterns
- [async-oneshot-response](#async-oneshot-response) - Request-response pattern
- [async-watch-latest](#async-watch-latest) - Latest-value broadcasting


## async-broadcast-pubsub

> Use `broadcast` channel for pub/sub where all subscribers receive all messages

### Why It Matters

Unlike `mpsc` where one consumer receives each message, `broadcast` delivers each message to all subscribers. This is ideal for event broadcasting, real-time notifications, or when multiple components need to react to the same events independently.

### Bad

```rust
use tokio::sync::mpsc;

// mpsc only delivers to ONE consumer
let (tx, mut rx) = mpsc::channel::<Event>(100);

// Only one of these receives each message!
let mut rx2 = ???;  // Can't clone receiver
```

### Good

```rust
use tokio::sync::broadcast;

// broadcast delivers to ALL subscribers
let (tx, _) = broadcast::channel::<Event>(100);

// Each subscriber gets ALL messages
let mut rx1 = tx.subscribe();
let mut rx2 = tx.subscribe();

tokio::spawn(async move {
    while let Ok(event) = rx1.recv().await {
        handle_in_logger(event);
    }
});

tokio::spawn(async move {
    while let Ok(event) = rx2.recv().await {
        handle_in_metrics(event);
    }
});

// Both subscribers receive this
tx.send(Event::UserLogin { user_id: 42 })?;
```

### Broadcast Semantics

```rust
use tokio::sync::broadcast;

let (tx, mut rx1) = broadcast::channel::<i32>(16);
let mut rx2 = tx.subscribe();

tx.send(1)?;
tx.send(2)?;

// Both receive all messages
assert_eq!(rx1.recv().await?, 1);
assert_eq!(rx1.recv().await?, 2);
assert_eq!(rx2.recv().await?, 1);
assert_eq!(rx2.recv().await?, 2);
```

### Handling Lagging Receivers

```rust
use tokio::sync::broadcast::{self, error::RecvError};

let (tx, mut rx) = broadcast::channel::<Event>(16);

loop {
    match rx.recv().await {
        Ok(event) => {
            process(event);
        }
        Err(RecvError::Lagged(count)) => {
            // Receiver couldn't keep up, missed `count` messages
            log::warn!("Missed {} events", count);
            // Continue receiving new messages
        }
        Err(RecvError::Closed) => {
            break;  // All senders dropped
        }
    }
}
```

### Event Bus Pattern

```rust
use tokio::sync::broadcast;

#[derive(Clone, Debug)]
enum AppEvent {
    UserLoggedIn { user_id: u64 },
    OrderCreated { order_id: u64 },
    SystemShutdown,
}

struct EventBus {
    tx: broadcast::Sender<AppEvent>,
}

impl EventBus {
    fn new() -> Self {
        let (tx, _) = broadcast::channel(1000);
        EventBus { tx }
    }
    
    fn publish(&self, event: AppEvent) {
        // Ignore error if no subscribers
        let _ = self.tx.send(event);
    }
    
    fn subscribe(&self) -> broadcast::Receiver<AppEvent> {
        self.tx.subscribe()
    }
}

// Usage
let bus = EventBus::new();

// Logger subscribes
let mut log_rx = bus.subscribe();
tokio::spawn(async move {
    while let Ok(event) = log_rx.recv().await {
        log::info!("Event: {:?}", event);
    }
});

// Metrics subscribes
let mut metrics_rx = bus.subscribe();
tokio::spawn(async move {
    while let Ok(event) = metrics_rx.recv().await {
        record_metric(&event);
    }
});

// Publish events
bus.publish(AppEvent::UserLoggedIn { user_id: 42 });
```

### Broadcast vs Watch

```rust
// broadcast: subscribers get ALL messages
// Good for: events, logs, notifications
let (tx, _) = broadcast::channel::<Event>(100);

// watch: subscribers get LATEST value only
// Good for: config changes, state updates
let (tx, _) = watch::channel(initial_state);

// If subscriber is slow:
// - broadcast: they receive old messages (or lag)
// - watch: they skip to latest (no history)
```

### Clone Requirement

```rust
// broadcast requires Clone because message is cloned to each receiver
use tokio::sync::broadcast;

#[derive(Clone)]  // Required for broadcast
struct Event {
    data: String,
}

let (tx, _) = broadcast::channel::<Event>(100);

// For non-Clone types, wrap in Arc
use std::sync::Arc;

let (tx, _) = broadcast::channel::<Arc<LargeNonClone>>(100);
```

### See Also

- [async-mpsc-queue](#async-mpsc-queue) - Single-consumer channels
- [async-watch-latest](#async-watch-latest) - Latest-value only
- [async-bounded-channel](#async-bounded-channel) - Buffer sizing


## async-cancellation-token

> Use `CancellationToken` for graceful shutdown and task cancellation

### Why It Matters

Dropping a `JoinHandle` doesn't cancel the task—it just detaches it. For graceful shutdown, you need explicit cancellation. `tokio_util::sync::CancellationToken` provides a cooperative cancellation mechanism that tasks can check and respond to, enabling clean resource cleanup.

### Bad

```rust
// Dropping handle doesn't stop the task
let handle = tokio::spawn(async {
    loop {
        do_work().await;
    }
});

drop(handle);  // Task continues running in background!

// Using bool flag - not async-aware
let running = Arc::new(AtomicBool::new(true));

tokio::spawn({
    let running = running.clone();
    async move {
        while running.load(Ordering::Relaxed) {
            do_work().await;  // Can't wake up if blocked here
        }
    }
});

running.store(false, Ordering::Relaxed);
// Task won't stop until current do_work() completes
```

### Good

```rust
use tokio_util::sync::CancellationToken;

let token = CancellationToken::new();

let handle = tokio::spawn({
    let token = token.clone();
    async move {
        loop {
            tokio::select! {
                _ = token.cancelled() => {
                    println!("Shutting down gracefully");
                    cleanup().await;
                    break;
                }
                _ = do_work() => {
                    // Work completed
                }
            }
        }
    }
});

// Later: trigger cancellation
token.cancel();
handle.await?;  // Task completes cleanly
```

### CancellationToken API

```rust
use tokio_util::sync::CancellationToken;

// Create token
let token = CancellationToken::new();

// Clone for sharing (cheap Arc-based clone)
let token2 = token.clone();

// Check if cancelled (non-blocking)
if token.is_cancelled() {
    return;
}

// Wait for cancellation (async)
token.cancelled().await;

// Trigger cancellation
token.cancel();

// Child tokens - cancelled when parent is cancelled
let child = token.child_token();
```

### Hierarchical Cancellation

```rust
async fn run_server(shutdown: CancellationToken) {
    let listener = TcpListener::bind("0.0.0.0:8080").await?;
    
    loop {
        tokio::select! {
            _ = shutdown.cancelled() => {
                println!("Server shutting down");
                break;
            }
            result = listener.accept() => {
                let (socket, _) = result?;
                // Each connection gets child token
                let conn_token = shutdown.child_token();
                tokio::spawn(handle_connection(socket, conn_token));
            }
        }
    }
    
    // Child tokens auto-cancelled when we exit
}

async fn handle_connection(socket: TcpStream, token: CancellationToken) {
    loop {
        tokio::select! {
            _ = token.cancelled() => {
                // Connection cleanup
                break;
            }
            data = socket.read() => {
                // Handle data
            }
        }
    }
}
```

### Graceful Shutdown Pattern

```rust
use tokio::signal;

async fn main() -> Result<()> {
    let shutdown = CancellationToken::new();
    
    // Spawn signal handler
    let shutdown_trigger = shutdown.clone();
    tokio::spawn(async move {
        signal::ctrl_c().await.expect("failed to listen for Ctrl+C");
        println!("Received Ctrl+C, initiating shutdown...");
        shutdown_trigger.cancel();
    });
    
    // Run application with shutdown token
    run_app(shutdown).await
}

async fn run_app(shutdown: CancellationToken) -> Result<()> {
    let mut tasks = JoinSet::new();
    
    tasks.spawn(worker_task(shutdown.child_token()));
    tasks.spawn(server_task(shutdown.child_token()));
    
    // Wait for shutdown or task completion
    tokio::select! {
        _ = shutdown.cancelled() => {
            println!("Shutdown requested, waiting for tasks...");
        }
        Some(result) = tasks.join_next() => {
            // A task completed/failed
            result??;
        }
    }
    
    // Wait for remaining tasks with timeout
    tokio::time::timeout(
        Duration::from_secs(30),
        async { while tasks.join_next().await.is_some() {} }
    ).await.ok();
    
    Ok(())
}
```

### DropGuard Pattern

```rust
use tokio_util::sync::CancellationToken;

// Auto-cancel on drop
let token = CancellationToken::new();
let guard = token.clone().drop_guard();

tokio::spawn({
    let token = token.clone();
    async move {
        token.cancelled().await;
        println!("Cancelled!");
    }
});

drop(guard);  // Automatically calls token.cancel()
```

### See Also

- [async-joinset-structured](#async-joinset-structured) - Managing multiple tasks
- [async-select-racing](#async-select-racing) - select! for cancellation
- [async-tokio-runtime](#async-tokio-runtime) - Runtime shutdown


## async-clone-before-await

> Clone Arc/Rc data before await points to avoid holding references across suspension

### Why It Matters

References held across `.await` points extend the future's lifetime and can cause borrow checker issues or prevent `Send` bounds. Cloning `Arc`/`Rc` before the await ensures the future only holds owned data, making it `Send` and avoiding lifetime complications.

### Bad

```rust
use std::sync::Arc;

async fn process(data: Arc<Data>) {
    // Borrow extends across await - future is not Send
    let slice = &data.items[..];  // Borrow of Arc contents
    
    expensive_async_operation().await;  // Await with active borrow
    
    use_slice(slice);  // Still using the borrow
}

// Error: future cannot be sent between threads safely
// because `&[Item]` cannot be sent between threads safely
tokio::spawn(process(data));
```

### Good

```rust
use std::sync::Arc;

async fn process(data: Arc<Data>) {
    // Clone what you need before await
    let items = data.items.clone();  // Owned Vec
    
    expensive_async_operation().await;
    
    use_items(&items);  // Using owned data
}

// Or clone the Arc itself
async fn share_data(data: Arc<Data>) {
    let data = data.clone();  // Another Arc handle
    
    some_async_work().await;
    
    process(&data);  // Safe - we own the Arc
}
```

### The Send Problem

```rust
// Futures must be Send to spawn on multi-threaded runtime
async fn not_send() {
    let rc = Rc::new(42);  // Rc is !Send
    
    tokio::time::sleep(Duration::from_secs(1)).await;
    
    println!("{}", rc);  // rc held across await
}

tokio::spawn(not_send());  // ERROR: future is not Send

// Fix: use Arc or don't hold across await
async fn is_send() {
    let arc = Arc::new(42);  // Arc is Send
    
    tokio::time::sleep(Duration::from_secs(1)).await;
    
    println!("{}", arc);
}

tokio::spawn(is_send());  // OK
```

### Minimizing Clones

```rust
// Bad: clone everything eagerly
async fn wasteful(data: Arc<LargeData>) {
    let data = (*data).clone();  // Clones entire LargeData
    async_work().await;
    use_one_field(&data.small_field);
}

// Good: clone only what you need
async fn efficient(data: Arc<LargeData>) {
    let small = data.small_field.clone();  // Clone only needed field
    async_work().await;
    use_one_field(&small);
}

// Good: if you need the whole thing, keep the Arc
async fn arc_efficient(data: Arc<LargeData>) {
    let data = data.clone();  // Cheap Arc clone
    async_work().await;
    use_data(&data);  // Access through Arc
}
```

### Spawn Pattern

```rust
// Common pattern: clone for spawned task
let shared = Arc::new(SharedState::new());

for i in 0..10 {
    let shared = shared.clone();  // Clone before moving into spawn
    tokio::spawn(async move {
        // Task owns its Arc clone
        shared.do_something(i).await;
    });
}
```

### Scope-Based Approach

```rust
// Limit borrow scope to before await
async fn scoped(data: Arc<Data>) {
    // Scope 1: borrow, compute, drop borrow
    let computed = {
        let slice = &data.items[..];  // Borrow
        compute_something(slice)       // Use
    };  // Borrow ends here
    
    // Now safe to await
    expensive_async_operation().await;
    
    use_computed(computed);
}
```

### MutexGuard Across Await

```rust
use tokio::sync::Mutex;

// BAD: holding guard across await
async fn bad(mutex: Arc<Mutex<Data>>) {
    let mut guard = mutex.lock().await;
    guard.value += 1;
    
    slow_operation().await;  // Guard held during await!
    
    guard.value += 1;
}

// GOOD: release before await
async fn good(mutex: Arc<Mutex<Data>>) {
    {
        let mut guard = mutex.lock().await;
        guard.value += 1;
    }  // Guard released
    
    slow_operation().await;
    
    {
        let mut guard = mutex.lock().await;
        guard.value += 1;
    }
}
```

### See Also

- [async-no-lock-await](#async-no-lock-await) - Lock guards across await
- [own-arc-shared](#own-arc-shared) - Arc usage patterns
- [async-spawn-blocking](#async-spawn-blocking) - Blocking in async


## async-join-parallel

> Use `join!` or `try_join!` for concurrent independent futures

### Why It Matters

Awaiting futures sequentially takes the sum of their durations. `join!` runs futures concurrently, taking only as long as the slowest one. For independent operations like multiple API calls or parallel file reads, this can dramatically reduce latency.

### Bad

```rust
async fn fetch_data() -> (User, Posts, Comments) {
    // Sequential: 300ms total (100 + 100 + 100)
    let user = fetch_user().await;        // 100ms
    let posts = fetch_posts().await;      // 100ms  
    let comments = fetch_comments().await; // 100ms
    
    (user, posts, comments)
}

async fn read_configs() -> Result<(Config, Settings)> {
    // Sequential: 20ms + 20ms = 40ms
    let config = fs::read_to_string("config.toml").await?;
    let settings = fs::read_to_string("settings.json").await?;
    
    Ok((parse_config(&config)?, parse_settings(&settings)?))
}
```

### Good

```rust
use tokio::join;

async fn fetch_data() -> (User, Posts, Comments) {
    // Concurrent: ~100ms total (max of all three)
    let (user, posts, comments) = join!(
        fetch_user(),
        fetch_posts(),
        fetch_comments(),
    );
    
    (user, posts, comments)
}

use tokio::try_join;

async fn read_configs() -> Result<(Config, Settings)> {
    // Concurrent: ~20ms total
    let (config_str, settings_str) = try_join!(
        fs::read_to_string("config.toml"),
        fs::read_to_string("settings.json"),
    )?;
    
    Ok((parse_config(&config_str)?, parse_settings(&settings_str)?))
}
```

### join! vs try_join!

```rust
// join! - all futures run to completion, returns tuple
let (a, b, c) = join!(future_a, future_b, future_c);

// try_join! - short-circuits on first error
let (a, b, c) = try_join!(fallible_a, fallible_b, fallible_c)?;
// If fallible_b fails, returns Err immediately
// Other futures may still be running (cancellation is async)
```

### futures::join_all for Dynamic Collections

```rust
use futures::future::join_all;

async fn fetch_all_users(ids: &[u64]) -> Vec<User> {
    let futures: Vec<_> = ids.iter()
        .map(|id| fetch_user(*id))
        .collect();
    
    join_all(futures).await
}

// With fallible futures
use futures::future::try_join_all;

async fn fetch_all_users(ids: &[u64]) -> Result<Vec<User>> {
    let futures: Vec<_> = ids.iter()
        .map(|id| fetch_user(*id))
        .collect();
    
    try_join_all(futures).await
}
```

### Limiting Concurrency

```rust
use futures::stream::{self, StreamExt};

async fn fetch_with_limit(ids: &[u64]) -> Vec<Result<User>> {
    stream::iter(ids)
        .map(|id| fetch_user(*id))
        .buffer_unordered(10)  // Max 10 concurrent requests
        .collect()
        .await
}

// Or with tokio::sync::Semaphore
use tokio::sync::Semaphore;

async fn fetch_with_semaphore(ids: &[u64]) -> Vec<User> {
    let semaphore = Arc::new(Semaphore::new(10));
    
    let futures: Vec<_> = ids.iter().map(|id| {
        let semaphore = semaphore.clone();
        async move {
            let _permit = semaphore.acquire().await.unwrap();
            fetch_user(*id).await
        }
    }).collect();
    
    join_all(futures).await
}
```

### When NOT to Use join!

```rust
// ❌ Dependent futures - must be sequential
async fn create_and_populate() -> Result<()> {
    let db = create_database().await?;   // Must complete first
    populate_tables(&db).await?;          // Depends on db
    Ok(())
}

// ❌ Short-circuiting logic
async fn find_first() -> Option<Data> {
    // Want to stop when one succeeds
    // Use select! instead
}

// ❌ Shared mutable state
async fn bad_shared_state() {
    let counter = Arc::new(Mutex::new(0));
    // This might work but can cause contention
    join!(
        increment(counter.clone()),
        increment(counter.clone()),
    );
}
```

### See Also

- [async-try-join](#async-try-join) - Error handling in concurrent futures
- [async-select-racing](#async-select-racing) - Racing futures
- [async-joinset-structured](#async-joinset-structured) - Dynamic task sets


## async-joinset-structured

> Use `JoinSet` for managing dynamic collections of spawned tasks

### Why It Matters

When spawning a variable number of tasks, collecting `JoinHandle`s in a `Vec` and using `join_all` works but lacks flexibility. `JoinSet` provides a better abstraction: add/remove tasks dynamically, get results as they complete, and abort all on drop. It's the idiomatic way to manage task collections.

### Bad

```rust
// Manual handle management
let mut handles: Vec<JoinHandle<Result<Data>>> = Vec::new();

for url in urls {
    handles.push(tokio::spawn(fetch(url)));
}

// Wait for all, in order (not as they complete)
let results = futures::future::join_all(handles).await;

// No easy way to cancel all, handle errors progressively, or add more tasks
```

### Good

```rust
use tokio::task::JoinSet;

let mut set = JoinSet::new();

for url in urls {
    set.spawn(fetch(url.clone()));
}

// Process results as they complete
while let Some(result) = set.join_next().await {
    match result {
        Ok(Ok(data)) => process(data),
        Ok(Err(e)) => log::error!("Task failed: {}", e),
        Err(e) => log::error!("Task panicked: {}", e),
    }
}

// All tasks done, set is empty
```

### Dynamic Task Addition

```rust
use tokio::task::JoinSet;

async fn worker_pool(mut rx: mpsc::Receiver<Task>) {
    let mut set = JoinSet::new();
    let max_concurrent = 10;
    
    loop {
        tokio::select! {
            // Accept new tasks if under limit
            Some(task) = rx.recv(), if set.len() < max_concurrent => {
                set.spawn(process_task(task));
            }
            
            // Process completed tasks
            Some(result) = set.join_next() => {
                handle_result(result);
            }
            
            // Exit when no tasks and channel closed
            else => break,
        }
    }
}
```

### Abort on Drop

```rust
use tokio::task::JoinSet;

{
    let mut set = JoinSet::new();
    set.spawn(long_running_task());
    set.spawn(another_task());
    
    // Early exit
    return;
}  // JoinSet dropped here - all tasks are aborted!

// Explicit abort
let mut set = JoinSet::new();
set.spawn(task());
set.abort_all();  // Cancel all tasks
```

### Error Handling Pattern

```rust
use tokio::task::JoinSet;

async fn fetch_all(urls: &[String]) -> Vec<Result<Data, Error>> {
    let mut set = JoinSet::new();
    let mut results = Vec::new();
    
    for url in urls {
        set.spawn(fetch(url.clone()));
    }
    
    while let Some(join_result) = set.join_next().await {
        let result = match join_result {
            Ok(task_result) => task_result,
            Err(join_error) => {
                if join_error.is_panic() {
                    Err(Error::TaskPanicked)
                } else {
                    Err(Error::TaskCancelled)
                }
            }
        };
        results.push(result);
    }
    
    results
}
```

### With Cancellation

```rust
use tokio::task::JoinSet;
use tokio_util::sync::CancellationToken;

async fn run_workers(shutdown: CancellationToken) {
    let mut set = JoinSet::new();
    
    for i in 0..4 {
        let token = shutdown.child_token();
        set.spawn(async move {
            loop {
                tokio::select! {
                    _ = token.cancelled() => break,
                    _ = do_work(i) => {}
                }
            }
        });
    }
    
    // Wait for shutdown
    shutdown.cancelled().await;
    
    // Abort remaining tasks
    set.abort_all();
    
    // Wait for all to finish (drain aborted tasks)
    while set.join_next().await.is_some() {}
}
```

### Spawning with Context

```rust
use tokio::task::JoinSet;

let mut set: JoinSet<(usize, Result<Data, Error>)> = JoinSet::new();

for (index, url) in urls.iter().enumerate() {
    let url = url.clone();
    set.spawn(async move {
        (index, fetch(&url).await)
    });
}

// Results include their index
while let Some(result) = set.join_next().await {
    if let Ok((index, data)) = result {
        results[index] = Some(data);
    }
}
```

### JoinSet vs join_all

| Feature | JoinSet | join_all |
|---------|---------|----------|
| Add tasks dynamically | Yes | No |
| Results as-completed | Yes | No (all at once) |
| Abort all on drop | Yes | No |
| Cancel individual | Yes | No |
| Memory efficient | Yes | Pre-allocates |

### See Also

- [async-join-parallel](#async-join-parallel) - Static concurrent futures
- [async-cancellation-token](#async-cancellation-token) - Cancellation patterns
- [async-try-join](#async-try-join) - Error handling in joins


## async-mpsc-queue

> Use `mpsc` channels for async message queues between tasks

### Why It Matters

`tokio::sync::mpsc` (multi-producer, single-consumer) is the workhorse channel for async Rust. It provides async send/receive, backpressure via bounded capacity, and efficient cloning of senders. It's the default choice for task-to-task communication.

### Bad

```rust
use std::sync::mpsc;  // Wrong! Blocks the async runtime

let (tx, rx) = std::sync::mpsc::channel();

tokio::spawn(async move {
    tx.send("hello").unwrap();  // Might block
});

tokio::spawn(async move {
    let msg = rx.recv().unwrap();  // BLOCKS the executor thread!
});
```

### Good

```rust
use tokio::sync::mpsc;

let (tx, mut rx) = mpsc::channel::<String>(100);

tokio::spawn(async move {
    tx.send("hello".to_string()).await.unwrap();
});

tokio::spawn(async move {
    while let Some(msg) = rx.recv().await {
        println!("Received: {}", msg);
    }
});
```

### Sender Cloning

```rust
use tokio::sync::mpsc;

let (tx, mut rx) = mpsc::channel::<Event>(100);

// Multiple producers
for i in 0..10 {
    let tx = tx.clone();  // Cheap clone
    tokio::spawn(async move {
        tx.send(Event { source: i }).await.unwrap();
    });
}

// Drop original sender so channel closes when all clones dropped
drop(tx);

// Consumer
while let Some(event) = rx.recv().await {
    process(event);
}
// Loop exits when all senders dropped
```

### Message Handler Pattern

```rust
use tokio::sync::mpsc;

enum Command {
    Get { key: String, reply: oneshot::Sender<Option<Value>> },
    Set { key: String, value: Value },
    Delete { key: String },
}

async fn run_store(mut commands: mpsc::Receiver<Command>) {
    let mut store = HashMap::new();
    
    while let Some(cmd) = commands.recv().await {
        match cmd {
            Command::Get { key, reply } => {
                let _ = reply.send(store.get(&key).cloned());
            }
            Command::Set { key, value } => {
                store.insert(key, value);
            }
            Command::Delete { key } => {
                store.remove(&key);
            }
        }
    }
}

// Usage
async fn client(tx: mpsc::Sender<Command>) -> Option<Value> {
    let (reply_tx, reply_rx) = oneshot::channel();
    
    tx.send(Command::Get { 
        key: "foo".to_string(), 
        reply: reply_tx 
    }).await.unwrap();
    
    reply_rx.await.unwrap()
}
```

### Graceful Shutdown

```rust
async fn worker(mut rx: mpsc::Receiver<Task>, shutdown: CancellationToken) {
    loop {
        tokio::select! {
            _ = shutdown.cancelled() => {
                // Drain remaining messages
                while let Ok(task) = rx.try_recv() {
                    process(task).await;
                }
                break;
            }
            Some(task) = rx.recv() => {
                process(task).await;
            }
            else => break,  // Channel closed
        }
    }
}
```

### WeakSender for Optional Producers

```rust
use tokio::sync::mpsc;

let (tx, mut rx) = mpsc::channel::<Message>(100);
let weak = tx.downgrade();  // Doesn't keep channel alive

tokio::spawn(async move {
    // Strong sender - keeps channel alive
    tx.send("from strong".into()).await.unwrap();
});

tokio::spawn(async move {
    // Weak sender - may fail if strong senders dropped
    if let Some(tx) = weak.upgrade() {
        tx.send("from weak".into()).await.unwrap();
    }
});
```

### Permit Pattern

```rust
// Reserve slot before preparing message
let permit = tx.reserve().await?;

// Now we have guaranteed capacity
let message = expensive_to_create_message();
permit.send(message);  // Never fails

// Useful when message creation is expensive
// and you don't want to create it if channel is full
```

### See Also

- [async-bounded-channel](#async-bounded-channel) - Why bounded channels
- [async-oneshot-response](#async-oneshot-response) - Request-response with oneshot
- [async-broadcast-pubsub](#async-broadcast-pubsub) - Multiple consumers


## async-no-lock-await

> Never hold `Mutex`/`RwLock` across `.await`

### Why It Matters

Holding a lock across an `.await` point can cause deadlocks and severely hurt performance. The task may be suspended while holding the lock, blocking all other tasks waiting for it - potentially indefinitely.

### Bad

```rust
use tokio::sync::Mutex;

async fn bad_update(state: &Mutex<State>) {
    let mut guard = state.lock().await;
    
    // BAD: Lock held across await!
    let data = fetch_from_network().await;
    
    guard.value = data;
}  // Lock finally released

// This can deadlock or starve other tasks
```

### Good

```rust
use tokio::sync::Mutex;

async fn good_update(state: &Mutex<State>) {
    // Fetch data BEFORE taking the lock
    let data = fetch_from_network().await;
    
    // Lock only for the quick update
    let mut guard = state.lock().await;
    guard.value = data;
}  // Lock released immediately

// Alternative: Clone data out, process, then update
async fn good_update_v2(state: &Mutex<State>) {
    // Extract what we need
    let id = {
        let guard = state.lock().await;
        guard.id.clone()
    };  // Lock released!
    
    // Do async work without lock
    let data = fetch_by_id(id).await;
    
    // Quick update
    state.lock().await.value = data;
}
```

### The Problem Visualized

```rust
// Task A:
let guard = mutex.lock().await;    // Acquires lock
expensive_io().await;              // Suspended, still holding lock!
// ... many milliseconds pass ...
drop(guard);                       // Finally releases

// Task B, C, D:
let guard = mutex.lock().await;    // All blocked waiting for A!
```

### Patterns for Extraction

```rust
use tokio::sync::Mutex;

// Pattern 1: Clone out, process, update
async fn pattern_clone(state: &Mutex<State>) {
    let config = state.lock().await.config.clone();
    let result = process_with_io(&config).await;
    state.lock().await.result = result;
}

// Pattern 2: Compute closure, apply
async fn pattern_closure(state: &Mutex<State>) {
    let update = compute_update().await;
    
    state.lock().await.apply(update);
}

// Pattern 3: Message passing
async fn pattern_message(
    state: &Mutex<State>,
    tx: mpsc::Sender<Update>,
) {
    let update = compute_update().await;
    tx.send(update).await.unwrap();
}

// Separate task handles updates
async fn state_manager(
    state: Arc<Mutex<State>>,
    mut rx: mpsc::Receiver<Update>,
) {
    while let Some(update) = rx.recv().await {
        state.lock().await.apply(update);
    }
}
```

### Using RwLock

```rust
use tokio::sync::RwLock;

async fn read_heavy(state: &RwLock<State>) {
    // Multiple readers OK, but still don't hold across await
    let value = {
        let guard = state.read().await;
        guard.value.clone()
    };
    
    // Process without lock
    let result = process(value).await;
    
    // Write lock for update
    state.write().await.result = result;
}
```

### std::sync::Mutex vs tokio::sync::Mutex

```rust
// std::sync::Mutex: Blocks the entire thread
// - Use for quick, CPU-only operations
// - NEVER use in async code with await inside

// tokio::sync::Mutex: Async-aware, yields to runtime
// - Use in async code
// - Still don't hold across await points!

// std::sync::Mutex in async (quick operation, OK):
async fn quick_update(state: &std::sync::Mutex<State>) {
    state.lock().unwrap().counter += 1;  // No await, OK
}

// tokio::sync::Mutex (must use if lock scope has await):
async fn must_await_inside(state: &tokio::sync::Mutex<State>) {
    let mut guard = state.lock().await;
    // Only if you REALLY need the lock during async op
    // (usually you don't - redesign instead)
}
```

### See Also

- [async-spawn-blocking](#async-spawn-blocking) - Use spawn_blocking for CPU work
- [async-clone-before-await](#async-clone-before-await) - Clone data before await
- [anti-lock-across-await](#anti-lock-across-await) - Anti-pattern reference


## async-oneshot-response

> Use `oneshot` channel for request-response patterns

### Why It Matters

When one task needs to send a request and wait for exactly one response, `oneshot` is the perfect fit. It's a single-use channel optimized for this pattern—no buffering, no clone overhead. Combined with `mpsc`, it enables clean actor-style message passing.

### Bad

```rust
// Using mpsc for single response - wasteful
let (tx, mut rx) = mpsc::channel::<Response>(1);
send_request().await;
let response = rx.recv().await.unwrap();
// Channel persists, could accidentally receive more

// Using shared state - complex
let result = Arc::new(Mutex::new(None));
send_request(result.clone()).await;
while result.lock().await.is_none() {
    tokio::time::sleep(Duration::from_millis(10)).await;  // Polling!
}
```

### Good

```rust
use tokio::sync::oneshot;

let (tx, rx) = oneshot::channel::<Response>();

// Send request with reply channel
send_request(Request { data, reply: tx }).await;

// Wait for response
let response = rx.await?;

// Channel is consumed - can't accidentally reuse
```

### Request-Response Pattern

```rust
use tokio::sync::{mpsc, oneshot};

enum Request {
    Get {
        key: String,
        reply: oneshot::Sender<Option<Value>>,
    },
    Set {
        key: String,
        value: Value,
        reply: oneshot::Sender<bool>,
    },
}

// Service handler
async fn service(mut rx: mpsc::Receiver<Request>) {
    let mut store = HashMap::new();
    
    while let Some(req) = rx.recv().await {
        match req {
            Request::Get { key, reply } => {
                let value = store.get(&key).cloned();
                let _ = reply.send(value);  // Ignore if receiver dropped
            }
            Request::Set { key, value, reply } => {
                store.insert(key, value);
                let _ = reply.send(true);
            }
        }
    }
}

// Client
async fn get_value(tx: &mpsc::Sender<Request>, key: &str) -> Option<Value> {
    let (reply_tx, reply_rx) = oneshot::channel();
    
    tx.send(Request::Get {
        key: key.to_string(),
        reply: reply_tx,
    }).await.ok()?;
    
    reply_rx.await.ok()?
}
```

### With Timeout

```rust
use tokio::time::{timeout, Duration};

async fn request_with_timeout(
    tx: &mpsc::Sender<Request>,
    key: &str,
) -> Result<Value, Error> {
    let (reply_tx, reply_rx) = oneshot::channel();
    
    tx.send(Request::Get {
        key: key.to_string(),
        reply: reply_tx,
    }).await.map_err(|_| Error::ServiceDown)?;
    
    timeout(Duration::from_secs(5), reply_rx)
        .await
        .map_err(|_| Error::Timeout)?
        .map_err(|_| Error::ServiceDown)?
        .ok_or(Error::NotFound)
}
```

### Error Handling

```rust
use tokio::sync::oneshot;

let (tx, rx) = oneshot::channel::<String>();

// Sender dropped without sending
drop(tx);
match rx.await {
    Ok(value) => println!("Got: {}", value),
    Err(oneshot::error::RecvError { .. }) => {
        println!("Sender dropped");
    }
}

// Receiver dropped before send
let (tx, rx) = oneshot::channel::<String>();
drop(rx);
match tx.send("hello".to_string()) {
    Ok(()) => println!("Sent"),
    Err(value) => println!("Receiver dropped, value: {}", value),
}
```

### Closed Detection

```rust
// Check if receiver is still waiting
let (tx, rx) = oneshot::channel::<i32>();

// In producer
if tx.is_closed() {
    println!("Receiver already gone, skip expensive computation");
} else {
    let result = expensive_computation();
    tx.send(result).ok();
}

// Async wait for close
let tx_clone = tx.clone();  // Note: can't actually clone, just showing concept
tokio::select! {
    _ = tx.closed() => println!("Receiver dropped"),
    result = compute() => { tx.send(result).ok(); }
}
```

### Response Type Wrapper

```rust
// Standardize request-response pattern
struct RpcRequest<Req, Res> {
    request: Req,
    reply: oneshot::Sender<Res>,
}

impl<Req, Res> RpcRequest<Req, Res> {
    fn new(request: Req) -> (Self, oneshot::Receiver<Res>) {
        let (tx, rx) = oneshot::channel();
        (RpcRequest { request, reply: tx }, rx)
    }
    
    fn respond(self, response: Res) {
        let _ = self.reply.send(response);
    }
}

// Usage
let (req, rx) = RpcRequest::new(GetUser { id: 42 });
tx.send(req).await?;
let user = rx.await?;
```

### See Also

- [async-mpsc-queue](#async-mpsc-queue) - Pair with oneshot for request-response
- [async-bounded-channel](#async-bounded-channel) - Channel sizing
- [async-select-racing](#async-select-racing) - Timeout patterns


## async-select-racing

> Use `select!` to race futures and handle the first to complete

### Why It Matters

Sometimes you need the first result from multiple futures—timeout vs operation, cancellation vs work, or competing alternatives. `tokio::select!` lets you race futures and handle whichever completes first, while properly cancelling the others.

### Bad

```rust
// Can't express "whichever finishes first"
async fn fetch_with_fallback() -> Data {
    match fetch_primary().await {
        Ok(data) => data,
        Err(_) => fetch_fallback().await.unwrap(),  // Sequential, not racing
    }
}

// Manual timeout is error-prone
async fn fetch_with_timeout() -> Option<Data> {
    let start = Instant::now();
    loop {
        if start.elapsed() > Duration::from_secs(5) {
            return None;
        }
        // How do we check timeout while awaiting?
    }
}
```

### Good

```rust
use tokio::select;

async fn fetch_with_timeout() -> Result<Data, Error> {
    select! {
        result = fetch_data() => result,
        _ = tokio::time::sleep(Duration::from_secs(5)) => {
            Err(Error::Timeout)
        }
    }
}

async fn fetch_with_fallback() -> Data {
    select! {
        result = fetch_primary() => {
            match result {
                Ok(data) => data,
                Err(_) => fetch_fallback().await.unwrap()
            }
        }
        _ = tokio::time::sleep(Duration::from_secs(1)) => {
            // Primary too slow, use fallback
            fetch_fallback().await.unwrap()
        }
    }
}
```

### select! Syntax

```rust
select! {
    // Pattern = future => handler
    result = async_operation() => {
        // Handle result
        println!("Got: {:?}", result);
    }
    
    // Can bind with pattern matching
    Ok(data) = fallible_operation() => {
        process(data);
    }
    
    // Conditional branches with if guards
    msg = channel.recv(), if should_receive => {
        handle_message(msg);
    }
    
    // else branch for when all futures are disabled
    else => {
        println!("All branches disabled");
    }
}
```

### Cancellation Behavior

```rust
async fn select_example() {
    select! {
        _ = operation_a() => {
            println!("A completed first");
            // operation_b() is dropped/cancelled
        }
        _ = operation_b() => {
            println!("B completed first");
            // operation_a() is dropped/cancelled
        }
    }
}

// Futures are cancelled at their next .await point
// For immediate cancellation, futures must be cancel-safe
```

### Biased Selection

```rust
// By default, select! randomly picks when multiple are ready
// Use biased mode for deterministic priority
select! {
    biased;  // Check branches in order
    
    msg = high_priority.recv() => handle_high(msg),
    msg = low_priority.recv() => handle_low(msg),
}

// Without biased, both channels have equal chance
// when both have messages ready
```

### Loop with select!

```rust
async fn event_loop(
    mut commands: mpsc::Receiver<Command>,
    shutdown: CancellationToken,
) {
    loop {
        select! {
            _ = shutdown.cancelled() => {
                println!("Shutting down");
                break;
            }
            Some(cmd) = commands.recv() => {
                process_command(cmd).await;
            }
            else => {
                // commands channel closed
                break;
            }
        }
    }
}
```

### Racing Multiple of Same Type

```rust
// Race multiple servers for fastest response
async fn fastest_response(servers: &[String]) -> Result<Response> {
    let futures = servers.iter()
        .map(|s| fetch_from(s))
        .collect::<Vec<_>>();
    
    // select! requires static branches, use select_all for dynamic
    let (result, _index, _remaining) = 
        futures::future::select_all(futures).await;
    
    result
}
```

### Common Patterns

```rust
// Timeout
select! {
    result = operation() => result,
    _ = sleep(Duration::from_secs(5)) => Err(Timeout),
}

// Cancellation
select! {
    result = operation() => result,
    _ = cancel_token.cancelled() => Err(Cancelled),
}

// Interval with cancellation
let mut interval = tokio::time::interval(Duration::from_secs(1));
loop {
    select! {
        _ = shutdown.cancelled() => break,
        _ = interval.tick() => {
            do_periodic_work().await;
        }
    }
}
```

### See Also

- [async-cancellation-token](#async-cancellation-token) - Cancellation patterns
- [async-join-parallel](#async-join-parallel) - All futures, not racing
- [async-bounded-channel](#async-bounded-channel) - Channel operations in select


## async-spawn-blocking

> Use `spawn_blocking` for CPU-intensive work

### Why It Matters

Async runtimes like Tokio use a small number of threads to handle many tasks. CPU-intensive or blocking operations on these threads starve other tasks. `spawn_blocking` moves such work to a dedicated thread pool.

### Bad

```rust
// BAD: Blocks the async runtime thread
async fn process_image(data: &[u8]) -> ProcessedImage {
    // CPU-intensive work on async thread!
    let resized = resize_image(data);      // Blocks!
    let compressed = compress(resized);     // Blocks!
    compressed
}

// BAD: Synchronous file I/O in async context
async fn read_large_file(path: &Path) -> Vec<u8> {
    std::fs::read(path).unwrap()  // Blocks the runtime!
}
```

### Good

```rust
use tokio::task;

// GOOD: Offload CPU work to blocking pool
async fn process_image(data: Vec<u8>) -> ProcessedImage {
    task::spawn_blocking(move || {
        let resized = resize_image(&data);
        compress(resized)
    })
    .await
    .expect("spawn_blocking failed")
}

// GOOD: Use async file I/O
async fn read_large_file(path: &Path) -> tokio::io::Result<Vec<u8>> {
    tokio::fs::read(path).await
}

// GOOD: Or spawn_blocking for unavoidable sync I/O
async fn read_with_sync_lib(path: PathBuf) -> Vec<u8> {
    task::spawn_blocking(move || {
        sync_library::read_file(&path)
    })
    .await
    .unwrap()
}
```

### What Counts as Blocking

```rust
// CPU-intensive operations
- Cryptographic operations (hashing, encryption)
- Image/video processing
- Compression/decompression
- Complex parsing
- Mathematical computations

// Blocking I/O
- std::fs operations
- Synchronous database drivers
- Synchronous HTTP clients
- Thread::sleep

// Example thresholds (rough guidelines):
// < 10µs: OK on async thread
// 10µs - 1ms: Consider spawn_blocking
// > 1ms: Definitely spawn_blocking
```

### Practical Examples

```rust
// Password hashing (CPU-intensive)
async fn hash_password(password: String) -> String {
    task::spawn_blocking(move || {
        bcrypt::hash(password, bcrypt::DEFAULT_COST).unwrap()
    })
    .await
    .unwrap()
}

// JSON parsing of large documents
async fn parse_large_json(data: String) -> serde_json::Value {
    task::spawn_blocking(move || {
        serde_json::from_str(&data).unwrap()
    })
    .await
    .unwrap()
}

// Compression
async fn compress_data(data: Vec<u8>) -> Vec<u8> {
    task::spawn_blocking(move || {
        let mut encoder = flate2::write::GzEncoder::new(
            Vec::new(),
            flate2::Compression::default(),
        );
        encoder.write_all(&data).unwrap();
        encoder.finish().unwrap()
    })
    .await
    .unwrap()
}
```

### spawn_blocking vs spawn

```rust
// spawn: Runs async code on runtime threads
tokio::spawn(async {
    // Async code here
    some_async_operation().await;
});

// spawn_blocking: Runs sync code on blocking thread pool
tokio::task::spawn_blocking(|| {
    // Synchronous, possibly CPU-intensive code
    heavy_computation();
});

// spawn_blocking returns JoinHandle that can be awaited
let result = tokio::task::spawn_blocking(|| {
    expensive_sync_operation()
}).await?;
```

### Rayon for Parallel CPU Work

```rust
// For parallel CPU work, consider Rayon inside spawn_blocking
async fn parallel_process(items: Vec<Item>) -> Vec<Output> {
    task::spawn_blocking(move || {
        use rayon::prelude::*;
        items.par_iter()
            .map(|item| cpu_intensive_transform(item))
            .collect()
    })
    .await
    .unwrap()
}
```

### See Also

- [async-tokio-fs](#async-tokio-fs) - Use tokio::fs for async file I/O
- [async-no-lock-await](#async-no-lock-await) - Don't hold locks across await


## async-tokio-fs

> Use `tokio::fs` instead of `std::fs` in async code

### Why It Matters

`std::fs` operations are blocking—they stop the current thread until the syscall completes. In async code, this blocks the executor thread, preventing it from running other tasks. `tokio::fs` wraps filesystem operations in `spawn_blocking`, keeping the executor responsive.

### Bad

```rust
async fn process_files(paths: &[PathBuf]) -> Result<Vec<String>> {
    let mut contents = Vec::new();
    
    for path in paths {
        // BLOCKS the entire executor thread!
        let data = std::fs::read_to_string(path)?;
        contents.push(data);
    }
    
    Ok(contents)
}

// While reading a file, NO other tasks can run on this thread
```

### Good

```rust
use tokio::fs;

async fn process_files(paths: &[PathBuf]) -> Result<Vec<String>> {
    let mut contents = Vec::new();
    
    for path in paths {
        // Non-blocking: allows other tasks to run
        let data = fs::read_to_string(path).await?;
        contents.push(data);
    }
    
    Ok(contents)
}

// Even better: concurrent reads
async fn process_files_concurrent(paths: &[PathBuf]) -> Result<Vec<String>> {
    let futures: Vec<_> = paths.iter()
        .map(|path| fs::read_to_string(path))
        .collect();
    
    futures::future::try_join_all(futures).await
}
```

### tokio::fs API

```rust
use tokio::fs;

// Reading
let contents = fs::read_to_string("file.txt").await?;
let bytes = fs::read("file.bin").await?;

// Writing
fs::write("output.txt", "contents").await?;

// File operations
let file = fs::File::open("file.txt").await?;
let file = fs::File::create("new.txt").await?;

// Directory operations
fs::create_dir("new_dir").await?;
fs::create_dir_all("nested/dir/path").await?;
fs::remove_dir("empty_dir").await?;
fs::remove_dir_all("dir_with_contents").await?;

// Metadata
let metadata = fs::metadata("file.txt").await?;
let canonical = fs::canonicalize("./relative").await?;

// Rename/remove
fs::rename("old.txt", "new.txt").await?;
fs::remove_file("file.txt").await?;

// Read directory
let mut entries = fs::read_dir("some_dir").await?;
while let Some(entry) = entries.next_entry().await? {
    println!("{}", entry.path().display());
}
```

### Async File I/O

```rust
use tokio::fs::File;
use tokio::io::{AsyncReadExt, AsyncWriteExt, AsyncBufReadExt, BufReader};

// Read with buffer
let mut file = File::open("large.bin").await?;
let mut buffer = vec![0u8; 4096];
let bytes_read = file.read(&mut buffer).await?;

// Read all
let mut contents = Vec::new();
file.read_to_end(&mut contents).await?;

// Write
let mut file = File::create("output.bin").await?;
file.write_all(b"data").await?;
file.flush().await?;

// Buffered line reading
let file = File::open("lines.txt").await?;
let reader = BufReader::new(file);
let mut lines = reader.lines();

while let Some(line) = lines.next_line().await? {
    println!("{}", line);
}
```

### When std::fs is Acceptable

```rust
// Startup/initialization (before async runtime)
fn main() {
    let config = std::fs::read_to_string("config.toml")
        .expect("config file required");
    
    tokio::runtime::Runtime::new()
        .unwrap()
        .block_on(run_with_config(config));
}

// Single-threaded current_thread runtime (less impact)
#[tokio::main(flavor = "current_thread")]
async fn main() {
    // Still prefer tokio::fs, but impact is lower
}

// When file operations are rare and quick
// (e.g., reading small config once per hour)
```

### Performance Considerations

```rust
// tokio::fs uses spawn_blocking internally
// For many small files, the overhead adds up

// Batch operations when possible
let paths: Vec<_> = entries.iter()
    .map(|e| e.path())
    .collect();

let contents = futures::future::try_join_all(
    paths.iter().map(|p| fs::read_to_string(p))
).await?;

// For heavy I/O, consider memory-mapped files
// (requires unsafe or mmap crate)
```

### See Also

- [async-spawn-blocking](#async-spawn-blocking) - How tokio::fs works internally
- [async-tokio-runtime](#async-tokio-runtime) - Runtime configuration
- [err-context-chain](#err-context-chain) - Adding path context to IO errors


## async-tokio-runtime

> Configure Tokio runtime appropriately for your workload

### Why It Matters

Tokio's default multi-threaded runtime isn't always optimal. CPU-bound work needs different configuration than IO-bound work. Incorrect configuration leads to poor performance, blocked workers, or resource exhaustion. Understanding runtime options lets you tune for your specific use case.

### Bad

```rust
// Default runtime for everything - not optimal
#[tokio::main]
async fn main() {
    // CPU-heavy work on async executor starves IO tasks
    for data in datasets {
        let result = heavy_computation(data).await;
    }
}

// Single-threaded when multi-threaded is needed
#[tokio::main(flavor = "current_thread")]
async fn main() {
    // Can't utilize multiple cores for concurrent tasks
    for _ in 0..1000 {
        tokio::spawn(async { /* IO work */ });
    }
}
```

### Good

```rust
// Multi-threaded for concurrent IO (default)
#[tokio::main]
async fn main() {
    // Good for many concurrent network connections
    let handles: Vec<_> = urls.iter()
        .map(|url| tokio::spawn(fetch(url.clone())))
        .collect();
    
    futures::future::join_all(handles).await;
}

// Current-thread for single-threaded scenarios
#[tokio::main(flavor = "current_thread")]
async fn main() {
    // Good for single-connection clients, simpler debugging
    let client = Client::new();
    client.run().await;
}

// Custom configuration
#[tokio::main(worker_threads = 4)]
async fn main() {
    // Limit to 4 worker threads
}

// Or manual setup for more control
fn main() {
    let runtime = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(4)
        .enable_all()
        .thread_name("my-worker")
        .build()
        .unwrap();
    
    runtime.block_on(async_main());
}
```

### Runtime Types

| Runtime | Use Case | Configuration |
|---------|----------|---------------|
| Multi-thread | IO-bound, many connections | `#[tokio::main]` (default) |
| Current-thread | CLI tools, tests, single connection | `flavor = "current_thread"` |
| Custom | Fine-tuned performance | `Builder::new_*()` |

### Worker Thread Tuning

```rust
use tokio::runtime::Builder;

// IO-bound: more threads than cores can help
let io_runtime = Builder::new_multi_thread()
    .worker_threads(num_cpus::get() * 2)  // IO can benefit from oversubscription
    .max_blocking_threads(32)              // For spawn_blocking calls
    .enable_io()
    .enable_time()
    .build()?;

// CPU-bound: match core count
let cpu_runtime = Builder::new_multi_thread()
    .worker_threads(num_cpus::get())       // No benefit from more than cores
    .build()?;
```

### Multiple Runtimes

```rust
// Separate runtimes for different workloads
struct App {
    io_runtime: Runtime,
    cpu_runtime: Runtime,
}

impl App {
    fn new() -> Self {
        Self {
            io_runtime: Builder::new_multi_thread()
                .worker_threads(8)
                .thread_name("io-worker")
                .build()
                .unwrap(),
            cpu_runtime: Builder::new_multi_thread()
                .worker_threads(4)
                .thread_name("cpu-worker")
                .build()
                .unwrap(),
        }
    }
    
    fn spawn_io<F>(&self, future: F) 
    where F: Future + Send + 'static, F::Output: Send + 'static 
    {
        self.io_runtime.spawn(future);
    }
    
    fn spawn_cpu<F>(&self, task: F) 
    where F: FnOnce() + Send + 'static 
    {
        self.cpu_runtime.spawn_blocking(task);
    }
}
```

### Runtime in Tests

```rust
// Single test runtime
#[tokio::test]
async fn test_single() {
    assert!(true);
}

// Multi-threaded test
#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn test_concurrent() {
    let (tx, rx) = tokio::sync::oneshot::channel();
    tokio::spawn(async move { tx.send(42).unwrap() });
    assert_eq!(rx.await.unwrap(), 42);
}

// Custom runtime in test
#[test]
fn test_with_custom_runtime() {
    let rt = Builder::new_current_thread().build().unwrap();
    rt.block_on(async {
        // test code
    });
}
```

### See Also

- [async-spawn-blocking](#async-spawn-blocking) - Handling blocking code
- [async-no-lock-await](#async-no-lock-await) - Avoiding lock issues
- [async-joinset-structured](#async-joinset-structured) - Managing spawned tasks


## async-try-join

> Use `try_join!` for concurrent fallible operations with early return on error

### Why It Matters

When running multiple fallible operations concurrently, `try_join!` returns `Err` as soon as any future fails, without waiting for the others. This provides fail-fast behavior while still running operations in parallel. For many operations, use `futures::future::try_join_all`.

### Bad

```rust
// Sequential - slow and no early return benefit
async fn fetch_all() -> Result<(A, B, C)> {
    let a = fetch_a().await?;  // If this fails, we wait for nothing
    let b = fetch_b().await?;  // But if this fails, we waited for A
    let c = fetch_c().await?;
    Ok((a, b, c))
}

// join! ignores errors
async fn fetch_all() -> (Result<A>, Result<B>, Result<C>) {
    let (a, b, c) = join!(fetch_a(), fetch_b(), fetch_c());
    // All complete even if first one failed
    (a, b, c)  // Now we have to handle three Results
}
```

### Good

```rust
use tokio::try_join;

async fn fetch_all() -> Result<(A, B, C)> {
    // Concurrent AND fail-fast
    let (a, b, c) = try_join!(
        fetch_a(),
        fetch_b(),
        fetch_c(),
    )?;
    
    Ok((a, b, c))
}

// For dynamic collections
use futures::future::try_join_all;

async fn fetch_users(ids: &[u64]) -> Result<Vec<User>> {
    let futures: Vec<_> = ids.iter()
        .map(|id| fetch_user(*id))
        .collect();
    
    try_join_all(futures).await
}
```

### Error Handling Patterns

```rust
// Different error types - need common error type
async fn mixed_operations() -> Result<(A, B), Error> {
    let (a, b) = try_join!(
        fetch_a().map_err(Error::from),  // Convert errors
        fetch_b().map_err(Error::from),
    )?;
    Ok((a, b))
}

// Collect all results, then handle errors
async fn all_or_nothing(ids: &[u64]) -> Result<Vec<User>> {
    try_join_all(ids.iter().map(|id| fetch_user(*id))).await
}

// Collect successes, log failures
async fn best_effort(ids: &[u64]) -> Vec<User> {
    let results = futures::future::join_all(
        ids.iter().map(|id| fetch_user(*id))
    ).await;
    
    results.into_iter()
        .filter_map(|r| match r {
            Ok(user) => Some(user),
            Err(e) => {
                log::warn!("Failed to fetch user: {}", e);
                None
            }
        })
        .collect()
}
```

### Cancellation Behavior

```rust
// try_join! cancels remaining futures on error
async fn with_cancellation() -> Result<()> {
    // If fetch_a() fails, fetch_b() and fetch_c() are dropped
    // But "dropped" != "immediately stopped"
    // They stop at their next .await point
    
    try_join!(
        async {
            fetch_a().await?;
            cleanup_a().await;  // May not run if other future fails
            Ok::<_, Error>(())
        },
        async {
            fetch_b().await?;
            cleanup_b().await;  // May not run if other future fails
            Ok::<_, Error>(())
        },
    )?;
    
    Ok(())
}

// For guaranteed cleanup, use Drop guards or explicit handling
```

### With Timeout

```rust
use tokio::time::{timeout, Duration};

async fn fetch_with_timeout() -> Result<(A, B)> {
    timeout(
        Duration::from_secs(10),
        try_join!(fetch_a(), fetch_b())
    )
    .await
    .map_err(|_| Error::Timeout)?
}

// Per-operation timeout
async fn individual_timeouts() -> Result<(A, B)> {
    try_join!(
        timeout(Duration::from_secs(5), fetch_a())
            .map_err(|_| Error::Timeout)
            .and_then(|r| async { r }),
        timeout(Duration::from_secs(5), fetch_b())
            .map_err(|_| Error::Timeout)
            .and_then(|r| async { r }),
    )
}
```

### try_join! vs FuturesUnordered

```rust
use futures::stream::{FuturesUnordered, StreamExt};

// try_join!: wait for all, fail fast
let (a, b, c) = try_join!(fa, fb, fc)?;

// FuturesUnordered: process as they complete
let mut futures = FuturesUnordered::new();
futures.push(fetch_a());
futures.push(fetch_b());
futures.push(fetch_c());

while let Some(result) = futures.next().await {
    match result {
        Ok(data) => process(data),
        Err(e) => return Err(e),  // Can fail fast manually
    }
}
```

### See Also

- [async-join-parallel](#async-join-parallel) - Non-fallible concurrent futures
- [async-select-racing](#async-select-racing) - First-to-complete semantics
- [err-question-mark](#err-question-mark) - Error propagation


## async-watch-latest

> Use `watch` channel for sharing the latest value with multiple observers

### Why It Matters

`watch` is optimized for scenarios where receivers only care about the most recent value, not the history of changes. Unlike `broadcast`, slow receivers don't lag—they simply skip intermediate values. This is perfect for configuration, state, or status that should always reflect the current situation.

### Bad

```rust
// Using broadcast when only latest value matters
let (tx, _) = broadcast::channel::<Config>(100);

// Receivers might process stale configs if they're slow
// And they waste time processing intermediate values

// Using mpsc with buffered stale values
let (tx, mut rx) = mpsc::channel::<Status>(100);
// Receiver might process outdated statuses
```

### Good

```rust
use tokio::sync::watch;

let (tx, rx) = watch::channel(Config::default());

// Multiple observers
let rx1 = rx.clone();
let rx2 = rx.clone();

// Observer 1: waits for changes
tokio::spawn(async move {
    let mut rx = rx1;
    while rx.changed().await.is_ok() {
        let config = rx.borrow();
        apply_config(&*config);
    }
});

// Observer 2: also sees all changes
tokio::spawn(async move {
    let mut rx = rx2;
    while rx.changed().await.is_ok() {
        let config = rx.borrow();
        log_config_change(&*config);
    }
});

// Update the value
tx.send(Config::new())?;
```

### watch Semantics

```rust
use tokio::sync::watch;

let (tx, mut rx) = watch::channel("initial");

// Immediate read - no waiting
assert_eq!(*rx.borrow(), "initial");

// Wait for change
tx.send("updated")?;
rx.changed().await?;
assert_eq!(*rx.borrow(), "updated");

// Multiple rapid updates - receiver sees latest
tx.send("v1")?;
tx.send("v2")?;
tx.send("v3")?;
rx.changed().await?;
assert_eq!(*rx.borrow(), "v3");  // Skipped v1, v2
```

### Configuration Reload Pattern

```rust
use tokio::sync::watch;
use std::sync::Arc;

struct AppConfig {
    log_level: Level,
    max_connections: usize,
}

async fn config_watcher(tx: watch::Sender<Arc<AppConfig>>) {
    loop {
        tokio::time::sleep(Duration::from_secs(60)).await;
        
        if let Ok(new_config) = reload_config_from_disk() {
            // Only notifies if value actually changed
            tx.send_if_modified(|current| {
                if *current != new_config {
                    *current = Arc::new(new_config);
                    true
                } else {
                    false
                }
            });
        }
    }
}

async fn worker(mut config_rx: watch::Receiver<Arc<AppConfig>>) {
    loop {
        tokio::select! {
            _ = config_rx.changed() => {
                let config = config_rx.borrow().clone();
                reconfigure(&config);
            }
            _ = do_work() => {}
        }
    }
}
```

### State Machine Updates

```rust
#[derive(Clone, PartialEq)]
enum ConnectionState {
    Disconnected,
    Connecting,
    Connected,
    Error(String),
}

struct Connection {
    state_tx: watch::Sender<ConnectionState>,
    state_rx: watch::Receiver<ConnectionState>,
}

impl Connection {
    async fn wait_connected(&mut self) -> Result<(), Error> {
        loop {
            let state = self.state_rx.borrow().clone();
            match state {
                ConnectionState::Connected => return Ok(()),
                ConnectionState::Error(e) => return Err(Error::Connection(e)),
                _ => {
                    self.state_rx.changed().await?;
                }
            }
        }
    }
}
```

### Borrow vs Clone

```rust
use tokio::sync::watch;

let (tx, rx) = watch::channel(vec![1, 2, 3]);

// borrow() returns Ref - must not hold across await
{
    let data = rx.borrow();
    println!("{:?}", *data);
}  // Ref dropped here

// For use across await, clone the data
let data = rx.borrow().clone();
some_async_operation().await;
use_data(&data);  // Safe

// Or use borrow_and_update() to mark as seen
let data = rx.borrow_and_update().clone();
```

### watch vs broadcast vs mpsc

| Feature | watch | broadcast | mpsc |
|---------|-------|-----------|------|
| Receivers | Multiple | Multiple | Single |
| Message delivery | Latest only | All messages | All messages |
| Slow receiver | Skips to latest | Lags/misses | Backpressure |
| Clone required | No | Yes | No |
| Best for | Config, status | Events | Work queues |

### See Also

- [async-broadcast-pubsub](#async-broadcast-pubsub) - When history matters
- [async-mpsc-queue](#async-mpsc-queue) - Work queue patterns
- [async-cancellation-token](#async-cancellation-token) - Related pattern
