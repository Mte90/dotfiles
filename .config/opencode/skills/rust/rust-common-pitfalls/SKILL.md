---
name: rust-common-pitfalls
description: "Common Rust development pitfalls: frequent compiler errors, struct constructor patterns, test organization, and coverage enforcement for reliable codebases."
metadata:
  author: "Sisyphus"
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

---

## Summary

**Remember**:
1. Read compiler errors literally — Rust's compiler is helpful
2. Use builders for complex construction with validation
3. Keep tests close to code they test (inline) or in `tests/`
4. Enforce coverage in CI — 80% is a good starting target
5. Never use `unwrap()` in production code — always handle errors explicitly
6. Derive `Clone`, `Debug`, `Eq`, `PartialEq` when possible — let the compiler do work