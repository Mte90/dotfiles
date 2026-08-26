---
name: rust-common-pitfalls
description: "Common Rust development pitfalls: frequent compiler errors, struct constructor patterns, test organization, and coverage enforcement for reliable codebases."
metadata:
  author: mte90
  version: "1.0.0"
  tags:
    - rust
    - compiler-errors
    - testing
    - patterns
    - best-practices
---

# Rust Common Development Pitfalls

Comprehensive guide for avoiding and fixing the most frequent issues encountered when developing in Rust.

## When to Use

- Resolving compiler errors in Rust projects
- Designing struct constructors and builders
- Organizing tests in Rust crates
- Setting up code coverage gates
- Debugging common runtime issues

## How It Works

This skill addresses the four most common pain points identified in Rust development:

1. **Frequent compiler errors** — Quick reference for error codes and solutions
2. **Struct constructor patterns** — Builder, factory, and newtype patterns
3. **Test organization** — Module placement, naming, and integration tests
4. **Coverage enforcement** — CI integration and threshold configuration

---

## Part 1: Common Compiler Errors Quick Reference

### E0433: Cannot find type in scope

**Cause**: Missing import or typo in type name.

**Solution**:
```rust
// Wrong: use chrono::NaiveDate;
use chrono::NaiveDate;  // Add import or check Cargo.toml

// Check for typos in type names
struct User { name: String }  // typo in "name" vs "named"
```

### E0597: Value does not live long enough

**Cause**: Lifetime mismatch between borrowed value and its container.

**Solution**:
```rust
// Problem: returning reference to temporary
fn get_str() -> &str {
    let s = String::from("temp");
    &s  // ERROR: s dropped before reference returned
}

// Fix: Return owned value or use static lifetime
fn get_str() -> String {
    String::from("temp")  // Ownership moves
}

// Or with static lifetime for constants
fn get_str() -> &'static str {
    "temp"  // Static lifetime
}
```

### E0308: Mismatched types

**Cause**: Type inference failure or expected vs actual type mismatch.

**Solution**:
```rust
// Problem: Expected i32, got &str
fn add(a: i32, b: i32) -> i32 { a + b }
let result = add("1", "2");  // ERROR

// Fix: Convert string to number
let result = add("1".parse::<i32>().unwrap(), "2".parse().unwrap());

// Or use type annotation
let a: i32 = "1".parse().unwrap();
let b: i32 = "2".parse().unwrap();
```

### E0596: Cannot borrow as mutable because it is also borrowed as immutable

**Cause**: Simultaneous mutable and immutable borrows.

**Solution**:
```rust
// Problem
let mut v = vec![1, 2, 3];
let first = &v[0];
v.push(4);  // ERROR: cannot mutate while borrowed

// Fix: Separate borrow scopes
let mut v = vec![1, 2, 3];
{
    let first = &v[0];
    println!("{}", first);
}  // borrow ends
v.push(4);  // now works
```

### E0277: Trait not satisfied

**Cause**: Type doesn't implement required trait.

**Solution**:
```rust
// Problem: T doesn't implement Display
fn print<T>(val: T) {
    println!("{}", val);  // ERROR
}

// Fix: Add trait bound
fn print<T: std::fmt::Display>(val: T) {
    println!("{}", val);
}

// Or use generic formatting
fn print(val: &impl std::fmt::Display) {
    println!("{}", val);
}
```

### E0282: Cannot infer type

**Cause**: Compiler cannot determine type from context.

**Solution**:
```rust
// Problem: Cannot infer type of iterator
let v = vec![1, 2, 3].iter().map(|x| x * 2).collect();  // ERROR

// Fix: Add type annotation
let v: Vec<i32> = vec![1, 2, 3].iter().map(|x| x * 2).collect();

// Or collect into specific type
use std::collections::HashMap;
let m: HashMap<_, _> = vec![(1, "a"), (2, "b")].into_iter().collect();
```

---

## Part 2: Struct Constructor Patterns

### Pattern 1: Simple Constructor with Validation

