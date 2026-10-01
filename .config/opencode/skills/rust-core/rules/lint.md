# Lints and Warnings

> Loaded on demand from `SKILL.md` — one rule per `## <rule-id>` section.


## lint-cargo-metadata

> Enable clippy::cargo for published crates

### Why It Matters

The `clippy::cargo` lint group checks Cargo.toml for issues that affect publishing and dependency management. For crates intended for crates.io, these checks help ensure a professional, well-configured package.

### Configuration

```toml
### Cargo.toml
[lints.clippy]
cargo = "warn"
```

Or in code:

```rust
#![warn(clippy::cargo)]
```

### What It Catches

#### Missing Metadata

```toml
### WARN: missing package.description
### WARN: missing package.license or package.license-file
### WARN: missing package.repository
[package]
name = "my-crate"
version = "0.1.0"
```

#### Dependency Issues

```toml
### WARN: feature used but not defined
### WARN: dependency version not specified
[dependencies]
serde = "*"  # Bad: any version
tokio = { git = "..." }  # WARN for published crates
```

#### Feature Issues

```toml
### WARN: negative_feature_names
[features]
no-std = []  # Should be: std = [] (opt-out vs opt-in)

### WARN: redundant_feature_names
[features]
default = ["feature-a"]
feature-a = []  # Feature name matches crate name
```

### Notable Lints

| Lint | Issue |
|------|-------|
| `cargo_common_metadata` | Missing description/license/repository |
| `multiple_crate_versions` | Same crate at different versions |
| `negative_feature_names` | Features like `no-std` instead of `std` |
| `redundant_feature_names` | Feature same as crate name |
| `wildcard_dependencies` | Using `*` for version |

### Complete Cargo.toml

```toml
[package]
name = "my-crate"
version = "0.1.0"
edition = "2021"
rust-version = "1.70"

### Required for cargo lint satisfaction
description = "A short description of what this crate does"
license = "MIT OR Apache-2.0"
repository = "https://github.com/user/my-crate"

### Recommended
documentation = "https://docs.rs/my-crate"
readme = "README.md"
keywords = ["keyword1", "keyword2"]
categories = ["category-slug"]

[dependencies]
### Specific versions, not wildcards
serde = "1.0"
tokio = { version = "1.0", features = ["full"] }

[features]
default = ["std"]
std = []  # Opt-out, not no-std opt-in

[lints.clippy]
cargo = "warn"
```

### Multiple Crate Versions

```
### WARN: multiple versions of `syn` in dependency tree
### syn v1.0.109
### syn v2.0.48
```

Fix by updating dependencies or using `[patch]`:

```toml
[patch.crates-io]
old-dep = { git = "...", branch = "syn-2" }
```

### When to Disable

For internal/unpublished crates:

```toml
[lints.clippy]
cargo = "allow"  # Not publishing, metadata not needed
```

Or selectively:

```toml
[lints.clippy]
cargo = "warn"
multiple_crate_versions = "allow"  # Acceptable in this project
```

### See Also

