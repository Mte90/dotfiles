# Error Handling

> Loaded on demand from `SKILL.md` — one rule per `## <rule-id>` section.


## err-anyhow-app

> Use `anyhow` for application error handling

### Why It Matters

Applications often don't need typed errors - they just need to report what went wrong with good context. `anyhow` provides easy error handling with context chaining, backtraces, and conversion from any error type.

### Bad

```rust
// Tedious type management
fn load_config() -> Result<Config, Box<dyn std::error::Error>> {
    let path = find_config()?;  // Returns FindError
    let content = std::fs::read_to_string(&path)?;  // Returns io::Error
    let config: Config = toml::from_str(&content)?;  // Returns toml::Error
    validate(&config)?;  // Returns ValidationError
    Ok(config)
}

// No context - hard to debug
fn process() -> Result<(), Box<dyn std::error::Error>> {
    let data = fetch()?;  // Which fetch failed?
    transform(data)?;     // What was being transformed?
    save()?;              // Where was it saving to?
    Ok(())
}
```

### Good

```rust
use anyhow::{Context, Result};

fn load_config() -> Result<Config> {
    let path = find_config()
        .context("failed to locate config file")?;
    
    let content = std::fs::read_to_string(&path)
        .with_context(|| format!("failed to read config from {}", path.display()))?;
    
    let config: Config = toml::from_str(&content)
        .context("failed to parse config as TOML")?;
    
    validate(&config)
        .context("config validation failed")?;
    
    Ok(config)
}

// Error message: "config validation failed: field 'port' must be > 0"
// Full chain preserved for debugging
```

### Key Features

```rust
use anyhow::{anyhow, bail, ensure, Context, Result};

fn example() -> Result<()> {
    // Create ad-hoc errors
    let err = anyhow!("something went wrong");
    
    // Early return with error
    bail!("aborting due to {}", reason);
    
    // Assert with error
    ensure!(condition, "condition was false");
    
    // Add context to any error
    risky_operation()
        .context("risky operation failed")?;
    
    // Dynamic context
    fetch(url)
        .with_context(|| format!("failed to fetch {}", url))?;
    
    Ok(())
}
```

### Main Function Pattern

```rust
use anyhow::Result;

fn main() -> Result<()> {
    let config = load_config()?;
    run_app(config)?;
    Ok(())
}

// Or with custom exit handling
fn main() {
    if let Err(e) = run() {
        eprintln!("Error: {:#}", e);  // Pretty-print with causes
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    // Application logic
    Ok(())
}
```

### Error Display Formats

```rust
use anyhow::Result;

fn show_error(err: anyhow::Error) {
    // Just the top-level message
    println!("{}", err);
    // "config validation failed"
    
    // With cause chain (# alternate format)
    println!("{:#}", err);
    // "config validation failed: field 'port' must be > 0"
    
    // Debug format with backtrace
    println!("{:?}", err);
    // Full backtrace if RUST_BACKTRACE=1
    
    // Iterate through cause chain
    for cause in err.chain() {
        println!("Caused by: {}", cause);
    }
}
```

### Combining with thiserror

```rust
// In your library crate - typed errors
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ApiError {
    #[error("rate limited")]
    RateLimited,
    #[error("not found: {0}")]
    NotFound(String),
}

// In your application - anyhow for handling
use anyhow::{Context, Result};

fn fetch_user(id: u64) -> Result<User> {
    api::get_user(id)
        .with_context(|| format!("failed to fetch user {}", id))
}

// Can still downcast if needed
fn handle_error(err: anyhow::Error) {
    if let Some(api_err) = err.downcast_ref::<ApiError>() {
        match api_err {
            ApiError::RateLimited => wait_and_retry(),
            ApiError::NotFound(id) => log_missing(id),
        }
    }
}
```

### When to Use Which

| Situation | Use |
|-----------|-----|
| Library public API | `thiserror` |
| Application code | `anyhow` |
| CLI tools | `anyhow` |
| Internal library code | Either |
| Need to match error variants | `thiserror` |
| Just need to report errors | `anyhow` |

### See Also