```rust
pub struct User {
    name: String,
    email: String,
    age: u8,
}

impl User {
    /// Creates a new user with validation.
    /// Returns Err if validation fails.
    pub fn new(name: impl Into<String>, email: impl Into<String>, age: u8) -> Result<Self, UserError> {
        let name = name.into();
        let email = email.into();

        // Validate
        if name.trim().is_empty() {
            return Err(UserError::EmptyName);
        }
        if !email.contains('@') {
            return Err(UserError::InvalidEmail(email));
        }
        if age > 150 {
            return Err(UserError::InvalidAge(age));
        }

        Ok(Self { name, email, age })
    }
}

#[derive(Debug)]
pub enum UserError {
    EmptyName,
    InvalidEmail(String),
    InvalidAge(u8),
}
```

### Pattern 2: Builder Pattern with Validation

```rust
pub struct UserBuilder {
    name: Option<String>,
    email: Option<String>,
    age: Option<u8>,
}

impl UserBuilder {
    pub fn new() -> Self {
        Self {
            name: None,
            email: None,
            age: None,
        }
    }

    pub fn name(mut self, name: impl Into<String>) -> Self {
        self.name = Some(name.into());
        self
    }

    pub fn email(mut self, email: impl Into<String>) -> Self {
        self.email = Some(email.into());
        self
    }

    pub fn age(mut self, age: u8) -> Self {
        self.age = Some(age);
        self
    }

    /// Builds the User, performing validation.
    /// # Errors
    /// Returns UserError if required fields are missing or invalid.
    pub fn build(self) -> Result<User, UserError> {
        let name = self.name.ok_or(UserError::MissingField("name"))?;
        let email = self.email.ok_or(UserError::MissingField("email"))?;
        let age = self.age.unwrap_or(0);  // default

        User::new(name, email, age)
    }
}

impl Default for UserBuilder {
    fn default() -> Self {
        Self::new()
    }
}

// Usage
let user = UserBuilder::new()
    .name("Alice")
    .email("alice@example.com")
    .age(30)
    .build()
    .expect("valid input");
```

### Pattern 3: Factory Pattern for Multiple Variants

```rust
pub struct VulnerabilityFinding {
    id: String,
    severity: Severity,
    message: String,
    location: Location,
    // ... many more fields
}

pub enum Severity {
    Info,
    Low,
    Medium,
    High,
    Critical,
}

impl VulnerabilityFinding {
    /// Factory for SQL injection findings
    pub fn sql_injection(location: Location, query: &str) -> Self {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            severity: Severity::High,
            message: format!("Potential SQL injection in: {}", query),
            location,
            // ... set other fields appropriately
        }
    }

    /// Factory for hardcoded credentials
    pub fn hardcoded_credential(location: Location, credential_type: &str) -> Self {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            severity: Severity::Critical,
            message: format!("Hardcoded {} detected", credential_type),
            location,
            // ...
        }
    }
}
```

### Pattern 4: Newtype for Type Safety

```rust
/// Newtype wrapper to prevent mixing up UserId and OrderId
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct UserId(pub u64);

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct OrderId(pub u64);

impl UserId {
    pub fn new(id: u64) -> Self {
        Self(id)
    }
}

impl OrderId {
    pub fn new(id: u64) -> Self {
        Self(id)
    }
}

// This prevents accidental argument swapping
fn get_user_orders(user_id: UserId, order_id: OrderId) -> Result<Order, ()> {
    // Cannot accidentally swap - type system catches it
    todo!()
}

// Usage
let user_id = UserId::new(42);
let order_id = OrderId::new(1);
get_user_orders(user_id, order_id).ok();
```

---

## Part 3: Test Organization

### Module Structure

```text
my_crate/
├── src/
│   └── lib.rs
├── tests/
│   ├── integration_test.rs    # One file = one test binary
│   └── common/
│       └── mod.rs             # Shared test utilities
└── src/
    └── some_module.rs         # Inline tests below
```

### Inline Tests in Source

