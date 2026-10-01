# Ownership, Borrowing, and Sharing

> Loaded on demand from `SKILL.md` — one rule per `## <rule-id>` section.


## own-arc-shared

> Use `Arc<T>` for thread-safe shared ownership

### Why It Matters

`Arc` (Atomic Reference Counted) provides shared ownership across threads. Unlike `Rc`, its reference count is updated atomically, making it safe for concurrent access. Use it when multiple threads need to read the same data.

### Bad

```rust
use std::rc::Rc;
use std::thread;

let data = Rc::new(vec![1, 2, 3]);
let data_clone = Rc::clone(&data);

// ERROR: Rc cannot be sent between threads safely
thread::spawn(move || {
    println!("{:?}", data_clone);
});
```

### Good

```rust
use std::sync::Arc;
use std::thread;

let data = Arc::new(vec![1, 2, 3]);
let data_clone = Arc::clone(&data);

thread::spawn(move || {
    println!("{:?}", data_clone);  // Safe!
});

println!("{:?}", data);  // Original still accessible
```

### Arc with Mutex for Mutable Shared State

```rust
use std::sync::{Arc, Mutex};
use std::thread;

let counter = Arc::new(Mutex::new(0));
let mut handles = vec![];

for _ in 0..10 {
    let counter = Arc::clone(&counter);
    let handle = thread::spawn(move || {
        let mut num = counter.lock().unwrap();
        *num += 1;
    });
    handles.push(handle);
}

for handle in handles {
    handle.join().unwrap();
}

println!("Result: {}", *counter.lock().unwrap());
```

### Arc vs Rc Decision Tree

```
Need shared ownership?
├── No → Use owned value or references
└── Yes → Will it cross thread boundaries?
    ├── No → Use Rc<T> (cheaper, no atomic ops)
    └── Yes → Use Arc<T>
        └── Need mutation?
            ├── No → Arc<T> is enough
            └── Yes → Arc<Mutex<T>> or Arc<RwLock<T>>
```

### Common Patterns

```rust
use std::sync::Arc;

// Shared configuration (read-only)
struct AppConfig {
    database_url: String,
    max_connections: u32,
}

fn setup_workers(config: Arc<AppConfig>) {
    for i in 0..4 {
        let config = Arc::clone(&config);
        std::thread::spawn(move || {
            println!("Worker {} using db: {}", i, config.database_url);
        });
    }
}

// Shared cache with interior mutability
use std::sync::RwLock;
use std::collections::HashMap;

type Cache = Arc<RwLock<HashMap<String, String>>>;

fn get_cached(cache: &Cache, key: &str) -> Option<String> {
    cache.read().unwrap().get(key).cloned()
}

fn set_cached(cache: &Cache, key: String, value: String) {
    cache.write().unwrap().insert(key, value);
}
```

### Performance Considerations

```rust
// Arc::clone is cheap - just increments atomic counter
let a = Arc::new(large_data);
let b = Arc::clone(&a);  // Fast! No data copied

// But atomic operations have overhead vs Rc
// Use Rc in single-threaded contexts for better performance

// Avoid cloning Arc in hot loops if possible
// Bad:
for item in items {
    let arc = Arc::clone(&shared);  // Atomic op each iteration
    process(arc, item);
}

// Better: Clone once outside loop if possible
let arc = Arc::clone(&shared);
for item in items {
    process(&arc, item);  // Pass reference
}
```

### See Also

