---
name: rust-common-pitfalls
description: Use when fixing Rust compiler errors and pitfalls - E0382/E0502/E0716 borrow-checker and move errors, test organization, coverage enforcement, thiserror design, panic elimination, or module splitting
metadata:
  author: mte90
  version: 2.0.0
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

**Real-World Examples from baco** (ses_1015b0539ffe):
- String vs &String drift in security_agent_verification.rs
- u32 vs usize mismatch in loop counters and array indexing

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

### E0382: Use of moved value

**Cause**: Value moved into another owner, then used again.

**Solution**:
```rust
// Problem: String moved to vec, then used
let s = String::from("hello");
let v = vec![s];  // s moved
println!("{}", s);  // ERROR: use after move

// Fix: Clone or borrow
let s = String::from("hello");
let v = vec![s.clone()];  // Clone ownership
println!("{}", s);  // OK

// Or borrow if clone is expensive
let s = String::from("hello");
let v = vec![&s];  // Borrow
println!("{}", s);  // OK
```

### E0502: Cannot borrow as immutable because it is also borrowed as mutable

**Cause**: Simultaneous mutable and immutable borrows violate Rust's borrowing rules.

**Solution**:
```rust
// Problem: mutable borrow while immutable borrow active
let mut v = vec![1, 2, 3];
let first = &v[0];  // immutable borrow
v.push(4);  // ERROR: mutable borrow while immutable active
println!("{}", first);

// Fix: Limit immutable borrow scope
let mut v = vec![1, 2, 3];
let first = v[0];  // Copy (i32 implements Copy)
v.push(4);
println!("{}", first);

// Or separate scopes for references
let mut v = vec![1, 2, 3];
{
    let first = &v[0];  // immutable borrow
    println!("{}", first);
}  // borrow ends
v.push(4);  // now OK
```

### E0507: Cannot move out of borrowed content

**Cause**: Trying to move a value out of a reference or container.

**Solution**:
```rust
// Problem: Moving out of Option in reference
struct Container { data: Option<String> }
fn extract(c: &Container) -> String {
    c.data.take().unwrap()  // ERROR: cannot move out of &Option
}

// Fix: Use take() to replace with None
fn extract(c: &mut Container) -> String {
    c.data.take().unwrap()  // OK: takes ownership, leaves None
}

// Or clone if mutation not possible
fn extract(c: &Container) -> String {
    c.data.clone().unwrap()  // OK: clones the String
}
```

### E0716: Temporary value dropped while borrowed

**Cause**: Reference to temporary that gets dropped at end of statement.

**Solution**:
```rust
// Problem: Temporary string literal dropped
fn get_line() -> &str {
    String::from("hello").as_str()  // ERROR: temp dropped
}

// Fix: Return owned String
fn get_line() -> String {
    String::from("hello")
}

// Or use static lifetime for constants
fn get_line() -> &'static str {
    "hello"  // Static string literal
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

## Deep Dives

The following reference files contain detailed guidance on advanced topics. Load them on demand when working on these areas:

| Reference File | Topic |
|----------------|-------|
| `references/design-patterns.md` | Builder, Factory, and Newtype patterns for struct construction |
| `references/testing-coverage.md` | Test organization and code coverage enforcement |
| `references/runtime-async.md` | Send+Sync, deadlocks, and async best practices |
| `references/module-hygiene.md` | Module splitting strategies and dead code detection |
| `references/error-design.md` | Error design with thiserror |
| `references/panic-elimination.md` | Panic elimination strategies and CI gates |

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