```rust
// src/some_module.rs

pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;

    // Unit tests for this module
    #[test]
    fn test_add_positive() {
        assert_eq!(add(2, 3), 5);
    }

    #[test]
    fn test_add_negative() {
        assert_eq!(add(-1, 1), 0);
    }

    #[test]
    fn test_add_returns_error_when_overflow() {
        // Test error conditions
        let result = add(i32::MAX, 1);
        assert!(result.is_negative());  // Wraps to negative
    }
}
```

### Integration Tests

```rust
// tests/integration_test.rs
use my_crate::{add, User, UserBuilder};

#[test]
fn test_full_user_flow() {
    // Integration test - tests components working together
    let user = UserBuilder::new()
        .name("Test")
        .email("test@example.com")
        .age(25)
        .build()
        .unwrap();

    assert_eq!(user.name(), "Test");
}

#[test]
fn test_invalid_email_rejected() {
    let result = UserBuilder::new()
        .name("Test")
        .email("invalid-email")
        .build();

    assert!(result.is_err());
}
```

### Test Modules Inside impl Blocks (Advanced)

**⚠️ Rare pattern - use only when necessary:**

```rust
pub struct Config {
    value: i32,
}

impl Config {
    pub fn new(value: i32) -> Self {
        Self { value }
    }

    #[cfg(test)]
    mod tests {
        use super::*;

        #[test]
        fn test_new_creates_config() {
            let cfg = Config::new(42);
            assert_eq!(cfg.value, 42);
        }
    }
}
```

### Test Naming Conventions

```rust
#[cfg(test)]
mod tests {
    use super::*;

    // DESCRIPTIVE: test_function_scenario_expected_behavior
    #[test]
    fn test_user_new_rejects_empty_email() {
        assert!(User::new("name", "").is_err());
    }

    #[test]
    fn test_builder_provides_defaults_for_optional_fields() {
        let user = UserBuilder::new()
            .name("Test")
            .email("test@example.com")
            .build()
            .unwrap();
        assert_eq!(user.age(), 0);  // default
    }

    // Group related tests with prefix
    #[test]
    fn test_vulnerability_sql_injection_severity_is_high() {
        let finding = VulnerabilityFinding::sql_injection(
            Location::new("test.rs", 1),
            "SELECT * FROM users"
        );
        assert!(matches!(finding.severity(), Severity::High));
    }
}
```

---

## Part 4: Code Coverage Enforcement

### Cargo Configuration

```toml
# .cargo/config.toml
[profile.release]
lto = true
opt-level = 3

[profile.dev]
debug = true
```

### CI Integration with cargo-llvm-cov

```yaml
# .github/workflows/coverage.yml
name: Coverage

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Rust
        uses: dtolnay/rust-toolchain@stable
        with:
          components: llvm-tools-preview
      
      - name: Install cargo-llvm-cov
        uses: taiki-e/install-action@cargo-llvm-cov
      
      - name: Generate coverage
        run: cargo llvm-cov --workspace --lcov --output-path lcov.info
      
      - name: Upload to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: lcov.info
          fail_ci_if_error: true
          threshold: 80%
```

### Coverage with Failure Threshold

```bash
# Run with minimum coverage requirement
cargo llvm-cov --fail-under-lines 80

# Or in CI with specific targets
cargo llvm-cov --fail-under-lines 80 \
  --fail-under-functions 70 \
  --fail-under-regions 60
```

### Excluding Code from Coverage

```rust
// Exclude generated code
#[cfg(test)]
mod generated_tests {
    // Tests for generated code - exclude from coverage
    include!("generated.rs");
}

// Exclude platform-specific code
#[cfg(target_os = "linux")]
fn linux_only_function() { /* ... */ }

#[cfg(not(target_os = "linux"))]
fn linux_only_function() {
    unreachable!("Linux only");
}
```

### Coverage Reports

```bash
# HTML report
cargo llvm-cov --html

# Terminal summary
cargo llvm-cov

# JSON for CI tools
cargo llvm-cov --json --output-path coverage.json
```

---

## Part 5: Common Runtime Issues Prevention

### Thread Safety with Send + Sync

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