- [doc-cargo-metadata](#doc-cargo-metadata) - Cargo.toml metadata
- [proj-workspace-deps](#proj-workspace-deps) - Workspace dependencies
- [lint-deny-correctness](#lint-deny-correctness) - Correctness lints


## lint-deny-correctness

> `#![deny(clippy::correctness)]`

### Why It Matters

Clippy's correctness lints catch code that is outright wrong - logic errors, undefined behavior, or code that doesn't do what you think. These should always be errors, not warnings.

### Setup

```rust
// At the top of lib.rs or main.rs
#![deny(clippy::correctness)]

// Or in Cargo.toml for workspace-wide
[lints.clippy]
correctness = "deny"
```

### What It Catches

```rust
// Infinite loop (iter::repeat without take)
for x in std::iter::repeat(1) {  // ERROR: infinite iterator
    println!("{}", x);
}

// Comparison to NaN (always false)
if x == f64::NAN {  // ERROR: NaN != NaN always
    // This never executes
}

// Use after free patterns
let r;
{
    let x = 5;
    r = &x;  // ERROR: x dropped here
}
println!("{}", r);

// Wrong equality check
if x = 5 {  // ERROR: assignment in condition (should be ==)
}

// Useless comparisons
if x >= 0 && x < 0 {  // ERROR: impossible condition
}
```

### Important Correctness Lints

```rust
// approx_constant - using imprecise PI, E values
let pi = 3.14;  // Use std::f64::consts::PI

// invalid_regex - regex that won't compile
let re = Regex::new("[");  // Invalid regex

// iter_next_loop - using .next() in for loop incorrectly
for x in iter.next() {  // Should be: for x in iter

// never_loop - loop that never actually loops
loop {
    break;  // Always breaks immediately
}

// nonsensical_open_options - impossible file options
File::options().read(false).write(false).open("f");

// unit_cmp - comparing unit type ()
if foo() == bar() { }  // Both return (), always true
```

### Full Recommended Lints

```rust
#![deny(clippy::correctness)]
#![warn(clippy::suspicious)]
#![warn(clippy::style)]
#![warn(clippy::complexity)]
#![warn(clippy::perf)]

// For published crates
#![warn(missing_docs)]
#![warn(clippy::cargo)]
```

### Running Clippy

```bash
### Basic check
cargo clippy

### With all warnings as errors
cargo clippy -- -D warnings

### Check specific lint category
cargo clippy -- -W clippy::correctness

### In CI (fail on warnings)
cargo clippy -- -D warnings -D clippy::correctness
```

### See Also

- [lint-warn-suspicious](#lint-warn-suspicious) - Warn on suspicious code
- [lint-warn-perf](#lint-warn-perf) - Warn on performance issues


## lint-missing-docs

> Warn on missing documentation for public items

### Why It Matters

The `missing_docs` lint ensures all public API items are documented. For libraries, documentation IS the user interface. Missing docs mean users can't understand your API without reading source code.

### Configuration

```rust
// In lib.rs
#![warn(missing_docs)]
```

Or in `Cargo.toml`:

```toml
[lints.rust]
missing_docs = "warn"
```

For strict enforcement:

```rust
#![deny(missing_docs)]
```

### What It Catches

```rust
#![warn(missing_docs)]

pub struct User {  // WARN: missing documentation for a struct
    pub name: String,  // WARN: missing documentation for a field
    pub age: u32,      // WARN: missing documentation for a field
}

pub fn process() { }  // WARN: missing documentation for a function

pub trait Handler {  // WARN: missing documentation for a trait
    fn handle(&self);  // WARN: missing documentation for a method
}
```

### Good

```rust
#![warn(missing_docs)]

//! User management module.

/// Represents a registered user in the system.
pub struct User {
    /// The user's display name.
    pub name: String,
    /// The user's age in years.
    pub age: u32,
}

/// Processes pending user requests.
///
/// # Examples
///
/// ```
/// process();
/// ```
pub fn process() { }

/// Handler trait for request processing.
pub trait Handler {
    /// Handle an incoming request.
    fn handle(&self);
}
```

### Private Items

`missing_docs` only applies to `pub` items. Private items don't trigger warnings:

```rust
#![warn(missing_docs)]

struct Internal { }  // No warning - private

pub struct Public { }  // WARN - public, needs docs
```

### Allow for Specific Items

```rust
#![warn(missing_docs)]

/// Documented module.
pub mod api {
    /// Documented struct.
    pub struct Config { }
    
    #[allow(missing_docs)]
    pub mod internal {
        // Internal API, docs not required
        pub struct Helper { }
    }
}
```

### Gradual Adoption

For existing codebases, start with `warn` and fix incrementally:

```rust
// Phase 1: Warn, fix critical items
#![warn(missing_docs)]

// Phase 2: After cleanup, deny
#![deny(missing_docs)]
```

### Combining with doc Attributes

```rust
#![warn(missing_docs)]
#![warn(rustdoc::broken_intra_doc_links)]
#![warn(rustdoc::private_intra_doc_links)]
```

### Workspace Configuration

```toml
### In workspace Cargo.toml
[workspace.lints.rust]
missing_docs = "warn"

### Member crates inherit
[lints]
workspace = true
```

### What to Document

| Item | Doc Focus |
|------|-----------|
| Structs | Purpose, usage example |
| Struct fields | What it represents |
| Enums | When to use each variant |
| Functions | What it does, params, return |
| Traits | Contract and expectations |
| Modules | What the module provides |

### See Also

- [doc-all-public](#doc-all-public) - Documentation patterns
- [lint-unsafe-doc](#lint-unsafe-doc) - Unsafe documentation
- [doc-examples-section](#doc-examples-section) - Adding examples


## lint-pedantic-selective

> Enable clippy::pedantic selectively

### Why It Matters

The `clippy::pedantic` group contains opinionated lints that aren't universally applicable. Enabling it wholesale produces noise; selectively enabling useful pedantic lints improves code quality without false positives.

### Bad

```rust
// Too noisy - will fight you constantly
#![warn(clippy::pedantic)]
```

### Good

```toml
### Cargo.toml - cherry-pick useful pedantic lints
[lints.clippy]
### Enable pedantic as baseline
pedantic = "warn"

### Disable noisy ones
missing_errors_doc = "allow"      # Document errors separately
missing_panics_doc = "allow"      # Document panics separately
module_name_repetitions = "allow" # Allow Foo::FooError pattern
too_many_lines = "allow"          # Function length varies
must_use_candidate = "allow"      # Too many suggestions
```

### Recommended Pedantic Lints

| Lint | Why Enable |
|------|-----------|
| `doc_markdown` | Catch unmarked code in docs |
| `match_wildcard_for_single_variants` | Explicit variant matching |
| `semicolon_if_nothing_returned` | Consistent semicolons |
| `string_add_assign` | Use `+=` for string concatenation |
| `unnested_or_patterns` | Simplify match patterns |
| `unused_self` | Catch methods that should be functions |
| `used_underscore_binding` | Warn on using `_var` |
| `wildcard_imports` | Avoid glob imports |

### Often Disabled

| Lint | Why Disable |
|------|-------------|
| `missing_errors_doc` | Handle with `#[doc]` policy |
| `missing_panics_doc` | Handle with `#[doc]` policy |
| `module_name_repetitions` | Sometimes intentional |
| `must_use_candidate` | Too aggressive |
| `too_many_lines` | Arbitrary threshold |
| `struct_excessive_bools` | Valid for config structs |

### Full Configuration

```toml
### Cargo.toml
[lints.clippy]
### Start with pedantic
pedantic = "warn"

### Keep these
doc_markdown = "warn"
match_wildcard_for_single_variants = "warn"
semicolon_if_nothing_returned = "warn"
unused_self = "warn"
wildcard_imports = "warn"

### Disable these
missing_errors_doc = "allow"
missing_panics_doc = "allow"
module_name_repetitions = "allow"
must_use_candidate = "allow"
too_many_lines = "allow"
similar_names = "allow"
struct_excessive_bools = "allow"
```

### Alternative: Explicit Opt-in

```toml
### Only enable specific lints, not the group
[lints.clippy]
### From pedantic, only these:
doc_markdown = "warn"
semicolon_if_nothing_returned = "warn"
unused_self = "warn"
wildcard_imports = "warn"
```

### Module-Level Overrides

```rust
// Allow specific lint for a module
#![allow(clippy::module_name_repetitions)]

// Or for specific items
#[allow(clippy::too_many_arguments)]
fn complex_function(/* many args */) { }
```

### Team Consensus

Pedantic lints are style choices. Agree as a team:

1. Enable `pedantic` as baseline
2. Run `cargo clippy` on codebase
3. Discuss each warning category
4. Disable ones that don't fit your style
5. Document decisions in `clippy.toml`

### See Also

- [lint-warn-style](#lint-warn-style) - Style warnings
- [lint-warn-complexity](#lint-warn-complexity) - Complexity warnings
- [lint-deny-correctness](#lint-deny-correctness) - Correctness lints


## lint-rustfmt-check

> Run cargo fmt --check in CI

### Why It Matters

Consistent formatting eliminates style debates and makes diffs cleaner. Running `cargo fmt --check` in CI ensures all code follows the same format. This catches formatting issues before merge, not after.

### CI Configuration

#### GitHub Actions

```yaml
name: CI

on: [push, pull_request]

jobs:
  fmt:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: rustfmt
      - run: cargo fmt --all --check
```

#### GitLab CI

```yaml
fmt:
  image: rust:latest
  script:
    - rustup component add rustfmt
    - cargo fmt --all --check
```

#### Pre-commit Hook

```bash
#!/bin/sh
### .git/hooks/pre-commit
cargo fmt --all --check
```

### Configuration

Create `rustfmt.toml` for custom settings:

```toml
### rustfmt.toml
edition = "2021"
max_width = 100
use_small_heuristics = "Max"
imports_granularity = "Module"
group_imports = "StdExternalCrate"
reorder_imports = true
```

### Common Options

| Option | Default | Description |
|--------|---------|-------------|
| `max_width` | 100 | Maximum line width |
| `tab_spaces` | 4 | Spaces per indent |
| `edition` | "2015" | Rust edition |
| `use_small_heuristics` | "Default" | Layout heuristics |
| `imports_granularity` | "Preserve" | Import grouping |
| `group_imports` | "Preserve" | Import ordering |

### Running Locally

```bash
### Check formatting (doesn't modify files)
cargo fmt --all --check

### Apply formatting
cargo fmt --all

### Format specific file
cargo fmt -- src/main.rs

### Check with verbose output
cargo fmt --all --check -- --verbose
```

### Workspace Formatting

```bash
### Format all workspace members
cargo fmt --all

### Format specific package
cargo fmt -p my-package
```

### Ignoring Files

In `rustfmt.toml`:

```toml
### Skip generated files
ignore = [
    "src/generated/*",
    "build.rs",
]
```

Or in code:

```rust
#[rustfmt::skip]
mod generated_code;

#[rustfmt::skip]
const MATRIX: [[i32; 4]; 4] = [
    [1, 0, 0, 0],
    [0, 1, 0, 0],
    [0, 0, 1, 0],
    [0, 0, 0, 1],
];
```

### Nightly Features

Some options require nightly:

```toml
### rustfmt.toml (nightly only)
unstable_features = true
imports_granularity = "Crate"
wrap_comments = true
format_code_in_doc_comments = true
```

```bash
### Use nightly rustfmt
cargo +nightly fmt
```

### IDE Integration

Most IDEs format on save. Configure to use project `rustfmt.toml`:

```json
// VS Code settings.json
{
  "rust-analyzer.rustfmt.extraArgs": ["--config-path", "./rustfmt.toml"]
}
```

### See Also

- [lint-warn-style](#lint-warn-style) - Style lints
- [lint-pedantic-selective](#lint-pedantic-selective) - Pedantic lints
- [name-funcs-snake](#name-funcs-snake) - Naming conventions


## lint-unsafe-doc

> Require documentation for unsafe blocks

### Why It Matters

The `undocumented_unsafe_blocks` lint ensures every unsafe block has a `// SAFETY:` comment explaining why the operation is sound. Unsafe code is the source of most memory safety bugs—documenting invariants catches mistakes and helps reviewers.

### Configuration

```rust
#![warn(clippy::undocumented_unsafe_blocks)]
```

Or in `Cargo.toml`:

```toml
[lints.clippy]
undocumented_unsafe_blocks = "warn"
```

For strict enforcement:

```toml
[lints.clippy]
undocumented_unsafe_blocks = "deny"
```

### Bad

```rust
pub fn read_data(ptr: *const u8, len: usize) -> &[u8] {
    unsafe {
        std::slice::from_raw_parts(ptr, len)  // WARN: undocumented
    }
}

impl Buffer {
    pub fn get_unchecked(&self, index: usize) -> &u8 {
        unsafe { self.data.get_unchecked(index) }  // WARN
    }
}
```

### Good

```rust
pub fn read_data(ptr: *const u8, len: usize) -> &[u8] {
    // SAFETY: Caller guarantees:
    // - ptr is valid for reads of len bytes
    // - ptr is properly aligned for u8
    // - the memory is initialized
    // - no mutable references exist to this memory
    unsafe {
        std::slice::from_raw_parts(ptr, len)
    }
}

impl Buffer {
    pub fn get_unchecked(&self, index: usize) -> &u8 {
        debug_assert!(index < self.len(), "index out of bounds");
        // SAFETY: We verified index < len in debug builds.
        // Callers must ensure index is within bounds.
        unsafe { self.data.get_unchecked(index) }
    }
}
```

### SAFETY Comment Format

```rust
// SAFETY: <explanation of why this is sound>
unsafe {
    // ...
}
```

The comment should explain:
1. **What invariants are upheld** - preconditions that make this safe
2. **Why the invariants hold** - how you know they're satisfied
3. **What could go wrong** - if invariants are violated

### Examples by Category

#### Pointer Operations

```rust
// SAFETY: ptr was obtained from Box::into_raw, so it's valid
// and properly aligned. We're taking back ownership.
let boxed = unsafe { Box::from_raw(ptr) };
```

#### Unchecked Operations

```rust
// SAFETY: We just checked that i < self.len() above.
// The bounds check cannot be elided by the optimizer
// because len() is not inlined.
unsafe { self.data.get_unchecked(i) }
```

#### FFI Calls

```rust
// SAFETY: libc::getenv is safe to call with a null-terminated
// string. We ensure null termination with CString::new.
// The returned pointer is valid for the lifetime of the environment.
let value = unsafe { libc::getenv(key.as_ptr()) };
```

#### Trait Implementations

```rust
// SAFETY: MyType contains no pointers or interior mutability,
// and all bit patterns are valid MyType values.
unsafe impl Send for MyType {}
unsafe impl Sync for MyType {}
```

### Related Lints

```toml
[lints.clippy]
undocumented_unsafe_blocks = "warn"
### Also consider:
multiple_unsafe_ops_per_block = "warn"  # One operation per block
```

### See Also

- [doc-safety-section](#doc-safety-section) - `# Safety` in docs
- [lint-deny-correctness](#lint-deny-correctness) - Correctness lints
- [type-repr-transparent](#type-repr-transparent) - FFI safety


## lint-warn-complexity

> Enable clippy::complexity for simpler code

### Why It Matters

The `clippy::complexity` lint group identifies unnecessarily complex code that can be simplified. Complex code is harder to read, maintain, and often hides bugs. Clippy suggests cleaner alternatives.

### Configuration

```rust
// In lib.rs or main.rs
#![warn(clippy::complexity)]
```

Or in `Cargo.toml`:

```toml
[lints.clippy]
complexity = "warn"
```

### What It Catches

### Unnecessary Complexity

```rust
// WARN: Overly complex boolean expression
if !(x == 0) { }  // Use: if x != 0 { }

// WARN: Manual implementation of Option::map
match option {
    Some(x) => Some(x + 1),
    None => None,
}  // Use: option.map(|x| x + 1)

// WARN: Unnecessary filter before count
iter.filter(|x| predicate(x)).count()  // Could simplify if only counting
```

### Redundant Operations

```rust
// WARN: Redundant allocation
let s = format!("literal");  // Use: "literal".to_string() or just "literal"

// WARN: Unnecessarily complicated match
match result {
    Ok(ok) => Ok(ok),
    Err(err) => Err(err),
}  // Just use: result

// WARN: Box::new in return position
fn make_error() -> Box<dyn Error> {
    Box::new(MyError)  // Could use: MyError.into()
}
```

### Overly Verbose Code

```rust
// WARN: bind_instead_of_map
option.and_then(|x| Some(x + 1))  // Use: option.map(|x| x + 1)

// WARN: clone_on_copy
let y = x.clone();  // Where x is Copy type, just use: let y = x;

// WARN: useless_let_if_seq
let result;
if condition {
    result = 1;
} else {
    result = 2;
}
// Use: let result = if condition { 1 } else { 2 };
```

### Notable Lints in This Group

| Lint | Simplification |
|------|---------------|
| `bind_instead_of_map` | Use `map` instead of `and_then(Some(...))` |
| `bool_comparison` | `if x == true` → `if x` |
| `clone_on_copy` | Remove `.clone()` for Copy types |
| `filter_next` | Use `.find()` instead |
| `option_map_unit_fn` | Use `if let` instead |
| `search_is_some` | Use `.any()` or `.contains()` |
| `unnecessary_cast` | Remove redundant casts |
| `useless_conversion` | Remove `.into()` when types match |

### Examples

```rust
// Before (complexity warnings)
fn find_positive(nums: &[i32]) -> Option<i32> {
    let filtered: Vec<_> = nums.iter()
        .cloned()
        .filter(|x| *x > 0)
        .collect();
    if filtered.len() == 0 {
        None
    } else {
        Some(filtered[0])
    }
}

// After (simplified)
fn find_positive(nums: &[i32]) -> Option<i32> {
    nums.iter()
        .copied()
        .find(|&x| x > 0)
}
```

### Cognitive Load

Complex code isn't just longer—it's harder to understand:

```rust
// High cognitive load
let value = if x.is_some() { x.unwrap() } else { y.unwrap_or(z) };

// Lower cognitive load
let value = x.unwrap_or_else(|| y.unwrap_or(z));
```

### See Also

- [lint-warn-style](#lint-warn-style) - Style warnings
- [lint-warn-perf](#lint-warn-perf) - Performance warnings
- [lint-pedantic-selective](#lint-pedantic-selective) - Pedantic lints


## lint-warn-perf

> Enable clippy::perf for performance improvements

### Why It Matters

The `clippy::perf` lint group catches performance anti-patterns—inefficient allocations, unnecessary copies, suboptimal API usage. While not all performance issues are critical, avoiding obvious inefficiencies is good practice.

### Configuration

```rust
// In lib.rs or main.rs
#![warn(clippy::perf)]
```

Or in `Cargo.toml`:

```toml
[lints.clippy]
perf = "warn"
```

### What It Catches

### Unnecessary Allocations

```rust
// WARN: Unnecessary to_string before into
fn take_string(s: impl Into<String>) { }
take_string("hello".to_string());  // Just use: "hello"

// WARN: Box::new in return with deref coercion
fn make_trait() -> Box<dyn Trait> {
    Box::new(concrete)  // Could use Into
}

// WARN: Unnecessary vec! for iteration
for x in vec![1, 2, 3] { }  // Use array: [1, 2, 3]
```

### Inefficient Operations

```rust
// WARN: Single-character string patterns
s.starts_with("x")  // Use char: 'x'
s.contains("a")     // Use char: 'a'

// WARN: iter().nth(0) instead of first()
iter.nth(0)  // Use: iter.first() or iter.next()

// WARN: Manual saturating arithmetic
if x > i32::MAX - y { i32::MAX } else { x + y }
// Use: x.saturating_add(y)
```

### Collection Inefficiencies

```rust
// WARN: extend with a single element
vec.extend(std::iter::once(item));  // Use: vec.push(item)

// WARN: Inefficient to_vec
slice.iter().cloned().collect::<Vec<_>>()  // Use: slice.to_vec()

// WARN: Manual string concatenation
let s = format!("{}{}", a, b);  // When both are &str, use: a.to_owned() + b
```

### Notable Lints in This Group

| Lint | Improvement |
|------|-------------|
| `box_collection` | Use `Vec<T>` not `Box<Vec<T>>` |
| `iter_nth` | Use `.get(n)` or `.next()` |
| `large_enum_variant` | Box large variants |
| `manual_memcpy` | Use slice copy methods |
| `redundant_allocation` | Remove double boxing |
| `single_char_pattern` | Use `char` not `&str` |
| `slow_vector_initialization` | Use `vec![0; n]` |
| `unnecessary_to_owned` | Remove redundant `.to_owned()` |

### Examples

```rust
// Before (perf warnings)
fn process(input: &str) -> String {
    let parts: Vec<_> = input.split(",").collect();
    let mut result = String::new();
    for part in parts.iter() {
        if part.starts_with(" ") {
            result = result + &part.trim().to_string();
        }
    }
    result
}

// After (optimized)
fn process(input: &str) -> String {
    input.split(',')
        .filter(|part| part.starts_with(' '))
        .map(str::trim)
        .collect()
}
```

### Allocation Patterns

```rust
// Unnecessary allocation
let vec: Vec<i32> = vec![];  // Creates capacity
let vec: Vec<i32> = Vec::new();  // No allocation

// Pre-allocation
let mut vec = Vec::with_capacity(100);  // One allocation
for i in 0..100 {
    vec.push(i);  // No reallocation
}
```

### String Patterns

```rust
// Slow: str pattern
s.contains("x");
s.find("y");

// Fast: char pattern
s.contains('x');
s.find('y');
```

### See Also

- [lint-warn-complexity](#lint-warn-complexity) - Complexity warnings
- [mem-with-capacity](#mem-with-capacity) - Pre-allocation
- [perf-profile-first](#perf-profile-first) - Profile before optimizing


## lint-warn-style

> Enable clippy::style for idiomatic code

### Why It Matters

The `clippy::style` lint group enforces idiomatic Rust patterns. While not bugs, style violations make code harder to read and maintain. Consistent style helps teams work together and makes code easier to review.

### Configuration

```rust
// In lib.rs or main.rs
#![warn(clippy::style)]
```

Or in `Cargo.toml`:

```toml
[lints.clippy]
style = "warn"
```

### What It Catches

### Redundant Code

```rust
// WARN: Redundant clone on Copy type
let x = 5;
let y = x.clone();  // Just use: let y = x;

// WARN: Redundant closure
iter.map(|x| foo(x))  // Just use: iter.map(foo)

// WARN: Redundant pattern matching
match result {
    Ok(x) => Ok(x),
    Err(e) => Err(e),
}  // Just return result
```

### Non-Idiomatic Patterns

```rust
// WARN: Should use if let
match option {
    Some(x) => do_something(x),
    None => {},
}
// Better: if let Some(x) = option { do_something(x) }

// WARN: Should use or_else
let value = if option.is_some() {
    option.unwrap()
} else {
    default()
};
// Better: option.unwrap_or_else(default)

// WARN: Collapsible if statements
if condition1 {
    if condition2 {
        do_something();
    }
}
// Better: if condition1 && condition2 { do_something() }
```

### Naming Issues

```rust
// WARN: Function should not start with 'is_' returning non-bool
fn is_valid() -> i32 { 0 }  // Misleading name

// WARN: Method should not be named 'new' without returning Self
impl Foo {
    fn new() -> Bar { Bar }  // Confusing
}
```

### Notable Lints in This Group

| Lint | Better Pattern |
|------|---------------|
| `len_zero` | Use `is_empty()` instead of `len() == 0` |
| `redundant_field_names` | Use shorthand `{ x }` not `{ x: x }` |
| `unused_unit` | Remove `-> ()` and trailing `()` |
| `collapsible_if` | Combine nested ifs with `&&` |
| `single_match` | Use `if let` instead |
| `match_like_matches_macro` | Use `matches!()` macro |
| `needless_return` | Remove explicit `return` at end |
| `question_mark` | Use `?` instead of `match` |

### Examples

```rust
// Before (style warnings)
fn process(data: Vec<i32>) -> Option<i32> {
    if data.len() == 0 {
        return None;
    }
    let first = match data.first() {
        Some(x) => x,
        None => return None,
    };
    return Some(*first);
}

// After (idiomatic)
fn process(data: Vec<i32>) -> Option<i32> {
    if data.is_empty() {
        return None;
    }
    let first = data.first()?;
    Some(*first)
}
```

### Selective Allowance

Some style lints may conflict with team preferences:

```rust
// If your team prefers explicit returns
#[allow(clippy::needless_return)]
fn explicit_return() -> i32 {
    return 42;
}
```

### See Also

- [lint-warn-suspicious](#lint-warn-suspicious) - Suspicious patterns
- [lint-warn-complexity](#lint-warn-complexity) - Complexity warnings
- [lint-rustfmt-check](#lint-rustfmt-check) - Formatting checks


## lint-warn-suspicious

> Enable clippy::suspicious for likely bugs

### Why It Matters

The `clippy::suspicious` lint group catches code patterns that are syntactically valid but almost always wrong. These are potential bugs that deserve investigation. Enabling this group as a warning helps catch mistakes early.

### Configuration

```rust
// In lib.rs or main.rs
#![warn(clippy::suspicious)]
```

Or in `Cargo.toml`:

```toml
[lints.clippy]
suspicious = "warn"
```

Or in `clippy.toml`:

```toml
warn = ["clippy::suspicious"]
```

### What It Catches

### Suspicious Arithmetic

```rust
// WARN: Suspicious use of + in a << expression
let bits = 1 << 4 + 1;  // Probably meant (1 << 4) + 1 or 1 << (4 + 1)

// WARN: Suspicious use of | in a + expression
let value = x | 1 + y;  // Probably meant (x | 1) + y or x | (1 + y)
```

### Suspicious Comparisons

```rust
// WARN: Almost swapped operands in a comparison
if 5 < x && x < 3 { }  // Impossible condition

// WARN: Suspicious assignment in a condition
if (x = 5) { }  // Probably meant x == 5
```

### Suspicious Method Calls

```rust
// WARN: Suspicious map usage
let _: Vec<_> = vec.iter().map(|x| { 
    println!("{}", x);  // Side effect in map
    x
}).collect();  // Use for_each instead

// WARN: Suspicious string formatting
let s = format!("{}", format!("{}", x));  // Redundant nested format
```

### Suspicious Casts

```rust
// WARN: Suspicious use of not on a bool
let inverted = !x as i32;  // Did you mean (!x) as i32 or !(x as i32)?

// WARN: Cast of float to int may lose precision
let n = 3.14_f64 as i32;  // May want .round() first
```

### Notable Lints in This Group

| Lint | Description |
|------|-------------|
| `suspicious_arithmetic_impl` | Unusual operator in arithmetic trait |
| `suspicious_assignment_formatting` | Looks like typo in assignment |
| `suspicious_else_formatting` | Else on wrong line |
| `suspicious_map` | Map with side effects |
| `suspicious_op_assign_impl` | Unusual op-assign implementation |
| `suspicious_splitn` | splitn that can't produce n parts |
| `suspicious_unary_op_formatting` | Confusing unary operator spacing |

### Example Catches

```rust
// Caught: Suspicious double negation
let value = --x;  // In Rust, this is -(-x), not pre-decrement

// Caught: Suspicious modulo
let remainder = x % 1;  // Always 0 for integers

// Caught: Suspicious else formatting
if condition {
    do_something();
}
else {  // Weird formatting, might be a mistake
    do_other();
}
```

### When to Allow

Rarely. If you need to suppress, document why:

```rust
#[allow(clippy::suspicious_arithmetic_impl)]
impl Mul for Matrix {
    // Custom matrix multiplication using + for reduction step
    fn mul(self, rhs: Self) -> Self::Output {
        // ...
    }
}
```

### See Also

- [lint-deny-correctness](#lint-deny-correctness) - Deny definite bugs
- [lint-warn-style](#lint-warn-style) - Style warnings
- [lint-warn-complexity](#lint-warn-complexity) - Complexity warnings


## lint-workspace-lints

> Configure lints at workspace level for consistent enforcement

### Why It Matters

Without centralized lint configuration, each crate develops its own standards (or none). Workspace-level lints (Rust 1.74+) ensure consistent code quality across all crates. Denied lints catch issues in CI before they reach production.

### Bad

```toml
### crate-a/Cargo.toml - strict
[lints.clippy]
unwrap_used = "deny"

### crate-b/Cargo.toml - lenient
### No lint config

### crate-c/Cargo.toml - different
[lints.clippy]
unwrap_used = "warn"

### Inconsistent enforcement, some issues slip through
```

### Good

```toml
### Root Cargo.toml
[workspace.lints.rust]
unsafe_code = "deny"
missing_docs = "warn"

[workspace.lints.clippy]
### Correctness
unwrap_used = "deny"
expect_used = "warn"
panic = "deny"

### Style
needless_pass_by_value = "warn"
redundant_clone = "warn"

### Complexity
cognitive_complexity = "warn"

[workspace.lints.rustdoc]
broken_intra_doc_links = "deny"

### crate-a/Cargo.toml
[lints]
workspace = true

### crate-b/Cargo.toml
[lints]
workspace = true
```

### Recommended Lint Configuration

```toml
### Root Cargo.toml
[workspace.lints.rust]
### Safety
unsafe_code = "deny"
missing_debug_implementations = "warn"

### Quality
unused_results = "warn"
unused_qualifications = "warn"

[workspace.lints.clippy]
### === Correctness (deny) ===
correctness = { level = "deny", priority = -1 }

### === Suspicious (deny) ===
suspicious = { level = "deny", priority = -1 }

### === Style (warn) ===
style = { level = "warn", priority = -1 }

### === Complexity (warn) ===
complexity = { level = "warn", priority = -1 }

### === Perf (warn) ===
perf = { level = "warn", priority = -1 }

### === Pedantic (selective) ===
### Not all pedantic lints are useful
doc_markdown = "warn"
needless_pass_by_value = "warn"
redundant_closure_for_method_calls = "warn"
semicolon_if_nothing_returned = "warn"

### === Nursery (selective) ===
cognitive_complexity = "warn"
useless_let_if_seq = "warn"

### === Restriction (selective) ===
unwrap_used = "deny"
expect_used = "warn"
dbg_macro = "warn"
print_stdout = "warn"  # Use logging instead
todo = "warn"

[workspace.lints.rustdoc]
broken_intra_doc_links = "deny"
private_intra_doc_links = "warn"
```

### Per-Crate Overrides

```toml
### crate-with-binary/Cargo.toml
[lints]
workspace = true

### Binary entry point can use unwrap
[lints.clippy]
unwrap_used = "allow"

### test-utils/Cargo.toml
[lints]
workspace = true

### Test utilities can print
[lints.clippy]
print_stdout = "allow"
```

### CI Integration

```yaml
### .github/workflows/ci.yml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy
      
      - name: Clippy
        run: cargo clippy --workspace --all-targets -- -D warnings
      
      - name: Rustdoc
        run: RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps
```

### Lint Categories

```toml
### Category-level configuration
[workspace.lints.clippy]
### All lints in category at once
correctness = { level = "deny", priority = -1 }
suspicious = { level = "deny", priority = -1 }
style = { level = "warn", priority = -1 }
complexity = { level = "warn", priority = -1 }
perf = { level = "warn", priority = -1 }
pedantic = { level = "warn", priority = -1 }

### Then override specific lints (higher priority)
missing_errors_doc = "allow"  # Override pedantic
```

### See Also

- [lint-deny-correctness](#lint-deny-correctness) - Critical lints
- [proj-workspace-deps](#proj-workspace-deps) - Workspace configuration
- [anti-unwrap-abuse](#anti-unwrap-abuse) - unwrap lints
