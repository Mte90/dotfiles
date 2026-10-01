# Memory and Allocation

> Loaded on demand from `SKILL.md` — one rule per `## <rule-id>` section.


## mem-arena-allocator

> Use arena allocators for batch allocations

### Why It Matters

Arena allocators (bump allocators) allocate memory from a contiguous region, making allocation extremely fast (just bump a pointer). All allocations are freed at once when the arena is dropped. Perfect for request-scoped or parse-tree allocations.

### Bad

```rust
// Many small allocations during parsing
fn parse(input: &str) -> Vec<Node> {
    let mut nodes = Vec::new();
    for token in tokenize(input) {
        nodes.push(Box::new(Node::new(token)));  // Heap alloc per node!
    }
    nodes
}

// Per-request allocations add up
fn handle_request(req: Request) -> Response {
    let headers = parse_headers(&req);      // Allocates
    let body = parse_body(&req);            // Allocates
    let response = generate_response();     // Allocates
    // All freed individually at end
    response
}
```

### Good

```rust
use bumpalo::Bump;

// All nodes allocated from same arena
fn parse<'a>(input: &str, arena: &'a Bump) -> Vec<&'a Node> {
    let mut nodes = Vec::new();
    for token in tokenize(input) {
        let node = arena.alloc(Node::new(token));  // Fast bump!
        nodes.push(node);
    }
    nodes
}  // Arena freed all at once

// Per-request arena
fn handle_request(req: Request) -> Response {
    let arena = Bump::new();
    
    let headers = parse_headers(&req, &arena);
    let body = parse_body(&req, &arena);
    let response = generate_response(&arena);
    
    // Convert to owned response before arena drops
    response.to_owned()
}  // All request memory freed instantly
```

### Thread-Local Scratch Arena Pattern

```rust
use bumpalo::Bump;
use std::cell::RefCell;

thread_local! {
    static SCRATCH: RefCell<Bump> = RefCell::new(Bump::with_capacity(4 * 1024));
}

fn with_scratch<T>(f: impl FnOnce(&Bump) -> T) -> T {
    SCRATCH.with(|scratch| {
        let arena = scratch.borrow();
        let result = f(&arena);
        result
    })
}

fn reset_scratch() {
    SCRATCH.with(|scratch| {
        scratch.borrow_mut().reset();
    });
}

// Usage
fn process_batch(items: &[Item]) -> Vec<Output> {
    with_scratch(|arena| {
        let temp_data: Vec<&TempData> = items
            .iter()
            .map(|item| arena.alloc(compute_temp(item)))
            .collect();
        
        // Use temp_data...
        let result = finalize(&temp_data);
        
        reset_scratch();  // Reuse arena memory
        result
    })
}
```

### Evidence from ROC Compiler

```rust
// https://github.com/roc-lang/roc/blob/main/crates/compiler/solve/src/to_var.rs
std::thread_local! {
    static SCRATCHPAD: RefCell<Option<bumpalo::Bump>> = 
        RefCell::new(Some(bumpalo::Bump::with_capacity(4 * 1024)));
}

fn take_scratchpad() -> bumpalo::Bump {
    SCRATCHPAD.with(|f| f.take().unwrap())
}

fn put_scratchpad(scratchpad: bumpalo::Bump) {
    SCRATCHPAD.with(|f| {
        f.replace(Some(scratchpad));
    });
}
```

### Bumpalo Collections

```rust
use bumpalo::Bump;
use bumpalo::collections::{Vec, String};

fn process<'a>(arena: &'a Bump, input: &str) -> Vec<'a, String<'a>> {
    let mut results = Vec::new_in(arena);
    
    for word in input.split_whitespace() {
        let mut s = String::new_in(arena);
        s.push_str(word);
        s.push_str("_processed");
        results.push(s);
    }
    
    results  // All allocated in arena
}
```

### When to Use Arenas

| Situation | Use Arena? |
|-----------|-----------|
| Parsing (AST nodes) | Yes |
| Request handling | Yes |
| Batch processing | Yes |
| Long-lived data | No |
| Data escaping scope | No (or copy out) |
| Simple programs | Overkill |

### Performance Impact

```rust
// Benchmarks from production systems:
// - Individual allocations: ~25-50ns each
// - Arena bump: ~1-2ns each (20-50x faster)
// - Arena reset: O(1) regardless of allocation count

// Memory overhead:
// - Arena wastes some memory (unused capacity)
// - But eliminates per-allocation metadata overhead
```

### See Also

