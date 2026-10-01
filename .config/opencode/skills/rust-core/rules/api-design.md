# API Design

> Loaded on demand from `SKILL.md` — one rule per `## <rule-id>` section.


## api-builder-must-use

> Mark builder methods with `#[must_use]` to prevent silent drops

### Why It Matters

Builder pattern methods return a modified builder. Without `#[must_use]`, calling a builder method and ignoring the return value silently does nothing—the builder is dropped, and the configuration is lost. This creates confusing bugs where code appears correct but has no effect.

### Bad

```rust
struct RequestBuilder {
    url: String,
    timeout: Option<Duration>,
    headers: Vec<(String, String)>,
}

impl RequestBuilder {
    fn timeout(mut self, duration: Duration) -> Self {
        self.timeout = Some(duration);
        self
    }
    
    fn header(mut self, key: &str, value: &str) -> Self {
        self.headers.push((key.to_string(), value.to_string()));
        self
    }
}

// Bug: builder methods are ignored - no warning!
let request = RequestBuilder::new("https://api.example.com");
request.timeout(Duration::from_secs(30));  // Dropped silently!
request.header("Authorization", "Bearer token");  // Dropped silently!
let response = request.send();  // Sends with no timeout or headers
```

### Good

```rust
struct RequestBuilder {
    url: String,
    timeout: Option<Duration>,
    headers: Vec<(String, String)>,
}

impl RequestBuilder {
    #[must_use = "builder methods return modified builder - chain or assign"]
    fn timeout(mut self, duration: Duration) -> Self {
        self.timeout = Some(duration);
        self
    }
    
    #[must_use = "builder methods return modified builder - chain or assign"]
    fn header(mut self, key: &str, value: &str) -> Self {
        self.headers.push((key.to_string(), value.to_string()));
        self
    }
}

// Now warns: unused return value that must be used
let request = RequestBuilder::new("https://api.example.com");
request.timeout(Duration::from_secs(30));  // Warning!

// Correct: chain methods
let response = RequestBuilder::new("https://api.example.com")
    .timeout(Duration::from_secs(30))
    .header("Authorization", "Bearer token")
    .send();
```

### Apply to Entire Type

```rust
#[must_use = "builders do nothing unless consumed"]
struct ConfigBuilder {
    log_level: Level,
    max_connections: usize,
}

// Now all methods returning Self warn if ignored
impl ConfigBuilder {
    fn log_level(mut self, level: Level) -> Self {
        self.log_level = level;
        self
    }
    
    fn max_connections(mut self, n: usize) -> Self {
        self.max_connections = n;
        self
    }
    
    fn build(self) -> Config {
        Config {
            log_level: self.log_level,
            max_connections: self.max_connections,
        }
    }
}
```

### Message Guidelines

```rust
// Descriptive message helps users understand
#[must_use = "builder methods return modified builder"]
fn with_foo(self, foo: Foo) -> Self { ... }

#[must_use = "this creates a new String and does not modify the original"]
fn to_uppercase(&self) -> String { ... }

#[must_use = "iterator adaptors are lazy - use .collect() to consume"]
fn map<F>(self, f: F) -> Map<Self, F> { ... }
```

### Clippy Lint

```toml
[lints.clippy]
must_use_candidate = "warn"  # Suggests where #[must_use] would help
return_self_not_must_use = "warn"  # Specifically for -> Self methods
```

### Standard Library Examples

```rust
// std::Option - must_use on map, and, or
let x: Option<i32> = Some(5);
x.map(|v| v * 2);  // Warning: unused return value

// std::Result - must_use on the type itself
#[must_use = "this `Result` may be an `Err` variant, which should be handled"]
pub enum Result<T, E> { ... }

// Iterator adaptors
let v = vec![1, 2, 3];
v.iter().map(|x| x * 2);  // Warning: iterators are lazy
```

### See Also

