# Documentation

> Loaded on demand from `SKILL.md` — one rule per `## <rule-id>` section.


## doc-all-public

> Document all public items with `///` doc comments

### Why It Matters

Public items define your crate's API contract. Without documentation, users must read source code to understand how to use your library. Well-documented APIs reduce support burden, improve adoption, and serve as the primary reference for users.

Rust's `cargo doc` generates beautiful HTML documentation from doc comments, but only if you write them.

### Bad

```rust
pub struct Config {
    pub timeout: Duration,
    pub retries: u32,
    pub base_url: String,
}

pub fn connect(config: Config) -> Result<Connection, Error> {
    // ...
}

pub enum Status {
    Pending,
    Active,
    Failed,
}
```

### Good

```rust
/// Configuration for establishing a connection to the service.
///
/// # Examples
///
/// ```
/// use my_crate::Config;
/// use std::time::Duration;
///
/// let config = Config {
///     timeout: Duration::from_secs(30),
///     retries: 3,
///     base_url: "https://api.example.com".to_string(),
/// };
/// ```
pub struct Config {
    /// Maximum time to wait for a response before timing out.
    pub timeout: Duration,
    
    /// Number of retry attempts for failed requests.
    pub retries: u32,
    
    /// Base URL for all API requests.
    pub base_url: String,
}

/// Establishes a connection using the provided configuration.
///
/// # Errors
///
/// Returns an error if the connection cannot be established
/// or if the configuration is invalid.
pub fn connect(config: Config) -> Result<Connection, Error> {
    // ...
}

/// Represents the current status of a job.
pub enum Status {
    /// Job is waiting to be processed.
    Pending,
    /// Job is currently being processed.
    Active,
    /// Job has failed and will not be retried.
    Failed,
}
```

### What to Document

| Item Type | Required Content |
|-----------|------------------|
| Structs | Purpose, usage example |
| Struct fields | What the field represents |
| Enums | When to use each variant |
| Enum variants | What state it represents |
| Functions | What it does, parameters, return value |
| Traits | Contract and expected behavior |
| Trait methods | Default implementation behavior |
| Type aliases | Why the alias exists |
| Constants | What the value represents |

### Enforcement

Enable the `missing_docs` lint to catch undocumented public items:

```rust
#![warn(missing_docs)]
```

Or in `Cargo.toml` for workspace-wide enforcement:

```toml
[workspace.lints.rust]
missing_docs = "warn"
```

### See Also

- [doc-module-inner](#doc-module-inner) - Module-level documentation
- [doc-examples-section](#doc-examples-section) - Adding examples
- [lint-missing-docs](#lint-missing-docs) - Enforcing documentation


## doc-cargo-metadata

> Fill `Cargo.toml` metadata for published crates

### Why It Matters

Cargo.toml metadata appears on crates.io, in search results, and helps users evaluate your crate. Missing metadata makes your crate look unprofessional, harder to find, and harder to trust. Complete metadata improves discoverability and adoption.

### Bad

```toml
[package]
name = "my-awesome-crate"
version = "0.1.0"
edition = "2021"

[dependencies]
### ...
```

### Good

```toml
[package]
name = "my-awesome-crate"
version = "0.1.0"
edition = "2021"
rust-version = "1.70"

### Required for crates.io
description = "A fast, ergonomic HTTP client for Rust"
license = "MIT OR Apache-2.0"
repository = "https://github.com/username/my-awesome-crate"

### Highly recommended
documentation = "https://docs.rs/my-awesome-crate"
readme = "README.md"
keywords = ["http", "client", "async", "networking"]
categories = ["network-programming", "web-programming::http-client"]
authors = ["Your Name <you@example.com>"]
homepage = "https://my-awesome-crate.dev"

### Optional but helpful
include = ["src/**/*", "Cargo.toml", "LICENSE*", "README.md"]
exclude = ["tests/fixtures/*", ".github/*"]

[badges]
maintenance = { status = "actively-developed" }

[dependencies]
### ...
```

### Required Fields for Publishing

| Field | Purpose |
|-------|---------|
| `name` | Crate name on crates.io |
| `version` | Semver version |
| `license` or `license-file` | SPDX license identifier |
| `description` | One-line summary (≤256 chars) |

### Recommended Fields

| Field | Purpose | Example |
|-------|---------|---------|
| `repository` | Link to source code | `https://github.com/user/repo` |
| `documentation` | Link to docs | `https://docs.rs/crate` |
| `readme` | Path to README | `README.md` |
| `keywords` | Search terms (max 5) | `["http", "async"]` |
| `categories` | crates.io categories | `["network-programming"]` |
| `rust-version` | MSRV | `"1.70"` |

### Keywords Best Practices