---
## Part 6: Module Splitting Strategies

### When to Split a Module

Signs a module has outgrown its single file:
- **>300 lines** — readability degrades, navigation becomes painful
- **Multiple responsibilities** — scanner logic mixed with staging, error handling, and output formatting
- **Frequent merge conflicts** — multiple developers editing the same large file
- **Hard to test** — too many internal dependencies to isolate units

### The `mod.rs` vs `mod/` Directory Pattern

**Before** (single large file):
```rust
// scanner.rs (500 lines)
pub fn scan_phase(phase: ScanPhase) -> Result<Vec<Finding>, ScanError> { ... }
pub fn stage_results(findings: &[Finding]) -> StagedResults { ... }
pub fn run_semgrep(path: &Path) -> Result<SemgrepOutput, SemgrepError> { ... }
// ... 490 more lines
```

**After** (split into submodules):
```rust
// scanner/mod.rs
pub mod phases;
pub mod staging;
pub mod semgrep;

// Re-export public API so callers see no difference
pub use phases::scan_phase;
pub use staging::stage_results;
pub use semgrep::run_semgrep;

// Also re-export types used in public signatures
pub use phases::ScanPhase;
pub use staging::StagedResults;
```

```rust
// scanner/phases.rs
use crate::scanner::{ScanPhase, Finding, ScanError};

pub fn scan_phase(phase: ScanPhase) -> Result<Vec<Finding>, ScanError> {
    // Implementation
}
```

### Visibility Strategy

| Visibility | Use Case |
|------------|----------|
| `pub` | True public API — stable across versions |
| `pub(crate)` | Internal cross-module access within the crate |
| (no `pub`) | Private to the module — implementation detail |

```rust
// scanner/mod.rs
pub mod phases;
mod staging_internal;  // Private helper module

pub use phases::scan_phase;

// Internal function, not exposed
pub(crate) fn internal_helper() -> Result<(), ScanError> {
    // Used by multiple modules but not part of public API
}
```

```rust
// scanner/phases.rs
use crate::scanner::internal_helper;  // Can access pub(crate)

pub fn scan_phase(phase: ScanPhase) -> Result<Vec<Finding>, ScanError> {
    internal_helper()?;  // Cross-module internal access
    // ...
}
```

### Preserving API Compatibility During Refactor

When splitting a module, maintain the **public facade**:

```rust
// Before split — callers import from scanner
use scanner::scan_phase;
use scanner::ScanPhase;

// After split — same imports still work
use scanner::scan_phase;  // Re-exported from scanner/mod.rs
use scanner::ScanPhase;   // Re-exported type
```

**Key steps:**
1. Create `scanner/mod.rs` with `pub mod` declarations
2. Move functions/types to appropriate submodules
3. Add `pub use` re-exports in `mod.rs` for all public symbols
4. Run tests — integration tests should pass without modification

### Common Pitfalls

| Pitfall | Consequence | Fix |
|---------|-------------|-----|
| Forgetting to re-export types in public signatures | Callers get "type not found" errors | Add `pub use submodule::TypeName` in `mod.rs` |
| Using `mod` instead of `pub mod` | Submodule not accessible outside parent | Change to `pub mod` if submodule is part of public API |
| Circular dependencies between submodules | Compilation error | Restructure — extract shared code to a separate module |
| Forgetting `pub` on items in submodules | Items not visible even with `pub use` | Ensure items are `pub` in their defining module |
| Integration test imports break | Test fails to compile | Verify `mod.rs` re-exports match the old single-file API |

### Integration Test Imports

After splitting, integration tests continue to work if `mod.rs` re-exports correctly:

```rust
// tests/integration_test.rs
use my_crate::scanner::{scan_phase, ScanPhase};  // Still works!

#[test]
fn test_scan_phase() {
    let results = scan_phase(ScanPhase::Semgrep).unwrap();
    assert!(!results.is_empty());
}
```

---

## Part 7: Error Design with thiserror

### When to Use `thiserror` vs `anyhow`

