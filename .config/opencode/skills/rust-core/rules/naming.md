# Naming

> Loaded on demand from `SKILL.md` — one rule per `## <rule-id>` section.


## name-acronym-word

> Treat acronyms as words in identifiers: `HttpServer`, not `HTTPServer`

### Why It Matters

When acronyms are written in ALL CAPS within identifiers, word boundaries become unclear: is `HTTPSHandler` "HTTPS Handler" or "HTTP SHandler"? Treating acronyms as words (`HttpsHandler`) maintains clear word boundaries and follows Rust convention. The standard library uses this consistently.

### Bad

```rust
// ALL CAPS acronyms - unclear word boundaries
struct HTTPServer { ... }      // HTTP + Server or H + TTP + Server?
struct TCPIPConnection { ... } // TCP + IP? Or other splits?
struct JSONParser { ... }
struct XMLHTTPRequest { ... }  // Very confusing

fn parseJSON(input: &str) { ... }
fn connectTCP(addr: &str) { ... }
```

### Good

```rust
// Acronyms as words - clear boundaries
struct HttpServer { ... }      // Http + Server
struct TcpIpConnection { ... } // Tcp + Ip + Connection
struct JsonParser { ... }
struct XmlHttpRequest { ... }

fn parse_json(input: &str) { ... }
fn connect_tcp(addr: &str) { ... }

// More examples
struct Uuid { ... }            // Not UUID
struct Uri { ... }             // Not URI
struct Url { ... }             // Not URL
struct Html { ... }            // Not HTML
struct Css { ... }             // Not CSS
struct Api { ... }             // Not API
```

### Standard Library Examples

```rust
// std uses acronyms as words
std::net::TcpStream            // Not TCPStream
std::net::TcpListener          // Not TCPListener
std::net::UdpSocket            // Not UDPSocket
std::net::IpAddr               // Not IPAddr
std::io::IoError               // Not IOError (though Io is acceptable too)
```

### Two-Letter Acronyms

```rust
// Two-letter acronyms can go either way
struct Io { ... }    // or IO - both acceptable
struct Id { ... }    // or ID - both acceptable

// Preference: treat as word for consistency
struct IoHandler { ... }     // Preferred
struct IdGenerator { ... }   // Preferred
```

### In snake_case

```rust
// Acronyms become lowercase in snake_case
fn parse_json() { ... }
fn connect_tcp() { ... }
fn generate_uuid() { ... }
fn fetch_http() { ... }
fn encode_url() { ... }

// Variables
let json_response = fetch_json();
let tcp_connection = connect_tcp();
let user_id = generate_uuid();
```

### Mixed Cases

```rust
// When acronym is part of compound
struct HttpsConnection { ... }   // Https (not HTTPS)
struct Utf8String { ... }        // Utf8 (not UTF8)
struct Base64Encoder { ... }     // Base64 as word

// Multiple acronyms
struct JsonApiClient { ... }     // Json + Api + Client
struct RestApiHandler { ... }    // Rest + Api + Handler
```

### See Also