- [api-builder-pattern](#api-builder-pattern) - Builder pattern best practices
- [api-must-use](#api-must-use) - General must_use guidelines
- [err-result-over-panic](#err-result-over-panic) - Result types are must_use


## api-builder-pattern

> Use Builder pattern for complex construction

### Why It Matters

When a type has many optional parameters or complex initialization, the Builder pattern provides a clear, flexible API. It avoids constructors with many parameters (which are error-prone) and makes the code self-documenting.

### Bad

```rust
// Constructor with many parameters - hard to read, easy to get wrong
let client = Client::new(
    "https://api.example.com",  // Which is which?
    30,                          // Timeout? Retries?
    true,                        // What does this mean?
    None,
    Some("auth_token"),
    false,
);

// Or many Option fields
struct Client {
    url: String,
    timeout: Option<Duration>,
    retries: Option<u32>,
    // ... 10 more optional fields
}
```

### Good

```rust
#[derive(Default)]
#[must_use = "builders do nothing unless you call build()"]
pub struct ClientBuilder {
    base_url: Option<String>,
    timeout: Option<Duration>,
    max_retries: u32,
    auth_token: Option<String>,
}

impl ClientBuilder {
    pub fn new() -> Self {
        Self::default()
    }
    
    /// Sets the base URL for all requests.
    pub fn base_url(mut self, url: impl Into<String>) -> Self {
        self.base_url = Some(url.into());
        self
    }
    
    /// Sets the request timeout. Default is 30 seconds.
    pub fn timeout(mut self, timeout: Duration) -> Self {
        self.timeout = Some(timeout);
        self
    }
    
    /// Sets the maximum number of retries. Default is 3.
    pub fn max_retries(mut self, n: u32) -> Self {
        self.max_retries = n;
        self
    }
    
    /// Sets the authentication token.
    pub fn auth_token(mut self, token: impl Into<String>) -> Self {
        self.auth_token = Some(token.into());
        self
    }
    
    /// Builds the client with the configured options.
    pub fn build(self) -> Result<Client, BuilderError> {
        let base_url = self.base_url
            .ok_or(BuilderError::MissingBaseUrl)?;
        
        Ok(Client {
            base_url,
            timeout: self.timeout.unwrap_or(Duration::from_secs(30)),
            max_retries: self.max_retries,
            auth_token: self.auth_token,
        })
    }
}

// Usage - clear and self-documenting
let client = ClientBuilder::new()
    .base_url("https://api.example.com")
    .timeout(Duration::from_secs(10))
    .max_retries(5)
    .auth_token("secret")
    .build()?;
```

### Builder Variations

```rust
// 1. Infallible builder (build() returns T, not Result)
impl WidgetBuilder {
    pub fn build(self) -> Widget {
        Widget {
            color: self.color.unwrap_or(Color::Black),
            size: self.size.unwrap_or(Size::Medium),
        }
    }
}

// 2. Typestate builder (compile-time required field checking)
pub struct ClientBuilder<Url> {
    url: Url,
    timeout: Option<Duration>,
}

pub struct NoUrl;
pub struct HasUrl(String);

impl ClientBuilder<NoUrl> {
    pub fn new() -> Self {
        Self { url: NoUrl, timeout: None }
    }
    
    pub fn url(self, url: String) -> ClientBuilder<HasUrl> {
        ClientBuilder { url: HasUrl(url), timeout: self.timeout }
    }
}

impl ClientBuilder<HasUrl> {
    pub fn build(self) -> Client {
        // url is guaranteed to be set
        Client { url: self.url.0, timeout: self.timeout }
    }
}

// 3. Consuming vs borrowing (consuming is more common)
// Consuming (takes self)
pub fn timeout(mut self, t: Duration) -> Self { ... }

// Borrowing (takes &mut self, allows reuse)
pub fn timeout(&mut self, t: Duration) -> &mut Self { ... }
```

### Evidence from reqwest

```rust
// https://github.com/seanmonstar/reqwest/blob/master/src/async_impl/client.rs

#[must_use]
pub struct ClientBuilder {
    config: Config,
}

impl ClientBuilder {
    pub fn new() -> ClientBuilder {
        ClientBuilder {
            config: Config::default(),
        }
    }
    
    pub fn timeout(mut self, timeout: Duration) -> ClientBuilder {
        self.config.timeout = Some(timeout);
        self
    }
    
    pub fn build(self) -> Result<Client, Error> {
        // Validation and construction
    }
}
```

### Key Attributes

```rust
#[derive(Default)]  // Enables MyBuilder::default()
#[must_use = "builders do nothing unless you call build()"]
pub struct MyBuilder { ... }

impl MyBuilder {
    #[must_use]  // Each method should have this
    pub fn option(mut self, value: T) -> Self { ... }
}
```

### See Also

- [api-builder-must-use](#api-builder-must-use) - Add #[must_use] to builders
- [api-typestate](#api-typestate) - Compile-time state machines
- [api-impl-into](#api-impl-into) - Accept impl Into for flexibility


## api-common-traits

> Implement standard traits (Debug, Clone, PartialEq, etc.) for public types

### Why It Matters

Standard traits make your types interoperable with the Rust ecosystem. `Debug` enables `println!("{:?}")` and error messages. `Clone` allows explicit duplication. `PartialEq` enables `==`. Without these, users can't use your types in common patterns like testing, collections, or debugging.

### Bad

```rust
// Bare struct - severely limited usability
pub struct Point {
    pub x: f64,
    pub y: f64,
}

// Can't debug
println!("{:?}", point);  // Error: Debug not implemented

// Can't compare
if point1 == point2 { }  // Error: PartialEq not implemented

// Can't use in HashMap
let mut map: HashMap<Point, Value> = HashMap::new();  // Error: Hash not implemented

// Can't clone
let copy = point.clone();  // Error: Clone not implemented
```

### Good

```rust
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

// Now everything works
println!("{:?}", point);
assert_eq!(point1, point2);
let copy = point;  // Copy, not just Clone

// For hashable types
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct UserId(u64);

let mut map: HashMap<UserId, User> = HashMap::new();
```

### Trait Derivation Guide

| Trait | Derive When | Requirements |
|-------|-------------|--------------|
| `Debug` | Always for public types | All fields implement Debug |
| `Clone` | Type can be duplicated | All fields implement Clone |
| `Copy` | Small, simple types | All fields implement Copy, no Drop |
| `PartialEq` | Comparison makes sense | All fields implement PartialEq |
| `Eq` | Total equality | PartialEq, no floating-point fields |
| `Hash` | Used as HashMap/HashSet key | Eq, consistent with PartialEq |
| `Default` | Sensible default exists | All fields implement Default |
| `PartialOrd` | Ordering makes sense | PartialEq, all fields implement PartialOrd |
| `Ord` | Total ordering | Eq + PartialOrd, no floating-point |

### Common Trait Bundles

```rust
// ID types
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct EntityId(u64);

// Value types
#[derive(Debug, Clone, Copy, PartialEq, Default)]
pub struct Vector2 { x: f32, y: f32 }

// Configuration
#[derive(Debug, Clone, PartialEq, Default)]
pub struct Config {
    name: String,
    options: HashMap<String, String>,
}

// Error types
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ParseError {
    InvalidSyntax(String),
    UnexpectedToken(Token),
}
```

### Manual Implementations

```rust
// When derive doesn't do what you want
struct CaseInsensitiveString(String);

impl PartialEq for CaseInsensitiveString {
    fn eq(&self, other: &Self) -> bool {
        self.0.to_lowercase() == other.0.to_lowercase()
    }
}

impl Eq for CaseInsensitiveString {}

impl Hash for CaseInsensitiveString {
    fn hash<H: Hasher>(&self, state: &mut H) {
        // Must be consistent with PartialEq
        self.0.to_lowercase().hash(state);
    }
}

// Custom Debug for sensitive data
struct Password(String);

impl Debug for Password {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Password([REDACTED])")
    }
}
```

### Serde Traits

```rust
use serde::{Serialize, Deserialize};

// For serializable types
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ApiResponse {
    pub status: String,
    pub data: Vec<Item>,
}

// With custom serialization
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    #[serde(default)]
    pub verbose: bool,
    
    #[serde(skip_serializing_if = "Option::is_none")]
    pub api_key: Option<String>,
}
```

### Minimum Recommended

```rust
// At minimum, public types should have:
#[derive(Debug, Clone, PartialEq)]
pub struct MyType { ... }

// Add based on use case:
// + Eq, Hash       → for HashMap keys
// + Ord, PartialOrd → for BTreeMap, sorting
// + Default        → for Option::unwrap_or_default()
// + Copy           → for small value types
// + Serialize      → for serialization
```

### See Also

- [own-copy-small](#own-copy-small) - When to implement Copy
- [api-default-impl](#api-default-impl) - Implementing Default
- [doc-examples-section](#doc-examples-section) - Documenting trait implementations


## api-default-impl

> Implement `Default` for types with sensible default values

### Why It Matters

`Default` is a standard trait that provides a canonical way to create a default instance. It integrates with many ecosystem patterns: `Option::unwrap_or_default()`, `#[derive(Default)]`, struct update syntax `..Default::default()`, and generic code that requires `T: Default`. Implementing it makes your types more ergonomic.

### Bad

```rust
struct Config {
    timeout: Duration,
    retries: u32,
    verbose: bool,
}

impl Config {
    // Custom constructor - works but non-standard
    fn new() -> Self {
        Config {
            timeout: Duration::from_secs(30),
            retries: 3,
            verbose: false,
        }
    }
}

// Can't use with standard patterns
let config: Config = Default::default();  // Error: Default not implemented
let timeout = settings.get("timeout").unwrap_or_default();  // Won't work
```

### Good

```rust
#[derive(Default)]
struct Config {
    #[default = Duration::from_secs(30)]  // Nightly, or implement manually
    timeout: Duration,
    retries: u32,     // Defaults to 0 with derive
    verbose: bool,    // Defaults to false with derive
}

// Or implement manually for custom defaults
impl Default for Config {
    fn default() -> Self {
        Config {
            timeout: Duration::from_secs(30),
            retries: 3,
            verbose: false,
        }
    }
}

// Now works with all standard patterns
let config = Config::default();
let config = Config { retries: 5, ..Default::default() };
let value = map.get("key").cloned().unwrap_or_default();
```

### Derive vs Manual

```rust
// Derive: all fields use their own Default
#[derive(Default)]
struct Simple {
    count: u32,      // 0
    name: String,    // ""
    items: Vec<i32>, // []
}

// Manual: when you need custom defaults
struct Connection {
    host: String,
    port: u16,
    timeout: Duration,
}

impl Default for Connection {
    fn default() -> Self {
        Connection {
            host: "localhost".to_string(),
            port: 8080,
            timeout: Duration::from_secs(30),
        }
    }
}
```

### Builder with Default

```rust
#[derive(Default)]
struct ServerBuilder {
    host: String,
    port: u16,
    workers: usize,
}

impl ServerBuilder {
    fn host(mut self, host: impl Into<String>) -> Self {
        self.host = host.into();
        self
    }
    
    fn port(mut self, port: u16) -> Self {
        self.port = port;
        self
    }
}

// Clean initialization
let server = ServerBuilder::default()
    .host("0.0.0.0")
    .port(3000)
    .build();
```

### Default with Required Fields

```rust
// When some fields have no sensible default, don't implement Default
struct User {
    id: UserId,       // No sensible default
    name: String,     // Could default to ""
}

// Instead, provide a constructor
impl User {
    fn new(id: UserId, name: impl Into<String>) -> Self {
        User { id, name: name.into() }
    }
}

// Or use builder with required fields
struct UserBuilder {
    id: Option<UserId>,
    name: String,
}

impl Default for UserBuilder {
    fn default() -> Self {
        UserBuilder {
            id: None,
            name: String::new(),
        }
    }
}
```

### Generic Default

```rust
// Require Default in generic bounds when needed
fn create_or_default<T: Default>(opt: Option<T>) -> T {
    opt.unwrap_or_default()
}

// PhantomData is Default regardless of T
use std::marker::PhantomData;
struct Wrapper<T> {
    _marker: PhantomData<T>,
}

impl<T> Default for Wrapper<T> {
    fn default() -> Self {
        Wrapper { _marker: PhantomData }
    }
}
```

### See Also

- [api-builder-pattern](#api-builder-pattern) - Building complex types
- [api-common-traits](#api-common-traits) - Other common traits to implement
- [api-from-not-into](#api-from-not-into) - Conversion traits


## api-extension-trait

> Use extension traits to add methods to external types

### Why It Matters

Rust's orphan rules prevent implementing external traits on external types. Extension traits provide a workaround: define a new trait with your methods, then implement it for the external type. This pattern is used extensively in the ecosystem (e.g., `itertools::Itertools`, `tokio::AsyncReadExt`).

### Bad

```rust
// Can't add methods directly to external types
impl Vec<u8> {
    fn as_hex(&self) -> String {
        // Error: cannot define inherent impl for a type outside this crate
    }
}

// Can't implement external trait for external type
impl SomeExternalTrait for Vec<u8> {
    // Error: orphan rules violation
}
```

### Good

```rust
// Define an extension trait
pub trait ByteSliceExt {
    fn as_hex(&self) -> String;
    fn is_ascii_printable(&self) -> bool;
}

// Implement for the external type
impl ByteSliceExt for [u8] {
    fn as_hex(&self) -> String {
        self.iter()
            .map(|b| format!("{:02x}", b))
            .collect()
    }
    
    fn is_ascii_printable(&self) -> bool {
        self.iter().all(|b| b.is_ascii_graphic() || b.is_ascii_whitespace())
    }
}

// Usage: import the trait to use the methods
use my_crate::ByteSliceExt;

let data: &[u8] = b"hello";
println!("{}", data.as_hex());  // "68656c6c6f"
```

### Convention: Ext Suffix

```rust
// Standard naming: TypeExt for extending Type
pub trait OptionExt<T> {
    fn unwrap_or_log(self, msg: &str) -> Option<T>;
}

impl<T> OptionExt<T> for Option<T> {
    fn unwrap_or_log(self, msg: &str) -> Option<T> {
        if self.is_none() {
            log::warn!("{}", msg);
        }
        self
    }
}

// For generic extensions
pub trait ResultExt<T, E> {
    fn log_err(self) -> Self;
}

impl<T, E: std::fmt::Display> ResultExt<T, E> for Result<T, E> {
    fn log_err(self) -> Self {
        if let Err(ref e) = self {
            log::error!("{}", e);
        }
        self
    }
}
```

### Ecosystem Examples

```rust
// itertools::Itertools
use itertools::Itertools;
let groups = vec![1, 1, 2, 2, 3].into_iter().group_by(|x| *x);

// futures::StreamExt
use futures::StreamExt;
let next = stream.next().await;

// tokio::io::AsyncReadExt
use tokio::io::AsyncReadExt;
let mut buf = [0u8; 1024];
reader.read(&mut buf).await?;

// anyhow::Context
use anyhow::Context;
let content = std::fs::read_to_string(path)
    .with_context(|| format!("failed to read {}", path))?;
```

### Scoped Extensions

```rust
// Extension only visible where imported
mod string_utils {
    pub trait StringExt {
        fn truncate_ellipsis(&self, max_len: usize) -> String;
    }
    
    impl StringExt for str {
        fn truncate_ellipsis(&self, max_len: usize) -> String {
            if self.len() <= max_len {
                self.to_string()
            } else {
                format!("{}...", &self[..max_len.saturating_sub(3)])
            }
        }
    }
}

// Only available when explicitly imported
use string_utils::StringExt;
let short = "very long string".truncate_ellipsis(10);
```

### Generic Extensions with Bounds

```rust
pub trait VecExt<T> {
    fn push_if_unique(&mut self, item: T)
    where
        T: PartialEq;
}

impl<T> VecExt<T> for Vec<T> {
    fn push_if_unique(&mut self, item: T)
    where
        T: PartialEq,
    {
        if !self.contains(&item) {
            self.push(item);
        }
    }
}

// Works with any T: PartialEq
let mut v = vec![1, 2, 3];
v.push_if_unique(2);  // No-op
v.push_if_unique(4);  // Adds 4
```

### See Also

- [api-sealed-trait](#api-sealed-trait) - Controlling trait implementations
- [api-impl-into](#api-impl-into) - Using standard conversion traits
- [name-as-free](#name-as-free) - Naming conventions for conversions


## api-from-not-into

> Implement `From<T>`, not `Into<U>` - From gives you Into for free

### Why It Matters

The standard library has a blanket implementation: `impl<T, U> Into<U> for T where U: From<T>`. This means implementing `From<T> for U` automatically gives you `Into<U> for T`. Implementing `Into` directly bypasses this and is considered non-idiomatic. Always implement `From`.

### Bad

```rust
struct UserId(u64);

// Non-idiomatic: implementing Into directly
impl Into<UserId> for u64 {
    fn into(self) -> UserId {
        UserId(self)
    }
}

// Works, but now you can't use From syntax
let id = UserId::from(42);  // Error: From not implemented
let id: UserId = 42.into(); // Works, but limited
```

### Good

```rust
struct UserId(u64);

// Idiomatic: implement From
impl From<u64> for UserId {
    fn from(id: u64) -> Self {
        UserId(id)
    }
}

// Now both work automatically
let id = UserId::from(42);   // From syntax
let id: UserId = 42.into();  // Into syntax (via blanket impl)

// And Into bound works in generics
fn process(id: impl Into<UserId>) {
    let id: UserId = id.into();
}
process(42u64);  // Works!
```

### Blanket Implementation

```rust
// This is in std, you don't write it
impl<T, U> Into<U> for T
where
    U: From<T>,
{
    fn into(self) -> U {
        U::from(self)
    }
}

// So when you implement From:
impl From<String> for MyType { ... }

// You automatically get:
// impl Into<MyType> for String { ... }
```

### Multiple From Implementations

```rust
struct Email(String);

impl From<String> for Email {
    fn from(s: String) -> Self {
        Email(s)
    }
}

impl From<&str> for Email {
    fn from(s: &str) -> Self {
        Email(s.to_string())
    }
}

// All of these work
let e1 = Email::from("test@example.com");
let e2 = Email::from(String::from("test@example.com"));
let e3: Email = "test@example.com".into();
let e4: Email = String::from("test@example.com").into();
```

### TryFrom for Fallible Conversions

```rust
use std::convert::TryFrom;

struct PositiveInt(u32);

// Fallible conversion
impl TryFrom<i32> for PositiveInt {
    type Error = &'static str;
    
    fn try_from(value: i32) -> Result<Self, Self::Error> {
        if value > 0 {
            Ok(PositiveInt(value as u32))
        } else {
            Err("value must be positive")
        }
    }
}

// Usage
let pos = PositiveInt::try_from(42)?;   // From-style
let pos: PositiveInt = 42.try_into()?;  // Into-style (via blanket)
```

### Clippy Lint

```toml
[lints.clippy]
from_over_into = "warn"  # Warns when implementing Into instead of From
```

```rust
// Clippy will warn:
impl Into<Bar> for Foo {  // Warning: prefer From
    fn into(self) -> Bar { ... }
}
```

### When Into IS Needed (Rare)

```rust
// Only when implementing for external types in specific trait bounds
// This is very rare and usually indicates a design issue

// Example: you can't implement From<ExternalA> for ExternalB
// because of orphan rules. But you usually shouldn't need to.
```

### See Also

- [api-impl-into](#api-impl-into) - Using Into in function parameters
- [err-from-impl](#err-from-impl) - From for error types
- [api-newtype-safety](#api-newtype-safety) - Newtype conversions


## api-impl-asref

> Use `AsRef<T>` when you only need to borrow the inner data

### Why It Matters

`AsRef<T>` provides a cheap borrowed view of data without taking ownership or copying. Functions accepting `impl AsRef<T>` can work with multiple types that contain or represent `T`, making APIs flexible while avoiding unnecessary allocations. Use `AsRef` when you only need to read, `Into` when you need to own.

### Bad

```rust
// Forces callers to provide exact types
fn process_text(text: &str) { ... }
fn read_file(path: &Path) { ... }

// Can't call directly with owned types
let s = String::from("hello");
process_text(&s);  // Works but verbose

let p = PathBuf::from("/file");
read_file(&p);  // Works but verbose
read_file("/file");  // Error! &str != &Path
```

### Good

```rust
// Accept anything that can be viewed as the target type
fn process_text(text: impl AsRef<str>) {
    let s: &str = text.as_ref();
    println!("{}", s);
}

fn read_file(path: impl AsRef<Path>) -> io::Result<Vec<u8>> {
    std::fs::read(path.as_ref())
}

// All of these work:
process_text("literal");        // &str
process_text(String::from("owned"));  // String
process_text(Cow::from("cow")); // Cow<str>

read_file("/path/to/file");     // &str  
read_file(Path::new("/path"));  // &Path
read_file(PathBuf::from("/path")); // PathBuf
read_file(OsStr::new("/path")); // &OsStr
```

### AsRef vs Into vs Borrow

```rust
// AsRef<T>: cheap borrow, no ownership transfer
fn read(p: impl AsRef<Path>) {
    let path: &Path = p.as_ref();
}

// Into<T>: ownership transfer, may allocate
fn store(p: impl Into<PathBuf>) {
    let owned: PathBuf = p.into();
}

// Borrow<T>: like AsRef but with Eq/Hash consistency guarantee
use std::borrow::Borrow;
fn lookup<Q: ?Sized>(map: &HashMap<String, V>, key: &Q) -> Option<&V>
where
    String: Borrow<Q>,
    Q: Hash + Eq,
{
    map.get(key)
}
```

### Implement AsRef for Custom Types

```rust
struct Name(String);

impl AsRef<str> for Name {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

impl AsRef<[u8]> for Name {
    fn as_ref(&self) -> &[u8] {
        self.0.as_bytes()
    }
}

// Now Name works with functions expecting AsRef<str>
fn greet(name: impl AsRef<str>) {
    println!("Hello, {}!", name.as_ref());
}

greet(Name("Alice".into()));
```

### Common AsRef Implementations

```rust
// Standard library provides many
impl AsRef<str> for String { ... }
impl AsRef<str> for str { ... }
impl AsRef<[u8]> for str { ... }
impl AsRef<[u8]> for String { ... }
impl AsRef<[u8]> for Vec<u8> { ... }
impl AsRef<Path> for str { ... }
impl AsRef<Path> for String { ... }
impl AsRef<Path> for PathBuf { ... }
impl AsRef<Path> for OsStr { ... }
impl AsRef<OsStr> for str { ... }
```

### When to Use Which

| Trait | Use When |
|-------|----------|
| `&T` | Single type, simple API |
| `AsRef<T>` | Read-only access, multiple input types |
| `Into<T>` | Need to store/own the value |
| `Borrow<T>` | HashMap/HashSet keys, Eq/Hash needed |
| `Deref<Target=T>` | Smart pointer semantics |

### Pattern: Optional AsRef Bound

```rust
// When T itself might be passed
fn process<T: AsRef<U>, U>(value: T) {
    let inner: &U = value.as_ref();
}

// More flexible: accept T or &T
fn process<T: AsRef<U> + ?Sized, U: ?Sized>(value: &T) {
    let inner: &U = value.as_ref();
}
```

### See Also

- [api-impl-into](#api-impl-into) - When to use Into instead
- [own-slice-over-vec](#own-slice-over-vec) - Using slices for flexibility
- [own-borrow-over-clone](#own-borrow-over-clone) - Preferring borrows


## api-impl-into

> Accept `impl Into<T>` for flexible APIs, implement `From<T>` for conversions

### Why It Matters

APIs that accept `impl Into<T>` are ergonomic—callers can pass the target type directly or any type that converts to it. This reduces boilerplate `.into()` calls at call sites. Implement `From<T>` rather than `Into<T>` because `From` implies `Into` through a blanket implementation.

### Bad

```rust
// Requires exact type - forces callers to convert
fn process_path(path: PathBuf) { ... }
fn set_name(name: String) { ... }

// Caller must convert explicitly
process_path(PathBuf::from("/path/to/file"));
process_path("/path/to/file".to_path_buf());  // Verbose
process_path("/path/to/file".into());          // Explicit

set_name(String::from("Alice"));
set_name("Alice".to_string());  // Verbose
```

### Good

```rust
// Accept anything that converts to the target type
fn process_path(path: impl Into<PathBuf>) {
    let path = path.into();  // Convert once inside
    // ...
}

fn set_name(name: impl Into<String>) {
    let name = name.into();
    // ...
}

// Callers are ergonomic
process_path("/path/to/file");    // &str converts automatically
process_path(PathBuf::from(".")); // PathBuf works too

set_name("Alice");                // &str
set_name(String::from("Alice"));  // String
set_name(format!("User-{}", id)); // String from format!
```

### Implement From, Not Into

```rust
struct UserId(u64);

// ✅ Implement From
impl From<u64> for UserId {
    fn from(id: u64) -> Self {
        UserId(id)
    }
}

// Into is automatically provided by blanket impl
let id: UserId = 42u64.into();  // Works!

// ❌ Don't implement Into directly
impl Into<UserId> for u64 {
    fn into(self) -> UserId {
        UserId(self)  // This works but is non-idiomatic
    }
}
```

### Common Conversions

```rust
// String-like types
fn log_message(msg: impl Into<String>) { ... }
log_message("literal");           // &str
log_message(String::from("own")); // String
log_message(Cow::from("cow"));    // Cow<str>

// Path-like types  
fn read_file(path: impl AsRef<Path>) { ... }  // AsRef for borrowed access
fn write_file(path: impl Into<PathBuf>) { ... }  // Into when storing

// Duration
fn set_timeout(duration: impl Into<Duration>) { ... }
set_timeout(Duration::from_secs(5));
// Note: no blanket impl for integers, would need custom wrapper
```

### AsRef vs Into

```rust
// AsRef<T>: borrow as &T, no conversion cost
fn count_bytes(data: impl AsRef<[u8]>) -> usize {
    data.as_ref().len()  // Just borrows, no allocation
}
count_bytes("hello");  // &str -> &[u8]
count_bytes(b"hello"); // &[u8] -> &[u8]
count_bytes(vec![1, 2, 3]);  // &Vec<u8> -> &[u8]

// Into<T>: convert to owned T, may allocate
fn store_data(data: impl Into<Vec<u8>>) {
    let owned: Vec<u8> = data.into();  // Takes ownership
    // ...
}
```

### When NOT to Use impl Into

```rust
// ❌ Trait objects need Sized
fn process(handler: impl Into<Box<dyn Handler>>) { }
// Better: just take Box<dyn Handler> directly

// ❌ Recursive types
struct Node {
    children: Vec<impl Into<Node>>,  // Error: impl Trait not allowed here
}

// ❌ Performance-critical hot paths (minor overhead of trait dispatch)
fn hot_path(value: impl Into<u64>) {
    // Consider taking u64 directly if called billions of times
}

// ❌ When you need to name the type
fn returns_impl() -> impl Into<String> { }  // Opaque, hard to use
```

### Builder Pattern with Into

```rust
struct Config {
    name: String,
    path: PathBuf,
}

impl Config {
    fn new(name: impl Into<String>) -> Self {
        Config {
            name: name.into(),
            path: PathBuf::new(),
        }
    }
    
    fn path(mut self, path: impl Into<PathBuf>) -> Self {
        self.path = path.into();
        self
    }
}

// Clean builder calls
let config = Config::new("myapp")
    .path("/etc/myapp");
```

### See Also

- [api-impl-asref](#api-impl-asref) - When to use AsRef instead
- [api-from-not-into](#api-from-not-into) - Why From is preferred
- [err-from-impl](#err-from-impl) - From for error conversion


## api-must-use

> Mark types and functions with `#[must_use]` when ignoring results is likely a bug

### Why It Matters

Some return values should never be ignored—`Result`, locks, RAII guards, computed values that have no side effects. Without `#[must_use]`, silently discarding these values can introduce subtle bugs that are hard to detect. The attribute generates compiler warnings when the value is unused.

### Bad

```rust
// Result ignored - error silently dropped
fn send_email(to: &str, body: &str) -> Result<(), EmailError> { ... }

send_email("user@example.com", "Hello!");  // No warning if Result ignored!
// Email may have failed, but we don't know

// Computed value ignored - likely a bug
fn compute_checksum(data: &[u8]) -> u32 { ... }

let data = vec![1, 2, 3, 4];
compute_checksum(&data);  // Result discarded - pointless call
```

### Good

```rust
#[must_use = "this `Result` may be an `Err` that should be handled"]
fn send_email(to: &str, body: &str) -> Result<(), EmailError> { ... }

send_email("user@example.com", "Hello!");  
// Warning: unused `Result` that must be used

// Mark pure functions
#[must_use = "this returns a new value and does not modify the input"]
fn compute_checksum(data: &[u8]) -> u32 { ... }

compute_checksum(&data);
// Warning: unused return value of `compute_checksum` that must be used
```

### Apply to Types

```rust
// Mark the type itself when it should always be used
#[must_use = "futures do nothing unless polled"]
struct MyFuture<T> { ... }

// Mark RAII guards
#[must_use = "if unused, the lock will be immediately released"]
struct MutexGuard<'a, T> { ... }

// Mark results/errors
#[must_use = "errors should be handled"]
enum AppError { ... }
```

### Standard Library Examples

```rust
// Result and Option are #[must_use]
let v: Vec<i32> = vec![1, 2, 3];
v.first();  // Warning: unused Option

// Iterator adapters are #[must_use]
v.iter().map(|x| x * 2);  // Warning: iterators are lazy

// String methods that return new values
let s = "hello";
s.to_uppercase();  // Warning: unused String
```

### When to Apply

```rust
// ✅ Pure functions (no side effects)
#[must_use]
fn add(a: i32, b: i32) -> i32 { a + b }

// ✅ Builder methods returning Self
#[must_use = "builder methods return a new builder"]
fn with_timeout(self, t: Duration) -> Self { ... }

// ✅ Fallible operations
#[must_use]
fn try_parse(s: &str) -> Result<Data, ParseError> { ... }

// ✅ Iterators and futures (lazy)
#[must_use = "iterators are lazy and do nothing unless consumed"]
struct Map<I, F> { ... }

// ❌ Side-effecting functions where result is optional
fn log(msg: &str) -> Result<(), io::Error> { ... }  // Might be ok to ignore

// ❌ Methods with useful side effects
fn vec.push(item);  // Mutates vec, no return to use
```

### Custom Messages

```rust
#[must_use = "creating a guard does nothing without assignment"]
struct ScopeGuard { ... }

#[must_use = "this returns the old value"]
fn replace(&mut self, new: T) -> T { ... }

#[must_use = "use `.await` to execute the future"]
async fn fetch() -> Data { ... }
```

### Clippy Lints

```toml
[lints.clippy]
must_use_candidate = "warn"      # Suggests where to add #[must_use]
unused_must_use = "deny"          # Built-in, treat warnings as errors
double_must_use = "warn"          # Redundant #[must_use]
```

### See Also

- [api-builder-must-use](#api-builder-must-use) - Builder pattern must_use
- [err-result-over-panic](#err-result-over-panic) - Result types require handling
- [lint-deny-correctness](#lint-deny-correctness) - Enabling useful lints


## api-newtype-safety

> Use newtypes to prevent mixing semantically different values

### Why It Matters

Raw primitives like `u64` or `String` carry no semantic meaning. A function taking `(u64, u64)` can easily be called with arguments swapped. Newtypes wrap primitives in distinct types, making the compiler catch mistakes at compile time rather than runtime.

### Bad

```rust
struct User {
    id: u64,
    group_id: u64,
    created_at: u64,  // Unix timestamp
}

fn add_user_to_group(user_id: u64, group_id: u64) { ... }

// Bug: arguments swapped - compiles fine, fails at runtime
let user = User { id: 100, group_id: 5, created_at: 1234567890 };
add_user_to_group(user.group_id, user.id);  // Silent bug!

// Bug: wrong field used - timestamp passed as ID
add_user_to_group(user.created_at, user.group_id);  // Compiles fine!
```

### Good

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct UserId(u64);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct GroupId(u64);

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
struct Timestamp(u64);

struct User {
    id: UserId,
    group_id: GroupId,
    created_at: Timestamp,
}

fn add_user_to_group(user_id: UserId, group_id: GroupId) { ... }

// Compile error: expected UserId, found GroupId
let user = User { ... };
add_user_to_group(user.group_id, user.id);  // Error!

// Compile error: expected UserId, found Timestamp
add_user_to_group(user.created_at, user.group_id);  // Error!
```

### Derive Common Traits

```rust
// Minimal: just enough for your use case
#[derive(Debug, Clone, Copy)]
struct MeterId(u32);

// Full ID type: hashable, comparable, displayable
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct OrderId(u64);

impl std::fmt::Display for OrderId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "ORD-{:08}", self.0)
    }
}

// With serde for serialization
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]  // Serializes as raw u64
struct ProductId(u64);
```

### Constructor Patterns

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct Email(String);

impl Email {
    /// Creates a new Email, validating the format.
    pub fn new(s: &str) -> Result<Self, EmailError> {
        if is_valid_email(s) {
            Ok(Email(s.to_string()))
        } else {
            Err(EmailError::InvalidFormat)
        }
    }
    
    /// Returns the email as a string slice.
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

// Usage enforces validation
let email = Email::new("user@example.com")?;  // Must go through validation
```

### Zero-Cost Abstraction

```rust
use std::mem::size_of;

#[derive(Clone, Copy)]
struct Miles(f64);

#[derive(Clone, Copy)]
struct Kilometers(f64);

// Same size as raw f64
assert_eq!(size_of::<Miles>(), size_of::<f64>());
assert_eq!(size_of::<Kilometers>(), size_of::<f64>());

// But can't accidentally mix them
fn drive(distance: Miles) { ... }

let km = Kilometers(100.0);
drive(km);  // Error: expected Miles, found Kilometers

// Explicit conversion
impl From<Kilometers> for Miles {
    fn from(km: Kilometers) -> Self {
        Miles(km.0 * 0.621371)
    }
}

drive(km.into());  // Explicit, visible conversion
```

### When Newtypes Help Most

```rust
// ✅ IDs that could be confused
fn transfer(from: AccountId, to: AccountId, amount: Money) { ... }

// ✅ Units that shouldn't mix
struct Celsius(f64);
struct Fahrenheit(f64);

// ✅ Validated strings
struct Username(String);  // Validated alphanumeric
struct Password(String);  // Never logged

// ✅ Different meanings of same type
struct Milliseconds(u64);
struct Seconds(u64);

// ❌ Overkill: single use, no confusion possible
struct X(i32);  // Just use i32
```

### See Also

- [type-newtype-ids](#type-newtype-ids) - Newtype pattern for IDs
- [api-parse-dont-validate](#api-parse-dont-validate) - Type-driven validation
- [own-copy-small](#own-copy-small) - Making newtypes Copy


## api-non-exhaustive

> Use `#[non_exhaustive]` on public enums and structs for forward compatibility

### Why It Matters

Adding a variant to a public enum or a field to a public struct is normally a breaking change—downstream code may match exhaustively or use struct literal syntax. `#[non_exhaustive]` forces external code to use wildcards in matches and constructors, allowing you to add variants/fields in minor versions without breaking callers.

### Bad

```rust
// Public enum - adding variant breaks downstream matches
pub enum ErrorKind {
    NotFound,
    PermissionDenied,
    TimedOut,
}

// Downstream code
match error.kind() {
    ErrorKind::NotFound => ...,
    ErrorKind::PermissionDenied => ...,
    ErrorKind::TimedOut => ...,
    // No wildcard - will break when you add ErrorKind::Interrupted
}

// Public struct - adding field breaks downstream construction
pub struct Config {
    pub name: String,
    pub value: i32,
}

// Downstream code
let config = Config { name: "test".into(), value: 42 };
// Will break when you add `pub enabled: bool`
```

### Good

```rust
// Can add variants in minor versions
#[non_exhaustive]
pub enum ErrorKind {
    NotFound,
    PermissionDenied,
    TimedOut,
    // Future: can add Interrupted here without breaking changes
}

// Downstream code MUST have wildcard
match error.kind() {
    ErrorKind::NotFound => ...,
    ErrorKind::PermissionDenied => ...,
    ErrorKind::TimedOut => ...,
    _ => ...,  // Required by non_exhaustive
}

// Can add fields in minor versions
#[non_exhaustive]
pub struct Config {
    pub name: String,
    pub value: i32,
}

// Downstream CANNOT use struct literal syntax
// let config = Config { name: "test".into(), value: 42 };  // Error!

// Must use constructor
impl Config {
    pub fn new(name: impl Into<String>, value: i32) -> Self {
        Config { name: name.into(), value }
    }
}
```

### How It Works

```rust
#[non_exhaustive]
pub enum Status {
    Active,
    Inactive,
}

// Inside your crate: exhaustive match is allowed
fn internal(s: Status) {
    match s {
        Status::Active => {},
        Status::Inactive => {},
        // No wildcard needed inside defining crate
    }
}

// Outside your crate: wildcard required
fn external(s: my_crate::Status) {
    match s {
        my_crate::Status::Active => {},
        my_crate::Status::Inactive => {},
        _ => {},  // REQUIRED
    }
}
```

### Struct Usage

```rust
#[non_exhaustive]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

impl Point {
    // Provide constructor
    pub fn new(x: f64, y: f64) -> Self {
        Point { x, y }
    }
}

// External code can read fields but not construct with literals
fn external(p: Point) {
    println!("x: {}, y: {}", p.x, p.y);  // Reading is fine
    
    // let p2 = Point { x: 1.0, y: 2.0 };  // Error!
    let p2 = Point::new(1.0, 2.0);  // Must use constructor
}
```

### Non-Exhaustive Variants

```rust
pub enum Message {
    // Specific variant is non-exhaustive
    #[non_exhaustive]
    Error { code: u32, message: String },
    
    Ok(Data),
}

// Can destructure Ok normally
// But Error requires `..` to handle future fields
match msg {
    Message::Ok(data) => {},
    Message::Error { code, message, .. } => {},  // `..` required
}
```

### When to Use

```rust
// ✅ Use for public API types that may evolve
#[non_exhaustive]
pub enum ApiError { ... }

#[non_exhaustive]
pub struct Options { ... }

// ✅ Use for error types
#[non_exhaustive]
pub enum MyError { ... }

// ❌ Don't use for internal types
enum InternalState { ... }  // Not public, no concern

// ❌ Don't use for stable, complete types
pub enum Ordering {  // Less, Equal, Greater is complete
    Less,
    Equal,
    Greater,
}
```

### See Also

- [api-sealed-trait](#api-sealed-trait) - Controlling trait implementations
- [err-custom-type](#err-custom-type) - Error type design
- [api-builder-pattern](#api-builder-pattern) - Alternative to struct literals


## api-parse-dont-validate

> Parse into validated types at boundaries

### Why It Matters

Instead of validating data and hoping you remember to check everywhere, parse it into a type that can only be constructed from valid data. The type system then guarantees validity - you can't forget to validate because invalid states are unrepresentable.

### Bad

```rust
// Validation scattered throughout codebase
fn send_email(email: &str) -> Result<(), Error> {
    // Did someone validate this already? Who knows!
    if !is_valid_email(email) {
        return Err(Error::InvalidEmail);
    }
    // Send email...
}

fn add_to_mailing_list(email: &str) -> Result<(), Error> {
    // Duplicate validation, or did we forget?
    if !is_valid_email(email) {
        return Err(Error::InvalidEmail);
    }
    // Add to list...
}

// Easy to forget validation
fn process_user_email(email: &str) {
    // Oops, no validation!
    database.store_email(email);
}
```

### Good

```rust
/// A validated email address.
/// Can only be constructed via `Email::parse()`.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Email(String);

impl Email {
    /// Parses and validates an email address.
    pub fn parse(s: impl Into<String>) -> Result<Self, EmailError> {
        let s = s.into();
        if Self::is_valid(&s) {
            Ok(Email(s))
        } else {
            Err(EmailError::Invalid)
        }
    }
    
    fn is_valid(s: &str) -> bool {
        s.contains('@') && s.len() > 3  // Simplified
    }
    
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

// Now functions can accept Email - guaranteed valid!
fn send_email(email: &Email) -> Result<(), Error> {
    // No validation needed - Email is always valid
    smtp_send(email.as_str())
}

fn add_to_mailing_list(email: Email) {
    // No validation needed
    list.push(email);
}
```

### More Examples

```rust
// Port number (1-65535)
pub struct Port(u16);

impl Port {
    pub fn new(n: u16) -> Option<Self> {
        if n > 0 { Some(Port(n)) } else { None }
    }
    
    pub fn get(&self) -> u16 {
        self.0
    }
}

// Non-empty string
pub struct NonEmptyString(String);

impl NonEmptyString {
    pub fn new(s: impl Into<String>) -> Option<Self> {
        let s = s.into();
        if s.is_empty() { None } else { Some(Self(s)) }
    }
}

// Positive integer
pub struct PositiveI32(i32);

impl PositiveI32 {
    pub fn new(n: i32) -> Option<Self> {
        if n > 0 { Some(Self(n)) } else { None }
    }
}

// Bounded value
pub struct Percentage(u8);

impl Percentage {
    pub fn new(n: u8) -> Option<Self> {
        if n <= 100 { Some(Self(n)) } else { None }
    }
}
```

### Parsing at Boundaries

```rust
// Parse at the system boundary (API, CLI, config file)
fn handle_request(raw: RawRequest) -> Result<Response, Error> {
    // Parse ALL inputs upfront
    let email = Email::parse(&raw.email)?;
    let age = Age::parse(raw.age)?;
    let username = Username::parse(&raw.username)?;
    
    // Now work with validated types
    process_user(email, age, username)
}

fn process_user(email: Email, age: Age, username: Username) {
    // All inputs guaranteed valid - no checks needed
}
```

### Evidence from sqlx

```rust
// sqlx parses SQL at compile time, ensuring query validity
// https://github.com/launchbadge/sqlx/blob/master/src/macros/mod.rs

// The query! macro parses and validates SQL
let user = sqlx::query!("SELECT * FROM users WHERE id = ?", id)
    .fetch_one(&pool)
    .await?;

// If SQL is invalid, compilation fails - invalid state unrepresentable
```

### Combining with Display

```rust
use std::fmt;

pub struct Email(String);

impl Email {
    pub fn parse(s: &str) -> Result<Self, EmailError> { ... }
}

// Implement Display for easy printing
impl fmt::Display for Email {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

// Implement AsRef for easy borrowing
impl AsRef<str> for Email {
    fn as_ref(&self) -> &str {
        &self.0
    }
}
```

### See Also

- [api-newtype-safety](#api-newtype-safety) - Use newtypes for type safety
- [type-newtype-validated](#type-newtype-validated) - Newtypes for validated data
- [api-typestate](#api-typestate) - Compile-time state machines


## api-sealed-trait

> Use sealed traits to prevent external implementations while allowing use

### Why It Matters

Public traits can be implemented by anyone, which may be undesirable when you need to guarantee behavior or add methods in future versions. A sealed trait can be used by external code but not implemented by it, giving you control over implementations while maintaining a usable API.

### Bad

```rust
// Anyone can implement this trait
pub trait DatabaseDriver {
    fn connect(&self, url: &str) -> Connection;
    fn execute(&self, query: &str) -> Result<Rows, Error>;
}

// External crate implements it incorrectly
impl DatabaseDriver for MyBadDriver {
    fn connect(&self, url: &str) -> Connection {
        // Buggy implementation that doesn't handle errors
        unsafe { force_connect(url) }
    }
}

// Later, you want to add a required method - BREAKING CHANGE
pub trait DatabaseDriver {
    fn connect(&self, url: &str) -> Connection;
    fn execute(&self, query: &str) -> Result<Rows, Error>;
    fn transaction(&self) -> Transaction;  // External impls now broken!
}
```

### Good

```rust
// Create a private module with a private trait
mod private {
    pub trait Sealed {}
}

// Public trait requires the private trait
pub trait DatabaseDriver: private::Sealed {
    fn connect(&self, url: &str) -> Connection;
    fn execute(&self, query: &str) -> Result<Rows, Error>;
}

// Only your crate can implement Sealed, thus DatabaseDriver
pub struct PostgresDriver;
impl private::Sealed for PostgresDriver {}
impl DatabaseDriver for PostgresDriver {
    fn connect(&self, url: &str) -> Connection { ... }
    fn execute(&self, query: &str) -> Result<Rows, Error> { ... }
}

pub struct MySqlDriver;
impl private::Sealed for MySqlDriver {}
impl DatabaseDriver for MySqlDriver {
    fn connect(&self, url: &str) -> Connection { ... }
    fn execute(&self, query: &str) -> Result<Rows, Error> { ... }
}

// External crate cannot implement - private::Sealed is not accessible
// impl DatabaseDriver for ExternalDriver { }  // Error!

// But external code CAN use the trait
fn use_driver(driver: &impl DatabaseDriver) {
    let conn = driver.connect("postgres://localhost");
}
```

### Full Pattern

```rust
pub mod db {
    mod private {
        pub trait Sealed {}
    }
    
    /// Database driver trait.
    /// 
    /// This trait is sealed and cannot be implemented outside this crate.
    pub trait Driver: private::Sealed {
        /// Connects to the database.
        fn connect(&self, url: &str) -> Result<Connection, Error>;
        
        /// Executes a query.
        fn execute(&self, sql: &str) -> Result<Rows, Error>;
    }
    
    pub struct Postgres;
    impl private::Sealed for Postgres {}
    impl Driver for Postgres { ... }
    
    pub struct Sqlite;
    impl private::Sealed for Sqlite {}
    impl Driver for Sqlite { ... }
}

// Usage works fine
use db::{Driver, Postgres};

fn query(driver: &impl Driver) {
    driver.execute("SELECT 1")?;
}

query(&Postgres);
```

### Benefits of Sealing

```rust
// 1. Add methods without breaking changes
pub trait Format: private::Sealed {
    fn format(&self) -> String;
    
    // Added later - not breaking because no external impls exist
    fn format_pretty(&self) -> String {
        self.format()  // Default implementation
    }
}

// 2. Guarantee invariants
pub trait SafeBuffer: private::Sealed {
    // You control all implementations, so you know they're all correct
    fn get(&self, index: usize) -> Option<&u8>;
}

// 3. Use as marker traits
pub trait ValidConfig: private::Sealed {}
// Only validated configs implement this
```

### Partially Sealed

```rust
// Allow implementing some methods but not all
mod private {
    pub trait SealedCore {}
}

pub trait Plugin: private::SealedCore {
    // Sealed - only we implement
    fn initialize(&self);
    fn shutdown(&self);
    
    // Open - users can override
    fn name(&self) -> &str { "unnamed" }
}

// Only we can add new required sealed methods
// Users can customize open methods
```

### When to Seal

| Seal When | Don't Seal When |
|-----------|-----------------|
| API stability is critical | You want extension points |
| Implementation correctness is hard | Users need custom implementations |
| You'll add methods later | Trait is simple and stable |
| Safety invariants required | Standard patterns (Iterator, etc.) |

### See Also

- [api-non-exhaustive](#api-non-exhaustive) - Related pattern for enums/structs
- [api-extension-trait](#api-extension-trait) - Adding methods to external types
- [api-typestate](#api-typestate) - Compile-time state guarantees


## api-serde-optional

> Make serde a feature flag, not a hard dependency for library crates

### Why It Matters

Not all users of your library need serialization. Making serde a required dependency adds compile time and binary size for everyone. Feature flags let users opt-in to serde support only when needed, following Rust's philosophy of zero-cost abstractions and minimal dependencies.

### Bad

```rust
// Cargo.toml
[dependencies]
serde = { version = "1.0", features = ["derive"] }

// lib.rs
use serde::{Serialize, Deserialize};

// Every user pays for serde, even if they don't need it
#[derive(Serialize, Deserialize)]
pub struct Config {
    pub name: String,
    pub value: i32,
}
```

### Good

```rust
// Cargo.toml
[dependencies]
serde = { version = "1.0", features = ["derive"], optional = true }

[features]
default = []
serde = ["dep:serde"]

// lib.rs
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct Config {
    pub name: String,
    pub value: i32,
}

// Users opt-in:
// my_crate = { version = "1.0", features = ["serde"] }
```

### Macro Pattern

```rust
// Reusable macro for serde derives
#[cfg(feature = "serde")]
macro_rules! impl_serde {
    ($($t:ty),*) => {
        $(
            impl serde::Serialize for $t {
                // ...
            }
            impl<'de> serde::Deserialize<'de> for $t {
                // ...
            }
        )*
    };
}

#[cfg(not(feature = "serde"))]
macro_rules! impl_serde {
    ($($t:ty),*) => {};
}

// Or use cfg_attr for derived impls
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct Point {
    pub x: f64,
    pub y: f64,
}
```

### Feature Documentation

```rust
// lib.rs

//! # Features
//!
//! - `serde`: Enables `Serialize` and `Deserialize` implementations for all types.
//!
//! # Example with serde
//!
//! ```toml
//! [dependencies]
//! my_crate = { version = "1.0", features = ["serde"] }
//! ```

#![cfg_attr(docsrs, feature(doc_cfg))]

/// A configuration type.
/// 
/// When the `serde` feature is enabled, this type implements
/// `Serialize` and `Deserialize`.
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
#[cfg_attr(docsrs, doc(cfg(feature = "serde")))]
pub struct Config {
    pub name: String,
}
```

### Multiple Optional Dependencies

```rust
// Cargo.toml
[dependencies]
serde = { version = "1.0", features = ["derive"], optional = true }
rkyv = { version = "0.7", optional = true }
borsh = { version = "0.10", optional = true }

[features]
default = []
serde = ["dep:serde"]
rkyv = ["dep:rkyv"]
borsh = ["dep:borsh"]

// lib.rs
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
#[cfg_attr(feature = "rkyv", derive(rkyv::Archive, rkyv::Serialize, rkyv::Deserialize))]
#[cfg_attr(feature = "borsh", derive(borsh::BorshSerialize, borsh::BorshDeserialize))]
pub struct Message {
    pub id: u64,
    pub content: String,
}
```

### Testing with Features

```bash
### Test without serde
cargo test

### Test with serde
cargo test --features serde

### Test all feature combinations
cargo test --all-features
```

```rust
// Test serde round-trip when feature enabled
#[cfg(feature = "serde")]
#[test]
fn test_serde_roundtrip() {
    let config = Config { name: "test".into() };
    let json = serde_json::to_string(&config).unwrap();
    let parsed: Config = serde_json::from_str(&json).unwrap();
    assert_eq!(config, parsed);
}
```

### When to Make Serde Required

```rust
// ✅ Required: Library is about serialization
// (e.g., json-schema, config-file parser)
[dependencies]
serde = "1.0"

// ✅ Required: Domain heavily uses serde
// (e.g., API client, data format library)

// ❌ Optional: General-purpose utility library
// ❌ Optional: Math/algorithm library
// ❌ Optional: Most libraries!
```

### See Also

- [proj-lib-main-split](#proj-lib-main-split) - Library structure
- [api-common-traits](#api-common-traits) - Core trait implementations
- [lint-deny-correctness](#lint-deny-correctness) - Feature testing


## api-typestate

> Use typestate pattern to encode state machine invariants in the type system

### Why It Matters

State machines with runtime state checks ("are we connected?", "is the transaction started?") can have invalid transitions. The typestate pattern uses different types for each state, making invalid state transitions compile errors. The compiler enforces your state machine.

### Bad

```rust
struct Connection {
    state: ConnectionState,
    socket: Option<TcpStream>,
}

enum ConnectionState {
    Disconnected,
    Connected,
    Authenticated,
}

impl Connection {
    fn send(&mut self, data: &[u8]) -> Result<(), Error> {
        // Runtime check - can fail if called in wrong state
        if self.state != ConnectionState::Authenticated {
            return Err(Error::NotAuthenticated);
        }
        self.socket.as_mut().unwrap().write_all(data)?;
        Ok(())
    }
    
    fn authenticate(&mut self, password: &str) -> Result<(), Error> {
        // Runtime check - can fail
        if self.state != ConnectionState::Connected {
            return Err(Error::NotConnected);
        }
        // ...
    }
}

// Bug: forgot to authenticate
let mut conn = Connection::new();
conn.connect()?;
conn.send(b"data")?;  // Runtime error: NotAuthenticated
```

### Good

```rust
// Different types for each state
struct Disconnected;
struct Connected { socket: TcpStream }
struct Authenticated { socket: TcpStream, session: Session }

struct Connection<State> {
    state: State,
}

impl Connection<Disconnected> {
    fn new() -> Self {
        Connection { state: Disconnected }
    }
    
    fn connect(self, addr: &str) -> Result<Connection<Connected>, Error> {
        let socket = TcpStream::connect(addr)?;
        Ok(Connection { state: Connected { socket } })
    }
}

impl Connection<Connected> {
    fn authenticate(self, password: &str) -> Result<Connection<Authenticated>, Error> {
        let session = do_auth(&self.state.socket, password)?;
        Ok(Connection {
            state: Authenticated { socket: self.state.socket, session }
        })
    }
}

impl Connection<Authenticated> {
    fn send(&mut self, data: &[u8]) -> Result<(), Error> {
        // No runtime check needed - type guarantees we're authenticated
        self.state.socket.write_all(data)?;
        Ok(())
    }
}

// Bug: forgot to authenticate
let conn = Connection::new();
let conn = conn.connect("server:8080")?;
conn.send(b"data");  // Compile error! send() not available on Connection<Connected>

// Correct usage
let conn = Connection::new();
let conn = conn.connect("server:8080")?;
let mut conn = conn.authenticate("secret")?;
conn.send(b"data")?;  // Works - type is Connection<Authenticated>
```

### Builder Typestate

```rust
// Enforce required fields via typestate
struct BuilderNoUrl;
struct BuilderWithUrl { url: String }

struct RequestBuilder<State> {
    state: State,
    timeout: Option<Duration>,
}

impl RequestBuilder<BuilderNoUrl> {
    fn new() -> Self {
        RequestBuilder {
            state: BuilderNoUrl,
            timeout: None,
        }
    }
    
    fn url(self, url: &str) -> RequestBuilder<BuilderWithUrl> {
        RequestBuilder {
            state: BuilderWithUrl { url: url.to_string() },
            timeout: self.timeout,
        }
    }
}

impl RequestBuilder<BuilderWithUrl> {
    fn timeout(mut self, t: Duration) -> Self {
        self.timeout = Some(t);
        self
    }
    
    // Only available once URL is set
    fn build(self) -> Request {
        Request {
            url: self.state.url,
            timeout: self.timeout,
        }
    }
}

// Compile error: build() not available
let bad = RequestBuilder::new().build();

// Correct: must set URL first
let good = RequestBuilder::new()
    .url("https://example.com")
    .timeout(Duration::from_secs(30))
    .build();
```

### Transaction Example

```rust
struct NotStarted;
struct InProgress { tx_id: u64 }
struct Committed;

struct Transaction<State> {
    conn: Connection,
    state: State,
}

impl Transaction<NotStarted> {
    fn begin(conn: Connection) -> Result<Transaction<InProgress>, Error> {
        let tx_id = conn.execute("BEGIN")?;
        Ok(Transaction {
            conn,
            state: InProgress { tx_id },
        })
    }
}

impl Transaction<InProgress> {
    fn execute(&mut self, sql: &str) -> Result<(), Error> {
        self.conn.execute(sql)
    }
    
    fn commit(self) -> Result<Transaction<Committed>, Error> {
        self.conn.execute("COMMIT")?;
        Ok(Transaction {
            conn: self.conn,
            state: Committed,
        })
    }
    
    fn rollback(self) -> Connection {
        let _ = self.conn.execute("ROLLBACK");
        self.conn
    }
}
```

### See Also

- [api-builder-pattern](#api-builder-pattern) - Basic builder pattern
- [api-parse-dont-validate](#api-parse-dont-validate) - Type-driven invariants
- [api-sealed-trait](#api-sealed-trait) - Restricting trait implementations