| Tool | Best For | Example |
|------|----------|---------|
| **`thiserror`** | Library errors, enum-based errors, public APIs | `ScanError::FileNotFound`, `ConfigError::InvalidPath` |
| **`anyhow`** | Application-level error aggregation, CLI tools | `Result<T, anyhow::Error>` in `main()` |

baco uses `thiserror` 9:1 over `anyhow` (225 vs 26 mentions) — this is the standard pattern for libraries.

### Designing Error Enums

```rust
use thiserror::Error;
use std::path::PathBuf;

#[derive(Debug, Error)]
pub enum ScanError {
    #[error("file not found: {path}")]
    FileNotFound { path: PathBuf },

    #[error("invalid configuration: {0}")]
    InvalidConfig(String),

    #[error("scan failed: {source}")]
    ScanFailed {
        #[from]
        source: std::io::Error,
    },

    #[error("semgrep error: {0}")]
    Semgrep(#[from] SemgrepError),

    #[error("phase {phase} timed out after {duration}s")]
    Timeout { phase: String, duration: u64 },
}
```

### The `#[from]` Attribute

Automatically implements `From<E>` for your error type, enabling the `?` operator:

```rust
// With #[from]
#[derive(Debug, Error)]
pub enum ScanError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}

// Now this works:
fn read_file(path: &Path) -> Result<String, ScanError> {
    let content = std::fs::read_to_string(path)?;  // Auto-converts io::Error
    Ok(content)
}

// Without #[from], you'd need:
fn read_file(path: &Path) -> Result<String, ScanError> {
    let content = std::fs::read_to_string(path)
        .map_err(ScanError::Io)?;  // Manual conversion
    Ok(content)
}
```

### Error Context Chaining

Wrap errors at each layer with structured context:

```rust
fn load_config(path: &Path) -> Result<Config, ScanError> {
    // Layer 1: IO error → FileNotFound
    let content = std::fs::read_to_string(path)
        .map_err(|e| ScanError::FileNotFound { path: path.to_path_buf() })?;
    
    // Layer 2: Parse error → InvalidConfig
    let config: Config = serde_json::from_str(&content)
        .map_err(|e| ScanError::InvalidConfig(format!("JSON parse: {}", e)))?;
    
    Ok(config)
}
```

### Unifying Errors Across Modules

When multiple modules produce different error types, create a top-level enum:

```rust
// scanner/error.rs
use thiserror::Error;

#[derive(Debug, Error)]
pub enum ScanError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("semgrep error: {0}")]
    Semgrep(#[from] semgrep::SemgrepError),

    #[error("config error: {0}")]
    Config(#[from] config::ConfigError),

    #[error("scan failed: {message}")]
    ScanFailed { message: String },
}

// semgrep/error.rs
#[derive(Debug, Error)]
pub enum SemgrepError {
    #[error("semgrep not found")]
    NotInstalled,
    #[error("semgrep exited with code {code}")]
    ExitCode { code: i32 },
}

// config/error.rs
#[derive(Debug, Error)]
pub enum ConfigError {
    #[error("missing field: {field}")]
    MissingField { field: String },
}
```

### Common Pitfalls

| Pitfall | Consequence | Fix |
|---------|-------------|-----|
| Forgetting `#[from]` and writing manual `From` impls | Boilerplate, error-prone | Use `#[from]` for automatic conversion |
| Using `String` error messages instead of structured variants | Lost context, hard to match on | Use enum variants with typed fields |
| Not deriving `Debug` on the error enum | Compilation error (required by `Error` trait) | Add `#[derive(Debug, Error)]` |
| Flat enum with 20+ variants | Hard to navigate, unclear domain boundaries | Nest by domain — create submodule error types |
| Mixing `thiserror` and `anyhow` in the same module | Confusing error handling strategy | Pick one per module — `thiserror` for libraries, `anyhow` for app entry points |

### Example: Complete Error Design