- [own-rc-single-thread](#own-rc-single-thread) - Use Rc for single-threaded sharing
- [own-mutex-interior](#own-mutex-interior) - Use Mutex for interior mutability
- [async-clone-before-await](#async-clone-before-await) - Clone Arc before await points


## own-borrow-over-clone

> Prefer `&T` borrowing over `.clone()`

### Why It Matters

Cloning allocates new memory and copies data, while borrowing is free. Unnecessary clones can significantly impact performance, especially in hot paths or with large data structures.

### Bad

```rust
fn process(data: &String) {
    let local = data.clone();  // Unnecessary allocation!
    println!("{}", local);
}

fn count_words(text: &String) -> usize {
    let owned = text.clone();  // Why clone just to read?
    owned.split_whitespace().count()
}

// Clone in a loop - multiplied cost
fn process_all(items: &[String]) {
    for item in items {
        let copy = item.clone();  // N allocations!
        handle(&copy);
    }
}
```

### Good

```rust
fn process(data: &str) {  // Accept &str, more flexible
    println!("{}", data);  // No allocation needed
}

fn count_words(text: &str) -> usize {
    text.split_whitespace().count()  // Just borrow
}

// Borrow in a loop - zero allocations
fn process_all(items: &[String]) {
    for item in items {
        handle(item);  // Pass reference
    }
}
```

### When Clone Is Acceptable

```rust
// 1. Need owned data for storage
struct Cache {
    data: HashMap<String, String>,
}

impl Cache {
    fn insert(&mut self, key: &str, value: &str) {
        // Clone needed - we're storing owned data
        self.data.insert(key.to_string(), value.to_string());
    }
}

// 2. Need to send across threads
fn spawn_worker(data: &Config) {
    let owned = data.clone();  // Clone needed for 'static
    std::thread::spawn(move || {
        use_config(owned);
    });
}

// 3. Copy types (no heap allocation)
let x: i32 = 42;
let y = x;  // Copy, not clone - this is fine
```

### Evidence

From ripgrep's codebase - uses `Cow` to avoid clones:
```rust
// https://github.com/BurntSushi/ripgrep/blob/master/crates/globset/src/pathutil.rs
pub(crate) fn file_name<'a>(path: &Cow<'a, [u8]>) -> Option<Cow<'a, [u8]>> {
    match *path {
        Cow::Borrowed(path) => Cow::Borrowed(&path[last_slash..]),
        Cow::Owned(ref path) => Cow::Owned(path.clone()),
    }
}
```

### See Also

- [own-slice-over-vec](#own-slice-over-vec) - Accept slices instead of references to collections
- [own-cow-conditional](#own-cow-conditional) - Use Cow for conditional ownership
- [mem-clone-from](#mem-clone-from) - Reuse allocations when cloning


## own-clone-explicit

> Use explicit `Clone` for types where copying has meaningful cost

### Why It Matters

Unlike `Copy` which is implicit and "free," `Clone` requires an explicit `.clone()` call, signaling that duplication has a cost. This makes heap allocations and deep copies visible in code, helping developers reason about performance. Types with heap data (`String`, `Vec`, `Box`) should implement `Clone` but not `Copy`.

### Bad

```rust
// Hiding expensive operations
fn process_data(data: Vec<u32>) -> Vec<u32> {
    let backup = data; // Moved, not copied - but unclear at call site
    transform(backup)
}

let my_data = vec![1, 2, 3, 4, 5];
let result = process_data(my_data);
// my_data is moved - surprise if you expected it to still exist
```

### Good

```rust
fn process_data(data: Vec<u32>) -> Vec<u32> {
    let backup = data; 
    transform(backup)
}

let my_data = vec![1, 2, 3, 4, 5];
let result = process_data(my_data.clone()); // Explicit: "I know this allocates"
// my_data still available

// Or better - take reference if you don't need ownership
fn process_data_ref(data: &[u32]) -> Vec<u32> {
    transform(data)
}
let result = process_data_ref(&my_data); // No clone needed
```

### Custom Clone Implementation

For types with mixed cheap/expensive fields, implement `Clone` manually:

```rust
#[derive(Debug)]
struct Document {
    id: u64,              // Cheap to copy
    content: String,      // Expensive to clone
    metadata: Metadata,   // Moderate cost
}

impl Clone for Document {
    fn clone(&self) -> Self {
        Self {
            id: self.id,
            content: self.content.clone(),
            metadata: self.metadata.clone(),
        }
    }
    
    // Optimization: reuse existing allocations
    fn clone_from(&mut self, source: &Self) {
        self.id = source.id;
        self.content.clone_from(&source.content); // Reuses capacity
        self.metadata.clone_from(&source.metadata);
    }
}
```

### clone_from Optimization

`clone_from` can reuse existing allocations:

```rust
let mut buffer = String::with_capacity(1000);

// Bad: drops old allocation, creates new one
buffer = source.clone();

// Good: reuses existing capacity if sufficient
buffer.clone_from(&source);
```

### Derive vs Manual Clone

```rust
// Derive when all fields need cloning
#[derive(Clone)]
struct Simple {
    data: Vec<u8>,
    name: String,
}

// Manual when you need special behavior
struct CachedValue {
    value: i32,
    cache: RefCell<Option<ExpensiveComputation>>,
}

impl Clone for CachedValue {
    fn clone(&self) -> Self {
        Self {
            value: self.value,
            cache: RefCell::new(None), // Don't clone cache, let it rebuild
        }
    }
}
```

### When to Avoid Clone

```rust
// Instead of cloning, consider:

// 1. References
fn process(data: &MyType) { } // Borrow instead of clone

// 2. Cow for conditional cloning
fn process(data: Cow<'_, str>) { } // Clone only if mutation needed

// 3. Arc for shared ownership
let shared = Arc::new(expensive_data);
let handle = shared.clone(); // Cheap: just increments counter

// 4. Passing by value when caller is done with it
fn consume(data: MyType) { } // Caller moves, no clone
```

### See Also

- [own-copy-small](#own-copy-small) - When implicit Copy is appropriate
- [own-cow-conditional](#own-cow-conditional) - Avoiding clones with Cow
- [mem-clone-from](#mem-clone-from) - Optimizing repeated clones


## own-copy-small

> Implement `Copy` for small, simple types

### Why It Matters

Types that implement `Copy` are implicitly duplicated on assignment instead of moved. This eliminates the need for explicit `.clone()` calls and makes the code more ergonomic. For small types (generally ≤16 bytes), copying is as fast or faster than moving a pointer.

### Bad

```rust
// Small type without Copy - requires explicit clone
#[derive(Clone, Debug)]
struct Point {
    x: f64,
    y: f64,
}

fn distance(p1: Point, p2: Point) -> f64 {
    ((p2.x - p1.x).powi(2) + (p2.y - p1.y).powi(2)).sqrt()
}

let origin = Point { x: 0.0, y: 0.0 };
let target = Point { x: 3.0, y: 4.0 };

let d1 = distance(origin.clone(), target.clone()); // Tedious
let d2 = distance(origin.clone(), target.clone()); // Every use needs clone
// origin and target still usable but verbose
```

### Good

```rust
// Small type with Copy - implicit duplication
#[derive(Clone, Copy, Debug)]
struct Point {
    x: f64,
    y: f64,
}

fn distance(p1: Point, p2: Point) -> f64 {
    ((p2.x - p1.x).powi(2) + (p2.y - p1.y).powi(2)).sqrt()
}

let origin = Point { x: 0.0, y: 0.0 };
let target = Point { x: 3.0, y: 4.0 };

let d1 = distance(origin, target); // Implicitly copied
let d2 = distance(origin, target); // Still works!
// origin and target remain valid
```

### Copy Requirements

A type can implement `Copy` only if:
1. All fields implement `Copy`
2. No custom `Drop` implementation
3. No heap-allocated data (`String`, `Vec`, `Box`, etc.)

```rust
// ✅ Can be Copy
#[derive(Clone, Copy)]
struct Color {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
}

// ❌ Cannot be Copy - contains String
#[derive(Clone)]
struct Person {
    name: String,  // String is not Copy
    age: u32,
}

// ❌ Cannot be Copy - has Drop
struct FileHandle {
    fd: i32,
}
impl Drop for FileHandle {
    fn drop(&mut self) { /* close file */ }
}
```

### Size Guidelines

| Size | Recommendation |
|------|----------------|
| ≤ 16 bytes | Implement `Copy` |
| 17-64 bytes | Consider `Copy`, benchmark if critical |
| > 64 bytes | Probably don't, prefer references |

```rust
use std::mem::size_of;

#[derive(Clone, Copy)]
struct SmallId(u64); // 8 bytes ✅

#[derive(Clone, Copy)]
struct Rect { x: f32, y: f32, w: f32, h: f32 } // 16 bytes ✅

#[derive(Clone)] // No Copy - 72 bytes
struct Transform {
    matrix: [[f64; 3]; 3], // 72 bytes, too large
}
```

### Common Copy Types

Standard library types that are `Copy`:
- All primitives: `i32`, `f64`, `bool`, `char`, etc.
- References: `&T`, `&mut T`
- Raw pointers: `*const T`, `*mut T`
- Function pointers: `fn(T) -> U`
- Tuples of `Copy` types: `(i32, f64)`
- Arrays of `Copy` types: `[u8; 32]`
- `Option<T>` where `T: Copy`
- `PhantomData<T>`

### See Also

- [own-clone-explicit](#own-clone-explicit) - When Clone without Copy is appropriate
- [type-newtype-ids](#type-newtype-ids) - Newtype pattern often uses Copy


## own-cow-conditional

> Use `Cow<'a, T>` for conditional ownership

### Why It Matters

`Cow` (Clone-on-Write) lets you avoid allocations when you *might* need to own data but usually don't. It holds either a borrowed reference or an owned value, cloning only when mutation is needed.

### Bad

```rust
// Always allocates, even when input doesn't need modification
fn normalize_path(path: &str) -> String {
    if path.contains("//") {
        path.replace("//", "/")  // Allocation needed
    } else {
        path.to_string()  // Unnecessary allocation!
    }
}

// Always clones the error message
fn format_error(code: u32) -> String {
    match code {
        404 => "Not Found".to_string(),      // Unnecessary!
        500 => "Internal Error".to_string(), // Unnecessary!
        _ => format!("Error {}", code),      // This one needs allocation
    }
}
```

### Good

```rust
use std::borrow::Cow;

// Only allocates when needed
fn normalize_path(path: &str) -> Cow<'_, str> {
    if path.contains("//") {
        Cow::Owned(path.replace("//", "/"))  // Allocate
    } else {
        Cow::Borrowed(path)  // Zero-cost borrow
    }
}

// Static strings stay borrowed
fn format_error(code: u32) -> Cow<'static, str> {
    match code {
        404 => Cow::Borrowed("Not Found"),      // No allocation
        500 => Cow::Borrowed("Internal Error"), // No allocation
        _ => Cow::Owned(format!("Error {}", code)), // Allocate only for unknown
    }
}
```

### Real-World Example from ripgrep

```rust
// https://github.com/BurntSushi/ripgrep/blob/master/crates/globset/src/pathutil.rs
pub(crate) fn file_name<'a>(path: &Cow<'a, [u8]>) -> Option<Cow<'a, [u8]>> {
    let last_slash = path.rfind_byte(b'/').map(|i| i + 1).unwrap_or(0);
    match *path {
        Cow::Borrowed(path) => Some(Cow::Borrowed(&path[last_slash..])),
        Cow::Owned(ref path) => {
            let mut path = path.clone();
            path.drain_bytes(..last_slash);
            Some(Cow::Owned(path))
        }
    }
}
```

### Clone-on-Write Pattern

```rust
use std::borrow::Cow;

fn process_text(text: Cow<'_, str>) -> Cow<'_, str> {
    if text.contains("bad_word") {
        // to_mut() clones if borrowed, returns &mut if owned
        let mut owned = text.into_owned();
        owned = owned.replace("bad_word", "***");
        Cow::Owned(owned)
    } else {
        text  // Pass through unchanged
    }
}

// Usage
let borrowed: Cow<str> = Cow::Borrowed("hello world");
let result = process_text(borrowed);  // No allocation!

let with_bad: Cow<str> = Cow::Borrowed("hello bad_word");
let result = process_text(with_bad);  // Allocates only here
```

### Cow with Collections

```rust
use std::borrow::Cow;

// Mixed borrowed/owned in a collection
fn collect_errors<'a>(
    static_errors: &[&'static str],
    dynamic_errors: Vec<String>,
) -> Vec<Cow<'a, str>> {
    let mut errors: Vec<Cow<str>> = Vec::new();
    
    // Static strings - no allocation
    for &e in static_errors {
        errors.push(Cow::Borrowed(e));
    }
    
    // Dynamic strings - take ownership
    for e in dynamic_errors {
        errors.push(Cow::Owned(e));
    }
    
    errors
}
```

### When to Use Cow

| Situation | Use Cow? |
|-----------|----------|
| Usually borrow, sometimes own | Yes |
| Always need owned data | No, just use owned type |
| Always borrow | No, just use reference |
| Hot path, avoiding all allocations | Yes |
| Returning static strings or formatted | Yes |

### See Also

- [own-borrow-over-clone](#own-borrow-over-clone) - Prefer borrowing over cloning
- [mem-avoid-format](#mem-avoid-format) - Avoid format! when possible


## own-lifetime-elision

> Rely on lifetime elision rules; add explicit lifetimes only when required

### Why It Matters

Rust's lifetime elision rules handle most common borrowing patterns automatically. Adding explicit lifetimes where they're not needed clutters code without adding clarity. However, understanding when elision applies helps you know when explicit lifetimes are truly necessary.

### Bad

```rust
// Unnecessary explicit lifetimes - elision handles these
fn first_word<'a>(s: &'a str) -> &'a str {
    s.split_whitespace().next().unwrap_or("")
}

fn get_name<'a>(person: &'a Person) -> &'a str {
    &person.name
}

impl<'a> Display for Wrapper<'a> {
    fn fmt<'b>(&'b self, f: &'b mut Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}
```

### Good

```rust
// Let elision do its job
fn first_word(s: &str) -> &str {
    s.split_whitespace().next().unwrap_or("")
}

fn get_name(person: &Person) -> &str {
    &person.name
}

impl Display for Wrapper<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}
```

### The Three Elision Rules

1. **Each input reference gets its own lifetime:**
   ```rust
   fn foo(x: &str, y: &str) 
   // becomes
   fn foo<'a, 'b>(x: &'a str, y: &'b str)
   ```

2. **One input reference → output gets same lifetime:**
   ```rust
   fn foo(x: &str) -> &str
   // becomes  
   fn foo<'a>(x: &'a str) -> &'a str
   ```

3. **Method with `&self`/`&mut self` → output gets self's lifetime:**
   ```rust
   fn foo(&self, x: &str) -> &str
   // becomes
   fn foo<'a, 'b>(&'a self, x: &'b str) -> &'a str
   ```

### When Explicit Lifetimes ARE Required

```rust
// Multiple input references, output could come from either
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

// Struct holding references
struct Parser<'input> {
    source: &'input str,
    position: usize,
}

// Multiple distinct lifetimes needed
struct Context<'s, 'c> {
    source: &'s str,
    cache: &'c mut Cache,
}

// Static lifetime for constants
fn get_default() -> &'static str {
    "default"
}
```

### Anonymous Lifetime `'_`

Use `'_` to let the compiler infer while being explicit about the presence of a lifetime:

```rust
// In struct definitions
impl Iterator for Parser<'_> {
    type Item = Token;
    fn next(&mut self) -> Option<Self::Item> { ... }
}

// In function signatures where it adds clarity
fn parse(input: &str) -> Result<Ast<'_>, Error> { ... }

// Especially useful in trait bounds
fn process(data: &impl AsRef<str>) -> Cow<'_, str> { ... }
```

### Common Patterns

```rust
// ✅ Elision works
fn trim(s: &str) -> &str { s.trim() }
fn first(v: &[i32]) -> Option<&i32> { v.first() }
fn name(&self) -> &str { &self.name }

// ❌ Elision fails - multiple inputs, ambiguous output
fn pick(a: &str, b: &str, first: bool) -> &str // Error!

// ✅ Fixed with explicit lifetime
fn pick<'a>(a: &'a str, b: &'a str, first: bool) -> &'a str {
    if first { a } else { b }
}
```

### See Also

- [own-borrow-over-clone](#own-borrow-over-clone) - Prefer borrowing to avoid ownership issues
- [api-impl-asref](#api-impl-asref) - Generic borrowing with AsRef


## own-move-large

> Move large types instead of copying; use `Box` if moves are expensive

### Why It Matters

In Rust, "moving" a value means copying its bytes to a new location and invalidating the old one. For large types (hundreds of bytes), this memcpy can be expensive. Boxing large types reduces move cost to copying a single pointer (8 bytes), making moves cheap regardless of the actual data size.

### Bad

```rust
// Large struct moved repeatedly = expensive memcpy each time
struct GameState {
    board: [[Cell; 100]; 100],  // 10,000 cells
    history: [Move; 1000],       // 1,000 moves
    players: [Player; 4],        // Player data
    // Total: potentially tens of KB
}

fn process_state(state: GameState) -> GameState {
    // Moving ~40KB+ of data
    let mut new_state = state;  // Memcpy here
    new_state.apply_rules();
    new_state  // Memcpy on return
}

let state = GameState::new();
let state = process_state(state);  // Two large memcpys
```

### Good

```rust
// Box reduces move cost to 8 bytes
struct GameState {
    board: Box<[[Cell; 100]; 100]>,  // Pointer to heap
    history: Vec<Move>,               // Already heap-allocated
    players: [Player; 4],
}

fn process_state(mut state: GameState) -> GameState {
    // Moving just pointers + small inline data
    state.apply_rules();
    state  // Cheap move
}

// Or use Box at call site for one-off cases
fn process_large(state: Box<LargeStruct>) -> Box<LargeStruct> {
    // 8-byte move regardless of LargeStruct size
    state
}
```

### When to Box

| Type Size | Move Frequency | Recommendation |
|-----------|----------------|----------------|
| < 128 bytes | Any | Don't box |
| 128-512 bytes | Rare | Probably don't box |
| 128-512 bytes | Frequent | Consider boxing |
| > 512 bytes | Any | Box or use references |
| > 4KB | Any | Definitely box |

### Stack vs Heap Tradeoffs

```rust
// Stack: fast allocation, limited size, moves copy bytes
struct StackHeavy {
    data: [u8; 4096],  // 4KB on stack
}

// Heap: allocation cost, unlimited size, moves copy pointer
struct HeapLight {
    data: Box<[u8; 4096]>,  // 8 bytes on stack, 4KB on heap
}

// Measure with size_of
use std::mem::size_of;
assert_eq!(size_of::<StackHeavy>(), 4096);
assert_eq!(size_of::<HeapLight>(), 8);
```

### Alternative: References

When you don't need ownership transfer, use references:

```rust
// Best: no move at all
fn analyze_state(state: &GameState) -> Analysis {
    // Borrows state, no copying
    compute_analysis(state)
}

// Mutable borrow for in-place modification
fn update_state(state: &mut GameState) {
    state.tick();
}
```

### Pattern: Builder Returns Boxed

```rust
impl LargeConfig {
    pub fn builder() -> ConfigBuilder {
        ConfigBuilder::default()
    }
}

impl ConfigBuilder {
    // Return boxed to avoid large move
    pub fn build(self) -> Box<LargeConfig> {
        Box::new(LargeConfig {
            // ... fields from builder
        })
    }
}
```

### Profile First

Don't prematurely optimize. Use tools to identify if moves are actually a bottleneck:

```rust
// Check type sizes
println!("Size of GameState: {}", std::mem::size_of::<GameState>());

// Profile with cargo flamegraph or perf to find hot memcpys
```

### See Also

- [own-copy-small](#own-copy-small) - Cheap types should be Copy
- [mem-box-large-variant](#mem-box-large-variant) - Boxing enum variants
- [perf-profile-first](#perf-profile-first) - Measure before optimizing


## own-mutex-interior

> Use `Mutex<T>` for interior mutability across threads

### Why It Matters

When you need shared mutable state across threads, `Mutex<T>` provides safe interior mutability with synchronization. Unlike `RefCell`, `Mutex` is `Send + Sync` and uses OS-level locking to ensure only one thread can access the data at a time.

### Bad

```rust
use std::cell::RefCell;
use std::sync::Arc;

// RefCell is !Sync - this won't compile
let shared = Arc::new(RefCell::new(vec![]));

// ERROR: RefCell cannot be shared between threads safely
std::thread::spawn({
    let shared = shared.clone();
    move || shared.borrow_mut().push(1)
});
```

### Good

```rust
use std::sync::{Arc, Mutex};

let shared = Arc::new(Mutex::new(vec![]));

let handles: Vec<_> = (0..10).map(|i| {
    let shared = shared.clone();
    std::thread::spawn(move || {
        let mut data = shared.lock().unwrap();
        data.push(i);
    })
}).collect();

for handle in handles {
    handle.join().unwrap();
}

println!("{:?}", shared.lock().unwrap()); // All values present
```

### Mutex Poisoning

If a thread panics while holding a lock, the mutex becomes "poisoned":

```rust
use std::sync::{Arc, Mutex};

let mutex = Arc::new(Mutex::new(0));

// Handle poisoning gracefully
match mutex.lock() {
    Ok(guard) => println!("Value: {}", *guard),
    Err(poisoned) => {
        // Recover the data anyway
        let guard = poisoned.into_inner();
        println!("Recovered value: {}", *guard);
    }
}

// Or ignore poisoning (use with caution)
let guard = mutex.lock().unwrap_or_else(|e| e.into_inner());
```

### Prefer parking_lot::Mutex

For better performance, consider `parking_lot::Mutex`:

```rust
use parking_lot::Mutex;
use std::sync::Arc;

let shared = Arc::new(Mutex::new(vec![]));

// No poisoning, no Result to unwrap
let mut data = shared.lock();
data.push(42);
// Lock automatically released when guard drops
```

Benefits of `parking_lot`:
- No poisoning (returns guard directly)
- Smaller size (1 byte vs 40+ bytes)
- Better performance under contention
- Fair locking option available

### When to Use What

| Type | Threading | Overhead | Use Case |
|------|-----------|----------|----------|
| `RefCell<T>` | Single | Minimal | Interior mutability, same thread |
| `Mutex<T>` | Multi | Locking | Shared mutable state across threads |
| `RwLock<T>` | Multi | Locking | Many readers, few writers |
| `parking_lot::Mutex` | Multi | Less | Drop-in std::Mutex replacement |

### See Also

- [own-rwlock-readers](#own-rwlock-readers) - When reads dominate writes
- [own-refcell-interior](#own-refcell-interior) - Single-threaded alternative
- [async-no-lock-await](#async-no-lock-await) - Avoiding locks across await points


## own-rc-single-thread

> Use `Rc<T>` for shared ownership in single-threaded contexts

### Why It Matters

`Rc<T>` (Reference Counted) provides shared ownership without the atomic overhead of `Arc<T>`. In single-threaded code, `Rc` is faster because it uses non-atomic reference counting. Using `Arc` when you don't need thread-safety wastes CPU cycles on unnecessary synchronization.

### Bad

```rust
use std::sync::Arc;

// Single-threaded application using Arc unnecessarily
fn build_tree() -> Arc<Node> {
    let root = Arc::new(Node::new("root"));
    let child1 = Arc::new(Node::new("child1"));
    let child2 = Arc::new(Node::new("child2"));
    
    // All in same thread, but paying atomic overhead
    root.add_child(child1.clone());
    root.add_child(child2.clone());
    root
}
```

Atomic operations have measurable overhead even without contention.

### Good

```rust
use std::rc::Rc;

// Single-threaded: use Rc for zero atomic overhead
fn build_tree() -> Rc<Node> {
    let root = Rc::new(Node::new("root"));
    let child1 = Rc::new(Node::new("child1"));
    let child2 = Rc::new(Node::new("child2"));
    
    root.add_child(child1.clone());
    root.add_child(child2.clone());
    root
}

// Compiler enforces single-thread: Rc is !Send + !Sync
// Attempting to send across threads = compile error
```

### Decision Guide

| Scenario | Use |
|----------|-----|
| Single-threaded, shared ownership | `Rc<T>` |
| Multi-threaded, shared ownership | `Arc<T>` |
| Single owner, might need multiple later | Start with `Rc`, upgrade if needed |
| Library code, unknown threading model | `Arc<T>` (safer default) |

### Evidence

The Rust standard library itself uses `Rc` extensively in single-threaded contexts like the `std::rc` module documentation examples.

### See Also

- [own-arc-shared](#own-arc-shared) - When you need thread-safe sharing
- [own-refcell-interior](#own-refcell-interior) - Combining Rc with interior mutability


## own-refcell-interior

> Use `RefCell<T>` for interior mutability in single-threaded code

### Why It Matters

Rust's borrow checker enforces rules at compile time, but sometimes you need to mutate data through a shared reference. `RefCell<T>` moves borrow checking to runtime, allowing mutation through `&self`. This is essential for patterns like caches, lazy initialization, and observer patterns where compile-time borrowing is too restrictive.

### Bad

```rust
struct Cache {
    // Requires &mut self to update, breaking shared reference patterns
    data: HashMap<String, String>,
}

impl Cache {
    fn get_or_compute(&mut self, key: &str) -> &str {
        // Caller needs &mut Cache, can't share cache reference
        if !self.data.contains_key(key) {
            self.data.insert(key.to_string(), expensive_compute(key));
        }
        &self.data[key]
    }
}
```

This forces exclusive access even for logically shared operations.

### Good

```rust
use std::cell::RefCell;
use std::collections::HashMap;

struct Cache {
    data: RefCell<HashMap<String, String>>,
}

impl Cache {
    fn get_or_compute(&self, key: &str) -> String {
        // Can mutate through &self
        let mut data = self.data.borrow_mut();
        if !data.contains_key(key) {
            data.insert(key.to_string(), expensive_compute(key));
        }
        data[key].clone()
    }
}

// Multiple references can coexist
let cache = Cache::new();
let ref1 = &cache;
let ref2 = &cache;
ref1.get_or_compute("key1");
ref2.get_or_compute("key2");
```

### Common Pattern: Rc<RefCell<T>>

```rust
use std::rc::Rc;
use std::cell::RefCell;

// Shared mutable state in single-threaded code
type SharedState = Rc<RefCell<AppState>>;

fn create_handlers(state: SharedState) -> Vec<Box<dyn Fn()>> {
    vec![
        Box::new({
            let state = state.clone();
            move || state.borrow_mut().increment()
        }),
        Box::new({
            let state = state.clone();
            move || state.borrow_mut().decrement()
        }),
    ]
}
```

### Runtime Panics

`RefCell` panics if you violate borrowing rules at runtime:

```rust
let cell = RefCell::new(5);
let borrow1 = cell.borrow();
let borrow2 = cell.borrow_mut(); // PANIC: already borrowed
```

Use `try_borrow()` and `try_borrow_mut()` for fallible borrowing.

### See Also

- [own-rc-single-thread](#own-rc-single-thread) - Combining with Rc for shared ownership
- [own-mutex-interior](#own-mutex-interior) - Thread-safe alternative


## own-rwlock-readers

> Use `RwLock<T>` when reads significantly outnumber writes

### Why It Matters

`Mutex<T>` allows only one thread to access data at a time, even for reads. `RwLock<T>` allows multiple concurrent readers OR one exclusive writer. For read-heavy workloads, this dramatically improves throughput by eliminating unnecessary serialization of read operations.

### Bad

```rust
use std::sync::{Arc, Mutex};

// Configuration rarely changes but is read constantly
let config = Arc::new(Mutex::new(Config::load()));

// Every read blocks other reads unnecessarily
fn get_setting(config: &Mutex<Config>, key: &str) -> String {
    let guard = config.lock().unwrap();
    guard.get(key).to_string()
}

// 100 threads reading = serialized, one at a time
```

### Good

```rust
use std::sync::{Arc, RwLock};

// Multiple readers can proceed concurrently
let config = Arc::new(RwLock::new(Config::load()));

fn get_setting(config: &RwLock<Config>, key: &str) -> String {
    let guard = config.read().unwrap(); // Multiple threads can hold read lock
    guard.get(key).to_string()
}

fn update_setting(config: &RwLock<Config>, key: &str, value: &str) {
    let mut guard = config.write().unwrap(); // Exclusive access for writes
    guard.set(key, value);
}

// 100 threads reading = parallel execution
```

### parking_lot::RwLock

Prefer `parking_lot::RwLock` for better performance:

```rust
use parking_lot::RwLock;
use std::sync::Arc;

let data = Arc::new(RwLock::new(HashMap::new()));

// Read - no unwrap needed
let value = data.read().get("key").cloned();

// Write
data.write().insert("key".to_string(), "value".to_string());

// Upgradeable read lock (unique to parking_lot)
let upgradeable = data.upgradable_read();
if upgradeable.get("key").is_none() {
    let mut write = parking_lot::RwLockUpgradableReadGuard::upgrade(upgradeable);
    write.insert("key".to_string(), "default".to_string());
}
```

### When RwLock Hurts

RwLock has overhead for tracking readers. It can be slower than Mutex when:

| Scenario | Better Choice |
|----------|---------------|
| Writes are frequent (>20% of operations) | `Mutex` |
| Lock held very briefly | `Mutex` |
| Single-threaded | `RefCell` |
| Reads dominate, lock held longer | `RwLock` |

### Write Starvation

Standard `RwLock` may starve writers if readers are continuous. `parking_lot::RwLock` is fair by default.

```rust
// parking_lot is writer-fair, preventing starvation
use parking_lot::RwLock;

// Or use std with explicit fairness (nightly)
// #![feature(rwlock_downgrade)]
```

### Real-World Pattern: Cached Computation

```rust
use parking_lot::RwLock;
use std::sync::Arc;

struct CachedData {
    cache: RwLock<Option<ExpensiveResult>>,
}

impl CachedData {
    fn get(&self) -> ExpensiveResult {
        // Fast path: read lock
        if let Some(cached) = self.cache.read().as_ref() {
            return cached.clone();
        }
        
        // Slow path: compute and cache
        let result = compute_expensive();
        *self.cache.write() = Some(result.clone());
        result
    }
}
```

### See Also

- [own-mutex-interior](#own-mutex-interior) - When writes are frequent
- [async-no-lock-await](#async-no-lock-await) - RwLock in async contexts


## own-slice-over-vec

> Accept `&[T]` not `&Vec<T>`, `&str` not `&String`

### Why It Matters

Accepting `&[T]` instead of `&Vec<T>` makes your function more flexible - it can accept slices from arrays, vectors, or other sources. Similarly, `&str` accepts string slices from `String`, `&'static str`, or substrings.

### Bad

```rust
// Overly restrictive - only accepts &Vec
fn sum(numbers: &Vec<i32>) -> i32 {
    numbers.iter().sum()
}

// Overly restrictive - only accepts &String
fn greet(name: &String) {
    println!("Hello, {}", name);
}

// Can't call with arrays or slices
let arr = [1, 2, 3];
// sum(&arr);  // ERROR: expected &Vec<i32>

let literal = "world";
// greet(&literal);  // ERROR: expected &String
```

### Good

```rust
// Flexible - accepts any slice-like thing
fn sum(numbers: &[i32]) -> i32 {
    numbers.iter().sum()
}

// Flexible - accepts any string-like thing
fn greet(name: &str) {
    println!("Hello, {}", name);
}

// Now all of these work:
let vec = vec![1, 2, 3];
let arr = [4, 5, 6];
let slice = &vec[0..2];

sum(&vec);    // Vec coerces to slice
sum(&arr);    // Array coerces to slice
sum(slice);   // Slice works directly

let string = String::from("Alice");
let literal = "Bob";

greet(&string);  // String coerces to &str
greet(literal);  // &str works directly
```

### The Deref Coercion Chain

```rust
// These coercions happen automatically:
// Vec<T>  -> &[T]   (via Deref)
// String  -> &str   (via Deref)
// Box<T>  -> &T     (via Deref)
// Arc<T>  -> &T     (via Deref)

fn process(data: &[u8]) { /* ... */ }

let vec: Vec<u8> = vec![1, 2, 3];
let boxed: Box<[u8]> = vec.into_boxed_slice();
let arc: Arc<[u8]> = Arc::from(&[1, 2, 3][..]);

process(&vec);    // Works
process(&boxed);  // Works
process(&arc);    // Works
```

### Path Types Too

```rust
// Bad
fn read_config(path: &PathBuf) -> Config { /* ... */ }

// Good - accepts &Path, &PathBuf, &str, &String
fn read_config(path: &Path) -> Config { /* ... */ }

// Even better - accept anything path-like
fn read_config(path: impl AsRef<Path>) -> Config {
    let path = path.as_ref();
    // ...
}
```

### When to Accept Owned Types

```rust
// Accept owned when you need to store it
struct Logger {
    prefix: String,  // Needs to own the string
}

impl Logger {
    // Take ownership - caller decides to clone or move
    fn new(prefix: String) -> Self {
        Self { prefix }
    }
    
    // Or use Into for flexibility
    fn with_prefix(prefix: impl Into<String>) -> Self {
        Self { prefix: prefix.into() }
    }
}
```

### See Also

- [api-impl-asref](#api-impl-asref) - Accept `impl AsRef<T>` for maximum flexibility
- [own-borrow-over-clone](#own-borrow-over-clone) - Prefer borrowing over cloning