```toml
### Good: specific, searchable terms
keywords = ["json", "serialization", "serde", "parsing"]

### Bad: too generic or redundant
keywords = ["rust", "library", "awesome", "fast", "best"]
```

### Categories

Choose from [crates.io categories](https://crates.io/category_slugs):

```toml
categories = [
    "network-programming",
    "web-programming::http-client",
    "asynchronous",
]
```

### License Patterns

```toml
### Single license
license = "MIT"

### Dual license (common in Rust ecosystem)
license = "MIT OR Apache-2.0"

### Custom license file
license-file = "LICENSE"
```

### Include/Exclude

Control what gets published:

```toml
### Explicit include (whitelist)
include = [
    "src/**/*",
    "Cargo.toml",
    "LICENSE*",
    "README.md",
    "CHANGELOG.md",
]

### Or exclude (blacklist)
exclude = [
    "tests/fixtures/large-file.bin",
    ".github/*",
    "benches/*",
]
```

### Verification

Check your package before publishing:

```bash
### See what will be included
cargo package --list

### Check metadata
cargo publish --dry-run
```

### See Also

- [doc-module-inner](#doc-module-inner) - Crate-level documentation
- [lint-cargo-metadata](#lint-cargo-metadata) - Linting Cargo.toml
- [proj-workspace-deps](#proj-workspace-deps) - Workspace management


## doc-errors-section

> Include `# Errors` section for fallible functions

### Why It Matters

Functions returning `Result` can fail in specific, documented ways. The `# Errors` section tells users exactly when and why a function might return an error, enabling them to handle failures appropriately without reading source code.

This is especially critical for library code where users cannot easily inspect implementation details.

### Bad

```rust
/// Opens a file and reads its contents.
pub fn read_file(path: &Path) -> Result<String, Error> {
    // Users have no idea what errors to expect
}

/// Connects to the database.
pub async fn connect(url: &str) -> Result<Connection, DbError> {
    // Multiple failure modes, none documented
}
```

### Good

```rust
/// Opens a file and reads its contents as a UTF-8 string.
///
/// # Errors
///
/// Returns an error if:
/// - The file does not exist ([`Error::NotFound`])
/// - The process lacks permission to read the file ([`Error::PermissionDenied`])
/// - The file contains invalid UTF-8 ([`Error::InvalidUtf8`])
pub fn read_file(path: &Path) -> Result<String, Error> {
    // ...
}

/// Establishes a connection to the database.
///
/// # Errors
///
/// This function will return an error if:
/// - The URL is malformed ([`DbError::InvalidUrl`])
/// - The database server is unreachable ([`DbError::ConnectionFailed`])
/// - Authentication fails ([`DbError::AuthenticationFailed`])
/// - The connection pool is exhausted ([`DbError::PoolExhausted`])
pub async fn connect(url: &str) -> Result<Connection, DbError> {
    // ...
}
```

### Error Documentation Patterns

### Simple Single Error

```rust
/// Parses a string as an integer.
///
/// # Errors
///
/// Returns [`ParseIntError`] if the string is not a valid integer.
pub fn parse_int(s: &str) -> Result<i64, ParseIntError> {
    s.parse()
}
```

### Multiple Error Variants

```rust
/// Sends an HTTP request and returns the response.
///
/// # Errors
///
/// | Error | Condition |
/// |-------|-----------|
/// | [`HttpError::Timeout`] | Request exceeded timeout duration |
/// | [`HttpError::InvalidUrl`] | URL could not be parsed |
/// | [`HttpError::ConnectionRefused`] | Server refused connection |
/// | [`HttpError::TlsError`] | TLS handshake failed |
pub fn send(request: Request) -> Result<Response, HttpError> {
    // ...
}
```

### Propagated Errors

```rust
/// Loads configuration from a file.
///
/// # Errors
///
/// Returns an error if:
/// - The configuration file cannot be read (IO error)
/// - The file contains invalid TOML syntax
/// - Required fields are missing from the configuration
///
/// The underlying error is wrapped with context about which
/// configuration file failed to load.
pub fn load_config(path: &Path) -> Result<Config, anyhow::Error> {
    // ...
}
```

### Linking to Error Types

Use intra-doc links to connect error variants to their definitions:

```rust
/// # Errors
///
/// Returns [`ValidationError::TooShort`] if the input is less than
/// the minimum length, or [`ValidationError::InvalidChars`] if it
/// contains forbidden characters.
```

### See Also

- [doc-panics-section](#doc-panics-section) - Documenting panics
- [err-doc-errors](#err-doc-errors) - Error documentation patterns
- [doc-intra-links](#doc-intra-links) - Linking to types


## doc-examples-section

> Include `# Examples` with runnable code

### Why It Matters

Examples are the most valuable part of documentation. They show users exactly how to use your API. Rust's doc tests ensure examples stay correct as code evolves.

### Bad

```rust
/// Parses a string into a Foo.
pub fn parse(s: &str) -> Result<Foo, Error> {
    // No examples - users have to guess usage
}

/// A widget for doing things.
/// 
/// This widget is very useful.
pub struct Widget {
    // Still no examples
}
```

### Good

```rust
/// Parses a string into a Foo.
///
/// # Examples
///
/// ```
/// use my_crate::parse;
///
/// let foo = parse("hello").unwrap();
/// assert_eq!(foo.name(), "hello");
/// ```
///
/// Handles empty strings:
///
/// ```
/// use my_crate::parse;
///
/// let foo = parse("").unwrap();
/// assert!(foo.is_empty());
/// ```
pub fn parse(s: &str) -> Result<Foo, Error> {
    // ...
}
```

### Use ? Not unwrap()

```rust
/// Loads configuration from a file.
///
/// # Examples
///
/// ```
/// # fn main() -> Result<(), Box<dyn std::error::Error>> {
/// use my_crate::Config;
///
/// let config = Config::load("config.toml")?;
/// println!("Port: {}", config.port);
/// # Ok(())
/// # }
/// ```
pub fn load(path: &str) -> Result<Config, Error> {
    // ...
}
```

### Hide Setup Code

```rust
/// Processes items from a database.
///
/// # Examples
///
/// ```
/// # use my_crate::{Database, Item};
/// # fn get_db() -> Database { Database::mock() }
/// let db = get_db();
/// let items = db.process_items()?;
/// assert!(!items.is_empty());
/// # Ok::<(), my_crate::Error>(())
/// ```
pub fn process_items(&self) -> Result<Vec<Item>, Error> {
    // ...
}
```

### Multiple Examples

```rust
/// Creates a new buffer with the specified capacity.
///
/// # Examples
///
/// Basic usage:
///
/// ```
/// use my_crate::Buffer;
///
/// let buf = Buffer::with_capacity(1024);
/// assert_eq!(buf.capacity(), 1024);
/// ```
///
/// Zero capacity creates an empty buffer:
///
/// ```
/// use my_crate::Buffer;
///
/// let buf = Buffer::with_capacity(0);
/// assert!(buf.is_empty());
/// ```
pub fn with_capacity(cap: usize) -> Self {
    // ...
}
```

### Show Error Cases

```rust
/// Divides two numbers.
///
/// # Examples
///
/// ```
/// use my_crate::divide;
///
/// assert_eq!(divide(10, 2), Ok(5));
/// ```
///
/// Division by zero returns an error:
///
/// ```
/// use my_crate::{divide, MathError};
///
/// assert_eq!(divide(10, 0), Err(MathError::DivisionByZero));
/// ```
pub fn divide(a: i32, b: i32) -> Result<i32, MathError> {
    // ...
}
```

### Running Doc Tests

```bash
### Run all doc tests
cargo test --doc

### Run doc tests for specific item
cargo test --doc my_function
```

### See Also

- [doc-question-mark](#doc-question-mark) - Use ? in examples
- [doc-hidden-setup](#doc-hidden-setup) - Hide setup code with #
- [doc-errors-section](#doc-errors-section) - Document error conditions


## doc-hidden-setup

> Use `# ` prefix to hide example setup code

### Why It Matters

Doc examples often require setup code (imports, struct initialization, mock data) that distracts from the main point. The `# ` prefix hides lines from rendered documentation while keeping them in the compiled test, showing users only the relevant code.

This keeps examples focused and readable while ensuring they still compile and run.

### Bad

```rust
/// Processes a batch of items.
///
/// # Examples
///
/// ```
/// use my_crate::{Processor, Config, Item};
/// use std::sync::Arc;
/// 
/// let config = Config {
///     batch_size: 100,
///     timeout_ms: 5000,
///     retry_count: 3,
/// };
/// let processor = Processor::new(Arc::new(config));
/// let items = vec![
///     Item::new("a"),
///     Item::new("b"),
///     Item::new("c"),
/// ];
/// 
/// // This is the actual example - buried after 15 lines of setup
/// let results = processor.process_batch(&items)?;
/// assert!(results.all_succeeded());
/// # Ok::<(), my_crate::Error>(())
/// ```
pub fn process_batch(&self, items: &[Item]) -> Result<Results, Error> {
    // ...
}
```

### Good

```rust
/// Processes a batch of items.
///
/// # Examples
///
/// ```
/// # use my_crate::{Processor, Config, Item, Error};
/// # use std::sync::Arc;
/// # let config = Config { batch_size: 100, timeout_ms: 5000, retry_count: 3 };
/// # let processor = Processor::new(Arc::new(config));
/// # let items = vec![Item::new("a"), Item::new("b"), Item::new("c")];
/// let results = processor.process_batch(&items)?;
/// assert!(results.all_succeeded());
/// # Ok::<(), Error>(())
/// ```
pub fn process_batch(&self, items: &[Item]) -> Result<Results, Error> {
    // ...
}
```

Users see only:

```rust
let results = processor.process_batch(&items)?;
assert!(results.all_succeeded());
```

### What to Hide

| Hide | Show |
|------|------|
| `use` statements | Core API usage |
| Type definitions | Method calls |
| Mock/test data setup | Key parameters |
| Error handling boilerplate | Return value handling |
| `Ok(())` return | Assertions (sometimes) |

### Pattern: Hiding Multi-Line Setup

```rust
/// # Examples
///
/// ```
/// # use my_crate::{Client, Request};
/// # fn main() -> Result<(), Box<dyn std::error::Error>> {
/// # let client = Client::builder()
/// #     .timeout(30)
/// #     .retry(3)
/// #     .build()?;
/// let response = client.send(Request::get("/users"))?;
/// println!("Status: {}", response.status());
/// # Ok(())
/// # }
/// ```
```

### Pattern: Showing Setup When Relevant

Sometimes setup IS the point—don't hide it:

```rust
/// Creates a new client with custom configuration.
///
/// # Examples
///
/// ```
/// use my_crate::Client;
///
/// // Configuration IS the example - show it
/// let client = Client::builder()
///     .base_url("https://api.example.com")
///     .timeout_secs(30)
///     .max_retries(3)
///     .build()?;
/// # Ok::<(), my_crate::Error>(())
/// ```
```

### Pattern: `ignore` and `no_run`

For examples that shouldn't run in tests:

```rust
/// # Examples
///
/// ```no_run
/// # use my_crate::Server;
/// // This would actually start a server - don't run in tests
/// let server = Server::bind("0.0.0.0:8080").await?;
/// server.run().await?;
/// # Ok::<(), my_crate::Error>(())
/// ```

/// ```ignore
/// // Pseudocode or incomplete example
/// let magic = do_something_undefined();
/// ```
```

### See Also

- [doc-examples-section](#doc-examples-section) - Writing examples
- [doc-question-mark](#doc-question-mark) - Using `?` in examples
- [test-doctest-examples](#test-doctest-examples) - Doctests as tests


## doc-intra-links

> Use intra-doc links to reference types and items

### Why It Matters

Intra-doc links (`[TypeName]`, `[method](Self::method)`) create clickable references in generated documentation. They're verified at doc-build time, catching broken links early. Unlike URL links, they automatically update when items are renamed or moved.

### Bad

```rust
/// Returns the length of the buffer.
/// 
/// See also `capacity()` for the allocated size, and the
/// `Buffer` struct for more details.
pub fn len(&self) -> usize {
    self.data.len()
}

/// Parses the input using std::str::FromStr trait.
/// Check the Error enum for possible failures.
pub fn parse<T: FromStr>(input: &str) -> Result<T, Error> {
    // ...
}
```

### Good

```rust
/// Returns the length of the buffer.
/// 
/// See also [`capacity()`](Self::capacity) for the allocated size, and
/// [`Buffer`] for more details.
pub fn len(&self) -> usize {
    self.data.len()
}

/// Parses the input using [`FromStr`] trait.
/// Check [`Error`] for possible failures.
///
/// [`FromStr`]: std::str::FromStr
pub fn parse<T: FromStr>(input: &str) -> Result<T, Error> {
    // ...
}
```

### Link Syntax

| Syntax | Links To | Example |
|--------|----------|---------|
| `[Name]` | Item in scope | `[Vec]`, `[Option]` |
| `[path::Name]` | Fully qualified item | `[std::vec::Vec]` |
| `[Self::method]` | Method on current type | `[Self::new]` |
| `[Type::method]` | Method on other type | `[String::new]` |
| `[Type::CONST]` | Associated constant | `[usize::MAX]` |
| `[text](path)` | Custom text | `[see here](Self::len)` |

### Common Patterns

### Linking to Self Members

```rust
impl Buffer {
    /// Creates an empty buffer.
    ///
    /// Use [`with_capacity`](Self::with_capacity) if you know the size.
    pub fn new() -> Self { /* ... */ }
    
    /// Creates a buffer with pre-allocated capacity.
    ///
    /// See [`new`](Self::new) for the default constructor.
    pub fn with_capacity(cap: usize) -> Self { /* ... */ }
}
```

### Linking to Trait Methods

```rust
/// Converts to a string representation.
///
/// This is the implementation of [`Display::fmt`](std::fmt::Display::fmt).
impl Display for MyType {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        // ...
    }
}
```

### Disambiguation

When names conflict, use suffixes:

```rust
/// See [`foo()`](fn@foo) for the function and [`foo`](mod@foo) for the module.

/// Works with [`Error`](struct@Error) struct or [`Error`](trait@Error) trait.
```

| Suffix | Item Type |
|--------|-----------|
| `fn@` | Function |
| `mod@` | Module |
| `struct@` | Struct |
| `enum@` | Enum |
| `trait@` | Trait |
| `type@` | Type alias |
| `const@` | Constant |
| `macro@` | Macro |

### Reference-Style Links

For repeated links or long paths:

```rust
/// Parses using [`serde`] with [`Deserialize`] trait.
/// Returns a [`Result`] that may contain [`Error`].
///
/// [`serde`]: https://serde.rs
/// [`Deserialize`]: serde::Deserialize
/// [`Result`]: std::result::Result
/// [`Error`]: crate::Error
```

### Verification

Enable link checking in CI:

```bash
RUSTDOCFLAGS="-D warnings" cargo doc --no-deps
```

This fails if any intra-doc links are broken.

### See Also

- [doc-all-public](#doc-all-public) - Documenting public items
- [doc-examples-section](#doc-examples-section) - Adding examples
- [doc-errors-section](#doc-errors-section) - Documenting errors


## doc-link-types

> Use intra-doc links to connect related types and functions

### Why It Matters

Intra-doc links (`[`TypeName`]`) create clickable references in generated documentation. They enable navigation between related items, verify that referenced items exist at compile time, and update automatically when items are renamed. Plain text references become stale and unclickable.

### Bad

```rust
/// Parses input and returns a ParseResult.
/// 
/// See also: ParseError for error types.
/// Uses the Tokenizer internally.
pub fn parse(input: &str) -> ParseResult {
    // "ParseResult", "ParseError", "Tokenizer" are not clickable
    // No verification they exist
}
```

### Good

```rust
/// Parses input and returns a [`ParseResult`].
///
/// # Errors
///
/// Returns [`ParseError::InvalidSyntax`] if the input contains invalid tokens.
/// Returns [`ParseError::UnexpectedEof`] if the input ends prematurely.
///
/// # Related
///
/// - [`Tokenizer`] - The underlying tokenizer used by this parser
/// - [`parse_file`] - Convenience function for parsing files
/// - [`ParseOptions`] - Configuration options for parsing
pub fn parse(input: &str) -> ParseResult {
    // All links are clickable and verified
}
```

### Link Syntax

```rust
/// Basic link to type in same module
/// See [`MyType`] for details.

/// Link to method
/// Use [`MyType::new`] to create instances.

/// Link to associated type
/// Returns [`Iterator::Item`].

/// Link to module
/// See the [`parser`] module.

/// Link to external crate type
/// Works with [`std::collections::HashMap`].

/// Link with custom text
/// See [the parser][`parse`] for details.

/// Link to module item
/// See [`crate::utils::helper`].

/// Link to parent module item
/// See [`super::Parent`].
```

### Common Patterns

```rust
/// A configuration builder.
///
/// # Example
///
/// ```
/// use my_crate::Config;
///
/// let config = Config::builder()
///     .timeout(30)
///     .build()?;
/// ```
///
/// # Methods
///
/// - [`Config::builder`] - Create a new builder
/// - [`Config::default`] - Create with defaults
///
/// # Related Types
///
/// - [`ConfigBuilder`] - The builder returned by [`Config::builder`]
/// - [`ConfigError`] - Errors that can occur when building
pub struct Config { ... }

impl Config {
    /// Creates a new [`ConfigBuilder`].
    ///
    /// This is equivalent to [`ConfigBuilder::new`].
    pub fn builder() -> ConfigBuilder { ... }
}
```

### Linking to Trait Items

```rust
/// Implements [`Iterator`] for lazy evaluation.
///
/// The [`Iterator::next`] method advances the cursor.
/// 
/// For parallel iteration, see [`rayon::ParallelIterator`].
pub struct MyIterator { ... }

impl Iterator for MyIterator {
    /// Advances and returns the next value.
    ///
    /// See also [`Iterator::nth`] for skipping elements.
    fn next(&mut self) -> Option<Self::Item> { ... }
}
```

### Broken Link Detection

```bash
### Catch broken intra-doc links
RUSTDOCFLAGS="-D warnings" cargo doc

### Or in CI
cargo doc --no-deps 2>&1 | grep "warning: unresolved link"
```

```toml
### Cargo.toml - deny broken links
[lints.rustdoc]
broken_intra_doc_links = "deny"
```

### Module-Level Documentation

```rust
//! # Parser Module
//!
//! This module provides parsing utilities.
//!
//! ## Main Types
//!
//! - [`Parser`] - The main parser struct
//! - [`Token`] - Tokens produced by tokenization
//! - [`Ast`] - The abstract syntax tree
//!
//! ## Functions
//!
//! - [`parse`] - Parse a string
//! - [`parse_file`] - Parse a file
//!
//! ## Errors
//!
//! All functions return [`ParseError`] on failure.

pub struct Parser { ... }
pub enum Token { ... }
pub struct Ast { ... }
```

### See Also

- [doc-examples-section](#doc-examples-section) - Code examples in docs
- [err-doc-errors](#err-doc-errors) - Documenting errors
- [lint-deny-correctness](#lint-deny-correctness) - Lint settings


## doc-module-inner

> Use `//!` for module-level documentation

### Why It Matters

Inner doc comments (`//!`) document the module itself, not the next item. They appear at the top of module files and describe the module's purpose, contents, and usage patterns. This helps users understand what a module provides before diving into individual items.

Module docs are the first thing users see in `cargo doc` when navigating to a module.

### Bad

```rust
// This module handles authentication
// It provides JWT and session-based auth

mod auth;

pub use auth::*;
```

```rust
// auth.rs
/// Authentication utilities  // Wrong: this documents nothing useful
use std::collections::HashMap;

pub struct Session { /* ... */ }
```

### Good

```rust
//! Authentication and authorization utilities.
//!
//! This module provides multiple authentication strategies:
//!
//! - [`JwtAuth`] - JSON Web Token based authentication
//! - [`SessionAuth`] - Cookie-based session authentication
//! - [`ApiKeyAuth`] - API key authentication for services
//!
//! # Examples
//!
//! ```
//! use my_crate::auth::{JwtAuth, Authenticator};
//!
//! let auth = JwtAuth::new("secret-key");
//! let token = auth.generate_token(&user)?;
//! ```
//!
//! # Feature Flags
//!
//! - `jwt` - Enables JWT authentication (enabled by default)
//! - `sessions` - Enables session-based authentication

use std::collections::HashMap;

pub struct Session { /* ... */ }
```

### Where to Use Inner Docs

| Location | Purpose |
|----------|---------|
| `lib.rs` | Crate-level documentation (appears on crate root) |
| `mod.rs` | Module documentation for directory modules |
| `module.rs` | Module documentation for single-file modules |

### Crate Root Example

```rust
//! # My Awesome Crate
//!
//! `my_crate` provides utilities for handling complex workflows.
//!
//! ## Quick Start
//!
//! ```rust
//! use my_crate::prelude::*;
//!
//! let workflow = Workflow::builder()
//!     .add_step(Step::new("fetch"))
//!     .add_step(Step::new("process"))
//!     .build();
//! ```
//!
//! ## Modules
//!
//! - [`workflow`] - Core workflow engine
//! - [`steps`] - Built-in workflow steps
//! - [`prelude`] - Common imports
//!
//! ## Feature Flags
//!
//! | Feature | Description |
//! |---------|-------------|
//! | `async` | Async workflow execution |
//! | `serde` | Serialization support |

pub mod workflow;
pub mod steps;
pub mod prelude;
```

### Key Sections for Module Docs

1. **Brief description** - One-line summary
2. **Overview** - What the module provides
3. **Examples** - How to use it
4. **Feature flags** - Optional functionality
5. **See Also** - Related modules

### See Also

- [doc-all-public](#doc-all-public) - Documenting public items
- [doc-examples-section](#doc-examples-section) - Adding examples
- [doc-cargo-metadata](#doc-cargo-metadata) - Crate metadata


## doc-panics-section

> Include `# Panics` section for functions that can panic

### Why It Matters

Panics are exceptional conditions that crash the program (or unwind the stack). Users need to know when a function might panic so they can ensure preconditions are met or avoid the function in contexts where panics are unacceptable (e.g., `no_std`, embedded, FFI).

If a function can panic, document exactly when.

### Bad

```rust
/// Returns the element at the given index.
pub fn get(index: usize) -> &T {
    &self.data[index]  // Panics if out of bounds - not documented!
}

/// Divides two numbers.
pub fn divide(a: i32, b: i32) -> i32 {
    a / b  // Panics on division by zero - not documented!
}
```

### Good

```rust
/// Returns the element at the given index.
///
/// # Panics
///
/// Panics if `index` is out of bounds (i.e., `index >= self.len()`).
///
/// # Examples
///
/// ```
/// let v = vec![1, 2, 3];
/// assert_eq!(v.get(1), &2);
/// ```
pub fn get(&self, index: usize) -> &T {
    &self.data[index]
}

/// Divides two numbers.
///
/// # Panics
///
/// Panics if `divisor` is zero.
///
/// For a non-panicking version, use [`checked_divide`].
pub fn divide(dividend: i32, divisor: i32) -> i32 {
    dividend / divisor
}

/// Divides two numbers, returning `None` if the divisor is zero.
pub fn checked_divide(dividend: i32, divisor: i32) -> Option<i32> {
    if divisor == 0 {
        None
    } else {
        Some(dividend / divisor)
    }
}
```

### Common Panic Conditions

| Operation | Panic Condition |
|-----------|-----------------|
| Index access `[i]` | Index out of bounds |
| Division `/`, `%` | Division by zero |
| `.unwrap()` | `None` or `Err` value |
| `.expect()` | `None` or `Err` value |
| `slice::split_at(mid)` | `mid > len` |
| `Vec::remove(i)` | `i >= len` |
| Overflow (debug) | Integer overflow |

### Pattern: Panic vs Return Error

Document why you chose to panic vs return `Result`:

```rust
/// Creates a new buffer with the given capacity.
///
/// # Panics
///
/// Panics if `capacity` is zero. A buffer must have at least
/// one byte of capacity.
///
/// This panics rather than returning an error because a zero-capacity
/// buffer represents a programming error, not a runtime condition.
pub fn new(capacity: usize) -> Self {
    assert!(capacity > 0, "capacity must be non-zero");
    // ...
}
```

### Pattern: Debug-Only Panics

```rust
/// Adds an item to the collection.
///
/// # Panics
///
/// In debug builds, panics if the collection is at capacity.
/// In release builds, this is a no-op when at capacity.
pub fn push(&mut self, item: T) {
    debug_assert!(self.len < self.capacity, "collection at capacity");
    // ...
}
```

### Provide Non-Panicking Alternatives

When documenting a panicking function, point to safe alternatives:

```rust
/// # Panics
///
/// Panics if the index is out of bounds.
///
/// For a non-panicking version, use [`get`] which returns `Option<&T>`.
```

### See Also

- [doc-errors-section](#doc-errors-section) - Documenting errors
- [doc-safety-section](#doc-safety-section) - Documenting unsafe
- [err-result-over-panic](#err-result-over-panic) - Preferring Result


## doc-question-mark

> Use `?` in examples, not `.unwrap()`

### Why It Matters

Doc examples should model best practices. Using `.unwrap()` teaches users to ignore errors, while `?` demonstrates proper error propagation. Examples with `?` also fail the doctest if an error occurs, catching bugs in documentation.

Rust doctests wrap examples in a function that returns `Result<(), E>` by default when you use `?`, making this pattern easy to adopt.

### Bad

```rust
/// Reads a configuration file.
///
/// # Examples
///
/// ```
/// let config = Config::from_file("config.toml").unwrap();
/// println!("{:?}", config.database_url);
/// ```
pub fn from_file(path: &str) -> Result<Config, Error> {
    // ...
}

/// Fetches data from the API.
///
/// # Examples
///
/// ```
/// let client = Client::new();
/// let response = client.get("https://api.example.com").unwrap();
/// let data: Data = response.json().unwrap();
/// ```
pub async fn get(&self, url: &str) -> Result<Response, Error> {
    // ...
}
```

### Good

```rust
/// Reads a configuration file.
///
/// # Examples
///
/// ```
/// # use my_crate::{Config, Error};
/// # fn main() -> Result<(), Error> {
/// let config = Config::from_file("config.toml")?;
/// println!("{:?}", config.database_url);
/// # Ok(())
/// # }
/// ```
pub fn from_file(path: &str) -> Result<Config, Error> {
    // ...
}

/// Fetches data from the API.
///
/// # Examples
///
/// ```no_run
/// # use my_crate::{Client, Data, Error};
/// # async fn example() -> Result<(), Error> {
/// let client = Client::new();
/// let response = client.get("https://api.example.com").await?;
/// let data: Data = response.json().await?;
/// # Ok(())
/// # }
/// ```
pub async fn get(&self, url: &str) -> Result<Response, Error> {
    // ...
}
```

### Doctest Wrapper Pattern

Rust wraps doc examples in a function. You can make this explicit:

```rust
/// # Examples
///
/// ```
/// # fn main() -> Result<(), Box<dyn std::error::Error>> {
/// let value = parse_config("key=value")?;
/// assert_eq!(value.key, "value");
/// # Ok(())
/// # }
/// ```
```

Or use the implicit wrapper (Rust 2021+):

```rust
/// # Examples
///
/// ```
/// # use my_crate::parse_config;
/// let value = parse_config("key=value")?;
/// assert_eq!(value.key, "value");
/// # Ok::<(), my_crate::Error>(())
/// ```
```

### When to Use `.unwrap()`

There are specific cases where `.unwrap()` is acceptable in examples:

```rust
/// # Examples
///
/// ```
/// // Static regex that is known at compile time to be valid
/// let re = Regex::new(r"^\d{4}-\d{2}-\d{2}$").unwrap();
///
/// // Parsing a literal that cannot fail
/// let n: i32 = "42".parse().unwrap();
/// ```
```

But still prefer `?` when demonstrating error handling patterns.

### Comparison

| Pattern | Behavior on Error | Teaches |
|---------|-------------------|---------|
| `.unwrap()` | Panics with generic message | Bad habits |
| `.expect()` | Panics with custom message | Slightly better |
| `?` | Propagates error, test fails | Best practices |

### See Also

- [doc-examples-section](#doc-examples-section) - Writing examples
- [doc-hidden-setup](#doc-hidden-setup) - Hiding setup code
- [err-question-mark](#err-question-mark) - Error propagation


## doc-safety-section

> Include `# Safety` section for unsafe functions

### Why It Matters

Unsafe functions require callers to uphold invariants that the compiler cannot verify. The `# Safety` section documents exactly what the caller must guarantee for the function to be sound. Without this, users cannot safely call the function.

This is not optional—it's a requirement for sound unsafe code.

### Bad

```rust
/// Reads a value from a raw pointer.
pub unsafe fn read_ptr<T>(ptr: *const T) -> T {
    // What guarantees must the caller provide? Unknown!
    ptr.read()
}

/// Creates a string from raw parts.
pub unsafe fn string_from_raw(ptr: *mut u8, len: usize, cap: usize) -> String {
    String::from_raw_parts(ptr, len, cap)
}
```

### Good

```rust
/// Reads a value from a raw pointer.
///
/// # Safety
///
/// The caller must ensure that:
/// - `ptr` is valid for reads of `size_of::<T>()` bytes
/// - `ptr` is properly aligned for type `T`
/// - `ptr` points to a properly initialized value of type `T`
/// - The memory referenced by `ptr` is not mutated during this call
pub unsafe fn read_ptr<T>(ptr: *const T) -> T {
    ptr.read()
}

/// Creates a `String` from raw parts.
///
/// # Safety
///
/// The caller must guarantee that:
/// - `ptr` was allocated by the same allocator that `String` uses
/// - `len` is less than or equal to `cap`
/// - The first `len` bytes at `ptr` are valid UTF-8
/// - `cap` is the capacity that `ptr` was allocated with
/// - No other code will use `ptr` after this call (ownership is transferred)
///
/// Violating these requirements leads to undefined behavior including
/// memory corruption, use-after-free, or invalid UTF-8 in strings.
pub unsafe fn string_from_raw(ptr: *mut u8, len: usize, cap: usize) -> String {
    String::from_raw_parts(ptr, len, cap)
}
```

### Key Elements of Safety Documentation

| Element | Description |
|---------|-------------|
| **Preconditions** | What must be true before calling |
| **Pointer validity** | Alignment, null-ness, lifetime |
| **Memory ownership** | Who owns what, transfer semantics |
| **Invariants** | Type invariants that must hold |
| **Consequences** | What happens if violated |

### Pattern: Unsafe Trait Implementations

```rust
/// A type that can be safely zeroed.
///
/// # Safety
///
/// Implementing this trait guarantees that:
/// - All bit patterns of zeros represent a valid value of this type
/// - The type has no padding bytes that could leak data
/// - The type contains no references or pointers
pub unsafe trait Zeroable {
    fn zeroed() -> Self;
}

// SAFETY: u32 is a primitive integer type where all zero bits
// represent a valid value (0).
unsafe impl Zeroable for u32 {
    fn zeroed() -> Self {
        0
    }
}
```

### Pattern: Unsafe Blocks in Safe Functions

When a safe function contains unsafe blocks, document the invariants:

```rust
/// Returns a reference to the element at the given index.
///
/// Returns `None` if the index is out of bounds.
pub fn get(&self, index: usize) -> Option<&T> {
    if index < self.len {
        // SAFETY: We just verified that index < len, so this
        // access is within bounds.
        Some(unsafe { self.data.get_unchecked(index) })
    } else {
        None
    }
}
```

### Common Safety Requirements

```rust
/// # Safety
///
/// - Pointer must be non-null
/// - Pointer must be aligned to `align_of::<T>()`
/// - Pointer must be valid for reads/writes of `size_of::<T>()` bytes
/// - Pointer must point to an initialized value of `T`
/// - The referenced memory must not be accessed through any other pointer
///   for the duration of the returned reference
/// - The total size must not exceed `isize::MAX`
```

### See Also

- [doc-panics-section](#doc-panics-section) - Documenting panics
- [lint-unsafe-doc](#lint-unsafe-doc) - Enforcing unsafe documentation
- [doc-errors-section](#doc-errors-section) - Documenting errors
