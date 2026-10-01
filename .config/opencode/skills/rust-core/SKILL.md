---
name: rust-core
description: >
  Use when writing, reviewing, or refactoring Rust code. Covers ownership,
  borrowing, error handling, async patterns, API design, memory optimization,
  performance, testing, and common anti-patterns. Targets Rust 1.80+ and
  Edition 2024. Invoke with /rust-core.
globs: ["**/*.rs"]
license: MIT
metadata:
  author: mte90
  version: "2.0.0"
  tags:
    - rust
    - core
    - ownership
    - error-handling
    - async
    - performance
    - testing
  sources:
    - Rust API Guidelines
    - Rust Performance Book
    - Rust Design Patterns
    - ripgrep, tokio, serde, polars codebases
---

# Rust Core

Comprehensive guide for writing high-quality, idiomatic, and optimized Rust code. Targets Rust 1.80+ and Edition 2024.

## When to Apply

- Writing new Rust functions, structs, or modules
- Implementing error handling or async code
- Designing public APIs for libraries
- Reviewing code for ownership/borrowing issues
- Optimizing memory usage or reducing allocations
- Tuning performance for hot paths
- Refactoring existing Rust code
- Fixing compiler errors (see [references/compiler-errors.md](references/compiler-errors.md))

## Edition 2024 Changes (Rust 1.85+)

| Change | Impact | Action |
|--------|--------|--------|
| `unsafe` blocks required for `extern` blocks | `extern "C" { ... }` now needs `unsafe { extern "C" { ... } }` | Wrap extern blocks in `unsafe` |
| `unsafe_op_in_unsafe_fn` lint | `unsafe fn` body requires explicit `unsafe` blocks for unsafe ops | Add `unsafe { ... }` inside unsafe fns |
| `if let` temporary scope | Temporaries dropped at end of `if let` block | May extend borrow lifetimes |
| `gen` keyword reserved | `gen { ... }` blocks for iterators | Use `gen` for lazy iterators |
| `#[diagnostic::on_unimplemented]` | Better error messages for trait failures | Add to library traits |
| Nested or-patterns | `Some(1 \| 2)` stabilized | Use in match arms |

Run `cargo fix --edition` to apply most changes automatically.

## Rule Categories by Priority

| Priority | Category | Prefix | Rules |
|----------|----------|--------|-------|
| 1 | Ownership & Borrowing | `own-` | 12 |
| 2 | Error Handling | `err-` | 12 |
| 3 | Memory Optimization | `mem-` | 15 |
| 4 | API Design | `api-` | 15 |
| 5 | Async/Await | `async-` | 15 |
| 6 | Compiler Optimization | `opt-` | 12 |
| 7 | Naming Conventions | `name-` | 16 |
| 8 | Type Safety | `type-` | 10 |
| 9 | Testing | `test-` | 13 |
| 10 | Documentation | `doc-` | 11 |
| 11 | Performance Patterns | `perf-` | 11 |
| 12 | Project Structure | `proj-` | 11 |
| 13 | Clippy & Linting | `lint-` | 11 |
| 14 | Anti-patterns | `anti-` | 15 |

Detailed rules live in `rules/` — 14 files, one per prefix group (`ownership.md` covers `own-`, `error-handling.md` covers `err-`, …). Each `## <rule-id>` section inside a category file is one rule, so a grep for a rule id lands directly on it.

## Rule Index

### Ownership & Borrowing (`own-`)

| Rule | Description |
|------|-------------|
| `own-borrow-over-clone` | Prefer `&T` borrowing over `.clone()` |
| `own-slice-over-vec` | Accept `&[T]` not `&Vec<T>`, `&str` not `&String` |
| `own-cow-conditional` | Use `Cow<'a, T>` for conditional ownership |
| `own-arc-shared` | Use `Arc<T>` for thread-safe shared ownership |
| `own-rc-single-thread` | Use `Rc<T>` for single-threaded sharing |
| `own-refcell-interior` | Use `RefCell<T>` for interior mutability (single-thread) |
| `own-mutex-interior` | Use `Mutex<T>` for interior mutability (multi-thread) |
| `own-rwlock-readers` | Use `RwLock<T>` when reads dominate writes |
| `own-copy-small` | Derive `Copy` for small, trivial types |
| `own-clone-explicit` | Make `Clone` explicit, avoid implicit copies |
| `own-move-large` | Move large data instead of cloning |
| `own-lifetime-elision` | Rely on lifetime elision when possible |