- [err-thiserror-lib](#err-thiserror-lib) - Use thiserror for libraries
- [err-context-chain](#err-context-chain) - Add context to errors


## err-context-chain

> Add context with `.context()` or `.with_context()`

### Why It Matters

Raw errors often lack information about what operation failed. Adding context creates an error chain that tells the full story: what you were trying to do, and why it failed.

### Bad

```rust
// Raw error - no context
fn load_user(id: u64) -> Result<User, Error> {
    let path = format!("users/{}.json", id);
    let content = std::fs::read_to_string(&path)?;
    Ok(serde_json::from_str(&content)?)
}

// Error message: "No such file or directory (os error 2)"
// Which file? What were we doing?
```

### Good

```rust
use anyhow::{Context, Result};

fn load_user(id: u64) -> Result<User> {
    let path = format!("users/{}.json", id);
    
    let content = std::fs::read_to_string(&path)
        .with_context(|| format!("failed to read user file: {}", path))?;
    
    let user: User = serde_json::from_str(&content)
        .with_context(|| format!("failed to parse user {} JSON", id))?;
    
    Ok(user)
}

// Error: "failed to parse user 42 JSON"
// Caused by: "expected ':' at line 5 column 12"
```

### context() vs with_context()

```rust
// context() - static string (slight allocation)
fs::read_to_string(path)
    .context("failed to read config")?;

// with_context() - lazy evaluation (only allocates on error)
fs::read_to_string(path)
    .with_context(|| format!("failed to read {}", path))?;

// Use with_context() when:
// - Message includes runtime data (format!)
// - Computing the message is expensive
// - Error path is cold (most of the time)
```

### Building Context Chains

```rust
fn process_order(order_id: u64) -> Result<()> {
    let order = fetch_order(order_id)
        .with_context(|| format!("failed to fetch order {}", order_id))?;
    
    let user = load_user(order.user_id)
        .with_context(|| format!("failed to load user for order {}", order_id))?;
    
    let payment = process_payment(&order, &user)
        .context("payment processing failed")?;
    
    ship_order(&order, &payment)
        .context("shipping failed")?;
    
    Ok(())
}

// Full error chain:
// "shipping failed"
// Caused by: "carrier API returned 503"
// Caused by: "connection refused"
```

### Displaying Error Chains

```rust
fn main() {
    if let Err(e) = run() {
        // Just top-level message
        eprintln!("Error: {}", e);
        
        // Full chain with alternate format
        eprintln!("Error: {:#}", e);
        
        // Debug format (includes backtrace if enabled)
        eprintln!("Error: {:?}", e);
        
        // Iterate through chain
        for (i, cause) in e.chain().enumerate() {
            eprintln!("  {}: {}", i, cause);
        }
    }
}
```

### With thiserror

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("failed to load config from {path}")]
    ConfigLoad {
        path: String,
        #[source]
        cause: std::io::Error,
    },
    
    #[error("failed to connect to database")]
    Database {
        #[source]
        cause: sqlx::Error,
    },
}

// Usage
fn load_config(path: &str) -> Result<Config, AppError> {
    let content = std::fs::read_to_string(path)
        .map_err(|e| AppError::ConfigLoad {
            path: path.to_string(),
            cause: e,
        })?;
    // ...
}
```

### See Also

- [err-anyhow-app](#err-anyhow-app) - Use anyhow for applications
- [err-source-chain](#err-source-chain) - Use #[source] to chain errors
- [err-question-mark](#err-question-mark) - Use ? for propagation


## err-custom-type

> Define custom error types for domain-specific failures

### Why It Matters

Generic errors like `String`, `Box<dyn Error>`, or catch-all enums obscure what can actually go wrong. Custom error types document failure modes in the type system, enable pattern matching for specific handling, and provide clear API contracts. They make your code self-documenting and help callers handle errors appropriately.

### Bad

```rust
// Generic string errors - no structure
fn validate_user(user: &User) -> Result<(), String> {
    if user.name.is_empty() {
        return Err("Name is empty".to_string());
    }
    if user.age > 150 {
        return Err("Age is invalid".to_string());
    }
    Ok(())
}

// Caller can't match on specific errors
match validate_user(&user) {
    Ok(()) => save(user),
    Err(msg) => {
        // Can only do string comparison - fragile!
        if msg.contains("Name") {
            prompt_for_name()
        }
    }
}
```

### Good

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ValidationError {
    #[error("name cannot be empty")]
    EmptyName,
    
    #[error("name exceeds maximum length of {max} characters")]
    NameTooLong { max: usize, actual: usize },
    
    #[error("invalid age {0}: must be between 0 and 150")]
    InvalidAge(u8),
    
    #[error("email format is invalid: {0}")]
    InvalidEmail(String),
}

fn validate_user(user: &User) -> Result<(), ValidationError> {
    if user.name.is_empty() {
        return Err(ValidationError::EmptyName);
    }
    if user.name.len() > 100 {
        return Err(ValidationError::NameTooLong { 
            max: 100, 
            actual: user.name.len() 
        });
    }
    if user.age > 150 {
        return Err(ValidationError::InvalidAge(user.age));
    }
    Ok(())
}

// Caller can match specifically
match validate_user(&user) {
    Ok(()) => save(user),
    Err(ValidationError::EmptyName) => prompt_for_name(),
    Err(ValidationError::InvalidAge(age)) => {
        show_error(&format!("Please enter a valid age (you entered {})", age))
    }
    Err(e) => show_error(&e.to_string()),
}
```

### Error Type Design Guidelines

```rust
// 1. Group related errors in domain-specific enums
#[derive(Error, Debug)]
pub enum AuthError {
    #[error("invalid credentials")]
    InvalidCredentials,
    #[error("account locked after {attempts} failed attempts")]
    AccountLocked { attempts: u32 },
    #[error("token expired")]
    TokenExpired,
}

#[derive(Error, Debug)]
pub enum PaymentError {
    #[error("insufficient funds: need {required}, have {available}")]
    InsufficientFunds { required: Decimal, available: Decimal },
    #[error("card declined: {reason}")]
    CardDeclined { reason: String },
}

// 2. Include relevant data for error handling/display
#[derive(Error, Debug)]
pub enum FileError {
    #[error("file not found: {path}")]
    NotFound { path: PathBuf },
    #[error("permission denied for {path}")]
    PermissionDenied { path: PathBuf },
}

// 3. Consider #[non_exhaustive] for public APIs
#[derive(Error, Debug)]
#[non_exhaustive]  // Allows adding variants without breaking changes
pub enum ApiError {
    #[error("rate limited")]
    RateLimited,
    #[error("not found")]
    NotFound,
}
```

### When to Use What

| Error Pattern | Use Case |
|---------------|----------|
| Custom enum | Library with specific failure modes |
| `thiserror` | Libraries needing `std::error::Error` |
| `anyhow::Error` | Applications, prototypes |
| Struct with source | Single error type with wrapped cause |