- [mem-with-capacity](#mem-with-capacity) - Pre-allocate when size is known
- [mem-reuse-collections](#mem-reuse-collections) - Reuse collections with clear()
- [opt-profile-first](#perf-profile-first) - Profile to verify benefit


## mem-arrayvec

> Use `ArrayVec<T, N>` for fixed-capacity collections that never heap-allocate

### Why It Matters

`ArrayVec` from the `arrayvec` crate provides Vec-like API with a compile-time maximum capacity, storing all elements inline on the stack. Unlike `SmallVec` which can spill to heap, `ArrayVec` guarantees no heap allocation—if you exceed capacity, it returns an error or panics. This is ideal for embedded systems, real-time code, or when you have a hard upper bound.

### Bad

```rust
// Vec always heap-allocates, even for small collections
fn parse_options(input: &str) -> Vec<Option> {
    let mut options = Vec::new();  // Heap allocation
    for part in input.split(',').take(8) {  // Know we never exceed 8
        options.push(parse_option(part));
    }
    options
}

// Or SmallVec when you truly can't exceed capacity
use smallvec::SmallVec;
fn get_flags() -> SmallVec<[Flag; 4]> {
    // SmallVec CAN heap-allocate if pushed beyond 4
    // That might be unexpected in no-alloc contexts
}
```

### Good

```rust
use arrayvec::ArrayVec;

// Guaranteed no heap allocation
fn parse_options(input: &str) -> ArrayVec<Option, 8> {
    let mut options = ArrayVec::new();
    for part in input.split(',') {
        if options.try_push(parse_option(part)).is_err() {
            break;  // Capacity reached, stop
        }
    }
    options
}

// For embedded/no_std contexts
#[no_std]
fn collect_readings() -> ArrayVec<SensorReading, 16> {
    let mut readings = ArrayVec::new();
    for sensor in SENSORS.iter() {
        readings.push(sensor.read());  // Panics if > 16
    }
    readings
}
```

### ArrayVec vs SmallVec vs Vec

| Type | Stack | Heap | Use When |
|------|-------|------|----------|
| `Vec<T>` | Never | Always | Unknown size, may grow indefinitely |
| `SmallVec<[T; N]>` | Up to N | Beyond N | Usually small, occasionally large |
| `ArrayVec<T, N>` | Always | Never | Hard limit, no heap allowed |

### API Patterns

```rust
use arrayvec::ArrayVec;

let mut arr: ArrayVec<i32, 4> = ArrayVec::new();

// Push with potential panic (like Vec)
arr.push(1);
arr.push(2);

// Safe push - returns Err if full
match arr.try_push(3) {
    Ok(()) => println!("Added"),
    Err(err) => println!("Full, couldn't add {}", err.element()),
}

// Check capacity
assert!(arr.len() < arr.capacity());

// Remaining capacity
let remaining = arr.remaining_capacity();

// Is it full?
if arr.is_full() {
    arr.pop();
}

// From iterator with limit
let arr: ArrayVec<_, 10> = (0..100)
    .filter(|x| x % 2 == 0)
    .take(10)  // Important: don't exceed capacity
    .collect();
```

### ArrayString for Stack Strings

```rust
use arrayvec::ArrayString;

// Stack-allocated string with max capacity
let mut s: ArrayString<64> = ArrayString::new();
s.push_str("Hello, ");
s.push_str("world!");

// No heap allocation for small strings
fn format_code(code: u32) -> ArrayString<16> {
    let mut s = ArrayString::new();
    write!(&mut s, "CODE-{:04}", code).unwrap();
    s
}
```

### When NOT to Use ArrayVec

```rust
// ❌ When size varies widely
fn parse_json_array(json: &str) -> ArrayVec<Value, ???> {
    // What capacity? JSON arrays can be any size
}

// ❌ When capacity is very large
let big: ArrayVec<u8, 1_000_000> = ArrayVec::new();  // 1MB on stack = bad

// ✅ Use SmallVec or Vec instead for these cases
```

### Cargo.toml

```toml
[dependencies]
arrayvec = "0.7"
```

### See Also

- [mem-smallvec](#mem-smallvec) - When heap fallback is acceptable
- [mem-with-capacity](#mem-with-capacity) - Pre-allocating Vec capacity
- [own-move-large](#own-move-large) - Large stack types considerations


## mem-assert-type-size

> Use static assertions to guard against accidental type size growth

### Why It Matters

Adding a field to a frequently-instantiated struct can silently bloat memory usage. Static size assertions catch this at compile time, making size changes intentional rather than accidental. This is especially important for types stored in large collections or passed frequently by value.

### Bad

```rust
struct Event {
    timestamp: u64,
    kind: EventKind,
    payload: [u8; 32],
}

// Later, someone adds a field without realizing the impact
struct Event {
    timestamp: u64,
    kind: EventKind,
    payload: [u8; 32],
    metadata: String,  // Silently adds 24 bytes!
}

// 10 million events now use 240MB more memory
// No warning, no review trigger
```

### Good

```rust
struct Event {
    timestamp: u64,
    kind: EventKind,
    payload: [u8; 32],
}

// Static assertion - breaks compile if size changes
const _: () = assert!(std::mem::size_of::<Event>() == 48);

// Or with static_assertions crate
use static_assertions::assert_eq_size;
assert_eq_size!(Event, [u8; 48]);

// Now adding metadata triggers compile error:
// error: assertion failed: std::mem::size_of::<Event>() == 48
```

### static_assertions Crate

```rust
use static_assertions::{assert_eq_size, const_assert};

struct Critical {
    id: u64,
    flags: u32,
    data: [u8; 16],
}

// Exact size assertion
assert_eq_size!(Critical, [u8; 32]);

// Maximum size assertion
const_assert!(std::mem::size_of::<Critical>() <= 64);

// Alignment assertion
const_assert!(std::mem::align_of::<Critical>() == 8);

// Compare sizes
assert_eq_size!(Critical, [u64; 4]);
```

### Built-in Const Assertions

```rust
// No external crate needed (Rust 1.57+)
struct Packet {
    header: u32,
    payload: [u8; 60],
}

const _: () = assert!(
    std::mem::size_of::<Packet>() == 64,
    "Packet must be exactly 64 bytes for protocol compliance"
);

// Compile error shows custom message if assertion fails
```

### Documenting Size Constraints

```rust
/// Network protocol packet header.
/// 
/// # Size
/// 
/// This struct is guaranteed to be exactly 32 bytes to match
/// the network protocol specification. Any changes to fields
/// must maintain this size constraint.
#[repr(C)]  // Predictable layout for FFI
struct Header {
    version: u16,
    flags: u16,
    length: u32,
    checksum: u64,
    reserved: [u8; 16],
}

const _: () = assert!(std::mem::size_of::<Header>() == 32);
```

### Testing Size Stability

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn critical_types_have_expected_sizes() {
        // Document expected sizes in tests too
        assert_eq!(std::mem::size_of::<Event>(), 48);
        assert_eq!(std::mem::size_of::<Message>(), 64);
        assert_eq!(std::mem::size_of::<Header>(), 32);
    }
    
    #[test]
    fn cache_line_aligned() {
        // Verify cache-friendly sizing
        assert!(std::mem::size_of::<HotData>() <= 64);
    }
}
```

### When to Assert

```rust
// ✅ Types stored in large collections
struct Node { /* ... */ }
const _: () = assert!(std::mem::size_of::<Node>() <= 64);

// ✅ Types used in FFI / binary protocols
#[repr(C)]
struct WireFormat { /* ... */ }
const _: () = assert!(std::mem::size_of::<WireFormat>() == 256);

// ✅ Performance-critical types
struct HotPath { /* ... */ }
const _: () = assert!(std::mem::size_of::<HotPath>() <= 128);

// ❌ Skip for rarely-instantiated types
struct AppConfig { /* many fields */ }
// Size doesn't matter, only one instance
```

### Cargo.toml

```toml
[dependencies]
static_assertions = "1.1"
```

### See Also

- [mem-smaller-integers](#mem-smaller-integers) - Choosing appropriate integer sizes
- [mem-box-large-variant](#mem-box-large-variant) - Managing enum variant sizes
- [opt-cache-friendly](#opt-cache-friendly) - Cache line considerations


## mem-avoid-format

> Avoid `format!()` when string literals work

### Why It Matters

`format!()` always allocates a new String, even for constant text. In hot paths, these allocations add up. Use string literals, `write!()`, or pre-allocated buffers instead.

### Bad

```rust
// Allocates every time, even for static text
fn get_error_message() -> String {
    format!("An error occurred")  // Unnecessary allocation!
}

// Allocates in a loop
for item in items {
    log::info!("{}", format!("Processing item: {}", item));  // Double work!
}

// format! in hot path
fn classify(n: i32) -> String {
    if n > 0 {
        format!("positive")  // Allocates!
    } else if n < 0 {
        format!("negative")  // Allocates!
    } else {
        format!("zero")      // Allocates!
    }
}
```

### Good

```rust
// Return &'static str for constants
fn get_error_message() -> &'static str {
    "An error occurred"  // No allocation
}

// Use format args directly
for item in items {
    log::info!("Processing item: {}", item);  // No intermediate String
}

// Return Cow for mixed static/dynamic
use std::borrow::Cow;

fn classify(n: i32) -> Cow<'static, str> {
    if n > 0 {
        Cow::Borrowed("positive")  // No allocation
    } else if n < 0 {
        Cow::Borrowed("negative")  // No allocation
    } else {
        Cow::Borrowed("zero")      // No allocation
    }
}

// Or just &'static str if always static
fn classify_str(n: i32) -> &'static str {
    if n > 0 { "positive" }
    else if n < 0 { "negative" }
    else { "zero" }
}
```

### Use write!() for Output

```rust
use std::io::Write;

// Bad: Allocate then write
fn bad_log(writer: &mut impl Write, msg: &str, code: u32) {
    let formatted = format!("[ERROR {}] {}", code, msg);  // Allocation!
    writer.write_all(formatted.as_bytes()).unwrap();
}

// Good: Write directly
fn good_log(writer: &mut impl Write, msg: &str, code: u32) {
    write!(writer, "[ERROR {}] {}", code, msg).unwrap();  // No allocation!
}
```

### Pre-allocate for Multiple Appends

```rust
// Bad: Multiple allocations
fn build_message(parts: &[&str]) -> String {
    let mut result = String::new();
    for part in parts {
        result = format!("{}{}\n", result, part);  // Allocates each iteration!
    }
    result
}

// Good: Pre-allocate
fn build_message(parts: &[&str]) -> String {
    let total_len: usize = parts.iter().map(|p| p.len() + 1).sum();
    let mut result = String::with_capacity(total_len);
    for part in parts {
        result.push_str(part);
        result.push('\n');
    }
    result
}

// Good: Use join
fn build_message(parts: &[&str]) -> String {
    parts.join("\n")
}
```

### CompactString for Small Strings

```rust
use compact_str::CompactString;

// Stack-allocated for strings <= 24 bytes
fn format_code(code: u32) -> CompactString {
    compact_str::format_compact!("ERR-{:04}", code)
    // Stack-allocated if result is small enough
}
```

### When format!() Is Fine

```rust
// Rare/cold paths - clarity over micro-optimization
fn log_startup_message() {
    println!("{}", format!("Starting {} v{}", APP_NAME, VERSION));
}

// When you need an owned String anyway
fn create_user_greeting(name: &str) -> String {
    format!("Hello, {}!", name)  // Need owned String
}

// Error messages (already on error path)
return Err(format!("Invalid value: {}", value).into());
```

### See Also

- [mem-write-over-format](#mem-write-over-format) - Use write!() instead of format!()
- [mem-with-capacity](#mem-with-capacity) - Pre-allocate strings
- [own-cow-conditional](#own-cow-conditional) - Use Cow for mixed static/dynamic


## mem-box-large-variant

> Box large enum variants to reduce overall enum size

### Why It Matters

An enum's size is determined by its largest variant. If one variant contains a large struct while others are small, every instance of the enum pays for the largest variant's size. Boxing the large variant puts that data on the heap, keeping the enum itself small. This can significantly reduce memory usage and improve cache performance.

### Bad

```rust
enum Message {
    Quit,                              // 0 bytes of data
    Move { x: i32, y: i32 },          // 8 bytes
    Text(String),                      // 24 bytes
    Image { 
        data: [u8; 1024],             // 1024 bytes - forces entire enum to ~1032 bytes!
        width: u32, 
        height: u32 
    },
}

// Every Message is ~1032 bytes, even Quit and Move
let messages: Vec<Message> = vec![
    Message::Quit,  // Wastes ~1032 bytes
    Message::Quit,  // Wastes ~1032 bytes
    Message::Move { x: 0, y: 0 },  // Wastes ~1024 bytes
];
```

### Good

```rust
struct ImageData {
    data: [u8; 1024],
    width: u32,
    height: u32,
}

enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Text(String),
    Image(Box<ImageData>),  // Now just 8 bytes (pointer)
}

// Message is now ~32 bytes (String variant is largest)
let messages: Vec<Message> = vec![
    Message::Quit,  // Uses ~32 bytes
    Message::Quit,  // Uses ~32 bytes  
    Message::Move { x: 0, y: 0 },  // Uses ~32 bytes
];
```

### Check Enum Sizes

```rust
use std::mem::size_of;

// Before boxing
enum BadEvent {
    Click { x: u32, y: u32 },           // 8 bytes
    KeyPress(char),                      // 4 bytes
    LargeData([u8; 256]),               // 256 bytes
}
println!("BadEvent: {} bytes", size_of::<BadEvent>());  // ~264 bytes

// After boxing
enum GoodEvent {
    Click { x: u32, y: u32 },
    KeyPress(char),
    LargeData(Box<[u8; 256]>),          // 8 bytes (pointer)
}
println!("GoodEvent: {} bytes", size_of::<GoodEvent>());  // ~16 bytes
```

### Clippy Lint

```toml
[lints.clippy]
large_enum_variant = "warn"  # Warns when variants differ significantly
```

```rust
// Clippy will suggest:
// warning: large size difference between variants
// help: consider boxing the large fields to reduce the total size
```

### When to Box

| Largest Variant | Other Variants | Action |
|-----------------|----------------|--------|
| < 64 bytes | Similar size | Don't box |
| > 128 bytes | Much smaller | Box the large variant |
| > 256 bytes | Any | Definitely box |

### Recursive Types Require Boxing

```rust
// Won't compile - infinite size
enum List {
    Cons(i32, List),
    Nil,
}

// Must box recursive variant
enum List {
    Cons(i32, Box<List>),  // Now finite size
    Nil,
}

// Same for ASTs
enum Expr {
    Number(i64),
    BinOp {
        op: Op,
        left: Box<Expr>,   // Recursive - must box
        right: Box<Expr>,
    },
}
```

### Pattern Matching with Boxed Variants

```rust
enum Event {
    Small(u32),
    Large(Box<LargeData>),
}

fn handle(event: Event) {
    match event {
        Event::Small(n) => println!("Small: {}", n),
        Event::Large(data) => {
            // data is Box<LargeData>, dereference to access
            println!("Large: {} bytes", data.size);
        }
    }
}

// Or match on reference
fn handle_ref(event: &Event) {
    match event {
        Event::Small(n) => println!("Small: {}", n),
        Event::Large(data) => {
            // data is &Box<LargeData>, auto-derefs
            println!("Large: {} bytes", data.size);
        }
    }
}
```

### See Also

- [own-move-large](#own-move-large) - Boxing large types for cheap moves
- [mem-smallvec](#mem-smallvec) - Alternative for inline small collections
- [lint-deny-correctness](#lint-deny-correctness) - Enabling clippy lints


## mem-boxed-slice

> Use `Box<[T]>` instead of `Vec<T>` for fixed-size heap data

### Why It Matters

`Vec<T>` stores three words: pointer, length, and capacity. When you know a collection won't grow, `Box<[T]>` stores only pointer and length (2 words), saving 8 bytes per instance. More importantly, it communicates intent: "this data is fixed-size." For large numbers of fixed collections, this adds up.

### Bad

```rust
struct Document {
    // Vec signals "might grow" but we never push after creation
    paragraphs: Vec<Paragraph>,  // 24 bytes: ptr + len + capacity
}

fn load_document(data: &[u8]) -> Document {
    let paragraphs: Vec<Paragraph> = parse_paragraphs(data);
    // paragraphs has capacity >= len, wasting the capacity field
    Document { paragraphs }
}
```

### Good

```rust
struct Document {
    // Box<[T]> signals "fixed size" - clear intent
    paragraphs: Box<[Paragraph]>,  // 16 bytes: ptr + len (as fat pointer)
}

fn load_document(data: &[u8]) -> Document {
    let paragraphs: Vec<Paragraph> = parse_paragraphs(data);
    Document { 
        paragraphs: paragraphs.into_boxed_slice()  // Shrinks + converts
    }
}
```

### Memory Layout

```rust
use std::mem::size_of;

// Vec: 24 bytes on 64-bit
assert_eq!(size_of::<Vec<u8>>(), 24);  // ptr(8) + len(8) + cap(8)

// Box<[T]>: 16 bytes (fat pointer)
assert_eq!(size_of::<Box<[u8]>>(), 16);  // ptr(8) + len(8)

// Savings per instance: 8 bytes
// For 1 million instances: 8 MB saved
```

### Conversion Patterns

```rust
// Vec to Box<[T]>
let vec: Vec<i32> = vec![1, 2, 3, 4, 5];
let boxed: Box<[i32]> = vec.into_boxed_slice();

// Box<[T]> back to Vec (if you need to grow)
let vec_again: Vec<i32> = boxed.into_vec();

// From iterator
let boxed: Box<[i32]> = (0..100).collect::<Vec<_>>().into_boxed_slice();

// Shrink Vec first if it has excess capacity
let mut vec = Vec::with_capacity(1000);
vec.extend(0..10);
vec.shrink_to_fit();  // Reduce capacity to length
let boxed = vec.into_boxed_slice();  // Now no wasted allocation
```

### When to Use What

| Type | Use When |
|------|----------|
| `Vec<T>` | Collection may grow/shrink |
| `Box<[T]>` | Fixed-size, heap-allocated, many instances |
| `[T; N]` | Fixed-size, stack-allocated, size known at compile time |
| `&[T]` | Borrowed view, don't need ownership |

### Box<str> for Immutable Strings

Same principle applies to strings:

```rust
use std::mem::size_of;

// String: 24 bytes (like Vec<u8>)
assert_eq!(size_of::<String>(), 24);

// Box<str>: 16 bytes
assert_eq!(size_of::<Box<str>>(), 16);

// For immutable strings
struct Name {
    value: Box<str>,  // Saves 8 bytes vs String
}

impl Name {
    fn new(s: &str) -> Self {
        Name { value: s.into() }  // &str -> Box<str>
    }
}

// Or from String
let s = String::from("hello");
let boxed: Box<str> = s.into_boxed_str();
```

### Real-World Example

```rust
// Cache with millions of entries
struct Cache {
    // 8 bytes saved per entry adds up
    entries: HashMap<Key, Box<[u8]>>,
}

impl Cache {
    fn insert(&mut self, key: Key, data: Vec<u8>) {
        // Convert to boxed slice for storage
        self.entries.insert(key, data.into_boxed_slice());
    }
    
    fn get(&self, key: &Key) -> Option<&[u8]> {
        // Returns regular slice reference
        self.entries.get(key).map(|b| b.as_ref())
    }
}
```

### See Also

- [mem-with-capacity](#mem-with-capacity) - Pre-allocating when size is known
- [own-slice-over-vec](#own-slice-over-vec) - Using slices in function parameters
- [mem-compact-string](#mem-compact-string) - Compact string alternatives


## mem-clone-from

> Use `clone_from()` to reuse allocations when repeatedly cloning

### Why It Matters

`x = y.clone()` drops x's allocation and creates a new one from y. `x.clone_from(&y)` reuses x's existing allocation if possible, avoiding the allocation overhead. For repeatedly cloning into the same variable (loops, buffers), this can significantly reduce allocator pressure.

### Bad

```rust
let mut buffer = String::with_capacity(1024);

for source in sources {
    buffer = source.clone();  // Drops old allocation, allocates new
    process(&buffer);
}

// Each iteration:
// 1. Drops buffer's 1024-byte allocation
// 2. Allocates new memory for source.clone()
// Allocator thrashing!
```

### Good

```rust
let mut buffer = String::with_capacity(1024);

for source in sources {
    buffer.clone_from(source);  // Reuses allocation if capacity sufficient
    process(&buffer);
}

// If source.len() <= 1024, no allocation happens
// Just copies bytes into existing buffer
```

### How clone_from Works

```rust
impl Clone for String {
    fn clone(&self) -> Self {
        // Always allocates new memory
        String::from(self.as_str())
    }
    
    fn clone_from(&mut self, source: &Self) {
        // Reuse existing capacity if possible
        self.clear();
        self.push_str(source);  // Only reallocates if capacity insufficient
    }
}
```

### Types That Benefit

```rust
// String - reuses capacity
let mut s = String::with_capacity(100);
s.clone_from(&other_string);

// Vec<T> - reuses capacity
let mut v: Vec<u8> = Vec::with_capacity(1000);
v.clone_from(&other_vec);

// HashMap - reuses buckets
let mut map = HashMap::with_capacity(100);
map.clone_from(&other_map);

// PathBuf - reuses capacity
let mut path = PathBuf::with_capacity(256);
path.clone_from(&other_path);
```

### Benchmarking the Difference

```rust
use criterion::{black_box, criterion_group, Criterion};

fn bench_clone_patterns(c: &mut Criterion) {
    let source = "x".repeat(1000);
    
    c.bench_function("clone assignment", |b| {
        let mut buffer = String::new();
        b.iter(|| {
            buffer = black_box(&source).clone();
        });
    });
    
    c.bench_function("clone_from", |b| {
        let mut buffer = String::with_capacity(1000);
        b.iter(|| {
            buffer.clone_from(black_box(&source));
        });
    });
}
// clone_from is typically 2-3x faster for this pattern
```

### Custom Implementations

When implementing Clone for your types:

```rust
#[derive(Debug)]
struct Buffer {
    data: Vec<u8>,
    metadata: Metadata,
}

impl Clone for Buffer {
    fn clone(&self) -> Self {
        Buffer {
            data: self.data.clone(),
            metadata: self.metadata.clone(),
        }
    }
    
    // Optimize clone_from to reuse vec capacity
    fn clone_from(&mut self, source: &Self) {
        self.data.clone_from(&source.data);  // Reuses allocation
        self.metadata = source.metadata.clone();
    }
}
```

### When NOT Needed

```rust
// Single clone - no benefit
let copy = original.clone();  // Can't reuse, no prior allocation

// Small Copy types - no allocation anyway
let x: i32 = y;  // Not even Clone, just Copy

// Immutable context
fn process(data: &String) {
    // Can't use clone_from - would need &mut self
}
```

### See Also

- [mem-with-capacity](#mem-with-capacity) - Pre-allocating capacity
- [mem-reuse-collections](#mem-reuse-collections) - Reusing collection allocations
- [own-clone-explicit](#own-clone-explicit) - When Clone is appropriate


## mem-compact-string

> Use compact string types for memory-constrained string storage

### Why It Matters

Standard `String` is 24 bytes (pointer + length + capacity). For applications storing millions of short strings, this overhead dominates. Compact string libraries like `compact_str`, `smartstring`, or `ecow` store small strings inline (no heap allocation) and use optimized layouts for larger strings.

### Bad

```rust
struct User {
    id: u64,
    // Most usernames are < 24 chars, but String is always 24 bytes + heap
    username: String,
    email: String,
}

// 1 million users = 24 bytes * 2 * 1M = 48MB just for String metadata
// Plus all the heap allocations for actual content
```

### Good

```rust
use compact_str::CompactString;

struct User {
    id: u64,
    // CompactString: 24 bytes, but strings ≤ 24 chars are inline (no heap)
    username: CompactString,
    email: CompactString,
}

// Most usernames fit inline = zero heap allocations
// Same memory footprint as String but way fewer allocations
```

### Compact String Libraries

#### compact_str

```rust
use compact_str::CompactString;

// Inline storage for strings ≤ 24 bytes
let small: CompactString = "hello".into();  // No heap allocation

// Automatic heap fallback for larger strings
let large: CompactString = "x".repeat(100).into();

// String-like API
let mut s = CompactString::new("hello");
s.push_str(" world");
assert_eq!(s.as_str(), "hello world");

// Format macro
use compact_str::format_compact;
let s = format_compact!("value: {}", 42);
```

#### smartstring

```rust
use smartstring::{SmartString, LazyCompact};

// Default is LazyCompact: 24 bytes inline capacity
let s: SmartString<LazyCompact> = "short string".into();

// Compact mode: 23 bytes inline on 64-bit
use smartstring::Compact;
let s: SmartString<Compact> = "hello".into();
```

#### ecow (copy-on-write)

```rust
use ecow::EcoString;

// Clone is O(1) - shares underlying data
let s1: EcoString = "shared data".into();
let s2 = s1.clone();  // Cheap, shares allocation

// Copy-on-write: only allocates on mutation
let mut s3 = s1.clone();
s3.push_str(" modified");  // Now allocates
```

### Memory Comparison

```rust
use std::mem::size_of;

// All 24 bytes, but different inline capacities
assert_eq!(size_of::<String>(), 24);
assert_eq!(size_of::<compact_str::CompactString>(), 24);
assert_eq!(size_of::<smartstring::SmartString>(), 24);
assert_eq!(size_of::<ecow::EcoString>(), 16);  // Even smaller!
```

### Inline Capacity

| Type | Size | Inline Capacity |
|------|------|-----------------|
| `String` | 24 | 0 (always heap) |
| `CompactString` | 24 | 24 bytes |
| `SmartString<LazyCompact>` | 24 | 23 bytes |
| `EcoString` | 16 | 15 bytes |

### When to Use

```rust
// ✅ Good: Many short strings in memory
struct Dictionary {
    words: Vec<CompactString>,  // Millions of short words
}

// ✅ Good: Frequently cloned strings
struct Template {
    parts: Vec<EcoString>,  // O(1) clone
}

// ❌ Don't: Hot path string manipulation
fn transform(s: &str) -> String {
    // Standard String is optimized for manipulation
    s.to_uppercase()
}

// ❌ Don't: API boundaries (prefer &str or String for interop)
pub fn public_api(input: CompactString) { }  // Forces dependency
pub fn public_api(input: impl Into<String>) { }  // Better
```

### Cargo.toml

```toml
[dependencies]
compact_str = "0.7"
### or
smartstring = "1.0"
### or
ecow = "0.2"
```

### See Also

- [mem-boxed-slice](#mem-boxed-slice) - Box<str> for immutable strings
- [own-cow-conditional](#own-cow-conditional) - Cow<str> for borrow-or-own
- [mem-smallvec](#mem-smallvec) - Similar concept for Vec


## mem-reuse-collections

> Clear and reuse collections instead of creating new ones in loops

### Why It Matters

Creating new `Vec`, `String`, or `HashMap` instances in hot loops generates significant allocator pressure. Clearing a collection and reusing it keeps the existing capacity, avoiding repeated allocation/deallocation cycles. This is especially impactful for frequently-executed code paths.

### Bad

```rust
fn process_batches(batches: &[Batch]) -> Vec<Result> {
    let mut results = Vec::new();
    
    for batch in batches {
        let mut temp = Vec::new();  // Allocates every iteration
        
        for item in &batch.items {
            temp.push(transform(item));
        }
        
        results.push(aggregate(&temp));
        // temp dropped here, deallocation
    }
    
    results
}

fn format_lines(items: &[Item]) -> String {
    let mut output = String::new();
    
    for item in items {
        let line = format!("{}: {}", item.name, item.value);  // Allocates
        output.push_str(&line);
        output.push('\n');
    }
    
    output
}
```

### Good

```rust
fn process_batches(batches: &[Batch]) -> Vec<Result> {
    let mut results = Vec::with_capacity(batches.len());
    let mut temp = Vec::new();  // Allocate once outside loop
    
    for batch in batches {
        temp.clear();  // Reuse allocation, just reset length
        
        for item in &batch.items {
            temp.push(transform(item));
        }
        
        results.push(aggregate(&temp));
        // temp keeps its capacity for next iteration
    }
    
    results
}

fn format_lines(items: &[Item]) -> String {
    use std::fmt::Write;
    
    let mut output = String::new();
    let mut line = String::new();  // Reusable buffer
    
    for item in items {
        line.clear();
        write!(&mut line, "{}: {}", item.name, item.value).unwrap();
        output.push_str(&line);
        output.push('\n');
    }
    
    output
}
```

### Clear vs Drain vs New

```rust
let mut vec = vec![1, 2, 3, 4, 5];

// clear(): keeps capacity, O(n) for Drop types
vec.clear();
assert_eq!(vec.len(), 0);
assert!(vec.capacity() >= 5);

// drain(): returns iterator, clears after iteration
let drained: Vec<_> = vec.drain(..).collect();

// truncate(): keeps first n elements
vec.truncate(2);

// Creating new: loses all capacity
vec = Vec::new();  // Capacity gone
```

### HashMap Reuse

```rust
use std::collections::HashMap;

fn count_words_per_line(lines: &[&str]) -> Vec<HashMap<String, usize>> {
    let mut results = Vec::with_capacity(lines.len());
    let mut counts = HashMap::new();  // Reuse across iterations
    
    for line in lines {
        counts.clear();  // Keeps bucket allocation
        
        for word in line.split_whitespace() {
            *counts.entry(word.to_string()).or_insert(0) += 1;
        }
        
        results.push(counts.clone());
    }
    
    results
}
```

### BufWriter Pattern

```rust
use std::io::{BufWriter, Write};

fn write_many_records(records: &[Record], mut output: impl Write) -> std::io::Result<()> {
    // BufWriter reuses its internal buffer
    let mut writer = BufWriter::with_capacity(8192, &mut output);
    let mut line = String::with_capacity(256);  // Reusable formatting buffer
    
    for record in records {
        line.clear();
        format_record(record, &mut line);
        writer.write_all(line.as_bytes())?;
        writer.write_all(b"\n")?;
    }
    
    writer.flush()
}
```

### When to Create Fresh

```rust
// When ownership transfer is needed
fn produce_results() -> Vec<Vec<Item>> {
    let mut results = Vec::new();
    
    for batch in batches {
        let processed: Vec<Item> = batch.process();  // Ownership transferred
        results.push(processed);  // Moved into results
    }
    
    results  // Each inner Vec is independent
}

// When thread safety requires it
std::thread::scope(|s| {
    for _ in 0..4 {
        s.spawn(|| {
            let local_buffer = Vec::new();  // Thread-local, can't share
            // ...
        });
    }
});
```

### See Also

- [mem-with-capacity](#mem-with-capacity) - Pre-allocating capacity
- [mem-clone-from](#mem-clone-from) - Reusing allocations when cloning
- [mem-write-over-format](#mem-write-over-format) - Avoiding format! allocations


## mem-smaller-integers

> Use appropriately-sized integers to reduce memory footprint

### Why It Matters

Using `i64` when `i16` suffices wastes 6 bytes per value. In arrays, vectors, and structs with millions of instances, this waste compounds dramatically. Choosing the smallest integer type that fits your domain reduces memory usage and improves cache utilization.

### Bad

```rust
struct Pixel {
    r: u64,  // Color channels 0-255 = 8 bits needed
    g: u64,  // Using 64 bits = 8x waste
    b: u64,
    a: u64,
}
// Size: 32 bytes per pixel

struct HttpStatus {
    code: i32,      // HTTP codes 100-599 = 10 bits needed
    version: i32,   // HTTP 1.0, 1.1, 2, 3 = 2 bits needed
}
// Size: 8 bytes per status

struct GeoPoint {
    lat: f64,   // -90 to 90
    lon: f64,   // -180 to 180
}
// Often f32 precision is sufficient for display
```

### Good

```rust
struct Pixel {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
}
// Size: 4 bytes per pixel (8x smaller!)

struct HttpStatus {
    code: u16,      // 100-599 fits in u16
    version: u8,    // 1, 2, 3 fits in u8
}
// Size: 3 bytes (+ 1 padding = 4 bytes)

struct GeoPoint {
    lat: f32,   // ~7 decimal digits precision
    lon: f32,   // Sufficient for most geo applications
}
// Size: 8 bytes vs 16 bytes
```

### Integer Size Reference

| Type | Range | Use For |
|------|-------|---------|
| `u8` | 0 to 255 | Bytes, small counts, flags |
| `i8` | -128 to 127 | Small signed values |
| `u16` | 0 to 65,535 | Port numbers, small indices |
| `i16` | -32,768 to 32,767 | Audio samples |
| `u32` | 0 to 4 billion | Array indices, timestamps (seconds) |
| `i32` | ±2 billion | General integers, file offsets |
| `u64` | 0 to 18 quintillion | Large counts, nanosecond timestamps |
| `usize` | Platform-dependent | Array indexing (required by Rust) |

### Struct Packing

```rust
use std::mem::size_of;

// Poor ordering - 24 bytes due to padding
struct Wasteful {
    a: u8,    // 1 byte + 7 padding
    b: u64,   // 8 bytes
    c: u8,    // 1 byte + 7 padding
}
assert_eq!(size_of::<Wasteful>(), 24);

// Better ordering - 16 bytes
struct Efficient {
    b: u64,   // 8 bytes (aligned)
    a: u8,    // 1 byte
    c: u8,    // 1 byte + 6 padding
}
assert_eq!(size_of::<Efficient>(), 16);

// Even better with smaller types - 10 bytes
struct Compact {
    b: u32,   // 4 bytes (if u32 suffices)
    a: u8,    // 1 byte
    c: u8,    // 1 byte
}
assert_eq!(size_of::<Compact>(), 8);  // With padding
```

### Conversion Safety

```rust
// Safe: always succeeds (widening)
let small: u8 = 42;
let big: u32 = small.into();

// Fallible: may overflow (narrowing)
let big: u32 = 1000;
let small: u8 = big.try_into().expect("value out of range");

// Or use checked conversion
if let Ok(small) = u8::try_from(big) {
    use_small(small);
} else {
    handle_overflow();
}
```

### Bitflags for Boolean Sets

```rust
use bitflags::bitflags;

// Instead of 8 separate bool fields (8 bytes minimum)
bitflags! {
    struct Permissions: u8 {
        const READ    = 0b0000_0001;
        const WRITE   = 0b0000_0010;
        const EXECUTE = 0b0000_0100;
        const DELETE  = 0b0000_1000;
    }
}
// All 8 flags in 1 byte!

let perms = Permissions::READ | Permissions::WRITE;
if perms.contains(Permissions::READ) {
    // ...
}
```

### NonZero Types for Option Optimization

```rust
use std::num::NonZeroU64;

// Option<u64> = 16 bytes (no null pointer optimization)
assert_eq!(size_of::<Option<u64>>(), 16);

// Option<NonZeroU64> = 8 bytes (0 represents None)
assert_eq!(size_of::<Option<NonZeroU64>>(), 8);

let id: Option<NonZeroU64> = NonZeroU64::new(42);
```

### See Also

- [mem-box-large-variant](#mem-box-large-variant) - Optimizing enum sizes
- [mem-assert-type-size](#mem-assert-type-size) - Compile-time size checks
- [type-newtype-ids](#type-newtype-ids) - Type safety for integer IDs


## mem-smallvec

> Use `SmallVec` for usually-small collections

### Why It Matters

`SmallVec<[T; N]>` stores up to N elements inline (on the stack), only allocating on the heap when the size exceeds N. This eliminates heap allocations for the common case while still allowing growth when needed.

### Bad

```rust
// Always heap-allocates, even for 1-2 elements
fn get_path_components(path: &str) -> Vec<&str> {
    path.split('/').collect()  // Usually 2-4 components
}

// Always heap-allocates for error list
fn validate(input: &Input) -> Vec<ValidationError> {
    let mut errors = Vec::new();  // Usually 0-3 errors
    // validation logic...
    errors
}
```

### Good

```rust
use smallvec::{smallvec, SmallVec};

// Stack-allocated for typical paths (1-8 components)
fn get_path_components(path: &str) -> SmallVec<[&str; 8]> {
    path.split('/').collect()
}

// Stack-allocated for typical error counts
fn validate(input: &Input) -> SmallVec<[ValidationError; 4]> {
    let mut errors = SmallVec::new();
    // validation logic...
    errors
}

// Using smallvec! macro
let v: SmallVec<[i32; 4]> = smallvec![1, 2, 3];
```

### Choosing Capacity N

```rust
// Measure your actual data distribution!
// Guidelines:

// Path components: 4-8 (most paths are shallow)
type PathParts<'a> = SmallVec<[&'a str; 8]>;