### Error Handling (`err-`)

| Rule | Description |
|------|-------------|
| `err-thiserror-lib` | Use `thiserror` for library error types |
| `err-anyhow-app` | Use `anyhow` for application error handling |
| `err-result-over-panic` | Return `Result`, don't panic on expected errors |
| `err-context-chain` | Add context with `.context()` or `.with_context()` |
| `err-no-unwrap-prod` | Never use `.unwrap()` in production code |
| `err-expect-bugs-only` | Use `.expect()` only for programming errors |
| `err-question-mark` | Use `?` operator for clean propagation |
| `err-from-impl` | Use `#[from]` for automatic error conversion |
| `err-source-chain` | Use `#[source]` to chain underlying errors |
| `err-lowercase-msg` | Error messages: lowercase, no trailing punctuation |
| `err-doc-errors` | Document errors with `# Errors` section |
| `err-custom-type` | Create custom error types, not `Box<dyn Error>` |

### Memory Optimization (`mem-`)

| Rule | Description |
|------|-------------|
| `mem-with-capacity` | Use `with_capacity()` when size is known |
| `mem-smallvec` | Use `SmallVec` for usually-small collections |
| `mem-arrayvec` | Use `ArrayVec` for bounded-size collections |
| `mem-box-large-variant` | Box large enum variants to reduce type size |
| `mem-boxed-slice` | Use `Box<[T]>` instead of `Vec<T>` when fixed |
| `mem-thinvec` | Use `ThinVec` for often-empty vectors |
| `mem-clone-from` | Use `clone_from()` to reuse allocations |
| `mem-reuse-collections` | Reuse collections with `clear()` in loops |
| `mem-avoid-format` | Avoid `format!()` when string literals work |
| `mem-write-over-format` | Use `write!()` instead of `format!()` |
| `mem-arena-allocator` | Use arena allocators for batch allocations |
| `mem-zero-copy` | Use zero-copy patterns with slices and `Bytes` |
| `mem-compact-string` | Use `CompactString` for small string optimization |
| `mem-smaller-integers` | Use smallest integer type that fits |
| `mem-assert-type-size` | Assert hot type sizes to prevent regressions |

### API Design (`api-`)

| Rule | Description |
|------|-------------|
| `api-builder-pattern` | Use Builder pattern for complex construction |
| `api-builder-must-use` | Add `#[must_use]` to builder types |
| `api-newtype-safety` | Use newtypes for type-safe distinctions |
| `api-typestate` | Use typestate for compile-time state machines |
| `api-sealed-trait` | Seal traits to prevent external implementations |
| `api-extension-trait` | Use extension traits to add methods to foreign types |
| `api-parse-dont-validate` | Parse into validated types at boundaries |
| `api-impl-into` | Accept `impl Into<T>` for flexible string inputs |
| `api-impl-asref` | Accept `impl AsRef<T>` for borrowed inputs |
| `api-must-use` | Add `#[must_use]` to `Result`-returning functions |
| `api-non-exhaustive` | Use `#[non_exhaustive]` for future-proof enums/structs |
| `api-from-not-into` | Implement `From`, not `Into` (auto-derived) |
| `api-default-impl` | Implement `Default` for sensible defaults |
| `api-common-traits` | Implement `Debug`, `Clone`, `PartialEq` eagerly |
| `api-serde-optional` | Gate `Serialize`/`Deserialize` behind feature flag |

### Async/Await (`async-`)

| Rule | Description |
|------|-------------|
| `async-tokio-runtime` | Use Tokio for production async runtime |
| `async-no-lock-await` | Never hold `Mutex`/`RwLock` across `.await` |
| `async-spawn-blocking` | Use `spawn_blocking` for CPU-intensive work |
| `async-tokio-fs` | Use `tokio::fs` not `std::fs` in async code |
| `async-cancellation-token` | Use `CancellationToken` for graceful shutdown |
| `async-join-parallel` | Use `tokio::join!` for parallel operations |
| `async-try-join` | Use `tokio::try_join!` for fallible parallel ops |
| `async-select-racing` | Use `tokio::select!` for racing/timeouts |
| `async-bounded-channel` | Use bounded channels for backpressure |
| `async-mpsc-queue` | Use `mpsc` for work queues |
| `async-broadcast-pubsub` | Use `broadcast` for pub/sub patterns |
| `async-watch-latest` | Use `watch` for latest-value sharing |
| `async-oneshot-response` | Use `oneshot` for request/response |
| `async-joinset-structured` | Use `JoinSet` for dynamic task groups |
| `async-clone-before-await` | Clone data before await, release locks |

