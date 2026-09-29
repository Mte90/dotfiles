<!-- This file is loaded on demand from the main SKILL.md Deep Dives section -->

## Part 8: Panic Elimination Strategies

### Why Panics in Hot Paths Are Dangerous

- **Crash on unexpected input** — no graceful degradation
- **No recovery** — process dies, user loses work
- **Hard to test** — panic paths often untested
- **Poor UX** — users see raw error messages or silent crashes

### `.unwrap()` → `?` Migration

```rust
// Bad: panics on None
fn load_config() -> Config {
    let content = std::fs::read_to_string("config.json").unwrap();
    serde_json::from_str(&content).unwrap()
}

// Good: propagates error
fn load_config() -> Result<Config, ScanError> {
    let content = std::fs::read_to_string("config.json")?
        .map_err(|e| ScanError::FileNotFound { path: "config.json".into() })?;
    serde_json::from_str(&content)
        .map_err(|e| ScanError::ConfigParse(e.to_string()))?
}
```

### `.expect()` with Context

`.expect()` is acceptable **only** for true invariants that are impossible to violate:

```rust
// Acceptable — invariant: process must have current thread
fn spawn_worker() -> JoinHandle<()> {
    let handle = std::thread::current()
        .expect("must have current thread to spawn worker");
    // ...
}

// NOT acceptable — file may legitimately not exist
fn load_data(path: &Path) -> Data {
    let file = File::open(path).expect("file should exist"); // BAD
}

// Good — handle the error
fn load_data(path: &Path) -> Result<Data, ScanError> {
    let file = File::open(path)?;
    // ...
}
```

### Result Propagation Pattern

Make functions return `Result<T, E>` instead of panicking:

```rust
// Bad
fn parse_config(content: &str) -> Config {
    let json: Value = serde_json::from_str(content).unwrap();
    Config {
        name: json["name"].as_str().unwrap().to_string(),
        port: json["port"].as_u16().unwrap(),
    }
}

// Good
fn parse_config(content: &str) -> Result<Config, ConfigError> {
    let json: Value = serde_json::from_str(content)
        .map_err(|e| ConfigError::ParseError(e.to_string()))?;
    
    let name = json["name"]
        .as_str()
        .ok_or(ConfigError::MissingField("name".into()))?
        .to_string();
    
    let port = json["port"]
        .as_u16()
        .ok_or(ConfigError::MissingField("port".into()))?;
    
    Ok(Config { name, port })
}
```

### Common Panic Sources and Fixes

| Source | Panic Risk | Fix |
|--------|------------|-----|
| Array indexing `arr[i]` | Out of bounds | `arr.get(i).ok_or(Error)?` or bounds check first |
| `unwrap()` on `Option` | `None` value | `ok_or(error)?` or `ok_or_else(|| ...)?` |
| `unwrap()` on `Result` | Error variant | `?` with error mapping via `map_err()` |
| Integer division | Divide by zero | `checked_div()` / `saturating_div()` |
| `Vec::remove` out of bounds | Index >= len | Bounds check: `if i < vec.len() { vec.remove(i) }` |
| `unwrap()` on `parse()` | Invalid format | `parse().map_err(...)?` |
| `expect()` on fallible I/O | File not found, permissions | Return `Result` instead |

### Audit Techniques with Clippy

Replace raw grep with clippy lints and structured error handling:

```bash
# Use clippy lints instead of grep
cargo clippy -- -D clippy::expect_used -D clippy::unwrap_used
```

```rust
// Add #[track_caller] for better panic locations
#[track_caller]
fn panic_with_location(msg: &str) {
    panic!("{}", msg);  // Panic reports caller's location
}

// For FFI boundaries: catch_unwind
use std::panic::{catch_unwind, AssertUnwindSafe};

fn safe_ffi_call(f: impl FnOnce() + Send) -> Result<(), ()> {
    catch_unwind(AssertUnwindSafe(f)).map_err(|_| ())
}
```

```bash
# Find all unwraps except in test code
grep -rn '\.unwrap()' src/ | grep -v test

# Find expect calls with context
grep -rn '\.expect(' src/ | grep -v "test\|cfg(test)"

# Use cargo-udeps to find unused error handling
cargo udeps
```

### CI Gate: Deny `unwrap()` in Non-Test Code

Add to `clippy.toml`:

```toml
# clippy.toml
allow-unwrap-in-tests = true

# Or in Cargo.toml with rustfmt
[lints.clippy]
panic_in_result_fn = "deny"
unwrap_used = "deny"
```

Run in CI:

```bash
cargo clippy -- -D clippy::unwrap_used -D clippy::panic_in_result_fn
```

### When Panics ARE Acceptable

| Scenario | Example | Rationale |
|----------|---------|----------|
| True invariants | `debug_assert!`, `unreachable!()` after exhaustive match | Logic guarantees impossibility |
| Test setup | `#[test] fn foo() { setup().unwrap(); }` | Test failure is expected on bad setup |
| `unreachable!()` | `match value { A => ..., B => ..., _ => unreachable!() }` | Exhaustive match proves impossibility |
| `unimplemented!()` | Stub for future work during development | Explicit marker, not production code |
| `todo!()` | Placeholder during implementation | Development-only, should be removed |

```rust
// Acceptable — exhaustive match proves unreachable
match status {
    Status::Active => process_active(),
    Status::Inactive => process_inactive(),
    _ => unreachable!("All status variants handled"),
}

// Acceptable — test setup
#[test]
fn test_scan() {
    let config = load_test_config().unwrap();  // Test fails if config invalid
    let results = scan(&config).unwrap();
    assert!(!results.is_empty());
}
```