// Function arguments: 4-8 (most functions have few args)  
type Args = SmallVec<[Arg; 8]>;

// AST children: 2-4 (binary ops, if/else, etc.)
type Children = SmallVec<[Node; 4]>;

// Error accumulation: 2-4 (most inputs have few errors)
type Errors = SmallVec<[Error; 4]>;

// Attribute lists: 4-8 (most items have few attributes)
type Attrs = SmallVec<[Attribute; 8]>;
```

### Evidence from rust-analyzer

```rust
// https://github.com/rust-lang/rust/blob/main/compiler/rustc_expand/src/base.rs
macro_rules! make_stmts_default {
    ($me:expr) => {
        $me.make_expr().map(|e| {
            smallvec![ast::Stmt {
                id: ast::DUMMY_NODE_ID,
                span: e.span,
                kind: ast::StmtKind::Expr(e),
            }]
        })
    }
}
```

### Trade-offs

```rust
// SmallVec is slightly larger than Vec
use std::mem::size_of;
// Vec<i32>: 24 bytes (ptr + len + cap)
// SmallVec<[i32; 4]>: 32 bytes (inline storage + len + discriminant)

// SmallVec has branching overhead on every operation
// (must check if inline or heap)

// Profile to verify benefit!
```

### When to Use SmallVec vs Alternatives

| Situation | Use |
|-----------|-----|
| Usually small, sometimes large | `SmallVec<[T; N]>` |
| Always small, fixed max | `ArrayVec<T, N>` |
| Rarely grows past initial | `Vec::with_capacity` |
| No `unsafe` allowed | `TinyVec` |
| Often empty | `ThinVec` |

### ArrayVec Alternative

```rust
use arrayvec::ArrayVec;

