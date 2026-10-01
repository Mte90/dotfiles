# Type Design

> Loaded on demand from `SKILL.md` — one rule per `## <rule-id>` section.


## type-enum-states

> Use enums for mutually exclusive states

### Why It Matters

When a value can be in exactly one of several states, an enum makes invalid states unrepresentable. The compiler ensures all states are handled. Contrast with boolean flags or optional fields that can represent impossible combinations.

### Bad

```rust
struct Connection {
    is_connected: bool,
    is_authenticated: bool,
    is_disconnected: bool,  // Can all three be true? False?
    socket: Option<TcpStream>,
    credentials: Option<Credentials>,
}

// Possible invalid states:
// - is_connected && is_disconnected (contradiction)
// - is_authenticated && !is_connected (impossible)
// - socket is None but is_connected is true (inconsistent)
```

### Good

```rust
enum ConnectionState {
    Disconnected,
    Connecting { address: SocketAddr },
    Connected { socket: TcpStream },
    Authenticated { socket: TcpStream, session: Session },
    Failed { error: ConnectionError },
}

struct Connection {
    state: ConnectionState,
}

// Impossible states are unrepresentable
// Each state has exactly the data it needs
```

### Pattern Matching Ensures Completeness

```rust
fn handle_connection(conn: &Connection) {
    match &conn.state {
        ConnectionState::Disconnected => {
            println!("Not connected");
        }
        ConnectionState::Connecting { address } => {
            println!("Connecting to {}", address);
        }
        ConnectionState::Connected { socket } => {
            println!("Connected, not authenticated");
        }
        ConnectionState::Authenticated { socket, session } => {
            println!("Authenticated as {}", session.user);
        }
        ConnectionState::Failed { error } => {
            println!("Failed: {}", error);
        }
    }
    // Compiler error if any state is missing
}
```

### State Transitions

```rust
impl Connection {
    fn connect(&mut self, addr: SocketAddr) -> Result<(), Error> {
        match &self.state {
            ConnectionState::Disconnected => {
                self.state = ConnectionState::Connecting { address: addr };
                Ok(())
            }
            _ => Err(Error::AlreadyConnected),
        }
    }
    
    fn on_connected(&mut self, socket: TcpStream) {
        if let ConnectionState::Connecting { .. } = &self.state {
            self.state = ConnectionState::Connected { socket };
        }
    }
    
    fn authenticate(&mut self, creds: Credentials) -> Result<(), Error> {
        match std::mem::replace(&mut self.state, ConnectionState::Disconnected) {
            ConnectionState::Connected { socket } => {
                let session = perform_auth(&socket, creds)?;
                self.state = ConnectionState::Authenticated { socket, session };
                Ok(())
            }
            other => {
                self.state = other;
                Err(Error::NotConnected)
            }
        }
    }
}
```

### Result and Option as State Enums

```rust
// Option<T> is an enum for "might not exist"
enum Option<T> {
    Some(T),
    None,
}

// Result<T, E> is an enum for "might have failed"
enum Result<T, E> {
    Ok(T),
    Err(E),
}

// Use these instead of nullable/sentinel values
fn find_user(id: u64) -> Option<User> { ... }
fn parse_config(s: &str) -> Result<Config, ParseError> { ... }
```

### Avoid Boolean Flags

```rust
// Bad: boolean flags
struct Task {
    is_running: bool,
    is_completed: bool,
    is_failed: bool,
    error: Option<Error>,
}

// Good: enum state
enum TaskState {
    Pending,
    Running { started_at: Instant },
    Completed { result: Output },
    Failed { error: Error },
}

struct Task {
    state: TaskState,
}
```

### See Also

