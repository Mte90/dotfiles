# Anti-Patterns

> Loaded on demand from `SKILL.md` — one rule per `## <rule-id>` section.


## anti-clone-excessive

> Don't clone when borrowing works

### Why It Matters

`.clone()` allocates memory and copies data. When you only need to read data, borrowing (`&T`) is free. Excessive cloning wastes memory, CPU cycles, and often indicates misunderstanding of ownership.

### Bad

```rust
// Cloning to pass to a function that only reads
fn print_name(name: String) {  // Takes ownership
    println!("{}", name);
}
let name = "Alice".to_string();
print_name(name.clone());  // Unnecessary clone
print_name(name);          // Could have just done this

// Cloning in a loop
for item in items.clone() {  // Clones entire Vec
    process(&item);
}

// Cloning for comparison
if input.clone() == expected {  // Pointless clone
    // ...
}

// Cloning struct fields
fn get_name(&self) -> String {
    self.name.clone()  // Caller might not need ownership
}
```

### Good

```rust
// Accept reference if only reading
fn print_name(name: &str) {
    println!("{}", name);
}
let name = "Alice".to_string();
print_name(&name);  // Borrow, no clone

// Iterate by reference
for item in &items {
    process(item);
}

// Compare by reference
if input == expected {
    // ...
}

// Return reference when possible
fn get_name(&self) -> &str {
    &self.name
}
```

### When to Clone

```rust
// Need owned data for async move
let name = name.clone();
tokio::spawn(async move {
    process(name).await;
});

// Storing in a new struct
struct Cache {
    data: String,
}
impl Cache {
    fn store(&mut self, data: &str) {
        self.data = data.to_string();  // Must own
    }
}

// Multiple owners (use Arc instead if frequent)
let shared = data.clone();
thread::spawn(move || use_data(shared));
```

### Alternatives to Clone

| Instead of | Use |
|------------|-----|
| `s.clone()` for reading | `&s` |
| `vec.clone()` for iteration | `&vec` or `vec.iter()` |
| `Clone` for shared ownership | `Arc<T>` |
| Clone in hot loop | Move outside loop |
| `s.to_string()` from `&str` | Accept `&str` if possible |

### Pattern: Clone on Write

```rust
use std::borrow::Cow;

fn process(input: Cow<str>) -> Cow<str> {
    if needs_modification(&input) {
        Cow::Owned(modify(&input))  // Clone only if needed
    } else {
        input  // No clone
    }
}
```

### Detecting Excessive Clones

```toml
### Cargo.toml
[lints.clippy]
clone_on_copy = "warn"
clone_on_ref_ptr = "warn"
redundant_clone = "warn"
```

### See Also