```rust
use thiserror::Error;
use std::path::PathBuf;

// Domain-specific error types
#[derive(Debug, Error)]
pub enum ConfigError {
    #[error("config file not found: {0}")]
    NotFound(PathBuf),

    #[error("invalid config: {0}")]
    ParseError(String),
}

#[derive(Debug, Error)]
pub enum ScanError {
    #[error("config error: {0}")]
    Config(#[from] ConfigError),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("no findings")]
    NoFindings,
}

// Usage with context
fn run_scan(config_path: &Path) -> Result<(), ScanError> {
    let config = load_config(config_path)?;  // ConfigError auto-converted
    let results = scan(&config)?;            // Io error auto-converted
    
    if results.is_empty() {
        return Err(ScanError::NoFindings);
    }
    
    Ok(())
}
```

---

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

### Audit Techniques

Find production `.unwrap()` calls:

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

---

## Quick Reference Card

| Issue | Error Code | Quick Fix |
|-------|-----------|-----------|
| Type not found | E0433 | Add import, check spelling |
| Lifetime mismatch | E0597 | Return owned value or 'static |
| Type mismatch | E0308 | Add type annotation or convert |
| Borrow conflict | E0596 | Separate borrow scopes |
| Trait not satisfied | E0277 | Add trait bound |
| Cannot infer type | E0282 | Add type annotation |

### Essential Commands

```bash
# Check code quickly
cargo check

# Run with all warnings
cargo build --all-targets

# Run clippy
cargo clippy -- -D warnings

# Format code
cargo fmt

# Run tests
cargo test

# Coverage report
cargo llvm-cov --html

# Audit dependencies
cargo audit
```

---

## Anti-Patterns to Avoid

```rust
// BAD: unwrap() in production
let value = map.get("key").unwrap();  // Panics on missing key!

// GOOD: Handle missing case
let value = map.get("key")
    .ok_or_else(|| Error::KeyNotFound)?;

// BAD: Clone to avoid borrow checker
fn process(data: &Vec<u8>) -> usize {
    let cloned = data.clone();  // Wasteful
    cloned.len()
}

// GOOD: Use reference directly
fn process(data: &[u8]) -> usize {
    data.len()
}

// BAD: String when &str suffices
fn greet(name: String) { ... }

// GOOD: Borrow when read-only
fn greet(name: &str) { ... }

// BAD: Ignoring Result
let _ = validate(input);  // Silently ignores error

// GOOD: Handle or expect
let _ = validate(input).expect("validation should pass");
```

## Best Practices

- **Read compiler errors fully before acting**: Rust's error messages are verbose for a reason—read the entire diagnostic including suggestions.
- **Use `cargo check` in a tight loop**: Faster than full builds; run after every small change to catch errors early.
- **Structure tests in `tests/` for integration and `#[cfg(test)] mod tests` for unit**: Keep unit tests close to code; use `tests/` for cross-module integration tests.
- **Enforce coverage with `cargo tarpaulin` or `cargo-llvm-cov`**: Set CI gates (e.g., 80% line coverage) to prevent regression.
- **Prefer `Result<T, E>` over `Option<T>` when errors carry meaning**: Use `Option` for absence, `Result` for recoverable failures with context.

---

## References

- [The Rust Programming Language (The Book)](https://doc.rust-lang.org/book/)
- [Rust Compiler Error Index](https://doc.rust-lang.org/error-index.html)
- [rustc Error Documentation](https://doc.rust-lang.org/rustc/errors/)
- [Cargo Book: Testing Chapter](https://doc.rust-lang.org/cargo/reference/testing.html)
- [cargo-llvm-cov Documentation](https://github.com/taiki-e/cargo-llvm-cov)
- [cargo-tarpaulin Documentation](https://github.com/xd009642/tarpaulin)

---

## Summary

**Remember**:
1. Read compiler errors literally — Rust's compiler is helpful
2. Use builders for complex construction with validation
3. Keep tests close to code they test (inline) or in `tests/`
4. Enforce coverage in CI — 80% is a good starting target
5. Never use `unwrap()` in production code — always handle errors explicitly
6. Derive `Clone`, `Debug`, `Eq`, `PartialEq` when possible — let the compiler do work