- [name-types-camel](#name-types-camel) - Type naming conventions
- [name-funcs-snake](#name-funcs-snake) - Function naming conventions
- [name-consts-screaming](#name-consts-screaming) - Constant naming


## name-as-free

> `as_` prefix: free reference conversion

### Why It Matters

Consistent naming helps users understand API cost. `as_` prefix signals a free (O(1), no allocation) conversion that returns a reference. This convention is used throughout the standard library.

### The Convention

| Prefix | Cost | Ownership | Example |
|--------|------|-----------|---------|
| `as_` | Free | `&T -> &U` | `str::as_bytes()` |
| `to_` | Expensive | `&T -> U` | `str::to_lowercase()` |
| `into_` | Variable | `T -> U` | `String::into_bytes()` |

### Examples

```rust
impl MyString {
    // as_ - free reference conversion
    pub fn as_str(&self) -> &str {
        &self.inner
    }
    
    pub fn as_bytes(&self) -> &[u8] {
        self.inner.as_bytes()
    }
}

impl Wrapper<T> {
    // as_ - returns reference to inner
    pub fn as_inner(&self) -> &T {
        &self.inner
    }
    
    pub fn as_inner_mut(&mut self) -> &mut T {
        &mut self.inner
    }
}
```

### Standard Library Examples

```rust
// String
let s = String::from("hello");
let bytes: &[u8] = s.as_bytes();    // Free, returns &[u8]
let str_ref: &str = s.as_str();     // Free, returns &str

// Vec
let v = vec![1, 2, 3];
let slice: &[i32] = v.as_slice();   // Free, returns &[i32]

// Path
let p = PathBuf::from("/home");
let path: &Path = p.as_path();      // Free, returns &Path

// OsString
let os = OsString::from("hello");
let os_str: &OsStr = os.as_os_str(); // Free, returns &OsStr
```

### Bad

```rust
impl MyType {
    // BAD: as_ but allocates
    pub fn as_string(&self) -> String {
        format!("{}", self.value)  // Allocates! Should be to_string()
    }
    
    // BAD: as_ but expensive
    pub fn as_processed(&self) -> &ProcessedData {
        // Actually does expensive computation
    }
}
```

### Good

```rust
impl MyType {
    // GOOD: Free reference
    pub fn as_str(&self) -> &str {
        &self.inner
    }
    
    // GOOD: to_ signals allocation
    pub fn to_string(&self) -> String {
        format!("{}", self.value)
    }
    
    // GOOD: into_ signals ownership transfer
    pub fn into_inner(self) -> Inner {
        self.inner
    }
}
```

### See Also

- [name-to-expensive](#name-to-expensive) - `to_` prefix for expensive conversions
- [name-into-ownership](#name-into-ownership) - `into_` prefix for ownership transfer


## name-consts-screaming

> Use `SCREAMING_SNAKE_CASE` for constants and statics

### Why It Matters

Constants and statics are special—they're known at compile time and have program-wide lifetime. `SCREAMING_SNAKE_CASE` makes them visually distinct from runtime variables. This convention is enforced by the compiler and universally expected.

### Bad

```rust
// lowercase/camelCase constants - compiler warns
const maxConnections: u32 = 100;  // warning
const default_timeout: u64 = 30;  // warning
static globalCounter: AtomicU64 = AtomicU64::new(0);  // warning
```

### Good

```rust
// SCREAMING_SNAKE_CASE for constants
const MAX_CONNECTIONS: u32 = 100;
const DEFAULT_TIMEOUT: Duration = Duration::from_secs(30);
const BUFFER_SIZE: usize = 4096;

// SCREAMING_SNAKE_CASE for statics
static GLOBAL_COUNTER: AtomicU64 = AtomicU64::new(0);
static CONFIG: OnceLock<Config> = OnceLock::new();

// Type-level constants in impl blocks
impl Buffer {
    const INITIAL_CAPACITY: usize = 1024;
    const MAX_CAPACITY: usize = 1024 * 1024;
}
```

### Associated Constants

```rust
trait Limit {
    const MAX: usize;
    const MIN: usize;
}

impl Limit for SmallBuffer {
    const MAX: usize = 256;
    const MIN: usize = 16;
}

// Generic associated constants
struct Container<T> {
    data: Vec<T>,
}

impl<T> Container<T> {
    const EMPTY: Self = Self { data: Vec::new() };
}
```

### Environment and Config

```rust
// Environment variable names
const ENV_DATABASE_URL: &str = "DATABASE_URL";
const ENV_LOG_LEVEL: &str = "LOG_LEVEL";

// Configuration keys
const CONFIG_TIMEOUT_SECONDS: &str = "timeout_seconds";
const CONFIG_MAX_RETRIES: &str = "max_retries";
```

### Lazy Static / OnceLock

```rust
use std::sync::OnceLock;

// Global configuration
static CONFIG: OnceLock<AppConfig> = OnceLock::new();

// Compiled regex
static EMAIL_REGEX: OnceLock<Regex> = OnceLock::new();

fn get_email_regex() -> &'static Regex {
    EMAIL_REGEX.get_or_init(|| {
        Regex::new(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").unwrap()
    })
}
```

### See Also

- [name-funcs-snake](#name-funcs-snake) - Function/variable naming
- [name-types-camel](#name-types-camel) - Type naming
- [type-newtype-ids](#type-newtype-ids) - Type-safe constants


## name-crate-no-rs

> Don't suffix crate names with `-rs` or `-rust`

### Why It Matters

Adding `-rs` or `-rust` to crate names is redundant—you're already on crates.io, it's obviously Rust. These suffixes waste characters, clutter the namespace, and can make crate names harder to type. The Rust community discourages this pattern.

### Bad

```toml
### Cargo.toml
[package]
name = "json-parser-rs"    # Redundant -rs
name = "my-lib-rust"       # Redundant -rust
name = "http-client-rs"    # We know it's Rust
name = "rust-sqlite"       # rust- prefix equally bad
```

### Good

```toml
### Cargo.toml
[package]
name = "json-parser"
name = "my-lib"
name = "http-client"
name = "sqlite-wrapper"

### Real crate examples (no -rs):
### serde (not serde-rs)
### tokio (not tokio-rs)
### reqwest (not reqwest-rs)
### clap (not clap-rs)
```

### When Context Is Needed

```toml
### If you're porting a library from another language:
name = "python-ast"        # Describes what it's for, not what it's written in

### If you're providing bindings:
name = "openssl"           # The Rust crate IS the Rust interface

### Platform-specific:
name = "windows-sys"       # Platform, not language
```

### Repository Naming

```
### GitHub repos don't need -rs either
github.com/user/my-library      # Good
github.com/user/my-library-rs   # Unnecessary

### Though some do for disambiguation from other language versions
github.com/rust-lang/rust       # The rust repo itself uses "rust"
```

### Exceptions

```toml
### Rare cases where disambiguation matters:
### - If there's a widely-known non-Rust project with the same name
### - Official Rust project repositories (rust-lang org)

### But even then, consider alternatives:
name = "fancy-lib"           # Instead of fancy-rs
name = "better-json"         # Instead of json-rust
name = "my-serde-impl"       # Instead of serde-rs-fork
```

### See Also

- [proj-workspace-deps](#proj-workspace-deps) - Cargo configuration
- [doc-cargo-metadata](#doc-cargo-metadata) - Package metadata
- [name-funcs-snake](#name-funcs-snake) - Naming conventions


## name-funcs-snake

> Use `snake_case` for functions, methods, variables, and modules

### Why It Matters

Rust uses `snake_case` for "value-level" names—functions, methods, variables, modules. This convention is enforced by the compiler and distinguishes runtime entities from types. Consistent naming makes code scannable and predictable.

### Bad

```rust
// CamelCase functions - compiler warns
fn calculateTotal() -> f64 { ... }  // warning: function `calculateTotal` should have a snake case name
fn getUserName() -> String { ... }  // warning

// Inconsistent naming
fn get_user() -> User { ... }
fn fetchOrder() -> Order { ... }  // Mixed conventions
```

### Good

```rust
// snake_case for functions
fn calculate_total() -> f64 { ... }
fn get_user_name() -> String { ... }
fn fetch_order() -> Order { ... }

// snake_case for methods
impl User {
    fn full_name(&self) -> String { ... }
    fn is_active(&self) -> bool { ... }
    fn set_email(&mut self, email: &str) { ... }
}

// snake_case for variables
let user_count = 42;
let max_connections = 100;
let is_valid = true;

// snake_case for modules
mod user_service;
mod http_client;
mod json_parser;
```

### Acronyms in snake_case

```rust
// Lowercase acronyms in snake_case
fn parse_json() -> Json { ... }   // Not parse_JSON
fn connect_tcp() -> TcpStream { ... }   // Not connect_TCP
fn generate_uuid() -> Uuid { ... }      // Not generate_UUID

let http_response = fetch();
let json_data = parse();
```

### Local Variables

```rust
fn process_data(input_data: &[u8]) -> Result<Output, Error> {
    let raw_bytes = input_data;
    let decoded_string = decode(raw_bytes)?;
    let parsed_value = parse(&decoded_string)?;
    let final_result = transform(parsed_value)?;
    
    Ok(final_result)
}
```

### See Also

- [name-types-camel](#name-types-camel) - Type naming
- [name-consts-screaming](#name-consts-screaming) - Constant naming
- [name-lifetime-short](#name-lifetime-short) - Lifetime naming


## name-into-ownership

> Use `into_` prefix for ownership-consuming conversions

### Why It Matters

The `into_` prefix signals "this method consumes self and returns something else." The original value is moved and no longer usable. This ownership transfer is usually cheap (no allocation), but the caller loses access to the original. Clear naming prevents "use after move" confusion.

### Bad

```rust
impl Wrapper {
    // Misleading: doesn't indicate ownership transfer
    fn get_inner(self) -> Inner {  
        self.inner
    }
    
    // Misleading: suggests borrowing
    fn as_inner(self) -> Inner {  // Takes self by value!
        self.inner
    }
}
```

### Good

```rust
impl Wrapper {
    // into_ clearly shows ownership transfer
    fn into_inner(self) -> Inner {
        self.inner
    }
}

// Usage is clear
let wrapper = Wrapper::new(inner);
let inner = wrapper.into_inner();  // wrapper is consumed
// wrapper.foo();  // Error: use of moved value
```

### Standard Library Examples

```rust
// All consume self and return owned data
let string: String = "hello".to_string();
let bytes: Vec<u8> = string.into_bytes();  // String consumed

let path = PathBuf::from("/foo");
let os_string: OsString = path.into_os_string();  // PathBuf consumed

let boxed: Box<[i32]> = vec![1, 2, 3].into_boxed_slice();  // Vec consumed

let vec: Vec<u8> = boxed.into_vec();  // Box consumed
```

### into_iter() Pattern

```rust
let vec = vec![1, 2, 3];

// into_iter consumes the collection
for item in vec.into_iter() {  // or just: for item in vec
    // item is i32, not &i32
}
// vec is consumed, can't use anymore

// Contrast with iter() which borrows
let vec = vec![1, 2, 3];
for item in vec.iter() {
    // item is &i32
}
// vec still usable
```

### IntoIterator Trait

```rust
impl IntoIterator for MyCollection {
    type Item = Element;
    type IntoIter = std::vec::IntoIter<Element>;
    
    fn into_iter(self) -> Self::IntoIter {
        self.elements.into_iter()  // Consumes self
    }
}
```

### Conversion Prefix Summary

```rust
struct Buffer {
    data: Vec<u8>,
    name: String,
}

impl Buffer {
    // as_ : free borrow, returns reference
    fn as_slice(&self) -> &[u8] {
        &self.data
    }
    
    // to_ : allocates, creates new value
    fn to_vec(&self) -> Vec<u8> {
        self.data.clone()
    }
    
    // into_ : consumes self, usually cheap
    fn into_inner(self) -> Vec<u8> {
        self.data
    }
    
    // into_ : can destructure into parts
    fn into_parts(self) -> (Vec<u8>, String) {
        (self.data, self.name)
    }
}
```

### See Also

- [name-as-free](#name-as-free) - Borrowing conversions
- [name-to-expensive](#name-to-expensive) - Allocating conversions
- [api-from-not-into](#api-from-not-into) - From trait implementation


## name-is-has-bool

> Use `is_`, `has_`, `can_`, `should_` prefixes for boolean-returning methods

### Why It Matters

Boolean methods answer yes/no questions. Prefixes like `is_`, `has_`, `can_` make the question explicit, so code reads naturally: `if user.is_active()`, `if buffer.has_remaining()`. Without prefixes, boolean methods are ambiguous and require reading documentation.

### Bad

```rust
impl User {
    // Unclear: does this check or set?
    fn active(&self) -> bool { ... }
    
    // Unclear: does this delete or check?
    fn deleted(&self) -> bool { ... }
    
    // Unclear return type
    fn admin(&self) -> bool { ... }
}

// Reading code is confusing
if user.active() { ... }  // Is this checking or activating?
```

### Good

```rust
impl User {
    // Clear: answers "is the user active?"
    fn is_active(&self) -> bool { ... }
    
    // Clear: answers "is the user deleted?"
    fn is_deleted(&self) -> bool { ... }
    
    // Clear: answers "is the user an admin?"
    fn is_admin(&self) -> bool { ... }
    
    // Clear: answers "does the user have permission X?"
    fn has_permission(&self, perm: Permission) -> bool { ... }
    
    // Clear: answers "can the user edit?"
    fn can_edit(&self) -> bool { ... }
}

// Reads naturally
if user.is_active() && user.has_permission(Permission::Write) {
    // ...
}
```

### Common Prefixes

| Prefix | Use For | Example |
|--------|---------|---------|
| `is_` | State/property check | `is_empty()`, `is_valid()`, `is_some()` |
| `has_` | Possession/containment | `has_key()`, `has_children()`, `has_remaining()` |
| `can_` | Capability/permission | `can_read()`, `can_write()`, `can_execute()` |
| `should_` | Recommendation/policy | `should_retry()`, `should_cache()` |
| `needs_` | Requirement | `needs_update()`, `needs_auth()` |
| `will_` | Future action | `will_block()`, `will_overflow()` |

### Standard Library Examples

```rust
// is_ prefix
vec.is_empty()
option.is_some()
option.is_none()
result.is_ok()
result.is_err()
char.is_alphabetic()
str.is_ascii()
path.is_file()
path.is_dir()

// has_ prefix (less common in std)
iterator.has_next()  // conceptual

// Checking methods
str.contains("foo")      // Not is_ because takes argument
str.starts_with("bar")   // Descriptive verb phrase
str.ends_with("baz")
```

### Negation

```rust
// Prefer positive form with caller negation
if !user.is_active() { ... }

// Rather than negative method
if user.is_inactive() { ... }  // Avoid double negatives: !is_inactive()

// Exception: when negative is the common case
fn is_empty(&self) -> bool { ... }     // Checking for empty is common
fn is_not_empty(&self) -> bool { ... } // Rarely needed, use !is_empty()
```

### Boolean Fields

```rust
struct Config {
    // Field names can omit prefix
    enabled: bool,
    verbose: bool,
    debug: bool,
}

impl Config {
    // But methods should have prefix
    fn is_enabled(&self) -> bool {
        self.enabled
    }
    
    fn is_verbose(&self) -> bool {
        self.verbose
    }
}
```

### See Also

- [name-no-get-prefix](#name-no-get-prefix) - Getter naming
- [name-funcs-snake](#name-funcs-snake) - Function naming
- [api-must-use](#api-must-use) - Boolean functions should be checked


## name-iter-convention

> Use iter/iter_mut/into_iter for iterator methods

### Why It Matters

Rust has a standard convention for iterator method names that signals ownership semantics. Following this convention makes APIs predictable and enables the `for item in collection` syntax to work correctly.

### The Three Iterator Methods

| Method | Returns | Ownership |
|--------|---------|-----------|
| `iter()` | `impl Iterator<Item = &T>` | Borrows collection |
| `iter_mut()` | `impl Iterator<Item = &mut T>` | Mutably borrows |
| `into_iter()` | `impl Iterator<Item = T>` | Consumes collection |

### Implementation

```rust
struct MyCollection<T> {
    items: Vec<T>,
}

impl<T> MyCollection<T> {
    /// Returns an iterator over references.
    fn iter(&self) -> impl Iterator<Item = &T> {
        self.items.iter()
    }
    
    /// Returns an iterator over mutable references.
    fn iter_mut(&mut self) -> impl Iterator<Item = &mut T> {
        self.items.iter_mut()
    }
}

// IntoIterator trait for into_iter()
impl<T> IntoIterator for MyCollection<T> {
    type Item = T;
    type IntoIter = std::vec::IntoIter<T>;
    
    fn into_iter(self) -> Self::IntoIter {
        self.items.into_iter()
    }
}

// Also implement for references
impl<'a, T> IntoIterator for &'a MyCollection<T> {
    type Item = &'a T;
    type IntoIter = std::slice::Iter<'a, T>;
    
    fn into_iter(self) -> Self::IntoIter {
        self.items.iter()
    }
}

impl<'a, T> IntoIterator for &'a mut MyCollection<T> {
    type Item = &'a mut T;
    type IntoIter = std::slice::IterMut<'a, T>;
    
    fn into_iter(self) -> Self::IntoIter {
        self.items.iter_mut()
    }
}
```

### Usage

```rust
let collection = MyCollection { items: vec![1, 2, 3] };

// Explicit methods
for x in collection.iter() { }     // Borrows
for x in collection.iter_mut() { } // Mutably borrows

// IntoIterator enables for loop syntax
for x in &collection { }      // Calls (&collection).into_iter()
for x in &mut collection { }  // Calls (&mut collection).into_iter()
for x in collection { }       // Consumes, calls collection.into_iter()
```

### Bad

```rust
impl MyCollection<T> {
    // Non-standard names
    fn elements(&self) -> impl Iterator<Item = &T> { }      // Should be iter()
    fn get_items(&self) -> impl Iterator<Item = &T> { }     // Should be iter()
    fn iterate(&self) -> impl Iterator<Item = &T> { }       // Should be iter()
    fn as_iter(&self) -> impl Iterator<Item = &T> { }       // Should be iter()
}
```

### Additional Iterator Methods

```rust
impl MyCollection<T> {
    // Filter by predicate
    fn iter_valid(&self) -> impl Iterator<Item = &T> {
        self.iter().filter(|x| x.is_valid())
    }
    
    // Specific slice
    fn iter_range(&self, start: usize, end: usize) -> impl Iterator<Item = &T> {
        self.items[start..end].iter()
    }
}
```

### Standard Library Examples

```rust
// Vec, slice, arrays
vec.iter()      // &T
vec.iter_mut()  // &mut T
vec.into_iter() // T

// HashMap
map.iter()      // (&K, &V)
map.iter_mut()  // (&K, &mut V)
map.into_iter() // (K, V)
map.keys()      // &K
map.values()    // &V
```

### See Also

- [name-iter-type-match](#name-iter-type-match) - Iterator type naming
- [name-iter-method](#name-iter-method) - Iterator method names
- [perf-iter-over-index](#perf-iter-over-index) - Prefer iterators


## name-iter-method

> Name iterator methods `iter()`, `iter_mut()`, and `into_iter()` consistently

### Why It Matters

Rust has a strong convention for iterator method names. Following these conventions makes your types work predictably with `for` loops and iterator adapters. Users expect `iter()` for shared references, `iter_mut()` for mutable references, and `into_iter()` for owned iteration.

### Bad

```rust
struct Collection<T> {
    items: Vec<T>,
}

impl<T> Collection<T> {
    // Non-standard names - confusing
    fn elements(&self) -> impl Iterator<Item = &T> {
        self.items.iter()
    }
    
    fn get_iterator(&self) -> impl Iterator<Item = &T> {
        self.items.iter()
    }
    
    fn to_iter(self) -> impl Iterator<Item = T> {
        self.items.into_iter()
    }
}
```

### Good

```rust
struct Collection<T> {
    items: Vec<T>,
}

impl<T> Collection<T> {
    /// Returns an iterator over references.
    fn iter(&self) -> impl Iterator<Item = &T> {
        self.items.iter()
    }
    
    /// Returns an iterator over mutable references.
    fn iter_mut(&mut self) -> impl Iterator<Item = &mut T> {
        self.items.iter_mut()
    }
}

// Implement IntoIterator for for-loop support
impl<T> IntoIterator for Collection<T> {
    type Item = T;
    type IntoIter = std::vec::IntoIter<T>;
    
    fn into_iter(self) -> Self::IntoIter {
        self.items.into_iter()
    }
}

impl<'a, T> IntoIterator for &'a Collection<T> {
    type Item = &'a T;
    type IntoIter = std::slice::Iter<'a, T>;
    
    fn into_iter(self) -> Self::IntoIter {
        self.items.iter()
    }
}

impl<'a, T> IntoIterator for &'a mut Collection<T> {
    type Item = &'a mut T;
    type IntoIter = std::slice::IterMut<'a, T>;
    
    fn into_iter(self) -> Self::IntoIter {
        self.items.iter_mut()
    }
}
```

### Iterator Convention Summary

| Method | Receiver | Yields | Use Case |
|--------|----------|--------|----------|
| `iter()` | `&self` | `&T` | Read-only iteration |
| `iter_mut()` | `&mut self` | `&mut T` | In-place modification |
| `into_iter()` | `self` | `T` | Consuming iteration |

### For Loop Integration

```rust
let col = Collection { items: vec![1, 2, 3] };

// These all work with proper IntoIterator impls
for item in &col {           // Calls (&col).into_iter() -> iter()
    println!("{}", item);    // &i32
}

for item in &mut col {       // Calls (&mut col).into_iter() -> iter_mut()
    *item += 1;              // &mut i32
}

for item in col {            // Calls col.into_iter()
    process(item);           // i32, consumes col
}
```

### Additional Iterator Methods

```rust
impl<T> Collection<T> {
    // Domain-specific iterators follow similar patterns
    
    /// Iterates over keys (for map-like structures).
    fn keys(&self) -> impl Iterator<Item = &K> { ... }
    
    /// Iterates over values.
    fn values(&self) -> impl Iterator<Item = &V> { ... }
    
    /// Iterates over mutable values.
    fn values_mut(&mut self) -> impl Iterator<Item = &mut V> { ... }
    
    /// Drains elements, leaving container empty.
    fn drain(&mut self) -> impl Iterator<Item = T> { ... }
}
```

### See Also

- [name-as-free](#name-as-free) - Conversion naming conventions
- [api-extension-trait](#api-extension-trait) - Iterator extensions
- [api-common-traits](#api-common-traits) - Standard trait implementations


## name-iter-type-match

> Name iterator types after their source method

### Why It Matters

Iterator types should match the method that creates them. `iter()` returns `Iter`, `into_iter()` returns `IntoIter`, `keys()` returns `Keys`. This naming pattern is established by the standard library and makes types predictable.

### Standard Library Pattern

```rust
// Vec
impl<T> Vec<T> {
    fn iter(&self) -> Iter<'_, T> { }       // Returns Iter
    fn iter_mut(&mut self) -> IterMut<'_, T> { }  // Returns IterMut
}

impl<T> IntoIterator for Vec<T> {
    type IntoIter = IntoIter<T>;  // Returns IntoIter
}

// HashMap
impl<K, V> HashMap<K, V> {
    fn iter(&self) -> Iter<'_, K, V> { }
    fn keys(&self) -> Keys<'_, K, V> { }    // Returns Keys
    fn values(&self) -> Values<'_, K, V> { }  // Returns Values
    fn drain(&mut self) -> Drain<'_, K, V> { }  // Returns Drain
}
```

### Implementation

```rust
mod my_collection {
    pub struct MyCollection<T> {
        items: Vec<T>,
    }
    
    // Iterator types in same module
    pub struct Iter<'a, T> {
        inner: std::slice::Iter<'a, T>,
    }
    
    pub struct IterMut<'a, T> {
        inner: std::slice::IterMut<'a, T>,
    }
    
    pub struct IntoIter<T> {
        inner: std::vec::IntoIter<T>,
    }
    
    impl<T> MyCollection<T> {
        pub fn iter(&self) -> Iter<'_, T> {
            Iter { inner: self.items.iter() }
        }
        
        pub fn iter_mut(&mut self) -> IterMut<'_, T> {
            IterMut { inner: self.items.iter_mut() }
        }
    }
    
    impl<T> IntoIterator for MyCollection<T> {
        type Item = T;
        type IntoIter = IntoIter<T>;
        
        fn into_iter(self) -> IntoIter<T> {
            IntoIter { inner: self.items.into_iter() }
        }
    }
    
    // Implement Iterator for each type
    impl<'a, T> Iterator for Iter<'a, T> {
        type Item = &'a T;
        fn next(&mut self) -> Option<Self::Item> {
            self.inner.next()
        }
    }
    
    impl<'a, T> Iterator for IterMut<'a, T> {
        type Item = &'a mut T;
        fn next(&mut self) -> Option<Self::Item> {
            self.inner.next()
        }
    }
    
    impl<T> Iterator for IntoIter<T> {
        type Item = T;
        fn next(&mut self) -> Option<Self::Item> {
            self.inner.next()
        }
    }
}
```

### Naming Convention

| Method | Iterator Type |
|--------|---------------|
| `iter()` | `Iter` |
| `iter_mut()` | `IterMut` |
| `into_iter()` | `IntoIter` |
| `keys()` | `Keys` |
| `values()` | `Values` |
| `values_mut()` | `ValuesMut` |
| `drain()` | `Drain` |
| `chunks()` | `Chunks` |
| `windows()` | `Windows` |

### Custom Iterator Methods

```rust
impl Graph {
    // Method name -> Type name
    fn nodes(&self) -> Nodes<'_> { }        // Custom: Nodes
    fn edges(&self) -> Edges<'_> { }        // Custom: Edges
    fn neighbors(&self, node: NodeId) -> Neighbors<'_> { }  // Custom: Neighbors
}

pub struct Nodes<'a> { /* ... */ }
pub struct Edges<'a> { /* ... */ }
pub struct Neighbors<'a> { /* ... */ }
```

### Bad

```rust
// Mismatched names
impl MyCollection<T> {
    fn iter(&self) -> MyCollectionIterator<'_, T> { }  // Should be Iter
    fn keys(&self) -> KeyIterator<'_, K> { }           // Should be Keys
}

// Generic names that don't match method
pub struct Iterator<T>;  // Conflicts with std::iter::Iterator
pub struct I<T>;         // Too cryptic
```

### See Also

- [name-iter-convention](#name-iter-convention) - iter/iter_mut/into_iter
- [name-iter-method](#name-iter-method) - Iterator method names
- [api-common-traits](#api-common-traits) - Implementing common traits


## name-lifetime-short

> Use short, conventional lifetime names: `'a`, `'b`, `'de`, `'src`

### Why It Matters

Lifetime parameters are ubiquitous in Rust signatures. Short names like `'a` keep signatures readable. For domain-specific lifetimes, descriptive but short names like `'src` or `'de` communicate intent without clutter. The Rust community has established conventions that aid recognition.

### Bad

```rust
// Overly verbose lifetimes
fn parse<'input_lifetime, 'output_lifetime>(
    input: &'input_lifetime str
) -> Result<&'output_lifetime str, Error> { ... }

// Meaningless long names
struct Parser<'parser_instance_lifetime> {
    source: &'parser_instance_lifetime str,
}
```

### Good

```rust
// Standard short lifetimes
fn parse<'a>(input: &'a str) -> Result<&'a str, Error> { ... }

struct Parser<'a> {
    source: &'a str,
}

// Multiple lifetimes: 'a, 'b, 'c
fn merge<'a, 'b>(first: &'a str, second: &'b str) -> String { ... }

// Descriptive when clarity helps
fn deserialize<'de>(input: &'de [u8]) -> Result<Value<'de>, Error> { ... }
```

### Common Lifetime Conventions

| Lifetime | Convention | Example |
|----------|------------|---------|
| `'a` | Generic, first lifetime | `fn foo<'a>(x: &'a str)` |
| `'b` | Generic, second lifetime | `fn bar<'a, 'b>(x: &'a T, y: &'b U)` |
| `'de` | Deserialization | serde's `Deserialize<'de>` |
| `'src` | Source code/input | `struct Lexer<'src>` |
| `'ctx` | Context | `struct Query<'ctx>` |
| `'input` | Input data | `struct Parser<'input>` |
| `'static` | Static lifetime | `&'static str` |

### Elision Preferred

```rust
// Let elision work when possible
fn first_word(s: &str) -> &str {  // Not fn first_word<'a>(s: &'a str) -> &'a str
    s.split_whitespace().next().unwrap_or("")
}

impl User {
    fn name(&self) -> &str {  // Elision handles this
        &self.name
    }
}
```

### Serde Convention

```rust
use serde::{Deserialize, Serialize};

// 'de is the standard serde lifetime for borrowed data
#[derive(Deserialize)]
struct Request<'de> {
    #[serde(borrow)]
    name: &'de str,
    #[serde(borrow)]
    tags: Vec<&'de str>,
}
```

### See Also

- [own-lifetime-elision](#own-lifetime-elision) - When to omit lifetimes
- [name-type-param-single](#name-type-param-single) - Type parameter naming
- [own-borrow-over-clone](#own-borrow-over-clone) - Borrowing patterns


## name-no-get-prefix

> Omit get_ prefix for simple getters

### Why It Matters

Rust convention omits the `get_` prefix for simple field access. Methods like `len()`, `name()`, `value()` are cleaner than `get_len()`, `get_name()`, `get_value()`. This follows the principle of making the common case concise.

The `get` prefix is reserved for methods that DO something beyond simple field access.

### Bad

```rust
struct User {
    name: String,
    age: u32,
}

impl User {
    fn get_name(&self) -> &str {      // Verbose
        &self.name
    }
    
    fn get_age(&self) -> u32 {         // Verbose
        self.age
    }
    
    fn get_is_adult(&self) -> bool {   // Doubly verbose
        self.age >= 18
    }
}

let name = user.get_name();
let age = user.get_age();
```

### Good

```rust
struct User {
    name: String,
    age: u32,
}

impl User {
    fn name(&self) -> &str {           // Clean
        &self.name
    }
    
    fn age(&self) -> u32 {             // Clean
        self.age
    }
    
    fn is_adult(&self) -> bool {       // Boolean uses is_ prefix
        self.age >= 18
    }
}

let name = user.name();
let age = user.age();
```

### When get_ IS Appropriate

Use `get` when the method does more than simple access:

```rust
impl HashMap<K, V> {
    // Returns Option - not just field access
    fn get(&self, key: &K) -> Option<&V> { }
    
    // Mutable variant
    fn get_mut(&mut self, key: &K) -> Option<&mut V> { }
}

impl Vec<T> {
    // Returns Option - bounds checked
    fn get(&self, index: usize) -> Option<&T> { }
}

impl Context {
    // Does computation/lookup, not just field access
    fn get_config(&self) -> Config {
        self.configs.get(&self.current_env).cloned().unwrap_or_default()
    }
}
```

### Standard Library Examples

```rust
// No get_ prefix
String::len()
Vec::len()
Vec::capacity()
Vec::is_empty()
Path::file_name()
Option::is_some()
Result::is_ok()

// With get - returns Option or does lookup
Vec::get(index)
HashMap::get(key)
BTreeMap::get(key)
```

### Pattern: Getter/Setter Pairs

```rust
impl Config {
    // Getter: no prefix
    fn timeout(&self) -> Duration {
        self.timeout
    }
    
    // Setter: use set_ prefix
    fn set_timeout(&mut self, timeout: Duration) {
        self.timeout = timeout;
    }
}
```

### Pattern: Builder Methods

```rust
impl ConfigBuilder {
    // Builder methods: no get_, no set_
    fn timeout(mut self, timeout: Duration) -> Self {
        self.timeout = timeout;
        self
    }
    
    fn retries(mut self, retries: u32) -> Self {
        self.retries = retries;
        self
    }
}
```

### Decision Guide

| Pattern | Naming |
|---------|--------|
| Simple field access | `name()`, `value()`, `len()` |
| Boolean property | `is_valid()`, `has_items()` |
| Fallible access | `get()`, `get_mut()` |
| Setter | `set_name()`, `set_value()` |
| Builder | `name()`, `value()` (consuming self) |

### See Also

- [name-is-has-bool](#name-is-has-bool) - Boolean naming
- [name-is-has-bool](#name-is-has-bool) - Boolean naming
- [api-builder-pattern](#api-builder-pattern) - Builder pattern


## name-to-expensive

> Use `to_` prefix for expensive conversions that allocate or compute

### Why It Matters

The `to_` prefix signals "this conversion has a cost"—typically allocation, cloning, or computation. Callers know to consider caching the result or avoiding repeated calls. This contrasts with `as_` (free reference conversion) and `into_` (ownership transfer).

### Bad

```rust
impl Name {
    // Misleading: suggests expensive operation
    fn as_uppercase(&self) -> String {
        self.0.to_uppercase()  // Allocates!
    }
    
    // Misleading: suggests cheap reference
    fn get_string(&self) -> String {
        self.0.clone()  // Allocates!
    }
}
```

### Good

```rust
impl Name {
    // to_ = allocates/computes
    fn to_uppercase(&self) -> String {
        self.0.to_uppercase()
    }
    
    // to_ = creates new value
    fn to_string(&self) -> String {
        self.0.clone()
    }
    
    // as_ = free reference (cheap)
    fn as_str(&self) -> &str {
        &self.0
    }
}
```

### Standard Library Examples

```rust
// to_ methods - all allocate or compute
let s: String = slice.to_vec();           // Allocates Vec
let s: String = "hello".to_string();      // Allocates String
let s: String = "HELLO".to_lowercase();   // Allocates new String
let s: String = path.to_string_lossy().into_owned();  // May allocate

// Contrast with as_ methods - all are free
let slice: &[u8] = s.as_bytes();          // Just reinterpret
let str_ref: &str = string.as_str();      // Just reference
let path: &Path = Path::new("foo");       // Just reference
```

### Conversion Method Prefixes

| Prefix | Cost | Ownership | Example |
|--------|------|-----------|---------|
| `as_` | Free (O(1)) | Borrows `&T` | `as_str()`, `as_bytes()` |
| `to_` | Allocates/Computes | Creates new | `to_string()`, `to_vec()` |
| `into_` | Usually free | Takes ownership | `into_inner()`, `into_vec()` |

### Custom Types

```rust
struct Email(String);

impl Email {
    // Cheap: just returns reference
    fn as_str(&self) -> &str {
        &self.0
    }
    
    // Expensive: allocates
    fn to_lowercase(&self) -> Email {
        Email(self.0.to_lowercase())
    }
    
    // Expensive: allocates
    fn to_display_format(&self) -> String {
        format!("<{}>", self.0)
    }
    
    // Ownership transfer: usually cheap
    fn into_string(self) -> String {
        self.0
    }
}
```

### to_owned() Pattern

```rust
// to_owned() for getting owned version of borrowed data
let borrowed: &str = "hello";
let owned: String = borrowed.to_owned();  // Allocates

let borrowed: &[i32] = &[1, 2, 3];
let owned: Vec<i32> = borrowed.to_owned();  // Allocates

// ToOwned trait
trait ToOwned {
    type Owned;
    fn to_owned(&self) -> Self::Owned;
}
```

### See Also

- [name-as-free](#name-as-free) - Free reference conversions
- [name-into-ownership](#name-into-ownership) - Ownership transfer
- [own-cow-conditional](#own-cow-conditional) - Avoiding unnecessary allocations


## name-type-param-single

> Use single uppercase letters for type parameters: `T`, `E`, `K`, `V`

### Why It Matters

Generic type parameters conventionally use single uppercase letters. This keeps signatures concise and follows established conventions that readers instantly recognize. `T` for "type", `E` for "error", `K` for "key", `V` for "value" are universal in Rust.

### Bad

```rust
// Verbose type parameters
struct Container<ElementType> {
    items: Vec<ElementType>,
}

fn process<InputType, OutputType>(input: InputType) -> OutputType { ... }

// Lowercase - looks like lifetime
struct Wrapper<t> { ... }  // Confusing
```

### Good

```rust
// Single uppercase letters
struct Container<T> {
    items: Vec<T>,
}

fn process<I, O>(input: I) -> O { ... }

// Standard conventions
struct HashMap<K, V> { ... }     // K=Key, V=Value
enum Result<T, E> { ... }         // T=Type, E=Error
enum Option<T> { ... }            // T=Type
struct Ref<'a, T> { ... }        // Lifetime + Type
```

### Standard Type Parameter Names

| Parameter | Meaning | Example |
|-----------|---------|---------|
| `T` | Type (generic) | `Vec<T>` |
| `E` | Error | `Result<T, E>` |
| `K` | Key | `HashMap<K, V>` |
| `V` | Value | `HashMap<K, V>` |
| `I` | Input / Item | `Iterator<Item = I>` |
| `O` | Output | `Fn(I) -> O` |
| `R` | Return / Result | `fn() -> R` |
| `S` | State | `StateMachine<S>` |
| `A` | Allocator | `Vec<T, A>` |
| `F` | Function | `map<F>(f: F)` |

### Multiple Type Parameters

```rust
// Use related letters
fn transform<I, O, E>(input: I) -> Result<O, E>
where
    I: Input,
    O: Output,
    E: Error,
{ ... }

// Or sequential: T, U, V
fn combine<T, U, V>(a: T, b: U) -> V { ... }

// Descriptive only when many parameters need clarity
struct Query<Db, Row, Err> { ... }
```

### Trait Bounds

```rust
// Keep type params short, move complexity to where clause
fn process<T, E>(value: T) -> Result<T, E>
where
    T: Clone + Debug + Send + Sync,
    E: Error + From<IoError>,
{ ... }

// Not inline
fn process<T: Clone + Debug + Send + Sync, E: Error + From<IoError>>(value: T) -> Result<T, E>
// Too long!
```

### See Also

- [name-lifetime-short](#name-lifetime-short) - Lifetime parameter naming
- [name-types-camel](#name-types-camel) - Concrete type naming
- [type-generic-bounds](#type-generic-bounds) - Trait bounds


## name-types-camel

> Use `UpperCamelCase` for types, traits, and enum names

### Why It Matters

Rust's naming conventions are enforced by the compiler and linter. Consistent naming makes code immediately recognizable—you know `HttpClient` is a type, `send_request` is a function. Violating conventions triggers warnings and makes code harder to read.

### Bad

```rust
// Lowercase types - compiler warns
struct http_client { ... }  // warning: type `http_client` should have an upper camel case name
trait serializable { ... }  // warning
enum response_type { ... }  // warning

// Screaming case for types
struct HTTP_CLIENT { ... }  // Not idiomatic
```

### Good

```rust
// UpperCamelCase for all types
struct HttpClient { ... }
trait Serializable { ... }
enum ResponseType { ... }

// Compound words
struct TcpConnection { ... }
struct IoError { ... }
struct FileReader { ... }

// Generic types
struct HashMap<K, V> { ... }
struct Result<T, E> { ... }
```

### Acronyms

```rust
// Treat acronyms as words (capitalize first letter only)
struct HttpServer { ... }      // Not HTTPServer
struct JsonParser { ... }      // Not JSONParser
struct Uuid { ... }            // Not UUID
struct TcpStream { ... }       // Not TCPStream

// Exception: Two-letter acronyms can be all caps
struct IOError { ... }         // Acceptable
struct IoError { ... }         // Also acceptable (preferred)
```

### Type Aliases

```rust
// Type aliases also use UpperCamelCase
type Result<T> = std::result::Result<T, Error>;
type BoxedFuture<'a, T> = Pin<Box<dyn Future<Output = T> + Send + 'a>>;
```

### See Also

- [name-variants-camel](#name-variants-camel) - Enum variant naming
- [name-funcs-snake](#name-funcs-snake) - Function naming
- [name-acronym-word](#name-acronym-word) - Acronym handling


## name-variants-camel

> Use `UpperCamelCase` for enum variants

### Why It Matters

Enum variants follow the same naming convention as types—`UpperCamelCase`. This distinguishes them from fields, variables, and functions. The compiler warns on violations, and consistent naming helps readers instantly recognize variant names.

### Bad

```rust
enum Status {
    pending,       // warning: variant `pending` should have an upper camel case name
    in_progress,   // warning
    COMPLETED,     // Not idiomatic
}

enum Color {
    RED,           // Screaming case - not Rust style
    GREEN,
    BLUE,
}
```

### Good

```rust
enum Status {
    Pending,
    InProgress,
    Completed,
    Failed,
}

enum Color {
    Red,
    Green,
    Blue,
    Custom(u8, u8, u8),
}

enum HttpMethod {
    Get,
    Post,
    Put,
    Delete,
    Patch,
}
```

### Variants with Data

```rust
enum Message {
    // Unit variant
    Quit,
    
    // Tuple variant
    Move(i32, i32),
    
    // Struct variant
    Write { text: String },
    
    // Named fields
    ChangeColor {
        red: u8,
        green: u8,
        blue: u8,
    },
}
```

### Variant Naming Tips

```rust
// Be specific
enum Error {
    NotFound,           // Good: specific
    PermissionDenied,   // Good: specific
    Error,              // Bad: vague
}

// Avoid redundant type name in variant
enum ConnectionState {
    Connected,          // Good
    Disconnected,       // Good
    ConnectionError,    // Bad: redundant "Connection"
}

// Use None/Some pattern for Option-like enums
enum MaybeValue<T> {
    Some(T),
    None,
}
```

### See Also

- [name-types-camel](#name-types-camel) - Type naming
- [api-non-exhaustive](#api-non-exhaustive) - Forward-compatible enums
- [type-enum-states](#type-enum-states) - State machine enums