// Fixed maximum capacity, never heap allocates
// Panics if you exceed capacity
fn parse_rgb(s: &str) -> ArrayVec<u8, 3> {
    let mut components = ArrayVec::new();
    for part in s.split(',').take(3) {
        components.push(part.parse().unwrap());
    }
    components
}
```

### TinyVec (No Unsafe)

```rust
use tinyvec::{tiny_vec, TinyVec};

// Same concept as SmallVec but 100% safe code
let v: TinyVec<[i32; 4]> = tiny_vec![1, 2, 3];
```

### See Also

- [mem-arrayvec](#mem-arrayvec) - Use ArrayVec for fixed-max collections
- [mem-with-capacity](#mem-with-capacity) - Pre-allocate when size is known
- [mem-thinvec](#mem-thinvec) - Use ThinVec for often-empty vectors


## mem-thinvec

> Use `ThinVec<T>` for nullable collections with minimal overhead

### Why It Matters

Standard `Vec<T>` is 24 bytes even when empty. `ThinVec` from Mozilla's `thin_vec` crate uses a single pointer (8 bytes), storing length and capacity inline with the heap allocation. For Option<Vec<T>> patterns or structs with many optional vecs, this significantly reduces memory overhead.

### Bad

```rust
struct TreeNode {
    value: i32,
    // Each node pays 24 bytes for children, even leaves
    children: Vec<TreeNode>,  // Most nodes are leaves with empty Vec
}