### Struct-Based Errors

For single error types with rich context:

```rust
#[derive(Error, Debug)]
#[error("query failed for table '{table}' with filter '{filter}'")]
pub struct QueryError {
    pub table: String,
    pub filter: String,
    #[source]
    pub source: DatabaseError,
}
```

### See Also

- [err-thiserror-lib](#err-thiserror-lib) - thiserror for error definitions
- [err-anyhow-app](#err-anyhow-app) - When to use anyhow instead
- [api-non-exhaustive](#api-non-exhaustive) - Forward-compatible enums


## err-doc-errors

> Document error conditions with `# Errors` section in doc comments

### Why It Matters

Users of your API need to know what can go wrong and why. The `# Errors` documentation section is the standard Rust convention for describing when a function returns `Err`. Good error documentation helps callers handle errors appropriately and understand the contract of your API.

### Bad

```rust
/// Loads a configuration from the specified path.
pub fn load_config(path: &Path) -> Result<Config, ConfigError> {
    // No documentation of error conditions
    // Caller must read source code to understand what can fail
}

/// Parses and validates the input string.
/// 
/// Returns the parsed value.  // What about errors?
pub fn parse_input(input: &str) -> Result<Value, ParseError> {
    // ...
}
```

### Good

```rust
/// Loads a configuration from the specified path.
///
/// # Errors
///
/// Returns an error if:
/// - The file at `path` does not exist or cannot be read
/// - The file contents are not valid TOML
/// - Required configuration keys are missing
/// - Configuration values are out of valid ranges
///
/// # Examples
///
/// ```
/// # use mylib::{load_config, ConfigError};
/// # fn main() -> Result<(), ConfigError> {
/// let config = load_config("app.toml")?;
/// # Ok(())
/// # }
/// ```
pub fn load_config(path: &Path) -> Result<Config, ConfigError> {
    // ...
}

/// Parses and validates the input string as a positive integer.
///
/// # Errors
///
/// Returns [`ParseError::Empty`] if the input is empty.
/// Returns [`ParseError::InvalidFormat`] if the input contains non-digit characters.
/// Returns [`ParseError::Overflow`] if the value exceeds `i64::MAX`.
/// Returns [`ParseError::NotPositive`] if the value is zero or negative.
pub fn parse_positive_int(input: &str) -> Result<i64, ParseError> {
    // ...
}
```

### Linking to Error Variants

```rust
/// Attempts to connect to the database.
///
/// # Errors
///
/// This function will return an error if:
///
/// - [`DbError::ConnectionFailed`] - The database server is unreachable
/// - [`DbError::AuthenticationFailed`] - Invalid credentials
/// - [`DbError::Timeout`] - Connection attempt exceeded timeout
/// - [`DbError::TlsError`] - TLS handshake failed
///
/// See [`DbError`] for more details on each variant.
pub fn connect(config: &DbConfig) -> Result<Connection, DbError> {
    // ...
}
```

### Panic vs Error Documentation

```rust
/// Divides two numbers.
///
/// # Errors
///
/// Returns [`MathError::DivisionByZero`] if `divisor` is zero.
///
/// # Panics
///
/// Panics if called from a non-main thread (debug builds only).
pub fn divide(dividend: i64, divisor: i64) -> Result<i64, MathError> {
    // ...
}
```

### Error Section Format Options

```rust
// Style 1: Bullet list (good for multiple conditions)
/// # Errors
///
/// Returns an error if:
/// - The file does not exist
/// - The file cannot be read
/// - The content is invalid UTF-8

// Style 2: Returns statements (good for mapping to variants)
/// # Errors
///
/// Returns [`Error::NotFound`] if the item doesn't exist.
/// Returns [`Error::PermissionDenied`] if access is forbidden.

// Style 3: Prose (good for complex conditions)
/// # Errors
///
/// This function returns an error when the input fails validation.
/// Validation includes checking that all required fields are present,
/// that numeric fields are within allowed ranges, and that string
/// fields match their expected formats.
```

### Clippy Lint

```toml
### Cargo.toml - require error documentation
[lints.clippy]
missing_errors_doc = "warn"
```

```rust
// This will warn without # Errors section
pub fn might_fail() -> Result<(), Error> { Ok(()) }
```

### See Also

- [doc-examples-section](#doc-examples-section) - Examples in documentation
- [err-thiserror-lib](#err-thiserror-lib) - Defining error types
- [api-must-use](#api-must-use) - Marking Results as must_use


## err-expect-bugs-only

> Use `expect()` only for invariants that indicate bugs, not user errors

### Why It Matters

`expect()` is better than `unwrap()` because it provides context, but it still panics. Reserve it for situations where failure indicates a bug in your code—a violated invariant, not a user error or external failure. The message should explain why the invariant should hold, helping future developers understand and fix the bug.

### Bad

```rust
// User input can legitimately fail - don't expect
fn parse_user_input(input: &str) -> Config {
    serde_json::from_str(input)
        .expect("Invalid JSON")  // User error, not a bug!
}

// Network can fail - don't expect
fn fetch_data(url: &str) -> Data {
    reqwest::get(url)
        .expect("Network request failed")  // External failure!
        .json()
        .expect("Invalid response")
}

// File might not exist - don't expect
fn load_config() -> Config {
    let content = fs::read_to_string("config.json")
        .expect("Config file missing");  // Environment issue!
}
```

### Good

```rust
// Invariant: after insert, key exists
fn cache_and_get(&mut self, key: String, value: Value) -> &Value {
    self.cache.insert(key.clone(), value);
    self.cache.get(&key)
        .expect("BUG: key must exist immediately after insert")
}

// Invariant: regex is compile-time constant
fn create_parser() -> Regex {
    Regex::new(r"^\d{4}-\d{2}-\d{2}$")
        .expect("BUG: date regex is invalid - this is a compile-time constant")
}

// Invariant: already validated
fn process_validated(data: ValidatedData) -> Result<Output, ProcessError> {
    let value = data.required_field
        .expect("BUG: ValidatedData guarantees required_field is Some");
    // ...
}

// Invariant: type system guarantees
fn get_first<T>(vec: Vec<T>) -> T 
where 
    Vec<T>: NonEmpty,  // Hypothetical trait
{
    vec.into_iter().next()
        .expect("BUG: NonEmpty Vec cannot be empty")
}
```

### expect() Message Guidelines

Messages should:
1. Start with "BUG:" or similar to indicate it's an invariant
2. Explain WHY the invariant should hold
3. Help developers fix the issue

```rust
// ❌ Bad messages
.expect("failed")                    // No context
.expect("should not be None")        // Doesn't explain why
.expect("Invalid state")             // Vague

// ✅ Good messages
.expect("BUG: HashMap entry exists after insert")
.expect("BUG: validated input must parse - validation is broken")
.expect("BUG: static regex compilation failed - regex syntax error in source")
```

### Pattern: Validate Once, expect() After

```rust
struct ValidatedEmail(String);

impl ValidatedEmail {
    pub fn new(email: &str) -> Result<Self, EmailError> {
        // Validation happens here, returns Result
        if !is_valid_email(email) {
            return Err(EmailError::Invalid);
        }
        Ok(ValidatedEmail(email.to_string()))
    }
    
    pub fn domain(&self) -> &str {
        // After validation, expect() is fine
        self.0.split('@').nth(1)
            .expect("BUG: ValidatedEmail must contain @")
    }
}
```

### Alternatives When expect() Is Wrong

```rust
// Don't: expect on user data
let port: u16 = input.parse().expect("Invalid port");

// Do: Return Result
let port: u16 = input.parse().map_err(|_| ConfigError::InvalidPort)?;

// Do: Provide default
let port: u16 = input.parse().unwrap_or(8080);

// Do: Handle explicitly
let port: u16 = match input.parse() {
    Ok(p) => p,
    Err(_) => {
        log::warn!("Invalid port '{}', using default", input);
        8080
    }
};
```

### See Also

- [err-no-unwrap-prod](#err-no-unwrap-prod) - Avoiding unwrap in production
- [err-result-over-panic](#err-result-over-panic) - When to return Result
- [api-parse-dont-validate](#api-parse-dont-validate) - Type-driven validation


## err-from-impl

> Implement `From<E>` for error conversions to enable `?` operator

### Why It Matters

The `?` operator automatically converts errors using `From` trait. By implementing `From<SourceError> for YourError`, you enable seamless error propagation without explicit `.map_err()` calls. This makes error handling code cleaner and ensures consistent error wrapping throughout your codebase.

### Bad

```rust
#[derive(Debug)]
enum AppError {
    Io(std::io::Error),
    Parse(serde_json::Error),
    Database(diesel::result::Error),
}

fn load_config(path: &str) -> Result<Config, AppError> {
    let content = std::fs::read_to_string(path)
        .map_err(|e| AppError::Io(e))?;  // Manual conversion everywhere
    
    let config: Config = serde_json::from_str(&content)
        .map_err(|e| AppError::Parse(e))?;  // Repeated boilerplate
    
    save_to_db(&config)
        .map_err(|e| AppError::Database(e))?;  // Gets tedious
    
    Ok(config)
}
```

### Good

```rust
#[derive(Debug)]
enum AppError {
    Io(std::io::Error),
    Parse(serde_json::Error),
    Database(diesel::result::Error),
}

// Implement From for each source error type
impl From<std::io::Error> for AppError {
    fn from(err: std::io::Error) -> Self {
        AppError::Io(err)
    }
}

impl From<serde_json::Error> for AppError {
    fn from(err: serde_json::Error) -> Self {
        AppError::Parse(err)
    }
}

impl From<diesel::result::Error> for AppError {
    fn from(err: diesel::result::Error) -> Self {
        AppError::Database(err)
    }
}

fn load_config(path: &str) -> Result<Config, AppError> {
    let content = std::fs::read_to_string(path)?;  // Auto-converts
    let config: Config = serde_json::from_str(&content)?;  // Clean!
    save_to_db(&config)?;
    Ok(config)
}
```

### Use thiserror for Automatic From

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum AppError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),  // Auto-generates From impl
    
    #[error("Parse error: {0}")]
    Parse(#[from] serde_json::Error),  // #[from] does the work
    
    #[error("Database error: {0}")]
    Database(#[from] diesel::result::Error),
}

// Now ? just works
fn load_config(path: &str) -> Result<Config, AppError> {
    let content = std::fs::read_to_string(path)?;
    let config: Config = serde_json::from_str(&content)?;
    save_to_db(&config)?;
    Ok(config)
}
```

### From with Context

Sometimes you need to add context during conversion:

```rust
#[derive(Error, Debug)]
enum ConfigError {
    #[error("Failed to read config from '{path}': {source}")]
    ReadFailed {
        path: String,
        #[source]
        source: std::io::Error,
    },
}

// Can't use #[from] when you need extra context
fn load_config(path: &str) -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string(path)
        .map_err(|source| ConfigError::ReadFailed {
            path: path.to_string(),
            source,
        })?;
    // ...
}

// Or use anyhow for ad-hoc context
use anyhow::{Context, Result};

fn load_config(path: &str) -> Result<Config> {
    let content = std::fs::read_to_string(path)
        .with_context(|| format!("Failed to read config from '{}'", path))?;
    // ...
}
```

### Blanket From Implementations

Be careful with blanket implementations:

```rust
// ❌ Too broad - conflicts with other From impls
impl<E: std::error::Error> From<E> for AppError {
    fn from(err: E) -> Self {
        AppError::Other(err.to_string())
    }
}

// ✅ Specific implementations
impl From<std::io::Error> for AppError { ... }
impl From<ParseIntError> for AppError { ... }
```

### See Also

- [err-thiserror-lib](#err-thiserror-lib) - Using thiserror for libraries
- [err-source-chain](#err-source-chain) - Preserving error chains
- [err-question-mark](#err-question-mark) - The ? operator


## err-lowercase-msg

> Start error messages lowercase, no trailing punctuation

### Why It Matters

Error messages are often chained, logged, or displayed with additional context. Consistent formatting—lowercase start, no trailing period—allows clean composition: "failed to load config: invalid JSON: unexpected token". Mixed case and punctuation create awkward output: "Failed to load config.: Invalid JSON.: Unexpected token.".

### Bad

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum ConfigError {
    #[error("Failed to read config file.")]  // Capital F, trailing period
    ReadFailed(#[from] std::io::Error),
    
    #[error("Invalid JSON format!")]  // Capital I, exclamation
    ParseFailed(#[from] serde_json::Error),
    
    #[error("The requested key was not found")]  // Reads like a sentence
    KeyNotFound(String),
}

// Chained output: "Config load error: Failed to read config file.: No such file"
// Awkward capitalization and punctuation
```

### Good

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum ConfigError {
    #[error("failed to read config file")]  // lowercase, no period
    ReadFailed(#[from] std::io::Error),
    
    #[error("invalid JSON format")]  // lowercase, no period
    ParseFailed(#[from] serde_json::Error),
    
    #[error("key not found: {0}")]  // lowercase, data at end
    KeyNotFound(String),
}

// Chained output: "config load error: failed to read config file: no such file"
// Clean, consistent
```

### Rust Standard Library Convention

The standard library follows this convention:

```rust
// std::io::Error messages
"entity not found"
"permission denied"
"connection refused"

// std::num::ParseIntError
"invalid digit found in string"

// std::str::Utf8Error  
"invalid utf-8 sequence"
```

### Formatting Guidelines

| Do | Don't |
|----|-------|
| `"failed to parse config"` | `"Failed to parse config."` |
| `"invalid input: expected number"` | `"Invalid input - expected a number!"` |
| `"connection timed out after {0}s"` | `"Connection Timed Out After {0} seconds."` |
| `"key '{0}' not found"` | `"Key Not Found: {0}"` |

### Context Addition Pattern

```rust
use anyhow::{Context, Result};

fn load_user(id: u64) -> Result<User> {
    let data = fetch(id)
        .with_context(|| format!("failed to fetch user {}", id))?;
    
    parse_user(data)
        .with_context(|| "failed to parse user data")?
}

// Output: "failed to fetch user 42: connection refused"
// All lowercase, clean chain
```

### Display vs Debug

```rust
#[derive(Error, Debug)]
#[error("invalid configuration")]  // Display: for users/logs
pub struct ConfigError {
    path: PathBuf,
    source: io::Error,
}

// Debug output (for developers) can have more detail
// Display output (for users) should be clean
```

### When to Use Capitals

```rust
// Proper nouns / acronyms keep their case
#[error("invalid JSON syntax")]     // JSON is an acronym
#[error("OAuth token expired")]     // OAuth is a proper noun
#[error("HTTP request failed")]     // HTTP is an acronym

// Error codes can be uppercase
#[error("error code E0001: invalid input")]
```

### See Also

- [err-thiserror-lib](#err-thiserror-lib) - Error definition with thiserror
- [err-context-chain](#err-context-chain) - Adding context to errors
- [doc-examples-section](#doc-examples-section) - Documentation conventions


## err-no-unwrap-prod

> Avoid `unwrap()` in production code; use `?`, `expect()`, or handle errors

### Why It Matters

`unwrap()` panics on `None` or `Err` without any context about what went wrong. In production, this creates cryptic crash messages that are hard to debug. Either propagate errors with `?`, use `expect()` with a message explaining the invariant, or handle the error explicitly.

### Bad

```rust
fn process_request(req: Request) -> Response {
    let user_id = req.headers.get("X-User-Id").unwrap();  // Why did it fail?
    let user = database.find_user(user_id).unwrap();       // Which operation?
    let data = user.preferences.get("theme").unwrap();     // No context
    
    Response::new(data)
}

// Crash message: "called `Option::unwrap()` on a `None` value"
// Where? Why? No idea.
```

### Good

```rust
// Option 1: Propagate with ?
fn process_request(req: Request) -> Result<Response, AppError> {
    let user_id = req.headers
        .get("X-User-Id")
        .ok_or(AppError::MissingHeader("X-User-Id"))?;
    
    let user = database.find_user(user_id)?;
    
    let data = user.preferences
        .get("theme")
        .ok_or(AppError::MissingPreference("theme"))?;
    
    Ok(Response::new(data))
}

// Option 2: expect() for invariants (not user input)
fn get_config_value(&self, key: &str) -> &str {
    self.config
        .get(key)
        .expect("BUG: required config key missing after validation")
}

// Option 3: Provide defaults
fn get_theme(user: &User) -> &str {
    user.preferences
        .get("theme")
        .unwrap_or(&"default")
}

// Option 4: Match for complex handling
fn process_optional(value: Option<Data>) -> ProcessedData {
    match value {
        Some(data) => process(data),
        None => {
            log::warn!("No data provided, using fallback");
            ProcessedData::default()
        }
    }
}
```

### `expect()` vs `unwrap()`

```rust
// Bad: no context
let port = config.get("port").unwrap();

// Better: explains the invariant
let port = config.get("port")
    .expect("config must contain 'port' after validation");

// Best: propagate if it's not truly an invariant
let port = config.get("port")
    .ok_or_else(|| ConfigError::MissingKey("port"))?;
```

### Alternatives to unwrap()

| Situation | Use Instead |
|-----------|-------------|
| Can propagate error | `?` operator |
| Has sensible default | `unwrap_or()`, `unwrap_or_default()` |
| Default requires computation | `unwrap_or_else(\|\| ...)` |
| Internal invariant | `expect("explanation")` |
| Need to handle both cases | `match` or `if let` |

### Clippy Lints

```toml
### Cargo.toml
[lints.clippy]
unwrap_used = "warn"      # Warn on unwrap()
expect_used = "warn"       # Also warn on expect() (stricter)
```

```rust
// Allow in specific places where it's justified
#[allow(clippy::unwrap_used)]
fn definitely_safe() {
    // Unwrap is safe here because...
    let x = Some(5).unwrap();
}
```

### See Also

- [err-result-over-panic](#err-result-over-panic) - Return Result instead of panicking
- [err-expect-bugs-only](#err-expect-bugs-only) - When expect() is appropriate
- [anti-unwrap-abuse](#anti-unwrap-abuse) - Patterns for avoiding unwrap


## err-question-mark

> Use `?` operator for clean propagation

### Why It Matters

The `?` operator is Rust's idiomatic way to propagate errors. It's concise, readable, and automatically converts between compatible error types using `From`. It replaces verbose `match` or `unwrap()` calls.

### Bad

```rust
// Verbose match-based error handling
fn load_config() -> Result<Config, Error> {
    let content = match std::fs::read_to_string("config.toml") {
        Ok(c) => c,
        Err(e) => return Err(Error::Io(e)),
    };
    
    let config = match toml::from_str(&content) {
        Ok(c) => c,
        Err(e) => return Err(Error::Parse(e)),
    };
    
    Ok(config)
}

// Or worse - using unwrap
fn load_config_bad() -> Config {
    let content = std::fs::read_to_string("config.toml").unwrap();
    toml::from_str(&content).unwrap()
}
```

### Good

```rust
fn load_config() -> Result<Config, Error> {
    let content = std::fs::read_to_string("config.toml")?;
    let config = toml::from_str(&content)?;
    Ok(config)
}

// Even more concise
fn load_config() -> Result<Config, Error> {
    Ok(toml::from_str(&std::fs::read_to_string("config.toml")?)?)
}
```

### How ? Works

```rust
// This:
let x = expr?;

// Expands roughly to:
let x = match expr {
    Ok(val) => val,
    Err(err) => return Err(From::from(err)),
};
```

### Combining with Context

```rust
use anyhow::{Context, Result};

fn load_user(id: u64) -> Result<User> {
    let path = format!("users/{}.json", id);
    
    let content = std::fs::read_to_string(&path)
        .with_context(|| format!("failed to read user file: {}", path))?;
    
    let user: User = serde_json::from_str(&content)
        .context("failed to parse user JSON")?;
    
    Ok(user)
}
```

### ? with Option

```rust
fn get_first_word(text: &str) -> Option<&str> {
    let first_line = text.lines().next()?;
    let first_word = first_line.split_whitespace().next()?;
    Some(first_word)
}

// Convert Option to Result
fn get_required_config(key: &str) -> Result<String, Error> {
    config.get(key)
        .cloned()
        .ok_or_else(|| Error::MissingConfig(key.to_string()))
}
```

### Error Type Conversion

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum MyError {
    #[error("io error")]
    Io(#[from] std::io::Error),  // Auto From impl
    
    #[error("parse error")]
    Parse(#[from] serde_json::Error),  // Auto From impl
}

fn process() -> Result<(), MyError> {
    // ? automatically converts io::Error to MyError via From
    let content = std::fs::read_to_string("file.txt")?;
    
    // ? automatically converts serde_json::Error to MyError
    let data: Data = serde_json::from_str(&content)?;
    
    Ok(())
}
```

### In main()

```rust
// Option 1: Return Result from main
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = load_config()?;
    run_app(config)?;
    Ok(())
}

// Option 2: Handle in main, exit on error
fn main() {
    if let Err(e) = run() {
        eprintln!("Error: {:#}", e);
        std::process::exit(1);
    }
}

fn run() -> anyhow::Result<()> {
    let config = load_config()?;
    run_app(config)?;
    Ok(())
}
```

### See Also

- [err-context-chain](#err-context-chain) - Add context with .context()
- [err-from-impl](#err-from-impl) - Use #[from] for automatic conversion
- [err-anyhow-app](#err-anyhow-app) - Use anyhow for applications


## err-result-over-panic

> Return `Result<T, E>` instead of panicking for recoverable errors

### Why It Matters

Panics unwind the stack and crash the thread (or program). They're unrecoverable from the caller's perspective. `Result<T, E>` gives callers the ability to decide how to handle errors—retry, fallback, propagate, or log. Libraries should almost never panic; applications should minimize panics to truly unrecoverable situations.

### Bad

```rust
fn parse_config(path: &str) -> Config {
    let content = std::fs::read_to_string(path)
        .expect("Failed to read config");  // Crashes on missing file
    
    serde_json::from_str(&content)
        .expect("Invalid config format")   // Crashes on bad JSON
}

fn divide(a: i32, b: i32) -> i32 {
    if b == 0 {
        panic!("Division by zero!");  // Crashes the program
    }
    a / b
}
```

Caller has no chance to recover or provide a fallback.

### Good

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum ConfigError {
    #[error("Failed to read config file: {0}")]
    Io(#[from] std::io::Error),
    #[error("Invalid config format: {0}")]
    Parse(#[from] serde_json::Error),
}

fn parse_config(path: &str) -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string(path)?;
    let config = serde_json::from_str(&content)?;
    Ok(config)
}

fn divide(a: i32, b: i32) -> Result<i32, &'static str> {
    if b == 0 {
        return Err("Division by zero");
    }
    Ok(a / b)
}

// Caller decides how to handle
match parse_config("app.json") {
    Ok(config) => run_app(config),
    Err(e) => {
        eprintln!("Using default config: {}", e);
        run_app(Config::default())
    }
}
```

### When Panic IS Appropriate

```rust
// 1. Bug in the program (invariant violation)
fn get_cached_value(&self, key: &str) -> &Value {
    self.cache.get(key).expect("BUG: key was verified to exist")
}

// 2. Setup/initialization that can't reasonably fail
fn main() {
    let config = Config::load().expect("Failed to load required config");
    // Can't run without config, panic is reasonable
}

// 3. Tests
#[test]
fn test_parse() {
    let result = parse("valid input").unwrap(); // unwrap OK in tests
    assert_eq!(result, expected);
}

// 4. Examples and prototypes
fn main() {
    // Quick prototype, panic is fine
    let data = fetch_data().unwrap();
}
```

### Panic vs Result Decision Guide

| Situation | Use |
|-----------|-----|
| File not found | `Result` |
| Network error | `Result` |
| Invalid user input | `Result` |
| Parse error | `Result` |
| Index out of bounds (from user data) | `Result` |
| Index out of bounds (internal bug) | Panic |
| Violated internal invariant | Panic |
| Unimplemented code path | Panic (`unimplemented!()`) |
| Impossible state reached | Panic (`unreachable!()`) |

### Library vs Application

```rust
// Library: NEVER panic on user input
pub fn parse(input: &str) -> Result<Ast, ParseError> {
    // Always return Result
}

// Application: Can panic at top level for critical failures
fn main() {
    if let Err(e) = run() {
        eprintln!("Fatal error: {}", e);
        std::process::exit(1);
    }
}
```

### See Also

- [err-thiserror-lib](#err-thiserror-lib) - Define error types for libraries
- [err-anyhow-app](#err-anyhow-app) - Ergonomic errors for applications
- [err-no-unwrap-prod](#err-no-unwrap-prod) - Avoid unwrap in production code
- [anti-unwrap-abuse](#anti-unwrap-abuse) - When unwrap is acceptable


## err-source-chain

> Preserve error chains with `#[source]` or `source()` method

### Why It Matters

Errors often have underlying causes. Preserving the error chain (via `source()` method) allows logging frameworks and error reporters to show the full context: "config parse failed → JSON syntax error at line 5 → unexpected token". Without chaining, you lose valuable debugging information.

### Bad

```rust
#[derive(Debug)]
enum ConfigError {
    ParseFailed(String),  // Lost the original serde_json::Error
}

fn load_config(path: &str) -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string(path)
        .map_err(|e| ConfigError::ParseFailed(e.to_string()))?;  // Chain lost!
    
    serde_json::from_str(&content)
        .map_err(|e| ConfigError::ParseFailed(e.to_string()))?  // No source
}

// Error output: "Parse failed: invalid type: ..."
// Missing: which file? what line? what was the parent error?
```

### Good

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum ConfigError {
    #[error("Failed to read config file '{path}'")]
    ReadFailed {
        path: String,
        #[source]  // Preserves the error chain
        source: std::io::Error,
    },
    
    #[error("Failed to parse config file '{path}'")]
    ParseFailed {
        path: String,
        #[source]  // Original parse error preserved
        source: serde_json::Error,
    },
}

fn load_config(path: &str) -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string(path)
        .map_err(|source| ConfigError::ReadFailed {
            path: path.to_string(),
            source,  // Chain preserved
        })?;
    
    serde_json::from_str(&content)
        .map_err(|source| ConfigError::ParseFailed {
            path: path.to_string(),
            source,
        })
}
```

### Manual source() Implementation

```rust
use std::error::Error;

#[derive(Debug)]
struct MyError {
    message: String,
    source: Option<Box<dyn Error + Send + Sync>>,
}

impl std::fmt::Display for MyError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.message)
    }
}

impl Error for MyError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        self.source.as_ref().map(|e| e.as_ref() as &(dyn Error + 'static))
    }
}
```

### Walking the Error Chain

```rust
fn print_error_chain(error: &dyn std::error::Error) {
    eprintln!("Error: {}", error);
    
    let mut source = error.source();
    while let Some(err) = source {
        eprintln!("Caused by: {}", err);
        source = err.source();
    }
}

// With anyhow, use {:?} for full chain
let result: anyhow::Result<()> = do_something();
if let Err(e) = result {
    eprintln!("{:?}", e);  // Prints full chain with backtraces
}
```

### anyhow Context

```rust
use anyhow::{Context, Result};

fn load_config(path: &str) -> Result<Config> {
    let content = std::fs::read_to_string(path)
        .with_context(|| format!("Failed to read '{}'", path))?;
    
    let config: Config = serde_json::from_str(&content)
        .with_context(|| format!("Failed to parse '{}'", path))?;
    
    Ok(config)
}

// Output:
// Error: Failed to parse 'config.json'
// Caused by: expected `:` at line 5 column 10
```

### #[from] vs #[source]

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum MyError {
    // #[from] = implements From + sets source
    #[error("IO error")]
    Io(#[from] std::io::Error),
    
    // #[source] = only sets source (no From impl)
    #[error("Parse error in file '{path}'")]
    Parse {
        path: String,
        #[source]
        source: serde_json::Error,
    },
}
```

### See Also

- [err-thiserror-lib](#err-thiserror-lib) - thiserror for error definitions
- [err-context-chain](#err-context-chain) - Adding context to errors
- [err-from-impl](#err-from-impl) - From implementations for ?


## err-thiserror-lib

> Use `thiserror` for library error types

### Why It Matters

Libraries should expose typed, matchable errors so users can handle specific error conditions. `thiserror` generates `Error` trait implementations with minimal boilerplate, creating ergonomic error types that are easy to match against.

### Bad

```rust
// String errors - not matchable
fn parse(input: &str) -> Result<Data, String> {
    Err("parse error".to_string())
}

// Box<dyn Error> - not matchable
fn load(path: &Path) -> Result<Data, Box<dyn std::error::Error>> {
    Err(Box::new(std::io::Error::new(std::io::ErrorKind::NotFound, "file not found")))
}

// Manual implementation - verbose
#[derive(Debug)]
enum MyError {
    Io(std::io::Error),
    Parse(String),
}

impl std::fmt::Display for MyError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            MyError::Io(e) => write!(f, "io error: {}", e),
            MyError::Parse(s) => write!(f, "parse error: {}", s),
        }
    }
}

impl std::error::Error for MyError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            MyError::Io(e) => Some(e),
            MyError::Parse(_) => None,
        }
    }
}
```

### Good

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ParseError {
    #[error("invalid syntax at line {line}: {message}")]
    Syntax { line: usize, message: String },
    
    #[error("unexpected end of file")]
    UnexpectedEof,
    
    #[error("invalid utf-8 encoding")]
    Utf8(#[from] std::str::Utf8Error),
    
    #[error("io error reading input")]
    Io(#[from] std::io::Error),
}

// Usage
fn parse(input: &str) -> Result<Ast, ParseError> {
    if input.is_empty() {
        return Err(ParseError::UnexpectedEof);
    }
    // ...
}

// Users can match specific errors
match parse(input) {
    Ok(ast) => process(ast),
    Err(ParseError::Syntax { line, message }) => {
        eprintln!("Syntax error on line {}: {}", line, message);
    }
    Err(ParseError::UnexpectedEof) => {
        eprintln!("File ended unexpectedly");
    }
    Err(e) => eprintln!("Error: {}", e),
}
```

### Key Attributes

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum MyError {
    // Simple message
    #[error("operation failed")]
    Failed,
    
    // Interpolated fields
    #[error("invalid value: {0}")]
    InvalidValue(String),
    
    // Named fields
    #[error("connection to {host}:{port} failed")]
    Connection { host: String, port: u16 },
    
    // Automatic From impl with #[from]
    #[error("database error")]
    Database(#[from] sqlx::Error),
    
    // Source without From (manual conversion needed)
    #[error("validation failed")]
    Validation {
        #[source]
        cause: ValidationError,
        field: String,
    },
    
    // Transparent - delegates Display and source to inner
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}
```

### Error Chaining

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ConfigError {
    #[error("failed to read config file")]
    Read(#[source] std::io::Error),
    
    #[error("failed to parse config")]
    Parse(#[source] toml::de::Error),
    
    #[error("invalid config value for '{key}'")]
    InvalidValue {
        key: String,
        #[source]
        cause: ValueError,
    },
}

// Error chain is preserved
fn load_config(path: &Path) -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string(path)
        .map_err(ConfigError::Read)?;
    
    let config: Config = toml::from_str(&content)
        .map_err(ConfigError::Parse)?;
    
    Ok(config)
}
```

### Library vs Application

| Context | Crate | Why |
|---------|-------|-----|
| Library | `thiserror` | Typed errors users can match |
| Application | `anyhow` | Easy error handling with context |
| Both | `thiserror` for public API, `anyhow` internally | Best of both |

### See Also

- [err-anyhow-app](#err-anyhow-app) - Use anyhow for applications
- [err-from-impl](#err-from-impl) - Use #[from] for automatic conversion
- [err-source-chain](#err-source-chain) - Use #[source] to chain errors