### Compiler Optimization (`opt-`)

| Rule | Description |
|------|-------------|
| `opt-inline-small` | Use `#[inline]` for small hot functions |
| `opt-inline-always-rare` | Use `#[inline(always)]` sparingly |
| `opt-inline-never-cold` | Use `#[inline(never)]` for cold paths |
| `opt-cold-unlikely` | Use `#[cold]` for error/unlikely paths |
| `opt-likely-hint` | Use `likely()`/`unlikely()` for branch hints |
| `opt-lto-release` | Enable LTO in release builds |
| `opt-codegen-units` | Use `codegen-units = 1` for max optimization |
| `opt-pgo-profile` | Use PGO for production builds |
| `opt-target-cpu` | Set `target-cpu=native` for local builds |
| `opt-bounds-check` | Use iterators to avoid bounds checks |
| `opt-simd-portable` | Use portable SIMD for data-parallel ops |
| `opt-cache-friendly` | Design cache-friendly data layouts (SoA) |

### Naming Conventions (`name-`)

| Rule | Description |
|------|-------------|
| `name-types-camel` | Use `UpperCamelCase` for types, traits, enums |
| `name-variants-camel` | Use `UpperCamelCase` for enum variants |
| `name-funcs-snake` | Use `snake_case` for functions, methods, modules |
| `name-consts-screaming` | Use `SCREAMING_SNAKE_CASE` for constants/statics |
| `name-lifetime-short` | Use short lowercase lifetimes: `'a`, `'de`, `'src` |
| `name-type-param-single` | Use single uppercase for type params: `T`, `E`, `K`, `V` |
| `name-as-free` | `as_` prefix: free reference conversion |
| `name-to-expensive` | `to_` prefix: expensive conversion |
| `name-into-ownership` | `into_` prefix: ownership transfer |
| `name-no-get-prefix` | No `get_` prefix for simple getters |
| `name-is-has-bool` | Use `is_`, `has_`, `can_` for boolean methods |
| `name-iter-convention` | Use `iter`/`iter_mut`/`into_iter` for iterators |
| `name-iter-method` | Name iterator methods consistently |
| `name-iter-type-match` | Iterator type names match method |
| `name-acronym-word` | Treat acronyms as words: `Uuid` not `UUID` |
| `name-crate-no-rs` | Crate names: no `-rs` suffix |

### Type Safety (`type-`)

| Rule | Description |
|------|-------------|
| `type-newtype-ids` | Wrap IDs in newtypes: `UserId(u64)` |
| `type-newtype-validated` | Newtypes for validated data: `Email`, `Url` |
| `type-enum-states` | Use enums for mutually exclusive states |
| `type-option-nullable` | Use `Option<T>` for nullable values |
| `type-result-fallible` | Use `Result<T, E>` for fallible operations |
| `type-phantom-marker` | Use `PhantomData<T>` for type-level markers |
| `type-never-diverge` | Use `!` type for functions that never return |
| `type-generic-bounds` | Add trait bounds only where needed |
| `type-no-stringly` | Avoid stringly-typed APIs, use enums/newtypes |
| `type-repr-transparent` | Use `#[repr(transparent)]` for FFI newtypes |

### Testing (`test-`)

| Rule | Description |
|------|-------------|
| `test-cfg-test-module` | Use `#[cfg(test)] mod tests { }` |
| `test-use-super` | Use `use super::*;` in test modules |
| `test-integration-dir` | Put integration tests in `tests/` directory |
| `test-descriptive-names` | Use descriptive test names |
| `test-arrange-act-assert` | Structure tests as arrange/act/assert |
| `test-proptest-properties` | Use `proptest` for property-based testing |
| `test-mockall-mocking` | Use `mockall` for trait mocking |
| `test-mock-traits` | Use traits for dependencies to enable mocking |
| `test-fixture-raii` | Use RAII pattern (Drop) for test cleanup |
| `test-tokio-async` | Use `#[tokio::test]` for async tests |
| `test-should-panic` | Use `#[should_panic]` for panic tests |
| `test-criterion-bench` | Use `criterion` for benchmarking |
| `test-doctest-examples` | Keep doc examples as executable tests |

### Documentation (`doc-`)