// Or using Option<Vec<T>>
struct SparseData {
    // Option<Vec> = 24 bytes (Vec is never null-pointer optimized)
    tags: Option<Vec<String>>,
    metadata: Option<Vec<Metadata>>,
    // 48 bytes for usually-None fields
}
```

### Good

```rust
use thin_vec::ThinVec;

struct TreeNode {
    value: i32,
    // Empty ThinVec is just a null pointer - 8 bytes
    children: ThinVec<TreeNode>,
}

struct SparseData {
    // ThinVec empty = 8 bytes each
    tags: ThinVec<String>,
    metadata: ThinVec<Metadata>,
    // 16 bytes vs 48 bytes
}
```

### Memory Layout

```rust
use std::mem::size_of;

// Standard Vec: always 24 bytes
assert_eq!(size_of::<Vec<u8>>(), 24);
assert_eq!(size_of::<Option<Vec<u8>>>(), 24);  // No NPO benefit

// ThinVec: 8 bytes (one pointer)
use thin_vec::ThinVec;
assert_eq!(size_of::<ThinVec<u8>>(), 8);
assert_eq!(size_of::<Option<ThinVec<u8>>>(), 8);  // Option is free!
```

### ThinVec vs Vec

| Feature | `Vec<T>` | `ThinVec<T>` |
|---------|----------|--------------|
| Size (empty) | 24 bytes | 8 bytes |
| Size (non-empty) | 24 bytes | 8 bytes (header on heap) |
| Option<T> optimization | No | Yes |
| Cache locality | Better (len/cap on stack) | Worse (len/cap on heap) |
| Iteration speed | Faster | Slightly slower |
| API compatibility | Full | Vec-like |

### When to Use ThinVec

```rust
// ✅ Good: Many instances, often empty
struct SparseGraph {
    nodes: Vec<Node>,
    // Most edges lists are empty or small
    edges: Vec<ThinVec<EdgeId>>,  // Saves 16 bytes per node
}