- [api-typestate](#api-typestate) - Type-level state machines
- [api-non-exhaustive](#api-non-exhaustive) - Forward-compatible enums
- [type-option-nullable](#type-option-nullable) - Option for optional values


## type-generic-bounds

> Add trait bounds only where needed, prefer where clauses for readability

### Why It Matters

Trait bounds constrain what types can be used with generic code. Adding unnecessary bounds limits flexibility. Adding bounds in the right place (impl vs function vs where clause) affects usability and readability. Well-placed bounds keep APIs flexible while ensuring type safety.

### Bad

```rust
// Bounds on struct definition - limits all uses
struct Container<T: Clone + Debug> {  // Even storage requires Clone?
    items: Vec<T>,
}

// Inline bounds make signature hard to read
fn process<T: Clone + Debug + Send + Sync + 'static, E: Error + Send + Clone>(
    value: T
) -> Result<T, E> { ... }

// Redundant bounds
fn print_twice<T: Clone + Debug>(value: T)
where
    T: Clone,  // Already specified above
{ ... }
```

### Good

```rust
// No bounds on struct - store anything
struct Container<T> {
    items: Vec<T>,
}

// Bounds only on impls that need them
impl<T: Clone> Container<T> {
    fn duplicate(&self) -> Self {
        Container { items: self.items.clone() }
    }
}

impl<T: Debug> Container<T> {
    fn debug_print(&self) {
        println!("{:?}", self.items);
    }
}

// Where clause for readability
fn process<T, E>(value: T) -> Result<T, E>
where
    T: Clone + Debug + Send + Sync + 'static,
    E: Error + Send + Clone,
{ ... }
```

### Bound Placement

```rust
// On struct: affects all uses of the type
struct MustBeClone<T: Clone> { data: T }  // Rarely needed

// On impl: affects specific functionality
impl<T: Clone> Container<T> { ... }  // Common pattern

// On function: affects that function only
fn requires_send<T: Send>(value: T) { ... }

// Recommendation: start with no bounds, add as needed
```

### Where Clause Benefits

```rust
// Inline: hard to read
fn complex<T: Clone + Debug + Send, U: AsRef<str> + Into<String>>(t: T, u: U) { }

// Where clause: clear and scannable
fn complex<T, U>(t: T, u: U)
where
    T: Clone + Debug + Send,
    U: AsRef<str> + Into<String>,
{ }

// Essential for complex bounds
fn foo<T, U>(t: T, u: U)
where
    T: Iterator<Item = U>,
    U: Clone + Into<String>,
    Vec<U>: Debug,  // Bounds on expressions
{ }
```

### Implied Bounds

```rust
// Supertrait bounds are implied
trait Foo: Clone + Debug {}

fn process<T: Foo>(value: T) {
    // T: Clone and T: Debug are implied by T: Foo
    let cloned = value.clone();
    println!("{:?}", cloned);
}

// Associated type bounds
fn process<I>(iter: I)
where
    I: Iterator,
    I::Item: Clone,  // Bound on associated type
{ }
```

### Conditional Trait Implementation

```rust
struct Wrapper<T>(T);

// Implement Clone only when T: Clone
impl<T: Clone> Clone for Wrapper<T> {
    fn clone(&self) -> Self {
        Wrapper(self.0.clone())
    }
}

// Implement Debug only when T: Debug  
impl<T: Debug> Debug for Wrapper<T> {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        f.debug_tuple("Wrapper").field(&self.0).finish()
    }
}

// Wrapper<i32> is Clone + Debug
// Wrapper<NonCloneable> is neither
```

### See Also

- [api-impl-into](#api-impl-into) - Using Into bounds
- [api-impl-asref](#api-impl-asref) - Using AsRef bounds
- [name-type-param-single](#name-type-param-single) - Type parameter naming


## type-never-diverge

> Use `!` (never type) for functions that never return

### Why It Matters

The never type `!` indicates a function will never return normally—it either loops forever, panics, or exits the process. This helps the compiler understand control flow and enables `!` to coerce to any type, making it useful in match arms and expressions.

### Bad

```rust
// Return type doesn't indicate non-returning
fn infinite_loop() {
    loop {
        process_events();
    }
    // Implicit () return type, but never returns
}

// Using Option when it always panics
fn unreachable_code() -> Option<()> {
    panic!("This should never be called");
}
```

### Good

```rust
// ! indicates function never returns
fn infinite_loop() -> ! {
    loop {
        process_events();
    }
}

fn abort_with_error(msg: &str) -> ! {
    eprintln!("Fatal error: {}", msg);
    std::process::exit(1);
}

fn panic_handler() -> ! {
    panic!("Unexpected state");
}
```

### Coercion to Any Type

```rust
// ! coerces to any type
fn get_value(opt: Option<i32>) -> i32 {
    match opt {
        Some(v) => v,
        None => panic!("No value"),  // panic! returns !, coerces to i32
    }
}

// Useful in Result handling
fn must_get_config() -> Config {
    match load_config() {
        Ok(c) => c,
        Err(e) => {
            log_error(&e);
            std::process::exit(1)  // Returns !, coerces to Config
        }
    }
}
```

### Standard Library Examples

```rust
// std::process::exit
pub fn exit(code: i32) -> !

// panic! macro
// Expands to an expression of type !

// std::hint::unreachable_unchecked
pub unsafe fn unreachable_unchecked() -> !

// loop {} with no break
fn forever() -> ! {
    loop {}
}
```

### In Match Expressions

```rust
enum State {
    Running,
    Stopped,
    Error,
}

fn get_status(state: &State) -> &str {
    match state {
        State::Running => "running",
        State::Stopped => "stopped",
        State::Error => unreachable!(),  // ! coerces to &str
    }
}

// With Result
fn process(r: Result<Data, Error>) -> Data {
    match r {
        Ok(d) => d,
        Err(e) => panic!("Unexpected error: {}", e),  // ! coerces to Data
    }
}
```

### Diverging Closures

```rust
// Closures that never return
let handler: fn() -> ! = || {
    panic!("Handler called");
};

// In thread spawn
std::thread::spawn(|| -> ! {
    loop {
        process_work();
    }
});
```

### Current Limitations (Nightly)

```rust
// Full ! type is nightly
#![feature(never_type)]

// Can use ! as type parameter
type NeverResult = Result<(), !>;  // Can never be Err

// On stable, use std::convert::Infallible
type StableNeverResult = Result<(), std::convert::Infallible>;
```

### See Also

- [err-result-over-panic](#err-result-over-panic) - When to panic vs return Result
- [type-result-fallible](#type-result-fallible) - Result for errors
- [opt-cold-unlikely](#opt-cold-unlikely) - Marking unlikely paths


## type-newtype-ids

> Wrap IDs in newtypes: `UserId(u64)`

### Why It Matters

Using raw integers for IDs is error-prone. It's easy to accidentally pass a `user_id` where a `post_id` is expected. Newtypes make these mix-ups compile-time errors instead of runtime bugs.

### Bad

```rust
fn get_user_posts(user_id: u64, post_id: u64) -> Vec<Post> {
    // Which is which? Easy to swap by accident
}

// Oops! Arguments swapped - compiles fine, wrong at runtime
let posts = get_user_posts(post_id, user_id);

// Even worse with multiple IDs
fn transfer(from: u64, to: u64, amount: u64) {
    // from/to can easily be swapped
}
```

### Good

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct UserId(pub u64);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct PostId(pub u64);

fn get_user_posts(user_id: UserId, post_id: PostId) -> Vec<Post> {
    // Types are distinct
}

// This won't compile - types don't match
// let posts = get_user_posts(post_id, user_id);  // ERROR!

// Correct usage
let posts = get_user_posts(UserId(1), PostId(42));
```

### Derive Common Traits

```rust
#[derive(
    Debug,      // For printing
    Clone,      // For copying
    Copy,       // For implicit copies (if small)
    PartialEq,  // For == comparison
    Eq,         // For HashMap keys
    Hash,       // For HashMap keys
    PartialOrd, // For sorting (optional)
    Ord,        // For BTreeMap keys (optional)
)]
pub struct UserId(pub u64);
```

### Add Useful Methods

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct UserId(u64);

impl UserId {
    pub const fn new(id: u64) -> Self {
        Self(id)
    }
    
    pub const fn get(self) -> u64 {
        self.0
    }
    
    // For database queries
    pub fn as_i64(self) -> i64 {
        self.0 as i64
    }
}

impl From<u64> for UserId {
    fn from(id: u64) -> Self {
        Self(id)
    }
}

impl std::fmt::Display for UserId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "user:{}", self.0)
    }
}
```

### With Serde

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]  // Serializes as just the inner value
pub struct UserId(pub u64);

// JSON: {"user_id": 123} not {"user_id": {"0": 123}}
```

### String IDs (UUIDs, etc.)

```rust
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct SessionId(String);

impl SessionId {
    pub fn new() -> Self {
        Self(uuid::Uuid::new_v4().to_string())
    }
    
    pub fn parse(s: &str) -> Result<Self, ParseError> {
        // Validate format
        uuid::Uuid::parse_str(s)?;
        Ok(Self(s.to_string()))
    }
    
    pub fn as_str(&self) -> &str {
        &self.0
    }
}
```

### Multiple Related IDs

```rust
// Macro for consistent ID types
macro_rules! define_id {
    ($name:ident) => {
        #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
        pub struct $name(pub u64);
        
        impl $name {
            pub const fn new(id: u64) -> Self { Self(id) }
            pub const fn get(self) -> u64 { self.0 }
        }
        
        impl From<u64> for $name {
            fn from(id: u64) -> Self { Self(id) }
        }
    };
}

define_id!(UserId);
define_id!(PostId);
define_id!(CommentId);
define_id!(TeamId);
```

### See Also

- [api-newtype-safety](#api-newtype-safety) - Newtypes for type safety
- [type-newtype-validated](#type-newtype-validated) - Newtypes for validated data
- [api-parse-dont-validate](#api-parse-dont-validate) - Parse into validated types


## type-newtype-validated

> Use newtypes to enforce validation at construction time

### Why It Matters

A validated newtype guarantees its inner value is always valid. Once you have an `Email`, you know it passed validation—no re-checking needed. This "parse, don't validate" pattern catches errors at boundaries and makes invalid states unrepresentable.

### Bad

```rust
// Validation scattered throughout code
fn send_email(to: &str, body: &str) -> Result<(), Error> {
    if !is_valid_email(to) {  // Must check every time
        return Err(Error::InvalidEmail);
    }
    // ...
}

fn add_recipient(list: &mut Vec<String>, email: &str) -> Result<(), Error> {
    if !is_valid_email(email) {  // Check again
        return Err(Error::InvalidEmail);
    }
    list.push(email.to_string());
    Ok(())
}
```

### Good

```rust
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Email(String);

impl Email {
    pub fn new(s: &str) -> Result<Self, EmailError> {
        if is_valid_email(s) {
            Ok(Email(s.to_string()))
        } else {
            Err(EmailError::Invalid(s.to_string()))
        }
    }
    
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

// No validation needed - Email is always valid
fn send_email(to: &Email, body: &str) -> Result<(), Error> {
    // to is guaranteed valid
    send_to_address(to.as_str(), body)
}

fn add_recipient(list: &mut Vec<Email>, email: Email) {
    // email is guaranteed valid
    list.push(email);
}
```

### Common Validated Types

```rust
// URLs
pub struct Url(url::Url);

impl Url {
    pub fn parse(s: &str) -> Result<Self, UrlError> {
        url::Url::parse(s)
            .map(Url)
            .map_err(UrlError::from)
    }
}

// Non-empty strings
pub struct NonEmptyString(String);

impl NonEmptyString {
    pub fn new(s: String) -> Option<Self> {
        if s.is_empty() {
            None
        } else {
            Some(NonEmptyString(s))
        }
    }
}

// Positive numbers
pub struct PositiveI32(i32);

impl PositiveI32 {
    pub fn new(n: i32) -> Option<Self> {
        if n > 0 {
            Some(PositiveI32(n))
        } else {
            None
        }
    }
    
    pub fn get(&self) -> i32 {
        self.0
    }
}

// Bounded ranges
pub struct Percentage(f64);

impl Percentage {
    pub fn new(value: f64) -> Result<Self, RangeError> {
        if (0.0..=100.0).contains(&value) {
            Ok(Percentage(value))
        } else {
            Err(RangeError::OutOfBounds)
        }
    }
}
```

### With Serde

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize)]
pub struct Email(String);

impl<'de> Deserialize<'de> for Email {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        Email::new(&s).map_err(serde::de::Error::custom)
    }
}

// JSON deserialization automatically validates
let email: Email = serde_json::from_str(r#""user@example.com""#)?;
```

### Compile-Time Validation

```rust
// For values known at compile time
macro_rules! email {
    ($s:literal) => {{
        const _: () = assert!(is_valid_email_const($s));
        Email::new_unchecked($s)
    }};
}

let admin = email!("admin@example.com");  // Validated at compile time
```

### See Also

- [api-parse-dont-validate](#api-parse-dont-validate) - Parse at boundaries
- [api-newtype-safety](#api-newtype-safety) - Type-safe distinctions
- [type-newtype-ids](#type-newtype-ids) - ID newtypes


## type-no-stringly

> Avoid stringly-typed APIs; use enums, newtypes, or validated types

### Why It Matters

Strings accept any value—typos, wrong formats, invalid data all compile fine. Enums, newtypes, and validated types catch errors at compile time or construction time, not runtime. They also provide better IDE support, documentation, and make invalid states unrepresentable.

### Bad

```rust
// Status as string - easy to get wrong
fn set_status(status: &str) {
    match status {
        "pending" => { ... }
        "active" => { ... }
        "completed" => { ... }
        _ => panic!("Unknown status"),  // Runtime error
    }
}

// Easy to misuse
set_status("pending");   // OK
set_status("Pending");   // Runtime error - wrong case
set_status("aktive");    // Runtime error - typo
set_status("done");      // Runtime error - wrong word

// Configuration as strings
fn configure(key: &str, value: &str) {
    // No type safety, no validation
}
```

### Good

```rust
// Status as enum - compile-time safety
enum Status {
    Pending,
    Active,
    Completed,
}

fn set_status(status: Status) {
    match status {
        Status::Pending => { ... }
        Status::Active => { ... }
        Status::Completed => { ... }
    }  // Exhaustive - compiler checks all cases
}

// Can only pass valid values
set_status(Status::Pending);  // OK
set_status(Status::Aktivev);  // Compile error - typo caught!

// Configuration with typed builder
struct Config {
    timeout: Duration,
    retries: u32,
    mode: Mode,
}

enum Mode { Fast, Safe, Balanced }
```

### Parsing at Boundaries

```rust
use std::str::FromStr;

#[derive(Debug, Clone, Copy)]
enum Priority {
    Low,
    Medium,
    High,
}

impl FromStr for Priority {
    type Err = ParseError;
    
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "low" => Ok(Priority::Low),
            "medium" | "med" => Ok(Priority::Medium),
            "high" => Ok(Priority::High),
            _ => Err(ParseError::UnknownPriority(s.to_string())),
        }
    }
}

// Parse once at boundary
fn handle_request(priority_str: &str) -> Result<(), Error> {
    let priority: Priority = priority_str.parse()?;
    // From here, priority is type-safe
    process(priority);
    Ok(())
}
```

### Validated Newtypes

```rust
// Instead of string for email
struct Email(String);

impl Email {
    fn new(s: &str) -> Result<Self, ValidationError> {
        if is_valid_email(s) {
            Ok(Email(s.to_string()))
        } else {
            Err(ValidationError::InvalidEmail)
        }
    }
}

// Instead of string for UUID
struct UserId(uuid::Uuid);

// Instead of string for paths
struct ConfigPath(PathBuf);
```

### With Serde

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
enum EventType {
    UserCreated,
    UserDeleted,
    UserUpdated,
}

// JSON: {"type": "user_created", ...}
// Automatically validated during deserialization
```

### See Also

- [anti-stringly-typed](#anti-stringly-typed) - Anti-pattern details
- [type-newtype-validated](#type-newtype-validated) - Validated newtypes
- [type-enum-states](#type-enum-states) - Enums for states


## type-option-nullable

> Use `Option<T>` for values that might not exist

### Why It Matters

`Option<T>` explicitly represents "value or nothing" in the type system. Unlike null pointers or sentinel values, you can't accidentally use a missing value—the compiler forces you to handle the `None` case. This eliminates null pointer exceptions at compile time.

### Bad

```rust
// Sentinel values - easy to forget to check
fn find_user(id: u64) -> User {
    // Returns "empty" user if not found - caller might not check
    users.get(&id).cloned().unwrap_or(User::empty())
}

// Nullable-style with raw pointers
fn find_user(id: u64) -> *const User {
    // Null if not found - unsafe, no compiler help
}

// Error-prone usage
let user = find_user(42);
println!("{}", user.name);  // Might be empty user - silent bug
```

### Good

```rust
// Option makes absence explicit
fn find_user(id: u64) -> Option<User> {
    users.get(&id).cloned()
}

// Must handle the None case
let user = find_user(42);
match user {
    Some(u) => println!("{}", u.name),
    None => println!("User not found"),
}

// Or use combinators
let name = find_user(42)
    .map(|u| u.name)
    .unwrap_or_else(|| "Unknown".to_string());
```

### Common Option Patterns

```rust
// if let for single case
if let Some(user) = find_user(id) {
    process(user);
}

// Chaining with map
let upper_name = find_user(id)
    .map(|u| u.name)
    .map(|n| n.to_uppercase());

// Providing defaults
let user = find_user(id).unwrap_or_default();
let user = find_user(id).unwrap_or_else(|| User::guest());

// ? operator for propagation
fn get_user_email(id: u64) -> Option<String> {
    let user = find_user(id)?;
    Some(user.email)
}

// and_then for chained optionals
fn get_user_country(id: u64) -> Option<String> {
    find_user(id)
        .and_then(|u| u.address)
        .and_then(|a| a.country)
}
```

### Struct Fields

```rust
struct User {
    name: String,
    email: String,
    phone: Option<String>,        // Optional field
    avatar_url: Option<Url>,      // Optional field
}

impl User {
    fn display_phone(&self) -> &str {
        self.phone.as_deref().unwrap_or("Not provided")
    }
}
```

### Option vs Result

```rust
// Option: value might not exist (no error context)
fn find(key: &str) -> Option<Value> { ... }

// Result: operation might fail (with error context)
fn parse(input: &str) -> Result<Value, ParseError> { ... }

// Convert Option to Result
let value = find("key").ok_or(Error::NotFound)?;

// Convert Result to Option
let value = parse("input").ok();  // Discards error
```

### Option References

```rust
// Option<&T> for optional borrows
fn get(&self, key: &str) -> Option<&Value> {
    self.map.get(key)
}

// as_ref() to borrow Option contents
let opt: Option<String> = Some("hello".to_string());
let opt_ref: Option<&String> = opt.as_ref();
let opt_str: Option<&str> = opt.as_deref();

// as_mut() for mutable borrow
let mut opt = Some(vec![1, 2, 3]);
if let Some(v) = opt.as_mut() {
    v.push(4);
}
```

### See Also

- [type-result-fallible](#type-result-fallible) - Result for errors
- [type-enum-states](#type-enum-states) - Enums for states
- [err-no-unwrap-prod](#err-no-unwrap-prod) - Handling Option safely


## type-phantom-marker

> Use `PhantomData` to express type relationships without runtime cost

### Why It Matters

Sometimes your type needs to be parameterized by a type that doesn't appear in any field—for variance, drop order, or semantic purposes. `PhantomData<T>` tells the compiler your type is "associated with" `T` without storing any `T` data. It has zero runtime cost.

### Bad

```rust
// Type parameter unused - compiler error
struct Handle<T> {
    id: u64,
    // Error: parameter `T` is never used
}

// Workaround with unnecessary storage
struct Handle<T> {
    id: u64,
    _type: Option<T>,  // Wastes memory, requires T: Default
}
```

### Good

```rust
use std::marker::PhantomData;

struct Handle<T> {
    id: u64,
    _marker: PhantomData<T>,  // Zero-size, tells compiler about T
}

impl<T> Handle<T> {
    fn new(id: u64) -> Self {
        Handle {
            id,
            _marker: PhantomData,
        }
    }
}

// Different Handle types are incompatible
struct User;
struct Order;

fn process_user(h: Handle<User>) { ... }

let user_handle = Handle::<User>::new(1);
let order_handle = Handle::<Order>::new(2);

process_user(user_handle);   // OK
process_user(order_handle);  // Error: expected Handle<User>, found Handle<Order>
```

### Expressing Ownership

```rust
use std::marker::PhantomData;

// Owns T conceptually (like Box<T>)
struct Container<T> {
    ptr: *mut T,
    _marker: PhantomData<T>,  // Acts like we own a T
}

// Drop will be called on T when Container drops
impl<T> Drop for Container<T> {
    fn drop(&mut self) {
        unsafe {
            std::ptr::drop_in_place(self.ptr);
        }
    }
}
```

### Expressing Borrowing

```rust
use std::marker::PhantomData;

// Borrows T for lifetime 'a
struct Ref<'a, T> {
    ptr: *const T,
    _marker: PhantomData<&'a T>,  // Acts like &'a T
}

// Compiler tracks lifetime correctly
impl<'a, T> Ref<'a, T> {
    fn get(&self) -> &'a T {
        unsafe { &*self.ptr }
    }
}
```

### Type-Level State Machine

```rust
use std::marker::PhantomData;

// States as zero-size types
struct Unlocked;
struct Locked;

struct Door<State> {
    _state: PhantomData<State>,
}

impl Door<Unlocked> {
    fn lock(self) -> Door<Locked> {
        println!("Locking...");
        Door { _state: PhantomData }
    }
    
    fn open(&self) {
        println!("Opening...");
    }
}

impl Door<Locked> {
    fn unlock(self) -> Door<Unlocked> {
        println!("Unlocking...");
        Door { _state: PhantomData }
    }
    
    // Can't call open() on Locked door - method doesn't exist
}

fn example() {
    let door: Door<Unlocked> = Door { _state: PhantomData };
    door.open();           // OK
    let locked = door.lock();
    // locked.open();      // Error: no method `open` for Door<Locked>
    let unlocked = locked.unlock();
    unlocked.open();       // OK
}
```

### Variance Control

```rust
use std::marker::PhantomData;

// Covariant in T (PhantomData<T>)
struct Producer<T> {
    _marker: PhantomData<T>,  // Covariant
}

// Contravariant in T (PhantomData<fn(T)>)
struct Consumer<T> {
    _marker: PhantomData<fn(T)>,  // Contravariant
}

// Invariant in T (PhantomData<fn(T) -> T>)
struct Both<T> {
    _marker: PhantomData<fn(T) -> T>,  // Invariant
}
```

### Common Uses

```rust
// 1. FFI handles with type safety
struct FileHandle<T: FileType> {
    fd: i32,
    _marker: PhantomData<T>,
}

// 2. Generic iterators
struct Iter<'a, T> {
    ptr: *const T,
    end: *const T,
    _marker: PhantomData<&'a T>,
}

// 3. Allocator-aware types
struct Vec<T, A: Allocator = Global> {
    buf: RawVec<T, A>,
    len: usize,
}
```

### See Also

- [api-typestate](#api-typestate) - State machine pattern
- [api-newtype-safety](#api-newtype-safety) - Type-safe wrappers
- [type-newtype-ids](#type-newtype-ids) - ID types


## type-repr-transparent

> Use `#[repr(transparent)]` for newtypes in FFI contexts

### Why It Matters

`#[repr(transparent)]` guarantees a newtype has the same memory layout as its inner type. This is essential for FFI where you need type safety in Rust but must match C ABI layouts. Without it, the compiler may add padding or change layout.

### Bad

```rust
// No layout guarantee - might not match inner type in FFI
struct Handle(u64);

// Passing to C code might fail
extern "C" {
    fn process_handle(h: Handle);  // May not work correctly
}

// Wrapping C type without layout guarantee
struct SafePointer(*mut c_void);
```

### Good

```rust
// Guaranteed same layout as inner type
#[repr(transparent)]
struct Handle(u64);

// Safe for FFI
extern "C" {
    fn process_handle(h: Handle);  // Works - same layout as u64
}

// FFI pointer wrapper
#[repr(transparent)]
struct SafePointer(*mut c_void);

impl SafePointer {
    // Safe Rust API around raw pointer
    pub fn new(ptr: *mut c_void) -> Option<Self> {
        if ptr.is_null() {
            None
        } else {
            Some(SafePointer(ptr))
        }
    }
}
```

### What repr(transparent) Guarantees

```rust
use std::mem::{size_of, align_of};

#[repr(transparent)]
struct Meters(f64);

// Same size
assert_eq!(size_of::<Meters>(), size_of::<f64>());

// Same alignment
assert_eq!(align_of::<Meters>(), align_of::<f64>());

// Same ABI - can pass where f64 expected
extern "C" fn measure(distance: Meters) { ... }
```

### With PhantomData

```rust
use std::marker::PhantomData;

// PhantomData is zero-sized, doesn't affect layout
#[repr(transparent)]
struct TypedHandle<T> {
    raw: u64,
    _marker: PhantomData<T>,  // Zero-sized, ignored for layout
}

// Still same layout as u64
assert_eq!(size_of::<TypedHandle<String>>(), size_of::<u64>());
```

### NonZero Wrappers

```rust
use std::num::NonZeroU64;

#[repr(transparent)]
struct NonZeroHandle(NonZeroU64);

// Inherits null-pointer optimization
assert_eq!(size_of::<Option<NonZeroHandle>>(), size_of::<u64>());
```

### FFI Pattern

```rust
mod ffi {
    use std::os::raw::c_int;
    
    #[repr(transparent)]
    pub struct FileDescriptor(c_int);
    
    extern "C" {
        pub fn open(path: *const i8, flags: c_int) -> FileDescriptor;
        pub fn close(fd: FileDescriptor) -> c_int;
        pub fn read(fd: FileDescriptor, buf: *mut u8, len: usize) -> isize;
    }
}

// Safe wrapper
pub struct File {
    fd: ffi::FileDescriptor,
}

impl File {
    pub fn open(path: &str) -> std::io::Result<Self> {
        let c_path = std::ffi::CString::new(path)?;
        let fd = unsafe { ffi::open(c_path.as_ptr(), 0) };
        // ... error handling
        Ok(File { fd })
    }
}
```

### When to Use

| Scenario | Use `#[repr(transparent)]`? |
|----------|----------------------------|
| FFI newtype wrappers | Yes |
| Type-safe handles | Yes |
| NonZero optimization | Yes |
| Pure Rust newtypes | Optional (doesn't hurt) |
| Multi-field structs | N/A (only for single-field) |

### See Also

- [type-newtype-ids](#type-newtype-ids) - Newtype pattern
- [type-phantom-marker](#type-phantom-marker) - PhantomData usage
- [api-newtype-safety](#api-newtype-safety) - Type-safe newtypes


## type-result-fallible

> Use `Result<T, E>` for operations that can fail

### Why It Matters

`Result<T, E>` makes failure explicit in the type system. Callers must acknowledge and handle potential errors—they can't accidentally ignore failures. The `?` operator makes error propagation ergonomic while maintaining explicit error handling.

### Bad

```rust
// Returning Option loses error context
fn read_config(path: &str) -> Option<Config> {
    let content = std::fs::read_to_string(path).ok()?;  // Why did it fail?
    toml::from_str(&content).ok()  // Parse error lost
}

// Panicking on errors
fn read_config(path: &str) -> Config {
    let content = std::fs::read_to_string(path).unwrap();  // Crashes
    toml::from_str(&content).unwrap()  // Crashes
}

// Sentinel values
fn divide(a: i32, b: i32) -> i32 {
    if b == 0 { return -1; }  // Magic value, easy to miss
    a / b
}
```

### Good

```rust
// Result with clear error type
fn read_config(path: &str) -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string(path)
        .map_err(ConfigError::IoError)?;
    toml::from_str(&content)
        .map_err(ConfigError::ParseError)
}

fn divide(a: i32, b: i32) -> Result<i32, DivisionError> {
    if b == 0 {
        return Err(DivisionError::DivideByZero);
    }
    Ok(a / b)
}

// Caller must handle
match divide(10, 0) {
    Ok(result) => println!("Result: {}", result),
    Err(e) => println!("Error: {}", e),
}
```

### The ? Operator

```rust
fn process_file(path: &str) -> Result<ProcessedData, Error> {
    let content = std::fs::read_to_string(path)?;  // Propagates Err
    let parsed: RawData = serde_json::from_str(&content)?;
    let validated = validate(parsed)?;
    let processed = transform(validated)?;
    Ok(processed)
}

// Equivalent to:
fn process_file(path: &str) -> Result<ProcessedData, Error> {
    let content = match std::fs::read_to_string(path) {
        Ok(c) => c,
        Err(e) => return Err(e.into()),
    };
    // ... etc
}
```

### Result Combinators

```rust
let result: Result<i32, Error> = Ok(42);

// map: transform success value
let doubled = result.map(|n| n * 2);  // Ok(84)

// map_err: transform error
let with_context = result.map_err(|e| format!("Failed: {}", e));

// and_then: chain fallible operations
let processed = result.and_then(|n| {
    if n > 0 { Ok(n * 2) } else { Err(Error::Negative) }
});

// unwrap_or: provide default on error
let value = result.unwrap_or(0);

// ok(): convert to Option, discarding error
let maybe_value: Option<i32> = result.ok();
```

### Defining Error Types

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ConfigError {
    #[error("failed to read file: {0}")]
    Io(#[from] std::io::Error),
    
    #[error("failed to parse config: {0}")]
    Parse(#[from] toml::de::Error),
    
    #[error("missing required field: {0}")]
    MissingField(String),
}

fn load_config(path: &str) -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string(path)?;  // Io error
    let config: Config = toml::from_str(&content)?;  // Parse error
    if config.name.is_empty() {
        return Err(ConfigError::MissingField("name".into()));
    }
    Ok(config)
}
```

### See Also

- [err-thiserror-lib](#err-thiserror-lib) - Defining error types
- [err-question-mark](#err-question-mark) - Using ? operator
- [type-option-nullable](#type-option-nullable) - Option vs Result