| Rule | Description |
|------|-------------|
| `doc-all-public` | Document all public items with `///` |
| `doc-module-inner` | Use `//!` for module-level documentation |
| `doc-examples-section` | Include `# Examples` with runnable code |
| `doc-errors-section` | Include `# Errors` for fallible functions |
| `doc-panics-section` | Include `# Panics` for panicking functions |
| `doc-safety-section` | Include `# Safety` for unsafe functions |
| `doc-question-mark` | Use `?` in examples, not `.unwrap()` |
| `doc-hidden-setup` | Use `# ` prefix to hide example setup code |
| `doc-intra-links` | Use intra-doc links: `[Vec]` |
| `doc-link-types` | Link related types and functions in docs |
| `doc-cargo-metadata` | Fill `Cargo.toml` metadata |

### Performance Patterns (`perf-`)

| Rule | Description |
|------|-------------|
| `perf-iter-over-index` | Prefer iterators over manual indexing |
| `perf-iter-lazy` | Keep iterators lazy, `collect()` only when needed |
| `perf-collect-once` | Don't `collect()` intermediate iterators |
| `perf-entry-api` | Use `entry()` API for map insert-or-update |
| `perf-drain-reuse` | Use `drain()` to reuse allocations |
| `perf-extend-batch` | Use `extend()` for batch insertions |
| `perf-chain-avoid` | Avoid `chain()` in hot loops |
| `perf-collect-into` | Use `collect_into()` for reusing containers |
| `perf-black-box-bench` | Use `black_box()` in benchmarks |
| `perf-release-profile` | Optimize release profile settings |
| `perf-profile-first` | Profile before optimizing |

### Project Structure (`proj-`)

| Rule | Description |
|------|-------------|
| `proj-lib-main-split` | Keep `main.rs` minimal, logic in `lib.rs` |
| `proj-mod-by-feature` | Organize modules by feature, not type |
| `proj-flat-small` | Keep small projects flat |
| `proj-mod-rs-dir` | Use `mod.rs` for multi-file modules |
| `proj-pub-crate-internal` | Use `pub(crate)` for internal APIs |
| `proj-pub-super-parent` | Use `pub(super)` for parent-only visibility |
| `proj-pub-use-reexport` | Use `pub use` for clean public API |
| `proj-prelude-module` | Create `prelude` module for common imports |
| `proj-bin-dir` | Put multiple binaries in `src/bin/` |
| `proj-workspace-large` | Use workspaces for large projects |
| `proj-workspace-deps` | Use workspace dependency inheritance |

### Clippy & Linting (`lint-`)

| Rule | Description |
|------|-------------|
| `lint-deny-correctness` | `#![deny(clippy::correctness)]` |
| `lint-warn-suspicious` | `#![warn(clippy::suspicious)]` |
| `lint-warn-style` | `#![warn(clippy::style)]` |
| `lint-warn-complexity` | `#![warn(clippy::complexity)]` |
| `lint-warn-perf` | `#![warn(clippy::perf)]` |
| `lint-pedantic-selective` | Enable `clippy::pedantic` selectively |
| `lint-missing-docs` | `#![warn(missing_docs)]` |
| `lint-unsafe-doc` | `#![warn(clippy::undocumented_unsafe_blocks)]` |
| `lint-cargo-metadata` | `#![warn(clippy::cargo)]` for published crates |
| `lint-rustfmt-check` | Run `cargo fmt --check` in CI |
| `lint-workspace-lints` | Configure lints at workspace level |

### Anti-patterns (`anti-`)

| Rule | Description |
|------|-------------|
| `anti-unwrap-abuse` | Don't use `.unwrap()` in production code |
| `anti-expect-lazy` | Don't use `.expect()` for recoverable errors |
| `anti-clone-excessive` | Don't clone when borrowing works |
| `anti-lock-across-await` | Don't hold locks across `.await` |
| `anti-string-for-str` | Don't accept `&String` when `&str` works |
| `anti-vec-for-slice` | Don't accept `&Vec<T>` when `&[T]` works |
| `anti-index-over-iter` | Don't use indexing when iterators work |
| `anti-panic-expected` | Don't panic on expected/recoverable errors |
| `anti-empty-catch` | Don't use empty `if let Err(_) = ...` blocks |
| `anti-over-abstraction` | Don't over-abstract with excessive generics |
| `anti-premature-optimize` | Don't optimize before profiling |
| `anti-type-erasure` | Don't use `Box<dyn Trait>` when `impl Trait` works |
| `anti-format-hot-path` | Don't use `format!()` in hot paths |
| `anti-collect-intermediate` | Don't `collect()` intermediate iterators |
| `anti-stringly-typed` | Don't use strings for structured data |