// ✅ Good: Nullable collection field
struct Document {
    content: String,
    attachments: ThinVec<Attachment>,  // Often empty
}

// ❌ Avoid: Hot loops, performance-critical iteration
fn process_hot_path(data: &ThinVec<Item>) {
    // Every length check goes through pointer indirection
    for item in data {  // Vec would be faster here
        process(item);
    }
}

// ❌ Avoid: Few instances
fn main() {
    let single_vec: ThinVec<i32> = ThinVec::new();
    // Saving 16 bytes once is meaningless
}
```

### API Compatibility

```rust
use thin_vec::{ThinVec, thin_vec};

// Constructor macro
let v: ThinVec<i32> = thin_vec![1, 2, 3];

// Familiar Vec-like API
let mut v = ThinVec::new();
v.push(1);
v.push(2);
v.extend([3, 4, 5]);
v.pop();

// Iteration
for item in &v {
    println!("{}", item);
}

// Slicing
let slice: &[i32] = &v[..];

// Conversion
let vec: Vec<i32> = v.into();
let thin: ThinVec<i32> = vec.into();
```

### Cargo.toml

```toml
[dependencies]
thin-vec = "0.2"
```

### See Also

- [mem-smallvec](#mem-smallvec) - Stack-allocated small vecs
- [mem-boxed-slice](#mem-boxed-slice) - Fixed-size heap slices
- [mem-with-capacity](#mem-with-capacity) - Pre-allocation strategies


## mem-with-capacity

> Use `with_capacity()` when size is known

### Why It Matters

When you know (or can estimate) the final size of a collection, pre-allocating avoids multiple reallocations as it grows. Each reallocation copies all existing elements, so avoiding them can dramatically improve performance.

### Bad

```rust
// Vec starts at capacity 0, reallocates at 4, 8, 16, 32...
let mut results = Vec::new();
for i in 0..1000 {
    results.push(process(i));  // ~10 reallocations!
}