- [own-borrow-over-clone](#own-borrow-over-clone) - Borrowing patterns
- [own-cow-conditional](#own-cow-conditional) - Clone on write
- [own-arc-shared](#own-arc-shared) - Shared ownership


## anti-collect-intermediate

> Don't collect intermediate iterators

### Why It Matters

Each `.collect()` allocates a new collection. Collecting intermediate results in a chain creates unnecessary allocations and prevents iterator fusion. Keep the chain lazy; collect only at the end.

### Bad

```rust
// Three allocations, three passes
fn process(data: Vec<i32>) -> Vec<i32> {
    let step1: Vec<_> = data.into_iter()
        .filter(|x| *x > 0)
        .collect();
    
    let step2: Vec<_> = step1.into_iter()
        .map(|x| x * 2)
        .collect();
    
    step2.into_iter()
        .filter(|x| *x < 100)
        .collect()
}

// Collecting just to check length
fn has_valid_items(items: &[Item]) -> bool {
    let valid: Vec<_> = items.iter()
        .filter(|i| i.is_valid())
        .collect();
    !valid.is_empty()
}

// Collecting to iterate again
fn sum_valid(items: &[Item]) -> i64 {
    let valid: Vec<_> = items.iter()
        .filter(|i| i.is_valid())
        .collect();
    valid.iter().map(|i| i.value).sum()
}
```

### Good

```rust
// Single allocation, single pass
fn process(data: Vec<i32>) -> Vec<i32> {
    data.into_iter()
        .filter(|x| *x > 0)
        .map(|x| x * 2)
        .filter(|x| *x < 100)
        .collect()
}

// No allocation - iterator short-circuits
fn has_valid_items(items: &[Item]) -> bool {
    items.iter().any(|i| i.is_valid())
}

// No intermediate allocation
fn sum_valid(items: &[Item]) -> i64 {
    items.iter()
        .filter(|i| i.is_valid())
        .map(|i| i.value)
        .sum()
}
```

### When Collection Is Needed

```rust
// Need to iterate twice
let valid: Vec<_> = items.iter()
    .filter(|i| i.is_valid())
    .collect();
let count = valid.len();
for item in &valid {
    process(item);
}

// Need to sort (requires concrete collection)
let mut sorted: Vec<_> = items.iter()
    .filter(|i| i.is_active())
    .collect();
sorted.sort_by_key(|i| i.priority);

// Need random access
let indexed: Vec<_> = items.iter().collect();
let middle = indexed.get(indexed.len() / 2);
```

### Iterator Methods That Avoid Collection

| Instead of Collecting to... | Use |
|-----------------------------|-----|
| Check if empty | `.any(|_| true)` or `.next().is_some()` |
| Check if any match | `.any(predicate)` |
| Check if all match | `.all(predicate)` |
| Count elements | `.count()` |
| Sum elements | `.sum()` |
| Find first | `.find(predicate)` |
| Get first | `.next()` |
| Get last | `.last()` |

### Pattern: Deferred Collection

```rust
// Return iterator, let caller collect if needed
fn valid_items(items: &[Item]) -> impl Iterator<Item = &Item> {
    items.iter().filter(|i| i.is_valid())
}

// Caller decides
let count = valid_items(&items).count();  // No collection
let vec: Vec<_> = valid_items(&items).collect();  // Collection when needed
```

### Comparison

| Pattern | Allocations | Passes |
|---------|-------------|--------|
| `.collect()` each step | N | N |
| Single chain, one `.collect()` | 1 | 1 |
| No collection (streaming) | 0 | 1 |

### See Also

- [perf-collect-once](#perf-collect-once) - Single collect
- [perf-iter-lazy](#perf-iter-lazy) - Lazy evaluation
- [perf-iter-over-index](#perf-iter-over-index) - Iterator patterns


## anti-empty-catch

> Don't silently ignore errors

### Why It Matters

Empty error handling (`if let Err(_) = ...`, `let _ = result`, `.ok()`) silently discards errors. Failures go unnoticed, bugs hide, and debugging becomes impossible. Every error deserves acknowledgment—even if just logging.

### Bad

```rust
// Silently ignores errors
let _ = write_to_file(data);

// Discards error completely
if let Err(_) = send_notification() {
    // Nothing - error vanishes
}

// Converts Result to Option, losing error info
let value = risky_operation().ok();

// Match with empty arm
match database.save(record) {
    Ok(_) => println!("saved"),
    Err(_) => {}  // Silent failure
}

// Ignored in loop
for item in items {
    let _ = process(item);  // Failures unnoticed
}
```

### Good

```rust
// Log the error
if let Err(e) = write_to_file(data) {
    error!("failed to write file: {}", e);
}

// Propagate if possible
send_notification()?;

// Or handle explicitly
match send_notification() {
    Ok(_) => info!("notification sent"),
    Err(e) => warn!("notification failed: {}", e),
}

// Collect errors in batch operations
let (successes, failures): (Vec<_>, Vec<_>) = items
    .into_iter()
    .map(process)
    .partition(Result::is_ok);

if !failures.is_empty() {
    warn!("{} items failed to process", failures.len());
}

// Explicit documentation when ignoring
// Intentionally ignored: cleanup failure is not critical
let _ = cleanup_temp_file();  // Add comment explaining why
```

### Acceptable Ignoring (Documented)

```rust
// Close errors often ignored, but document it
// INTENTIONAL: TCP close errors are not actionable
let _ = stream.shutdown(Shutdown::Both);

// Mutex poisoning recovery
// INTENTIONAL: We'll reset the state anyway
let guard = mutex.lock().unwrap_or_else(|e| e.into_inner());
```

### Pattern: Collect and Report

```rust
fn process_batch(items: Vec<Item>) -> BatchResult {
    let mut errors = Vec::new();
    
    for item in items {
        if let Err(e) = process_item(&item) {
            errors.push((item.id, e));
        }
    }
    
    if errors.is_empty() {
        BatchResult::AllSucceeded
    } else {
        BatchResult::PartialFailure(errors)
    }
}
```

### Pattern: Best-Effort Operations

```rust
// Metrics/telemetry can fail without affecting main flow
fn report_metric(name: &str, value: f64) {
    if let Err(e) = metrics_client.record(name, value) {
        // Log but don't propagate - metrics are not critical
        debug!("failed to record metric {}: {}", name, e);
    }
}
```

### Clippy Lint

```toml
[lints.clippy]
let_underscore_drop = "warn"
ignored_unit_patterns = "warn"
```

### Decision Guide

| Situation | Action |
|-----------|--------|
| Critical operation | `?` or handle explicitly |
| Non-critical, debugging needed | Log the error |
| Truly ignorable (rare) | `let _ =` with comment |
| Batch operation | Collect errors, report |

### See Also

- [err-result-over-panic](#err-result-over-panic) - Proper error handling
- [err-context-chain](#err-context-chain) - Adding context
- [anti-unwrap-abuse](#anti-unwrap-abuse) - Unwrap issues


## anti-expect-lazy

> Don't use expect for recoverable errors

### Why It Matters

`.expect()` panics with a custom message, but it's still a panic. Using it for errors that could reasonably occur in production (network failures, file not found, invalid input) crashes the program instead of handling the error gracefully.

Reserve `.expect()` for programming errors where panic is appropriate.

### Bad

```rust
// Network failures are expected - don't panic
let response = client.get(url).await.expect("failed to fetch");

// Files might not exist
let config = fs::read_to_string("config.toml").expect("config not found");

// User input can be invalid
let age: u32 = input.parse().expect("invalid age");

// Database queries can fail
let user = db.find_user(id).await.expect("user not found");
```

### Good

```rust
// Handle recoverable errors properly
let response = client.get(url).await
    .context("failed to fetch URL")?;

// Return error if file doesn't exist
let config = fs::read_to_string("config.toml")
    .context("failed to read config file")?;

// Validate and return error
let age: u32 = input.parse()
    .map_err(|_| Error::InvalidInput("age must be a number"))?;

// Handle missing data
let user = db.find_user(id).await?
    .ok_or(Error::NotFound("user"))?;
```

### When expect() Is Appropriate

Use `.expect()` for invariants that indicate bugs:

```rust
// Mutex poisoning indicates a bug elsewhere
let guard = mutex.lock().expect("mutex poisoned");

// Regex is known valid at compile time
let re = Regex::new(r"^\d{4}$").expect("invalid regex");

// Thread spawn failure is unrecoverable
let handle = thread::spawn(|| work()).expect("failed to spawn thread");

// Static data that must be valid
let config: Config = toml::from_str(EMBEDDED_CONFIG)
    .expect("embedded config is invalid");
```

### Pattern: expect() vs unwrap()

```rust
// unwrap: no context, hard to debug
let x = option.unwrap();

// expect: gives context, still panics
let x = option.expect("value should exist after validation");

// ?: proper error handling
let x = option.ok_or(Error::MissingValue)?;
```

### Decision Guide

| Situation | Use |
|-----------|-----|
| User input | `?` with error |
| File/network I/O | `?` with error |
| Database operations | `?` with error |
| Parsed constants | `.expect()` |
| Thread/mutex operations | `.expect()` |
| After validation check | `.expect()` with explanation |
| Never expected to fail | `.expect()` documenting invariant |

### See Also

- [err-expect-bugs-only](#err-expect-bugs-only) - When to use expect
- [err-no-unwrap-prod](#err-no-unwrap-prod) - Avoiding unwrap
- [anti-unwrap-abuse](#anti-unwrap-abuse) - Unwrap anti-pattern


## anti-format-hot-path

> Don't use format! in hot paths

### Why It Matters

`format!()` allocates a new `String` every call. In hot paths (loops, frequently called functions), this creates allocation churn that impacts performance. Pre-allocate, reuse buffers, or use `write!()` to an existing buffer.

### Bad

```rust
// format! in loop - allocates every iteration
fn log_events(events: &[Event]) {
    for event in events {
        let message = format!("[{}] {}: {}", event.level, event.source, event.message);
        logger.log(&message);
    }
}

// format! for building parts
fn build_url(base: &str, path: &str, params: &[(&str, &str)]) -> String {
    let mut url = format!("{}{}", base, path);
    for (key, value) in params {
        url = format!("{}{}={}&", url, key, value);  // New allocation each time
    }
    url
}

// format! for simple concatenation
fn greet(name: &str) -> String {
    format!("Hello, {}!", name)  // Fine for one-off, bad if called 1M times
}
```

### Good

```rust
use std::fmt::Write;

// Reuse buffer across iterations
fn log_events(events: &[Event]) {
    let mut buffer = String::with_capacity(256);
    for event in events {
        buffer.clear();
        write!(buffer, "[{}] {}: {}", event.level, event.source, event.message).unwrap();
        logger.log(&buffer);
    }
}

// Build incrementally in single buffer
fn build_url(base: &str, path: &str, params: &[(&str, &str)]) -> String {
    let mut url = String::with_capacity(base.len() + path.len() + params.len() * 20);
    url.push_str(base);
    url.push_str(path);
    for (key, value) in params {
        write!(url, "{}={}&", key, value).unwrap();
    }
    url
}

// For truly hot paths, avoid allocation entirely
fn greet_to_buf(name: &str, buffer: &mut String) {
    buffer.clear();
    buffer.push_str("Hello, ");
    buffer.push_str(name);
    buffer.push('!');
}
```

### Comparison

| Approach | Allocations | Performance |
|----------|-------------|-------------|
| `format!()` in loop | N | Slow |
| `write!()` to reused buffer | 1 | Fast |
| `push_str()` + `push()` | 1 | Fastest |
| Pre-sized `String::with_capacity()` | 1 (no realloc) | Fast |

### When format! Is Fine

```rust
// One-time initialization
let config_path = format!("{}/config.toml", home_dir);

// Error messages (not hot path)
return Err(format!("invalid input: {}", input));

// Debug output
println!("Debug: {:?}", value);
```

### Pattern: Formatter Buffer Pool

```rust
use std::cell::RefCell;

thread_local! {
    static BUFFER: RefCell<String> = RefCell::new(String::with_capacity(256));
}

fn format_event(event: &Event) -> String {
    BUFFER.with(|buf| {
        let mut buf = buf.borrow_mut();
        buf.clear();
        write!(buf, "[{}] {}", event.level, event.message).unwrap();
        buf.clone()  // Still one allocation per call, but no parsing
    })
}
```

### Pattern: Display Implementation

```rust
struct Event {
    level: Level,
    message: String,
}

impl std::fmt::Display for Event {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "[{}] {}", self.level, self.message)
    }
}

// Caller controls allocation
let mut buf = String::new();
write!(buf, "{}", event)?;
```

### Clippy Lint

```toml
[lints.clippy]
format_in_format_args = "warn"
```

### See Also

- [mem-avoid-format](#mem-avoid-format) - Avoiding format
- [mem-write-over-format](#mem-write-over-format) - Using write!
- [mem-reuse-collections](#mem-reuse-collections) - Buffer reuse


## anti-index-over-iter

> Don't use indexing when iterators work

### Why It Matters

Manual indexing (`for i in 0..len`) requires bounds checks on every access, prevents SIMD optimization, and introduces off-by-one error risks. Iterators eliminate these issues and are more idiomatic Rust.

### Bad

```rust
// Manual indexing - bounds checked every access
fn sum_squares(data: &[i32]) -> i64 {
    let mut result = 0i64;
    for i in 0..data.len() {
        result += (data[i] as i64) * (data[i] as i64);
    }
    result
}

// Index-based with multiple arrays
fn dot_product(a: &[f64], b: &[f64]) -> f64 {
    let mut sum = 0.0;
    for i in 0..a.len().min(b.len()) {
        sum += a[i] * b[i];
    }
    sum
}

// Mutation with indices
fn normalize(data: &mut [f64]) {
    let max = data.iter().cloned().fold(0.0, f64::max);
    for i in 0..data.len() {
        data[i] /= max;
    }
}
```

### Good

```rust
// Iterator - no bounds checks, SIMD-friendly
fn sum_squares(data: &[i32]) -> i64 {
    data.iter()
        .map(|&x| (x as i64) * (x as i64))
        .sum()
}

// Zip - handles length mismatch automatically
fn dot_product(a: &[f64], b: &[f64]) -> f64 {
    a.iter()
        .zip(b.iter())
        .map(|(&x, &y)| x * y)
        .sum()
}

// Mutable iteration
fn normalize(data: &mut [f64]) {
    let max = data.iter().cloned().fold(0.0, f64::max);
    for x in data.iter_mut() {
        *x /= max;
    }
}
```

### When Indices Are Needed

Sometimes you genuinely need indices:

```rust
// Need index in output
for (i, item) in items.iter().enumerate() {
    println!("{}: {}", i, item);
}

// Non-sequential access
for i in (0..len).step_by(2) {
    swap(&mut data[i], &mut data[i + 1]);
}

// Multi-dimensional iteration
for i in 0..rows {
    for j in 0..cols {
        matrix[i][j] = i * cols + j;
    }
}
```

### Comparison

| Pattern | Bounds Checks | SIMD | Safety |
|---------|---------------|------|--------|
| `for i in 0..len { data[i] }` | Every access | Limited | Off-by-one risk |
| `for x in &data` | None | Good | Safe |
| `for x in data.iter()` | None | Good | Safe |
| `data.iter().enumerate()` | None | Good | Safe |

### Common Conversions

| Index Pattern | Iterator Pattern |
|---------------|------------------|
| `for i in 0..v.len()` | `for x in &v` |
| `v[0]` | `v.first()` |
| `v[v.len()-1]` | `v.last()` |
| `for i in 0..a.len() { a[i] + b[i] }` | `a.iter().zip(&b)` |
| `for i in 0..v.len() { v[i] *= 2 }` | `for x in &mut v { *x *= 2 }` |

### Performance Note

```rust
// Iterator version can auto-vectorize
let sum: i32 = data.iter().sum();

// Manual indexing prevents vectorization
let mut sum = 0;
for i in 0..data.len() {
    sum += data[i];
}
```

### See Also

- [perf-iter-over-index](#perf-iter-over-index) - Performance details
- [opt-bounds-check](#opt-bounds-check) - Bounds check elimination
- [perf-iter-lazy](#perf-iter-lazy) - Lazy iterators


## anti-lock-across-await

> Don't hold locks across await points

### Why It Matters

Holding a `Mutex` or `RwLock` guard across an `.await` causes the lock to be held while the task is suspended. Other tasks waiting for the lock block indefinitely. With `std::sync::Mutex`, this is even worse—it can deadlock the entire runtime.

### Bad

```rust
use std::sync::Mutex;
use tokio::sync::Mutex as AsyncMutex;

// DEADLOCK RISK: std::sync::Mutex held across await
async fn bad_std_mutex(data: &Mutex<Vec<i32>>) {
    let mut guard = data.lock().unwrap();
    do_async_work().await;  // Lock held during await!
    guard.push(42);
}

// BLOCKS OTHER TASKS: tokio Mutex held across await
async fn bad_async_mutex(data: &AsyncMutex<Vec<i32>>) {
    let mut guard = data.lock().await;
    slow_network_call().await;  // Lock held for entire call!
    guard.push(42);
}
```

### Good

```rust
use std::sync::Mutex;
use tokio::sync::Mutex as AsyncMutex;

// Release lock before await
async fn good_approach(data: &Mutex<Vec<i32>>) {
    let value = {
        let guard = data.lock().unwrap();
        guard.last().copied()  // Extract what you need
    };  // Lock released here
    
    let result = do_async_work(value).await;
    
    {
        let mut guard = data.lock().unwrap();
        guard.push(result);
    }
}

// Minimize lock scope with async mutex
async fn good_async_mutex(data: &AsyncMutex<Vec<i32>>, item: i32) {
    // Quick lock, quick release
    data.lock().await.push(item);
    
    // Async work without lock
    let result = slow_network_call().await;
    
    // Quick lock again
    data.lock().await.push(result);
}
```

### Pattern: Clone Before Await

```rust
async fn process(data: &AsyncMutex<Config>) -> Result<()> {
    // Clone inside lock scope
    let config = data.lock().await.clone();
    
    // Now use config freely across awaits
    let result = fetch_data(&config.url).await?;
    process_result(&config, result).await?;
    
    Ok(())
}
```

### Pattern: Restructure to Avoid Lock

```rust
// Instead of locking a shared map
struct Service {
    data: AsyncMutex<HashMap<String, Data>>,
}

// Use channels or owned data
struct BetterService {
    // Each task owns its data via channels
    sender: mpsc::Sender<Request>,
}

impl BetterService {
    async fn request(&self, key: String) -> Data {
        let (tx, rx) = oneshot::channel();
        self.sender.send(Request { key, respond: tx }).await?;
        rx.await?
    }
}
```

### What Can Cross Await

| Type | Safe Across Await? |
|------|--------------------|
| `std::sync::Mutex` guard | **NO** - can deadlock |
| `std::sync::RwLock` guard | **NO** - can deadlock |
| `tokio::sync::Mutex` guard | Allowed but blocks tasks |
| `tokio::sync::RwLock` guard | Allowed but blocks tasks |
| Owned values | Yes |
| `Arc<T>` | Yes |
| References | Depends on lifetime |

### Detection

```toml
### Cargo.toml
[lints.clippy]
await_holding_lock = "deny"
await_holding_refcell_ref = "deny"
```

### See Also

- [async-no-lock-await](#async-no-lock-await) - Async lock patterns
- [async-clone-before-await](#async-clone-before-await) - Clone pattern
- [own-mutex-interior](#own-mutex-interior) - Mutex usage


## anti-over-abstraction

> Don't over-abstract with excessive generics

### Why It Matters

Generics and traits are powerful but come at a cost: compile times, binary size, and cognitive load. Over-abstraction—making everything generic "for flexibility"—often adds complexity without benefit. Start concrete; generalize when you have real use cases.

### Bad

```rust
// Overly generic for a simple function
fn add<T, U, R>(a: T, b: U) -> R
where
    T: Into<R>,
    U: Into<R>,
    R: std::ops::Add<Output = R>,
{
    a.into() + b.into()
}

// Just call add(1, 2) - why make it this complex?

// Trait explosion
trait Readable {}
trait Writable {}
trait ReadWritable: Readable + Writable {}
trait AsyncReadable {}
trait AsyncWritable {}
trait AsyncReadWritable: AsyncReadable + AsyncWritable {}

// Abstract factory pattern (Java flashback)
trait Factory<T> {
    fn create(&self) -> T;
}
trait FactoryFactory<F: Factory<T>, T> {
    fn create_factory(&self) -> F;
}
```

### Good

```rust
// Concrete implementation - clear and simple
fn add_i32(a: i32, b: i32) -> i32 {
    a + b
}

// Generic when actually needed (e.g., library code)
fn add<T: std::ops::Add<Output = T>>(a: T, b: T) -> T {
    a + b
}

// Simple traits for actual polymorphism needs
trait Storage {
    fn save(&self, key: &str, value: &[u8]) -> Result<(), Error>;
    fn load(&self, key: &str) -> Result<Vec<u8>, Error>;
}

// Concrete types first
struct FileStorage { path: PathBuf }
struct MemoryStorage { data: HashMap<String, Vec<u8>> }
```

### Signs of Over-Abstraction

| Sign | Symptom |
|------|---------|
| Single implementation | Generic trait with only one impl |
| Type parameter soup | `T, U, V, W` everywhere |
| Marker traits | Traits with no methods |
| Deep trait bounds | `where T: A + B + C + D + E` |
| Phantom generics | Type parameters not used meaningfully |

### When to Generalize

Generalize when:
- You have 2+ concrete types that share behavior
- You're writing library code for public consumption
- Performance requires static dispatch
- The abstraction simplifies the API

Don't generalize when:
- You "might need it later" (YAGNI)
- Only one type will ever implement it
- It makes code harder to understand

### Rule of Three

Wait until you have three similar concrete implementations before abstracting:

```rust
// Version 1: Just FileStorage
struct FileStorage { /* ... */ }

// Version 2: Added MemoryStorage, similar interface
struct MemoryStorage { /* ... */ }

// Version 3: Now Redis too - time to abstract
trait Storage {
    fn save(&self, key: &str, value: &[u8]) -> Result<()>;
    fn load(&self, key: &str) -> Result<Vec<u8>>;
}
```

### Prefer Concrete Types in Private Code

```rust
// Internal function - concrete type is fine
fn process_orders(db: &PostgresDb, orders: Vec<Order>) { }

// Public API - might benefit from abstraction
pub fn process_orders<S: Storage>(storage: &S, orders: Vec<Order>) { }
```

### See Also

- [type-generic-bounds](#type-generic-bounds) - Minimal bounds
- [api-sealed-trait](#api-sealed-trait) - Controlled extension
- [anti-type-erasure](#anti-type-erasure) - When Box<dyn> is wrong


## anti-panic-expected

> Don't panic on expected or recoverable errors

### Why It Matters

Panics crash the program. They're for unrecoverable situations—bugs, corrupted state, invariant violations. Using panic for expected conditions (network failures, file not found, invalid input) makes programs fragile and forces callers to catch panics or die.

Use `Result` for recoverable errors.

### Bad

```rust
// Network failures are expected
fn fetch_data(url: &str) -> Data {
    let response = reqwest::blocking::get(url)
        .expect("network error");  // Crashes on timeout
    response.json().expect("invalid json")  // Crashes on bad response
}

// User input is often invalid
fn parse_config(input: &str) -> Config {
    toml::from_str(input).expect("invalid config")  // Crashes on typo
}

// Files may not exist
fn load_settings() -> Settings {
    let content = fs::read_to_string("settings.json")
        .expect("settings not found");  // Crashes if missing
    serde_json::from_str(&content).expect("invalid settings")
}

// Custom panic for validation
fn process_age(age: i32) {
    if age < 0 {
        panic!("age cannot be negative");  // Should return error
    }
}
```

### Good

```rust
// Return errors for expected failures
fn fetch_data(url: &str) -> Result<Data, FetchError> {
    let response = reqwest::blocking::get(url)
        .context("failed to connect")?;
    let data = response.json()
        .context("failed to parse response")?;
    Ok(data)
}

// Validate and return Result
fn parse_config(input: &str) -> Result<Config, ConfigError> {
    toml::from_str(input).map_err(ConfigError::Parse)
}

// Handle missing files gracefully
fn load_settings() -> Result<Settings, SettingsError> {
    let content = fs::read_to_string("settings.json")?;
    let settings = serde_json::from_str(&content)?;
    Ok(settings)
}

// Return error for validation failure
fn process_age(age: i32) -> Result<(), ValidationError> {
    if age < 0 {
        return Err(ValidationError::NegativeAge);
    }
    Ok(())
}
```

### When to Panic

Panic IS appropriate for:

```rust
// Bug detection - invariant violated
fn get_unchecked(&self, index: usize) -> &T {
    assert!(index < self.len(), "index out of bounds - this is a bug");
    unsafe { self.data.get_unchecked(index) }
}

// Unrecoverable state
fn init() {
    if !CAN_PROCEED {
        panic!("system requirements not met");
    }
}

// Tests
#[test]
fn test_fails() {
    panic!("expected panic in test");
}
```

### Decision Guide

| Condition | Action |
|-----------|--------|
| Invalid user input | Return `Err` |
| Network failure | Return `Err` |
| File not found | Return `Err` |
| Malformed data | Return `Err` |
| Bug/impossible state | `panic!` or `unreachable!` |
| Failed assertion in test | `panic!` |
| Unrecoverable init failure | `panic!` |

### Anti-pattern: panic! for Control Flow

```rust
// BAD: Using panic for control flow
fn find_or_die(items: &[Item], id: u64) -> &Item {
    items.iter()
        .find(|i| i.id == id)
        .unwrap_or_else(|| panic!("item {} not found", id))
}

// GOOD: Return Option or Result
fn find(items: &[Item], id: u64) -> Option<&Item> {
    items.iter().find(|i| i.id == id)
}
```

### See Also

- [err-result-over-panic](#err-result-over-panic) - Use Result
- [anti-unwrap-abuse](#anti-unwrap-abuse) - Unwrap anti-pattern
- [err-expect-bugs-only](#err-expect-bugs-only) - When to expect


## anti-premature-optimize

> Don't optimize before profiling

### Why It Matters

Premature optimization wastes time, complicates code, and often targets the wrong bottlenecks. Most code isn't performance-critical; the hot 10% matters. Profile first, then optimize the actual bottlenecks with data-driven decisions.

### Bad

```rust
// "Optimizing" without measurement
fn sum(data: &[i32]) -> i32 {
    // Using unsafe "for performance" without profiling
    unsafe {
        let mut sum = 0;
        for i in 0..data.len() {
            sum += *data.get_unchecked(i);
        }
        sum
    }
}

// Complex caching with no evidence it's needed
lazy_static! {
    static ref CACHE: RwLock<HashMap<String, Arc<Result>>> = 
        RwLock::new(HashMap::new());
}

// Hand-rolled data structures "for speed"
struct MyVec<T> {
    ptr: *mut T,
    len: usize,
    cap: usize,
}
```

### Good

```rust
// Simple, idiomatic - let compiler optimize
fn sum(data: &[i32]) -> i32 {
    data.iter().sum()
}

// Profile, then optimize if needed
fn sum_optimized(data: &[i32]) -> i32 {
    // After profiling showed this is a bottleneck,
    // we measured that manual SIMD gives 3x speedup
    #[cfg(target_arch = "x86_64")]
    {
        // SIMD implementation with benchmark data
    }
    #[cfg(not(target_arch = "x86_64"))]
    {
        data.iter().sum()
    }
}

// Use standard library - it's well-optimized
let cache: HashMap<String, Result> = HashMap::new();
```

### Profiling Workflow

```bash
### 1. Write correct code first
cargo build --release

### 2. Profile with real workloads
cargo flamegraph --bin my_app -- --real-args
### or
cargo bench

### 3. Identify hotspots (top 10% of time)

### 4. Measure before optimizing
### 5. Optimize ONE thing
### 6. Measure after - verify improvement
### 7. Repeat if still slow
```

### Optimization Principles

| Do | Don't |
|----|-------|
| Profile first | Guess at bottlenecks |
| Optimize hotspots | Optimize everything |
| Measure improvement | Assume it's faster |
| Keep it simple | Add complexity speculatively |
| Trust the compiler | Outsmart the compiler |

### When to Optimize

```rust
// AFTER profiling shows this is 40% of runtime
#[inline]
fn hot_function(data: &[u8]) -> u64 {
    // Optimized implementation justified by benchmarks
}

// Clear, measurable benefit documented
/// Pre-allocated buffer for repeated formatting.
/// Benchmarks show 3x speedup for >1000 calls/sec workloads.
struct FormatterPool {
    buffers: Vec<String>,
}
```

### Common Premature Optimizations

| Premature | Reality |
|-----------|---------|
| `#[inline(always)]` everywhere | Compiler usually knows better |
| `unsafe` for bounds check removal | Iterator does this safely |
| Custom allocator | Default is usually fine |
| Object pooling | Allocator is fast enough |
| Manual SIMD | Auto-vectorization works |

### Profile Tools

```bash
### Sampling profiler
perf record ./target/release/app && perf report

### Flamegraph
cargo install flamegraph
cargo flamegraph

### Criterion benchmarks
cargo bench

### Memory profiling
valgrind --tool=massif ./target/release/app
```

### Document Optimizations

```rust
/// Lookup table for fast character classification.
/// 
/// # Performance
/// 
/// Benchmarked with criterion (benchmarks/char_class.rs):
/// - Table lookup: 2.3ns/op
/// - Match statement: 8.7ns/op
/// 
/// Justified for hot path in parser (called 10M+ times).
static CHAR_CLASS: [CharClass; 256] = [/* ... */];
```

### See Also

- [perf-profile-first](#perf-profile-first) - Profile before optimize
- [test-criterion-bench](#test-criterion-bench) - Benchmarking
- [opt-inline-small](#opt-inline-small) - Inline guidelines


## anti-string-for-str

> Don't accept &String when &str works

### Why It Matters

`&String` is strictly less flexible than `&str`. A `&str` can be created from `String`, `&str`, literals, and slices. A `&String` requires exactly a `String`. This forces callers to allocate when they might not need to.

### Bad

```rust
// Forces callers to have a String
fn greet(name: &String) {
    println!("Hello, {}", name);
}

// Caller must allocate
greet(&"Alice".to_string());  // Unnecessary allocation
greet(&name);                 // Only works if name is String

// In struct
struct Config {
    name: String,
}

impl Config {
    fn set_name(&mut self, name: &String) {  // Too restrictive
        self.name = name.clone();
    }
}
```

### Good

```rust
// Accept &str - works with String, &str, literals
fn greet(name: &str) {
    println!("Hello, {}", name);
}

// All these work
greet("Alice");           // String literal
greet(&name);             // &String coerces to &str
greet(name.as_str());     // Explicit &str

// In struct
impl Config {
    fn set_name(&mut self, name: &str) {
        self.name = name.to_string();
    }
    
    // Or accept owned String if caller usually has one
    fn set_name_owned(&mut self, name: String) {
        self.name = name;
    }
    
    // Or be generic
    fn set_name_into(&mut self, name: impl Into<String>) {
        self.name = name.into();
    }
}
```

### Deref Coercion

`String` implements `Deref<Target = str>`, so `&String` automatically coerces to `&str`:

```rust
fn takes_str(s: &str) { }

let owned = String::from("hello");
takes_str(&owned);  // &String -> &str via Deref
```

### When to Accept &String

Rarely. Maybe if you need `String`-specific methods:

```rust
fn needs_capacity(s: &String) -> usize {
    s.capacity()  // Only String has capacity()
}
```

But usually you'd take `&str` and let the caller manage the `String`.

### Pattern: Flexible APIs

```rust
// Most flexible: accept anything that can become &str
fn process(input: impl AsRef<str>) {
    let s: &str = input.as_ref();
    // ...
}

process("literal");
process(String::from("owned"));
process(&some_string);
```

### Similar Anti-patterns

| Anti-pattern | Better |
|--------------|--------|
| `&String` | `&str` |
| `&Vec<T>` | `&[T]` |
| `&Box<T>` | `&T` |
| `&PathBuf` | `&Path` |
| `&OsString` | `&OsStr` |

### Clippy Detection

```toml
[lints.clippy]
ptr_arg = "warn"  # Catches &String, &Vec, &PathBuf
```

### See Also

- [anti-vec-for-slice](#anti-vec-for-slice) - Similar pattern for Vec
- [own-slice-over-vec](#own-slice-over-vec) - Slice patterns
- [api-impl-asref](#api-impl-asref) - AsRef pattern


## anti-stringly-typed

> Don't use strings where enums or newtypes would provide type safety

### Why It Matters

Strings are the most primitive way to represent data—they accept any value, provide no validation, and offer no IDE support. When you have a fixed set of valid values or a semantic type, use enums or newtypes. The compiler catches mistakes at compile time instead of runtime.

### Bad

```rust
fn process_order(status: &str, priority: &str) {
    // What are valid statuses? "pending"? "Pending"? "PENDING"?
    // What are valid priorities? "high"? "1"? "urgent"?
    match status {
        "pending" => { ... }
        "completed" => { ... }
        _ => panic!("unknown status"),  // Runtime error
    }
}

struct User {
    email: String,    // Any string, even "not an email"
    phone: String,    // Any string, even "hello"
    user_id: String,  // Could be confused with other string IDs
}

// Easy to make mistakes
process_order("complete", "high");  // Typo: "complete" vs "completed"
process_order("high", "pending");   // Swapped arguments - compiles!
```

### Good

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum OrderStatus {
    Pending,
    Processing,
    Completed,
    Cancelled,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
enum Priority {
    Low,
    Medium,
    High,
    Critical,
}

fn process_order(status: OrderStatus, priority: Priority) {
    match status {
        OrderStatus::Pending => { ... }
        OrderStatus::Processing => { ... }
        OrderStatus::Completed => { ... }
        OrderStatus::Cancelled => { ... }
    }  // Exhaustive - compiler checks all cases
}

// Validated newtypes
struct Email(String);
struct PhoneNumber(String);
struct UserId(u64);

impl Email {
    pub fn new(s: &str) -> Result<Self, ValidationError> {
        if is_valid_email(s) {
            Ok(Email(s.to_string()))
        } else {
            Err(ValidationError::InvalidEmail)
        }
    }
}

struct User {
    email: Email,       // Must be valid email
    phone: PhoneNumber, // Must be valid phone
    user_id: UserId,    // Can't confuse with other IDs
}

// Compile errors catch mistakes
process_order(OrderStatus::Completed, Priority::High);  // Clear and correct
process_order(Priority::High, OrderStatus::Pending);    // Compile error!
```

### Parsing Strings to Types

```rust
use std::str::FromStr;

#[derive(Debug, Clone, Copy)]
enum OrderStatus {
    Pending,
    Processing,
    Completed,
    Cancelled,
}

impl FromStr for OrderStatus {
    type Err = ParseError;
    
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "pending" => Ok(OrderStatus::Pending),
            "processing" => Ok(OrderStatus::Processing),
            "completed" => Ok(OrderStatus::Completed),
            "cancelled" | "canceled" => Ok(OrderStatus::Cancelled),
            _ => Err(ParseError::UnknownStatus(s.to_string())),
        }
    }
}

// Parse at boundary, use types internally
fn handle_request(status_str: &str) -> Result<(), Error> {
    let status: OrderStatus = status_str.parse()?;  // Validate once
    process_order(status);  // Type-safe from here
    Ok(())
}
```

### With Serde

```rust
use serde::{Serialize, Deserialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
enum Status {
    Pending,
    InProgress,
    Completed,
}

// JSON: {"status": "in_progress"}
// Deserialization validates automatically
```

### Error Messages

```rust
#[derive(Debug, Clone, Copy)]
enum Color {
    Red,
    Green,
    Blue,
}

impl std::fmt::Display for Color {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Color::Red => write!(f, "red"),
            Color::Green => write!(f, "green"),
            Color::Blue => write!(f, "blue"),
        }
    }
}

// Type-safe and displayable
println!("Selected color: {}", Color::Red);
```

### See Also

- [api-newtype-safety](#api-newtype-safety) - Newtype pattern
- [api-parse-dont-validate](#api-parse-dont-validate) - Parse at boundaries
- [type-newtype-ids](#type-newtype-ids) - Type-safe IDs


## anti-type-erasure

> Don't use Box<dyn Trait> when impl Trait works

### Why It Matters

`Box<dyn Trait>` (type erasure) introduces heap allocation and dynamic dispatch overhead. When you have a single concrete type or can use generics, `impl Trait` provides the same flexibility with zero overhead through monomorphization.

### Bad

```rust
// Unnecessary type erasure
fn get_iterator() -> Box<dyn Iterator<Item = i32>> {
    Box::new((0..10).map(|x| x * 2))
}

// Boxing for no reason
fn make_handler() -> Box<dyn Fn(i32) -> i32> {
    Box::new(|x| x + 1)
}

// Vec of boxed trait objects when one type would do
fn get_validators() -> Vec<Box<dyn Validator>> {
    vec![
        Box::new(LengthValidator),
        Box::new(RegexValidator),
    ]
}
```

### Good

```rust
// impl Trait - zero overhead, inlined
fn get_iterator() -> impl Iterator<Item = i32> {
    (0..10).map(|x| x * 2)
}

// impl Fn - no boxing
fn make_handler() -> impl Fn(i32) -> i32 {
    |x| x + 1
}

// When mixed types are genuinely needed, Box is OK
fn get_validators() -> Vec<Box<dyn Validator>> {
    // Actually different types at runtime - Box is appropriate
    config.validators.iter()
        .map(|v| v.create_validator())
        .collect()
}
```

### When to Use Box<dyn Trait>

Type erasure IS appropriate when:

```rust
// Heterogeneous collection of different types
let handlers: Vec<Box<dyn Handler>> = vec![
    Box::new(LogHandler),
    Box::new(MetricsHandler),
    Box::new(AuthHandler),
];

// Type cannot be known at compile time
fn create_from_config(config: &Config) -> Box<dyn Database> {
    match config.db_type {
        DbType::Postgres => Box::new(PostgresDb::new()),
        DbType::Sqlite => Box::new(SqliteDb::new()),
    }
}

// Recursive types
struct Node {
    value: i32,
    children: Vec<Box<dyn NodeTrait>>,
}

// Breaking cycles in complex ownership
struct EventLoop {
    handlers: Vec<Box<dyn EventHandler>>,
}
```

### Comparison

| Approach | Allocation | Dispatch | Binary Size |
|----------|------------|----------|-------------|
| `impl Trait` | Stack/inline | Static | Larger (monomorphization) |
| `Box<dyn Trait>` | Heap | Dynamic | Smaller |
| Generics `<T>` | Stack/inline | Static | Larger |

### impl Trait Positions

```rust
// Return position - caller doesn't need to know concrete type
fn process() -> impl Future<Output = Result> { }

// Argument position - like generics but simpler
fn handle(handler: impl Handler) { }

// Can't use in trait definitions (use associated types instead)
trait Processor {
    type Output: Display;  // Not impl Display
    fn process(&self) -> Self::Output;
}
```

### Pattern: Enum Instead of dyn

```rust
// Instead of Box<dyn Shape>
enum Shape {
    Circle { radius: f64 },
    Rectangle { width: f64, height: f64 },
    Triangle { base: f64, height: f64 },
}

impl Shape {
    fn area(&self) -> f64 {
        match self {
            Shape::Circle { radius } => PI * radius * radius,
            Shape::Rectangle { width, height } => width * height,
            Shape::Triangle { base, height } => 0.5 * base * height,
        }
    }
}
```

### See Also

- [anti-over-abstraction](#anti-over-abstraction) - Excessive generics
- [type-generic-bounds](#type-generic-bounds) - Generic constraints
- [mem-box-large-variant](#mem-box-large-variant) - Boxing enum variants


## anti-unwrap-abuse

> Don't use `.unwrap()` in production code

### Why It Matters

`.unwrap()` panics on `None` or `Err`, crashing your program. In production, this means lost data, failed requests, and unhappy users. It also makes debugging harder since panic messages often lack context.

### Bad

```rust
// Crashes if file doesn't exist
let content = std::fs::read_to_string("config.toml").unwrap();

// Crashes on invalid input
let num: i32 = user_input.parse().unwrap();

// Crashes if key missing
let value = map.get("key").unwrap();

// Crashes if channel closed
let msg = receiver.recv().unwrap();
```

### Good

```rust
// Propagate with ?
fn load_config() -> Result<Config, Error> {
    let content = std::fs::read_to_string("config.toml")?;
    Ok(toml::from_str(&content)?)
}

// Provide default
let num: i32 = user_input.parse().unwrap_or(0);

// Handle missing key
let value = map.get("key").ok_or(Error::MissingKey)?;

// Or use if-let
if let Some(value) = map.get("key") {
    process(value);
}

// Channel with proper handling
match receiver.recv() {
    Ok(msg) => handle(msg),
    Err(_) => break,  // Channel closed
}
```

### When unwrap() Is Acceptable

```rust
// 1. Tests - panics are expected failures
#[test]
fn test_parse() {
    let result = parse("valid").unwrap();  // OK in tests
    assert_eq!(result, expected);
}

// 2. Const/static initialization (compile-time guaranteed)
static REGEX: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"^\d+$").unwrap()  // Known-valid pattern
});

// 3. After a check that guarantees success
if map.contains_key("key") {
    let value = map.get("key").unwrap();  // Just checked
}
// Better: use if-let or entry API instead

// 4. Truly impossible cases with proof comment
let last = vec.pop().unwrap();  
// OK only if you just checked !vec.is_empty()
// Better: use last() or pattern match
```

### Alternatives to unwrap()

```rust
// unwrap_or - provide default
let x = opt.unwrap_or(default);

// unwrap_or_default - use Default trait
let x = opt.unwrap_or_default();

// unwrap_or_else - compute default lazily
let x = opt.unwrap_or_else(|| expensive_default());

// ? operator - propagate errors
let x = opt.ok_or(Error::Missing)?;

// if let - handle Some/Ok case
if let Some(x) = opt {
    use_x(x);
}

// match - handle all cases
match opt {
    Some(x) => use_x(x),
    None => handle_none(),
}

// map - transform if present
let y = opt.map(|x| x + 1);

// and_then - chain fallible operations
let z = opt.and_then(|x| x.checked_add(1));
```

### expect() Is Slightly Better

```rust
// unwrap() - no context
let file = File::open(path).unwrap();
// Panics with: "called `Result::unwrap()` on an `Err` value: Os { code: 2, ... }"

// expect() - adds context
let file = File::open(path)
    .expect("config file should exist at startup");
// Panics with: "config file should exist at startup: Os { code: 2, ... }"

// But still use only for invariants, not error handling
```

### Clippy Lint

```rust
// Enable these lints to catch unwrap usage:
#![warn(clippy::unwrap_used)]
#![warn(clippy::expect_used)]  // Stricter

// Or per-function:
#[allow(clippy::unwrap_used)]
fn tests_only() { }
```

### See Also

- [err-question-mark](#err-question-mark) - Use ? for propagation
- [err-result-over-panic](#err-result-over-panic) - Return Result instead of panicking
- [anti-expect-lazy](#anti-expect-lazy) - Don't use expect for recoverable errors


## anti-vec-for-slice

> Don't accept &Vec<T> when &[T] works

### Why It Matters

`&Vec<T>` is strictly less flexible than `&[T]`. A slice can be created from `Vec`, arrays, and other slice-like types. Accepting `&Vec<T>` forces callers to have exactly a `Vec`, preventing them from using arrays, slices, or other collections.

### Bad

```rust
// Forces callers to have a Vec
fn sum(numbers: &Vec<i32>) -> i32 {
    numbers.iter().sum()
}

// Caller must allocate
let arr = [1, 2, 3, 4, 5];
sum(&arr.to_vec());  // Unnecessary allocation

// Slice won't work
let slice: &[i32] = &[1, 2, 3];
// sum(slice);  // Error: expected &Vec<i32>
```

### Good

```rust
// Accept slice - works with Vec, arrays, slices
fn sum(numbers: &[i32]) -> i32 {
    numbers.iter().sum()
}

// All these work
sum(&[1, 2, 3, 4, 5]);        // Array
sum(&vec![1, 2, 3]);          // Vec
sum(&numbers[1..3]);          // Slice of slice
sum(numbers.as_slice());      // Explicit slice
```

### Deref Coercion

`Vec<T>` implements `Deref<Target = [T]>`, so `&Vec<T>` automatically coerces to `&[T]`:

```rust
fn takes_slice(s: &[i32]) { }

let vec = vec![1, 2, 3];
takes_slice(&vec);  // &Vec<i32> -> &[i32] via Deref
```

### Mutable Slices

Same applies to `&mut`:

```rust
// Bad
fn double(numbers: &mut Vec<i32>) {
    for n in numbers.iter_mut() {
        *n *= 2;
    }
}

// Good
fn double(numbers: &mut [i32]) {
    for n in numbers.iter_mut() {
        *n *= 2;
    }
}
```

### When to Accept &Vec<T>

Rarely. Only when you need Vec-specific operations:

```rust
fn needs_capacity(v: &Vec<i32>) -> usize {
    v.capacity()  // Only Vec has capacity
}

fn might_grow(v: &mut Vec<i32>) {
    v.push(42);  // Slice can't push
}
```

### Pattern: Accepting Multiple Types

```rust
// Accept anything that can be viewed as a slice
fn process<T: AsRef<[u8]>>(data: T) {
    let bytes: &[u8] = data.as_ref();
    // ...
}

process(&[1u8, 2, 3]);       // Array
process(vec![1u8, 2, 3]);    // Vec
process(&some_vec);          // &Vec
process(b"bytes");           // Byte string
```

### Similar Anti-patterns

| Anti-pattern | Better |
|--------------|--------|
| `&Vec<T>` | `&[T]` |
| `&String` | `&str` |
| `&PathBuf` | `&Path` |
| `&Box<T>` | `&T` |

### Clippy Detection

```toml
[lints.clippy]
ptr_arg = "warn"  # Catches &Vec, &String, &PathBuf
```

### See Also

- [anti-string-for-str](#anti-string-for-str) - Similar for String
- [own-slice-over-vec](#own-slice-over-vec) - Slice patterns
- [api-impl-asref](#api-impl-asref) - AsRef pattern