## Ownership & Borrowing

- Prefer `&T` borrowing over `.clone()`
- Accept `&[T]` not `&Vec<T>`, `&str` not `&String`
- Use `Cow<'a, T>` for conditional ownership
- Use `Arc<T>` for thread-safe shared ownership, `Rc<T>` for single-threaded
- Use `RefCell<T>` (single-thread) or `Mutex<T>`/`RwLock<T>` (multi-thread) for interior mutability
- Derive `Copy` for small, trivial types
- Move large data instead of cloning
- Rely on lifetime elision when possible

## Error Handling

- Use `thiserror` for library error types, `anyhow` for application error handling
- Return `Result`, don't panic on expected errors
- Add context with `.context()` or `.with_context()`
- Never use `.unwrap()` in production code
- Use `.expect()` only for programming errors
- Use `?` operator for clean propagation
- Use `#[from]` for automatic error conversion
- Use `#[source]` to chain underlying errors
- Error messages: lowercase, no trailing punctuation
- Document errors with `# Errors` section
- Create custom error types, not `Box<dyn Error>`

## Memory Optimization

- Use `with_capacity()` when size is known
- Use `SmallVec` for usually-small collections, `ArrayVec` for bounded-size
- Box large enum variants to reduce type size
- Use `Box<[T]>` instead of `Vec<T>` when fixed size
- Use `clone_from()` to reuse allocations
- Reuse collections with `clear()` in loops
- Avoid `format!()` when string literals work; use `write!()` instead
- Use smallest integer type that fits
- Assert hot type sizes to prevent regressions

## API Design

- Use Builder pattern for complex construction; add `#[must_use]` to builder types
- Use newtypes for type-safe distinctions (`UserId(u64)`, `Email`, `Url`)
- Use typestate for compile-time state machines
- Seal traits to prevent external implementations when appropriate
- Use extension traits to add methods to foreign types
- Parse into validated types at boundaries
- Accept `impl Into<T>` for flexible string inputs, `impl AsRef<T>` for borrowed inputs
- Add `#[must_use]` to `Result`-returning functions
- Use `#[non_exhaustive]` for future-proof enums/structs
- Implement `From`, not `Into` (auto-derived)
- Implement `Default` for sensible defaults
- Implement `Debug`, `Clone`, `PartialEq` eagerly
- Gate `Serialize`/`Deserialize` behind feature flag

## Async/Await

- Use Tokio for production async runtime
- Never hold `Mutex`/`RwLock` across `.await`
- Use `spawn_blocking` for CPU-intensive work
- Use `tokio::fs` not `std::fs` in async code
- Use `CancellationToken` for graceful shutdown
- Use `tokio::join!` for parallel operations, `tokio::try_join!` for fallible
- Use `tokio::select!` for racing/timeouts
- Use bounded channels for backpressure
- Use `JoinSet` for dynamic task groups
- Clone data before await, release locks

## Testing

- Use `#[cfg(test)] mod tests { }` with `use super::*;`
- Put integration tests in `tests/` directory
- Structure tests as arrange/act/assert
- Use `#[tokio::test]` for async tests
- Use `proptest` for property-based testing
- Use `mockall` for trait mocking; design dependencies as traits
- Use RAII pattern (Drop) for test cleanup
- Use `criterion` for benchmarking
- Keep doc examples as executable tests
- Use `#[should_panic]` for panic tests
- Aim for 80%+ coverage; test edge cases and error paths

## Anti-Patterns

The 15 `anti-*` rules are indexed in the Rule Index above with full rationale and ❌/✅ examples in [`rules/anti-patterns.md`](rules/anti-patterns.md).

## Essential Commands

```bash
cargo build --release    # Build with optimizations
cargo test                # Run all tests
cargo test -- --nocapture # Run tests with output
cargo clippy -- -D warnings  # Lint with warnings as errors
cargo fmt --check         # Check formatting
cargo doc --no-deps       # Generate documentation
cargo bench               # Run benchmarks
cargo fix --edition       # Auto-fix edition migration
```

## Cargo.toml Release Profile

```toml
[profile.release]
opt-level = 3
lto = "fat"
codegen-units = 1
panic = "abort"
strip = true

[profile.dev.package."*"]
opt-level = 3
```

## References

- `rules/` — 14 category files (179 rules total), one file per prefix group, read on demand
- `references/compiler-errors.md` — Compiler error quick reference (E0382, E0502, E0716, etc.)