// String grows similarly
let mut output = String::new();
for word in words {
    output.push_str(word);
    output.push(' ');
}

// HashMap default capacity is small
let mut map = HashMap::new();
for (k, v) in pairs {  // Many reallocations
    map.insert(k, v);
}
```

### Good

```rust
// Pre-allocate exact size
let mut results = Vec::with_capacity(1000);
for i in 0..1000 {
    results.push(process(i));  // Zero reallocations!
}

// Or use collect with size hint (iterator provides capacity)
let results: Vec<_> = (0..1000).map(process).collect();

// Pre-allocate string
let estimated_len = words.iter().map(|w| w.len() + 1).sum();
let mut output = String::with_capacity(estimated_len);
for word in words {
    output.push_str(word);
    output.push(' ');
}

// Pre-allocate HashMap
let mut map = HashMap::with_capacity(pairs.len());
for (k, v) in pairs {
    map.insert(k, v);
}
```

### Collection Capacity Methods

```rust
// Vec
let mut v = Vec::with_capacity(100);
v.reserve(50);        // Ensure at least 50 more slots
v.reserve_exact(50);  // Ensure exactly 50 more (no extra)
v.shrink_to_fit();    // Release unused capacity

// String
let mut s = String::with_capacity(100);
s.reserve(50);

// HashMap / HashSet
let mut m = HashMap::with_capacity(100);
m.reserve(50);

// VecDeque
let mut d = VecDeque::with_capacity(100);
```

### Estimating Capacity

```rust
// From iterator length
fn collect_results(items: &[Item]) -> Vec<Output> {
    let mut results = Vec::with_capacity(items.len());
    for item in items {
        results.push(process(item));
    }
    results
}

// From filter estimate (if ~10% pass filter)
fn filter_valid(items: &[Item]) -> Vec<&Item> {
    let mut valid = Vec::with_capacity(items.len() / 10);
    for item in items {
        if item.is_valid() {
            valid.push(item);
        }
    }
    valid
}

// String from parts
fn join_with_sep(parts: &[&str], sep: &str) -> String {
    let total_len: usize = parts.iter().map(|p| p.len()).sum();
    let sep_len = if parts.is_empty() { 0 } else { sep.len() * (parts.len() - 1) };
    
    let mut result = String::with_capacity(total_len + sep_len);
    for (i, part) in parts.iter().enumerate() {
        if i > 0 {
            result.push_str(sep);
        }
        result.push_str(part);
    }
    result
}
```

### Evidence from Production Code

From fd (file finder):
```rust
// https://github.com/sharkdp/fd/blob/master/src/walk.rs
struct ReceiverBuffer<'a, W> {
    buffer: Vec<DirEntry>,
    // ...
}

impl<'a, W: Write> ReceiverBuffer<'a, W> {
    fn new(...) -> Self {
        Self {
            buffer: Vec::with_capacity(MAX_BUFFER_LENGTH),
            // ...
        }
    }
}
```

### When to Skip

```rust
// Unknown size, small expected
let mut small: Vec<i32> = Vec::new();  // OK for small collections

// Using collect() with good size_hint
let v: Vec<_> = iter.collect();  // collect() uses size_hint

// Capacity overhead exceeds benefit
let mut rarely_used = Vec::new();  // OK if rarely grown
```

### See Also

- [mem-reuse-collections](#mem-reuse-collections) - Reuse collections with clear()
- [mem-smallvec](#mem-smallvec) - Use SmallVec for usually-small collections
- [perf-extend-batch](#perf-extend-batch) - Use extend() for batch insertions


## mem-write-over-format

> Use `write!()` into existing buffers instead of `format!()` allocations

### Why It Matters

`format!()` always allocates a new `String`. In hot paths or loops, these allocations add up. `write!()` writes directly into an existing buffer, reusing its capacity. For high-frequency formatting operations, this can eliminate significant allocator overhead.

### Bad

```rust
fn log_event(event: &Event, output: &mut Vec<u8>) {
    // format! allocates a new String every call
    let line = format!(
        "[{}] {}: {}\n",
        event.timestamp,
        event.level,
        event.message
    );
    output.extend_from_slice(line.as_bytes());
}

fn build_response(items: &[Item]) -> String {
    let mut result = String::new();
    
    for item in items {
        // format! allocates for each item
        result.push_str(&format!("{}: {}\n", item.name, item.value));
    }
    
    result
}
```

### Good

```rust
use std::fmt::Write;

fn log_event(event: &Event, output: &mut Vec<u8>) {
    use std::io::Write;
    // write! to Vec<u8> directly, no intermediate allocation
    write!(
        output,
        "[{}] {}: {}\n",
        event.timestamp,
        event.level,
        event.message
    ).unwrap();
}

fn build_response(items: &[Item]) -> String {
    use std::fmt::Write;
    
    let mut result = String::with_capacity(items.len() * 64);
    
    for item in items {
        // write! into existing String, reuses capacity
        write!(&mut result, "{}: {}\n", item.name, item.value).unwrap();
    }
    
    result
}
```

### Write Trait Varieties

```rust
// std::fmt::Write - for String, &mut String
use std::fmt::Write as FmtWrite;
let mut s = String::new();
write!(&mut s, "Hello {}", 42).unwrap();

// std::io::Write - for Vec<u8>, File, TcpStream, etc.
use std::io::Write as IoWrite;
let mut v: Vec<u8> = Vec::new();
write!(&mut v, "Hello {}", 42).unwrap();

// Both can fail in principle, but String/Vec never fail
// Still need .unwrap() due to Result return type
```

### Reusable Formatting Buffer

```rust
use std::fmt::Write;

struct Formatter {
    buffer: String,
}

impl Formatter {
    fn new() -> Self {
        Self { buffer: String::with_capacity(1024) }
    }
    
    fn format_event(&mut self, event: &Event) -> &str {
        self.buffer.clear();  // Reuse allocation
        write!(
            &mut self.buffer, 
            "[{}] {}",
            event.timestamp, 
            event.message
        ).unwrap();
        &self.buffer
    }
}

// Usage
let mut formatter = Formatter::new();
for event in events {
    let formatted = formatter.format_event(event);
    send_log(formatted);
}
```

### writeln! for Lines

```rust
use std::fmt::Write;

let mut output = String::new();

// writeln! adds newline automatically
writeln!(&mut output, "Line 1: {}", value1).unwrap();
writeln!(&mut output, "Line 2: {}", value2).unwrap();

// Equivalent to
write!(&mut output, "Line 1: {}\n", value1).unwrap();
```

### When format! Is Fine

```rust
// One-time formatting, not in loop
let message = format!("Starting server on port {}", port);
log::info!("{}", message);

// Return value (can't return reference to local buffer)
fn describe(item: &Item) -> String {
    format!("{}: {}", item.name, item.value)  // Must allocate
}

// Debug/error paths (not hot)
if condition {
    panic!("Unexpected: {}", format!("details: {:?}", debug_info));
}
```

### Benchmark Difference

```rust
// format! in loop: ~500ns per iteration (allocation heavy)
for i in 0..1000 {
    let s = format!("item-{}", i);
    process(&s);
}

// write! with reuse: ~50ns per iteration (no allocation)
let mut buf = String::with_capacity(32);
for i in 0..1000 {
    buf.clear();
    write!(&mut buf, "item-{}", i).unwrap();
    process(&buf);
}
```

### See Also

- [mem-avoid-format](#mem-avoid-format) - General format! avoidance patterns
- [mem-reuse-collections](#mem-reuse-collections) - Reusing buffers in loops
- [mem-with-capacity](#mem-with-capacity) - Pre-allocating string capacity


## mem-zero-copy

> Use zero-copy patterns with slices and `Bytes`

### Why It Matters

Zero-copy means working with data without copying it. Instead of allocating new memory and copying bytes, you work with references to the original data. This dramatically reduces memory usage and improves performance, especially for large data.

### Bad

```rust
// Copies every line into a new String
fn get_lines(data: &str) -> Vec<String> {
    data.lines()
        .map(|line| line.to_string())  // Allocates!
        .collect()
}

// Copies the entire buffer
fn process_packet(buffer: &[u8]) -> Vec<u8> {
    let header = buffer[0..16].to_vec();  // Copy!
    let body = buffer[16..].to_vec();      // Copy!
    // Process...
    [header, body].concat()  // Another copy!
}
```

### Good

```rust
// Zero-copy: returns references to original data
fn get_lines(data: &str) -> Vec<&str> {
    data.lines().collect()  // Just pointers!
}

// Zero-copy with slices
fn process_packet(buffer: &[u8]) -> (&[u8], &[u8]) {
    let header = &buffer[0..16];  // Just a pointer + length
    let body = &buffer[16..];     // Just a pointer + length
    (header, body)
}
```

### Using bytes::Bytes

```rust
use bytes::Bytes;

// Bytes provides zero-copy slicing with reference counting
let data = Bytes::from("hello world");

// Slicing doesn't copy - just increments refcount
let hello = data.slice(0..5);   // Zero-copy!
let world = data.slice(6..11); // Zero-copy!

// Both hello and world share the underlying allocation
// Memory is freed when all references are dropped
```

### Real-World Pattern from Deno

```rust
// https://github.com/denoland/deno/blob/main/ext/http/lib.rs
fn method_to_cow(method: &http::Method) -> Cow<'static, str> {
    match *method {
        Method::GET => Cow::Borrowed("GET"),      // Zero-copy
        Method::POST => Cow::Borrowed("POST"),    // Zero-copy
        Method::PUT => Cow::Borrowed("PUT"),      // Zero-copy
        _ => Cow::Owned(method.to_string()),      // Only copies for rare methods
    }
}
```

### Zero-Copy Parsing

```rust
// Bad: Copies each parsed field
struct ParsedBad {
    name: String,
    value: String,
}

fn parse_bad(input: &str) -> ParsedBad {
    let (name, value) = input.split_once('=').unwrap();
    ParsedBad {
        name: name.to_string(),   // Copy!
        value: value.to_string(), // Copy!
    }
}

// Good: References into original string
struct Parsed<'a> {
    name: &'a str,
    value: &'a str,
}

fn parse_good(input: &str) -> Parsed<'_> {
    let (name, value) = input.split_once('=').unwrap();
    Parsed { name, value }  // Zero-copy!
}
```

### Combining with Cow

```rust
use std::borrow::Cow;

// Zero-copy when possible, copy when needed
fn normalize<'a>(input: &'a str) -> Cow<'a, str> {
    if input.contains('\t') {
        // Must copy to modify
        Cow::Owned(input.replace('\t', "    "))
    } else {
        // Zero-copy reference
        Cow::Borrowed(input)
    }
}
```

### memchr for Fast Searching

```rust
use memchr::memchr;

// Fast byte search using SIMD
fn find_newline(data: &[u8]) -> Option<usize> {
    memchr(b'\n', data)  // SIMD-accelerated, no allocation
}

// Find all occurrences
use memchr::memchr_iter;

fn count_newlines(data: &[u8]) -> usize {
    memchr_iter(b'\n', data).count()
}
```

### When Zero-Copy Isn't Possible

```rust
// Need to modify data - must copy
fn uppercase(s: &str) -> String {
    s.to_uppercase()  // Creates new String
}

// Need data to outlive source
fn store_for_later(s: &str) -> String {
    s.to_string()  // Must copy for ownership
}

// Cross-thread transfer (without Arc)
fn send_to_thread(data: &[u8]) {
    let owned = data.to_vec();  // Must copy
    std::thread::spawn(move || {
        process(&owned);
    });
}
```

### See Also

- [own-cow-conditional](#own-cow-conditional) - Use Cow for conditional ownership
- [own-borrow-over-clone](#own-borrow-over-clone) - Prefer borrowing over cloning
- [mem-arena-allocator](#mem-arena-allocator) - Arena allocators for batch operations
