# Compiler and Build Optimization

> Loaded on demand from `SKILL.md` — one rule per `## <rule-id>` section.


## opt-bounds-check

> Use iterators and patterns that eliminate bounds checks in hot paths

### Why It Matters

Rust's safety guarantees require bounds checking on array/slice indexing. In tight loops, these checks can cause measurable overhead (branch mispredictions, preventing vectorization). Patterns like iterators, `get_unchecked`, and index splitting can eliminate these checks while maintaining safety.

### Bad

```rust
fn sum_products(a: &[f64], b: &[f64]) -> f64 {
    let mut sum = 0.0;
    for i in 0..a.len() {
        sum += a[i] * b[i];  // Two bounds checks per iteration
    }
    sum
}

fn apply_filter(data: &mut [u8], kernel: &[u8; 3]) {
    for i in 1..data.len() - 1 {
        // Three bounds checks per iteration
        data[i] = (data[i - 1] + data[i] + data[i + 1]) / 3;
    }
}
```

### Good

```rust
fn sum_products(a: &[f64], b: &[f64]) -> f64 {
    // Iterator zips - no bounds checks, vectorizes well
    a.iter().zip(b.iter()).map(|(x, y)| x * y).sum()
}

fn apply_filter(data: &mut [u8]) {
    // Windows pattern - no bounds checks
    for window in data.windows(3) {
        // window[0], window[1], window[2] are all valid
    }
    
    // Or use chunks
    for chunk in data.chunks_exact(4) {
        process_simd(chunk);
    }
}
```

### Iterator Patterns

```rust
// All of these avoid bounds checks:

// zip - parallel iteration
for (a, b) in xs.iter().zip(ys.iter()) { ... }

// enumerate - index + value  
for (i, x) in data.iter().enumerate() { ... }

// windows - sliding window
for window in data.windows(3) { ... }

// chunks - fixed-size groups
for chunk in data.chunks(4) { ... }
for chunk in data.chunks_exact(4) { ... }  // Guarantees exact size

// split_at - divide slice
let (left, right) = data.split_at(mid);
```

### Split for Parallel Access

```rust
fn parallel_sum(data: &[i32]) -> i32 {
    // Split into independent chunks
    let (left, right) = data.split_at(data.len() / 2);
    
    // Process chunks without bounds checks
    let sum_left: i32 = left.iter().sum();
    let sum_right: i32 = right.iter().sum();
    
    sum_left + sum_right
}
```

### get_unchecked for Proven Safety

```rust
fn matrix_multiply(a: &[f64], b: &[f64], c: &mut [f64], n: usize) {
    assert!(a.len() >= n * n);
    assert!(b.len() >= n * n);
    assert!(c.len() >= n * n);
    
    for i in 0..n {
        for j in 0..n {
            let mut sum = 0.0;
            for k in 0..n {
                // SAFETY: bounds verified by asserts above
                unsafe {
                    sum += a.get_unchecked(i * n + k) 
                         * b.get_unchecked(k * n + j);
                }
            }
            // SAFETY: bounds verified by asserts above
            unsafe {
                *c.get_unchecked_mut(i * n + j) = sum;
            }
        }
    }
}
```

### Slice Patterns

```rust
fn process_header(data: &[u8]) -> Option<Header> {
    // Slice pattern - single length check, no per-field checks
    let [a, b, c, d, rest @ ..] = data else {
        return None;
    };
    
    Some(Header {
        magic: *a,
        version: *b,
        flags: u16::from_le_bytes([*c, *d]),
        payload: rest,
    })
}
```

### Verify Bounds Check Elimination

```bash
### Check generated assembly
cargo asm --release my_crate::hot_function

### Look for 'cmp' and 'ja'/'jbe' instructions near array access
### If eliminated, you'll see direct memory access
```

### When to Accept Bounds Checks

```rust
// Random access patterns - checks unavoidable
fn random_lookup(data: &[u8], indices: &[usize]) -> Vec<u8> {
    indices.iter()
        .filter_map(|&i| data.get(i).copied())  // Checked, but necessary
        .collect()
}

// Infrequent access - overhead negligible
fn get_config(&self, key: &str) -> Option<&Value> {
    self.config.get(key)  // Fine, not hot path
}
```

### See Also

- [opt-simd-portable](#opt-simd-portable) - SIMD requires unchecked access
- [opt-cache-friendly](#opt-cache-friendly) - Cache-efficient patterns
- [perf-profile-first](#perf-profile-first) - Identify actual hot paths


## opt-cache-friendly

> Organize data for cache-efficient access patterns

### Why It Matters

Cache misses are expensive—a L3 cache miss costs ~100+ cycles vs ~4 cycles for L1 hit. Data layout and access patterns determine cache efficiency. Arrays of structs (AoS) vs structs of arrays (SoA), memory locality, and access patterns can make order-of-magnitude performance differences.

### Bad

```rust
// Array of Structs (AoS) - poor cache use when accessing one field
struct Particle {
    position: [f32; 3],  // 12 bytes
    velocity: [f32; 3],  // 12 bytes
    mass: f32,           // 4 bytes
    id: u64,             // 8 bytes
    flags: u8,           // 1 byte + padding
    // Total: 40 bytes per particle
}

fn update_positions(particles: &mut [Particle], dt: f32) {
    for p in particles {
        // Access position and velocity - 24 bytes
        // But loads 40-byte struct per particle
        // 16 bytes wasted per cache line load
        p.position[0] += p.velocity[0] * dt;
        p.position[1] += p.velocity[1] * dt;
        p.position[2] += p.velocity[2] * dt;
    }
}
```

### Good

```rust
// Struct of Arrays (SoA) - cache-efficient for field access
struct Particles {
    positions_x: Vec<f32>,
    positions_y: Vec<f32>,
    positions_z: Vec<f32>,
    velocities_x: Vec<f32>,
    velocities_y: Vec<f32>,
    velocities_z: Vec<f32>,
    masses: Vec<f32>,
    ids: Vec<u64>,
    flags: Vec<u8>,
}

fn update_positions(p: &mut Particles, dt: f32) {
    // Access contiguous memory - perfect cache utilization
    for (px, vx) in p.positions_x.iter_mut().zip(&p.velocities_x) {
        *px += vx * dt;
    }
    for (py, vy) in p.positions_y.iter_mut().zip(&p.velocities_y) {
        *py += vy * dt;
    }
    for (pz, vz) in p.positions_z.iter_mut().zip(&p.velocities_z) {
        *pz += vz * dt;
    }
}
```

### Hot/Cold Splitting

```rust
// Separate frequently and rarely accessed fields
struct EntityHot {
    position: [f32; 3],
    velocity: [f32; 3],
    // Hot data - accessed every frame
}

struct EntityCold {
    name: String,
    creation_time: Instant,
    metadata: HashMap<String, Value>,
    // Cold data - rarely accessed
}

struct Entities {
    hot: Vec<EntityHot>,
    cold: Vec<EntityCold>,
}

// Hot loop touches only hot data
fn update(entities: &mut Entities, dt: f32) {
    for e in &mut entities.hot {
        e.position[0] += e.velocity[0] * dt;
        // Cold data stays out of cache
    }
}
```

### Prefetching

```rust
// Process in cache-line-sized chunks
const CACHE_LINE: usize = 64;

fn process_with_prefetch(data: &mut [u8]) {
    for chunk in data.chunks_mut(CACHE_LINE) {
        // Prefetch next chunk while processing current
        // (automatic in many cases, manual for complex patterns)
        process_chunk(chunk);
    }
}

// Matrix multiplication - block for cache
fn matmul_blocked(a: &[f64], b: &[f64], c: &mut [f64], n: usize) {
    const BLOCK: usize = 32;  // Fits in L1 cache
    
    for i0 in (0..n).step_by(BLOCK) {
        for j0 in (0..n).step_by(BLOCK) {
            for k0 in (0..n).step_by(BLOCK) {
                // Process BLOCK x BLOCK tile
                for i in i0..min(i0 + BLOCK, n) {
                    for j in j0..min(j0 + BLOCK, n) {
                        // Inner loop operates on cached data
                    }
                }
            }
        }
    }
}
```

### Avoid Pointer Chasing

```rust
// Bad: linked list - random memory access
struct Node {
    value: i32,
    next: Option<Box<Node>>,
}

fn sum_linked(head: &Node) -> i32 {
    // Each node is a cache miss
}

// Good: contiguous vector
fn sum_vector(data: &[i32]) -> i32 {
    data.iter().sum()  // Sequential access, prefetcher happy
}

// Good: if graph needed, use indices
struct Graph {
    values: Vec<i32>,
    edges: Vec<usize>,  // Indices into values
}
```

### Memory Layout Attributes

```rust
// Ensure cache-line alignment
#[repr(C, align(64))]
struct CacheAligned {
    data: [u8; 64],
}

// Prevent false sharing in concurrent code
#[repr(C, align(64))]
struct PaddedCounter {
    value: AtomicU64,
    _pad: [u8; 56],
}
```

### Measuring Cache Performance

```bash
### Linux perf
perf stat -e cache-references,cache-misses ./my_program

### Detailed cache analysis
perf stat -e L1-dcache-loads,L1-dcache-load-misses,LLC-loads,LLC-load-misses ./my_program

### Cachegrind
valgrind --tool=cachegrind ./my_program
```

### See Also

- [mem-smaller-integers](#mem-smaller-integers) - Smaller data fits more in cache
- [mem-box-large-variant](#mem-box-large-variant) - Keep enum sizes small
- [opt-bounds-check](#opt-bounds-check) - Sequential access patterns


## opt-codegen-units

> Set `codegen-units = 1` for maximum optimization in release builds

### Why It Matters

By default, Cargo splits code into multiple codegen units for parallel compilation. This speeds up builds but prevents some cross-unit optimizations. Setting `codegen-units = 1` allows LLVM to optimize across the entire crate, potentially improving runtime performance by 5-20% at the cost of slower builds.

### Bad

```toml
### Cargo.toml - default settings
[profile.release]
### codegen-units defaults to 16
### Fast to compile, but misses optimization opportunities
```

### Good

```toml
### Cargo.toml - optimized for runtime performance
[profile.release]
codegen-units = 1  # Single unit = better optimization
lto = true         # Link-time optimization
opt-level = 3      # Maximum optimization
```

### What codegen-units Affects

| Codegen Units | Compile Time | Runtime Performance | Memory Use |
|---------------|--------------|---------------------|------------|
| 16 (default)  | Faster       | Baseline            | Lower      |
| 4-8           | Moderate     | Slightly better     | Moderate   |
| 1             | Slower       | Best                | Higher     |

### How It Works

```rust
// With codegen-units = 16:
// - Crate split into 16 independent compilation units
// - Compiled in parallel
// - Limited visibility between units for optimization

// With codegen-units = 1:
// - Entire crate in single unit
// - LLVM sees all code at once
// - Can inline across module boundaries
// - Better dead code elimination
// - Better constant propagation
```

### Full Release Profile

```toml
[profile.release]
### Maximum runtime performance
opt-level = 3
lto = "fat"
codegen-units = 1
panic = "abort"      # Smaller binary, slight perf gain
strip = true         # Smaller binary

[profile.release-with-debug]
### Performance with debugging ability
inherits = "release"
debug = true         # Keep debug symbols
strip = false

[profile.bench]
### For benchmarking
inherits = "release"
```

### Build Time Trade-offs

```bash
### Default release build (fast compile)
cargo build --release
### Time: ~30s

### Optimized release build (slow compile, fast runtime)
### With codegen-units = 1, lto = "fat"
cargo build --release
### Time: ~2-5min, but potentially 10-20% faster binary
```

### Per-Profile Configuration

```toml
### Fast debug builds
[profile.dev]
codegen-units = 256  # Maximum parallelism

### Fast CI builds
[profile.ci]
inherits = "release"
codegen-units = 16   # Balance compile time vs runtime
lto = "thin"         # Faster than "fat"

### Production release
[profile.production]
inherits = "release"
codegen-units = 1
lto = "fat"
```

### When to Use What

```rust
// codegen-units = 16 (default)
// - Development builds
// - CI where compile time matters
// - When runtime performance isn't critical

// codegen-units = 1
// - Production deployments
// - Performance-critical applications
// - Final releases
// - Benchmarking
```

### Measuring Impact

```bash
### Build with different settings
cargo build --release

### Benchmark
cargo bench

### Compare binary sizes
ls -lh target/release/my_binary

### Profile runtime
perf stat ./target/release/my_binary
```

### See Also

- [opt-lto-release](#opt-lto-release) - Link-time optimization
- [opt-pgo-profile](#opt-pgo-profile) - Profile-guided optimization
- [opt-target-cpu](#opt-target-cpu) - CPU-specific optimization


## opt-cold-unlikely

> Mark unlikely code paths with `#[cold]` to help compiler optimization

### Why It Matters

The `#[cold]` attribute tells the compiler that a function is rarely called. The compiler uses this to optimize code layout—keeping cold code away from hot code improves instruction cache utilization. Combined with branch layout optimization, this can measurably improve performance.

### Bad

```rust
// All branches treated equally
fn validate(input: &str) -> Result<Data, ValidationError> {
    if input.is_empty() {
        return Err(ValidationError::Empty);  // Rare
    }
    
    if input.len() > 1000 {
        return Err(ValidationError::TooLong);  // Rare  
    }
    
    if !input.is_ascii() {
        return Err(ValidationError::NonAscii);  // Rare
    }
    
    // This is the common case
    Ok(parse_data(input))
}
```

### Good

```rust
fn validate(input: &str) -> Result<Data, ValidationError> {
    if input.is_empty() {
        return cold_empty_error();
    }
    
    if input.len() > 1000 {
        return cold_too_long_error();
    }
    
    if !input.is_ascii() {
        return cold_non_ascii_error();
    }
    
    Ok(parse_data(input))
}

#[cold]
fn cold_empty_error() -> Result<Data, ValidationError> {
    Err(ValidationError::Empty)
}

#[cold]
fn cold_too_long_error() -> Result<Data, ValidationError> {
    Err(ValidationError::TooLong)
}

#[cold]
fn cold_non_ascii_error() -> Result<Data, ValidationError> {
    Err(ValidationError::NonAscii)
}
```

### What #[cold] Does

1. **Code placement**: Cold functions are placed in separate code sections, away from hot code
2. **Branch prediction**: Compiler generates branch hints favoring the non-cold path
3. **Inlining decisions**: Cold functions are not inlined into hot paths
4. **Optimization budget**: Compiler spends less effort optimizing cold code

### Common Cold Patterns

```rust
// Error handling
#[cold]
fn handle_error<E: std::fmt::Display>(e: E) -> ! {
    eprintln!("Fatal error: {}", e);
    std::process::exit(1);
}

// Logging rare events
#[cold]
fn log_rare_event(event: &Event) {
    log::warn!("Rare event occurred: {:?}", event);
}

// Fallback paths
#[cold]
fn slow_fallback(data: &Data) -> Output {
    // This path should rarely be taken
    compute_slowly(data)
}

// Panic handlers
#[cold]
fn panic_invalid_state(state: &State) -> ! {
    panic!("Invalid state: {:?}", state);
}
```

### Assertions and Invariants

```rust
fn get_unchecked(&self, index: usize) -> &T {
    if index >= self.len {
        cold_bounds_panic(index, self.len);
    }
    unsafe { &*self.ptr.add(index) }
}

#[cold]
#[inline(never)]
fn cold_bounds_panic(index: usize, len: usize) -> ! {
    panic!("index out of bounds: the len is {} but the index is {}", len, index);
}
```

### Combining with #[inline(never)]

```rust
// Usually combine both for maximum effect
#[cold]
#[inline(never)]
fn error_path() -> Error {
    // Complex error construction stays out of hot code
    Error {
        backtrace: Backtrace::capture(),
        context: gather_context(),
    }
}
```

### Measuring Impact

```rust
// Check code layout with objdump
// objdump -d target/release/binary | less

// Look for .cold sections
// nm target/release/binary | grep cold

// Profile to verify improvement
// perf stat -e cache-misses,cache-references ./binary
```

### See Also

- [opt-inline-never-cold](#opt-inline-never-cold) - Combining with inline(never)
- [opt-likely-hint](#opt-likely-hint) - Branch prediction hints
- [err-result-over-panic](#err-result-over-panic) - Error handling


## opt-inline-always-rare

> Use `#[inline(always)]` sparingly—only for critical hot paths proven by profiling

### Why It Matters

`#[inline(always)]` forces the compiler to inline a function regardless of heuristics. Overuse increases binary size, hurts instruction cache, and can slow down code. The compiler is usually smarter about inlining than humans. Reserve this for measured hot paths where benchmarks prove a benefit.

### Bad

```rust
// Annotating everything - trusting intuition over data
#[inline(always)]
pub fn get_name(&self) -> &str {
    &self.name
}

#[inline(always)]
pub fn calculate_tax(amount: f64) -> f64 {
    amount * 0.1
}

#[inline(always)]
fn helper(x: i32) -> i32 {
    x + 1
}

// Result: bloated binary, poor cache utilization
```

### Good

```rust
// Let compiler decide for most functions
pub fn get_name(&self) -> &str {
    &self.name
}

pub fn calculate_tax(amount: f64) -> f64 {
    amount * 0.1
}

// Only force inline for proven hot paths
impl Hasher for MyHasher {
    // Hasher::write is called millions of times in tight loops
    // Profiling showed 15% improvement from forced inlining
    #[inline(always)]
    fn write(&mut self, bytes: &[u8]) {
        // Very small, very hot
        self.state = self.state.wrapping_add(bytes.len() as u64);
    }
}
```

### When #[inline(always)] Helps

```rust
// ✅ Tiny functions in hot inner loops
#[inline(always)]
fn fast_hash(a: u64, b: u64) -> u64 {
    a.wrapping_mul(b).wrapping_add(a)
}

// ✅ Generic functions that benefit from monomorphization
#[inline(always)]
fn swap<T>(a: &mut T, b: &mut T) {
    std::mem::swap(a, b);
}

// ✅ Iterator adapters and closures
#[inline(always)]
fn apply<T, F: Fn(T) -> T>(f: F, x: T) -> T {
    f(x)
}

// ✅ SIMD/vectorization helpers
#[inline(always)]
fn add_simd(a: &[f32], b: &[f32], out: &mut [f32]) {
    // ...
}
```

### Inline Variants

```rust
// #[inline] - hint to inline, compiler may ignore
#[inline]
fn suggested_inline(x: i32) -> i32 { x + 1 }

// #[inline(always)] - force inline (almost always)
#[inline(always)]
fn force_inline(x: i32) -> i32 { x + 1 }

// #[inline(never)] - prevent inlining (for profiling, code size)
#[inline(never)]
fn no_inline(x: i32) -> i32 { x + 1 }

// No annotation - compiler decides based on heuristics
fn compiler_decides(x: i32) -> i32 { x + 1 }
```

### Measuring Inline Impact

```rust
// Use criterion to benchmark
use criterion::{criterion_group, criterion_main, Criterion};

fn bench_with_inline(c: &mut Criterion) {
    c.bench_function("hot_path_inline", |b| {
        b.iter(|| hot_loop())
    });
}

// Compare binary sizes
// cargo bloat --release --crates

// Check if function was inlined
// cargo asm --rust my_crate::hot_function
```

### Generic Functions

```rust
// Generic functions across crate boundaries often need #[inline]
// Because the generic code is compiled in the calling crate

// In library crate:
#[inline]  // Allow inlining in downstream crates
pub fn generic_function<T: Display>(x: T) {
    println!("{}", x);
}

// Without #[inline], the generic function can't be inlined
// across crate boundaries even if beneficial
```

### See Also

- [opt-inline-small](#opt-inline-small) - Regular inline for small functions
- [opt-inline-never-cold](#opt-inline-never-cold) - Preventing inlining
- [perf-profile-first](#perf-profile-first) - Profile before optimizing


## opt-inline-never-cold

> Use `#[inline(never)]` and `#[cold]` for error paths and rarely-executed code

### Why It Matters

Inlining error handling code into hot paths wastes instruction cache space and can prevent other optimizations. `#[inline(never)]` keeps cold code out of the hot path. `#[cold]` tells the compiler this branch is unlikely, enabling better branch prediction hints and code layout.

### Bad

```rust
fn process_data(data: &[u8]) -> Result<Output, Error> {
    if data.is_empty() {
        // Error path inlined into hot function
        return Err(Error::Empty {
            context: format!("Expected data, got empty slice"),
            suggestions: vec!["Check input", "Validate before calling"],
        });
    }
    
    // Hot path - now polluted with error construction code
    do_processing(data)
}
```

### Good

```rust
fn process_data(data: &[u8]) -> Result<Output, Error> {
    if data.is_empty() {
        return Err(empty_data_error());  // Cold path stays small
    }
    
    do_processing(data)
}

#[cold]
#[inline(never)]
fn empty_data_error() -> Error {
    Error::Empty {
        context: format!("Expected data, got empty slice"),
        suggestions: vec!["Check input", "Validate before calling"],
    }
}
```

### #[cold] for Unlikely Branches

```rust
fn parse_value(input: &str) -> Result<i32, ParseError> {
    match input.parse() {
        Ok(n) => Ok(n),
        Err(e) => cold_parse_error(input, e),
    }
}

#[cold]
fn cold_parse_error(input: &str, e: std::num::ParseIntError) -> Result<i32, ParseError> {
    Err(ParseError {
        input: input.to_string(),
        source: e,
    })
}
```

### Panic Paths

```rust
fn get_index(&self, idx: usize) -> &T {
    if idx >= self.len {
        cold_out_of_bounds(idx, self.len);
    }
    unsafe { self.ptr.add(idx).as_ref().unwrap() }
}

#[cold]
#[inline(never)]
fn cold_out_of_bounds(idx: usize, len: usize) -> ! {
    panic!("index {} out of bounds for length {}", idx, len);
}
```

### Error Construction Functions

```rust
// Keep error construction out of hot path
impl MyError {
    #[cold]
    pub fn io_error(source: std::io::Error, path: &Path) -> Self {
        MyError::Io {
            source,
            path: path.to_path_buf(),
            context: get_context(),
        }
    }
    
    #[cold]
    pub fn validation_error(msg: &str, field: &str) -> Self {
        MyError::Validation {
            message: msg.to_string(),
            field: field.to_string(),
        }
    }
}

fn read_config(path: &Path) -> Result<Config, MyError> {
    std::fs::read_to_string(path)
        .map_err(|e| MyError::io_error(e, path))?
        .parse()
        .map_err(|e| MyError::parse_error(e))
}
```

### likely/unlikely Hints

```rust
// Nightly: intrinsics for branch hints
#![feature(core_intrinsics)]
use std::intrinsics::{likely, unlikely};

fn process(data: Option<&Data>) -> Result<Output, Error> {
    if unlikely(data.is_none()) {
        return cold_none_error();
    }
    
    let data = data.unwrap();
    
    if likely(data.is_valid()) {
        fast_process(data)
    } else {
        slow_validate_and_process(data)
    }
}

// Stable alternative: structure code so hot path is "fall through"
fn process(data: Option<&Data>) -> Result<Output, Error> {
    let data = match data {
        Some(d) => d,
        None => return cold_none_error(),  // Early return = unlikely hint
    };
    
    // Compiler assumes code after early returns is "hot"
    fast_process(data)
}
```

### Pattern: Extract Cold Code

```rust
// Before: cold code inline
fn hot_function(x: i32) -> i32 {
    if x < 0 {
        log::error!("Negative value: {}", x);
        eprintln!("Debug info: {:?}", std::backtrace::Backtrace::capture());
        return 0;
    }
    x * 2
}

// After: cold code extracted
fn hot_function(x: i32) -> i32 {
    if x < 0 {
        return handle_negative(x);
    }
    x * 2
}

#[cold]
#[inline(never)]
fn handle_negative(x: i32) -> i32 {
    log::error!("Negative value: {}", x);
    eprintln!("Debug info: {:?}", std::backtrace::Backtrace::capture());
    0
}
```

### See Also

- [opt-inline-small](#opt-inline-small) - Inlining for hot code
- [opt-inline-always-rare](#opt-inline-always-rare) - Forced inlining
- [err-result-over-panic](#err-result-over-panic) - Error handling patterns


## opt-inline-small

> Use `#[inline]` for small hot functions

### Why It Matters

Function call overhead (stack frame setup, register saves, jumps) can dominate small functions. Inlining eliminates this overhead and enables further optimizations by the compiler. The compiler often inlines automatically, but hints help for cross-crate calls.

### Bad

```rust
// Small hot function without inline hint
// May not be inlined across crate boundaries
fn is_ascii_digit(b: u8) -> bool {
    b >= b'0' && b <= b'9'
}

// Called millions of times
for byte in data {
    if is_ascii_digit(*byte) {  // Function call overhead
        count += 1;
    }
}
```

### Good

```rust
#[inline]
fn is_ascii_digit(b: u8) -> bool {
    b >= b'0' && b <= b'9'
}

// Now the compiler will inline this
for byte in data {
    if is_ascii_digit(*byte) {  // Inlined, no call overhead
        count += 1;
    }
}
```

### Inline Attributes

```rust
// No attribute - compiler decides (usually good for same-crate)
fn auto_decide() { }

// Suggest inlining - helps cross-crate
#[inline]
fn suggest_inline() { }

// Strongly suggest inlining - almost always inlined
#[inline(always)]
fn force_inline() { }

// Strongly suggest NOT inlining - for large/cold code
#[inline(never)]
fn prevent_inline() { }
```

### When to Use Each

```rust
// #[inline] - Small functions, especially in libraries
#[inline]
pub fn len(&self) -> usize {
    self.inner.len()
}

// #[inline(always)] - Critical hot path, verified by profiling
#[inline(always)]
fn hot_inner_loop_helper(x: u32) -> u32 {
    x.wrapping_mul(0x9E3779B9)
}

// #[inline(never)] - Error handlers, cold paths
#[inline(never)]
fn handle_error(err: Error) -> ! {
    eprintln!("Fatal: {}", err);
    std::process::exit(1);
}

// No attribute - large functions, infrequent calls
fn complex_processing(data: &mut Data) {
    // Many lines of code...
}
```

### Evidence from ripgrep

```rust
// https://github.com/BurntSushi/ripgrep/blob/master/crates/printer/src/standard.rs

#[inline(always)]
fn write_prelude(
    &self,
    absolute_byte_offset: u64,
    line_number: Option<u64>,
    column: Option<u64>,
) -> io::Result<()> {
    // Hot path in printing matches
}

#[inline(always)]
fn write_line(&self, line: &[u8]) -> io::Result<()> {
    // Called for every line
}
```

### Generic Functions

```rust
// Generic functions are already candidates for per-monomorphization inlining
// But #[inline] helps ensure it across crates

#[inline]
pub fn min<T: Ord>(a: T, b: T) -> T {
    if a < b { a } else { b }
}
```

### Cautions

```rust
// DON'T inline large functions - hurts instruction cache
#[inline(always)]  // BAD for large function
fn large_complex_function(data: &mut [u8]) {
    // 100+ lines of code
    // Inlining bloats every call site
}

// DON'T assume inlining always helps - measure!
// Sometimes the compiler makes better decisions

// Inlining is non-transitive
#[inline]
fn outer() {
    inner();  // inner() also needs #[inline] to be inlined together
}

fn inner() { }  // Won't be inlined at outer's call sites
```

### Verifying Inlining

```bash
### Check if function was inlined using Cachegrind
### Non-inlined functions show entry/exit counts

### Or examine assembly
cargo rustc --release -- --emit=asm
### Look for call instructions vs inlined code
```

### See Also

- [opt-inline-always-rare](#opt-inline-always-rare) - Use #[inline(always)] sparingly
- [opt-inline-never-cold](#opt-inline-never-cold) - Use #[inline(never)] for cold paths
- [opt-cold-unlikely](#opt-cold-unlikely) - Use #[cold] for unlikely paths
- [opt-lto-release](#opt-lto-release) - LTO enables cross-crate inlining


## opt-likely-hint

> Use code structure to hint at likely branches; use intrinsics on nightly

### Why It Matters

Modern CPUs predict branches to speculatively execute code. Mispredictions cause pipeline stalls (10-20 cycles). Helping the compiler understand which branches are likely allows it to generate optimal code layout and branch hints, improving performance in hot paths.

### Stable Rust: Code Structure Hints

```rust
// Pattern 1: Early returns for unlikely cases
fn process(data: Option<&Data>) -> i32 {
    // Compiler assumes early return is "unlikely"
    let data = match data {
        None => return 0,  // Unlikely
        Some(d) => d,
    };
    
    // Hot path continues here
    complex_processing(data)
}

// Pattern 2: if-else ordering
fn calculate(x: i32) -> i32 {
    if x >= 0 {
        // Put likely case in "if" branch
        x * 2
    } else {
        // Unlikely case in "else"
        handle_negative(x)
    }
}

// Pattern 3: Cold function extraction
fn hot_path(data: &[u8]) -> Result<(), Error> {
    if data.is_empty() {
        return cold_empty_error();  // Extracted = unlikely
    }
    
    process_fast(data)
}

#[cold]
fn cold_empty_error() -> Result<(), Error> {
    Err(Error::EmptyInput)
}
```

### Nightly: Intrinsics

```rust
#![feature(core_intrinsics)]
use std::intrinsics::{likely, unlikely};

fn process(data: &Data) -> i32 {
    if unlikely(data.is_corrupted()) {
        return handle_corruption(data);
    }
    
    if likely(data.is_cached()) {
        return fast_cached_path(data);
    }
    
    slow_uncached_path(data)
}
```

### Boolean Likely Wrapper (Nightly)

```rust
#![feature(core_intrinsics)]

#[inline(always)]
fn likely(b: bool) -> bool {
    std::intrinsics::likely(b)
}

#[inline(always)]
fn unlikely(b: bool) -> bool {
    std::intrinsics::unlikely(b)
}

// Usage
if likely(x > 0) {
    hot_path(x)
} else {
    cold_path(x)
}
```

### Stable: likely-stable Crate

```rust
use likely_stable::{likely, unlikely};

fn check(value: i32) -> bool {
    if unlikely(value < 0) {
        handle_negative()
    } else if likely(value < 1000) {
        handle_common()
    } else {
        handle_large()
    }
}
```

### Loop Optimization

```rust
fn search(data: &[i32], target: i32) -> Option<usize> {
    for (i, &item) in data.iter().enumerate() {
        // Assume most iterations DON'T find the target
        if unlikely(item == target) {
            return Some(i);
        }
    }
    None
}

// Alternative: structure for likely case
fn search_common(data: &[i32], target: i32) -> Option<usize> {
    // If target is usually found
    for (i, &item) in data.iter().enumerate() {
        if likely(item == target) {
            return Some(i);
        }
    }
    None
}
```

### Match Arm Ordering

```rust
// Put most common variants first
fn process_message(msg: Message) {
    match msg {
        // Most common - listed first
        Message::Data(d) => handle_data(d),
        Message::Heartbeat => (), // Second most common
        
        // Rare cases last
        Message::Error(e) => handle_error(e),
        Message::Shutdown => shutdown(),
    }
}
```

### Benchmark-Driven Hints

```rust
// Profile first to know which branches are actually likely!
fn speculative(x: i32) -> i32 {
    // DON'T GUESS - measure with profiling
    // perf record / perf report
    // cargo flamegraph
    
    if x > threshold {  // Is this actually common?
        path_a(x)
    } else {
        path_b(x)
    }
}
```

### See Also

- [opt-cold-unlikely](#opt-cold-unlikely) - #[cold] for unlikely functions
- [opt-inline-never-cold](#opt-inline-never-cold) - Keeping cold code separate
- [perf-profile-first](#perf-profile-first) - Profile to know what's likely


## opt-lto-release

> Enable LTO in release builds

### Why It Matters

Link-Time Optimization (LTO) enables optimizations across crate boundaries that aren't possible during normal compilation. This includes cross-crate inlining, dead code elimination, and devirtualization. Typically provides 5-20% performance improvement.

### Bad

```toml
### Cargo.toml - default release profile
[profile.release]
opt-level = 3
### No LTO = missed optimization opportunities
```

### Good

```toml
### Cargo.toml - optimized release profile
[profile.release]
opt-level = 3
lto = "fat"          # Maximum optimization
codegen-units = 1    # Better optimization (single codegen unit)
panic = "abort"      # Smaller binary, no unwind tables
strip = true         # Remove symbols for smaller binary
```

### LTO Options Explained

```toml
### No LTO (default)
lto = false

### Thin LTO - fast compilation, most benefits
lto = "thin"

### Fat LTO - slowest compilation, maximum optimization
lto = "fat"
### Equivalent to:
lto = true

### Thin-local - LTO within each crate only
lto = "off"
```

### Trade-offs

| Setting | Compile Time | Binary Size | Performance |
|---------|--------------|-------------|-------------|
| `lto = false` | Fast | Larger | Baseline |
| `lto = "thin"` | Medium | Smaller | +5-15% |
| `lto = "fat"` | Slow | Smallest | +10-20% |

### Evidence from Production

```toml
### From Anchor (Solana framework)
### https://github.com/solana-foundation/anchor/blob/master/cli/src/rust_template.rs
[profile.release]
overflow-checks = true
lto = "fat"
codegen-units = 1

### From sol-trade-sdk
### https://github.com/0xfnzero/sol-trade-sdk
[profile.release]
opt-level = 3
lto = "fat"
codegen-units = 1
panic = "abort"
```

### Complete Optimized Profile

```toml
[profile.release]
opt-level = 3        # Maximum optimization
lto = "fat"          # Link-time optimization
codegen-units = 1    # Single codegen unit for better optimization
panic = "abort"      # Remove panic unwinding code
strip = true         # Strip symbols
debug = false        # No debug info

### For benchmarking (need some debug info for profiling)
[profile.bench]
inherits = "release"
debug = true
strip = false

### Fast dev builds with optimized dependencies
[profile.dev]
opt-level = 0
debug = true

[profile.dev.package."*"]
opt-level = 3        # Optimize dependencies even in dev
```

### When to Use Each

| Situation | LTO Setting |
|-----------|-------------|
| Development | `false` (fast compiles) |
| CI builds | `"thin"` (balance) |
| Release binaries | `"fat"` (max perf) |
| Libraries (crates.io) | `false` (users choose) |

### Measuring Impact

```bash
### Build without LTO
cargo build --release
hyperfine ./target/release/myapp

### Build with LTO
### (after adding lto = "fat" to Cargo.toml)
cargo build --release
hyperfine ./target/release/myapp

### Compare binary sizes
ls -la target/release/myapp
```

### See Also

- [opt-codegen-units](#opt-codegen-units) - Use codegen-units = 1
- [opt-pgo-profile](#opt-pgo-profile) - Profile-guided optimization
- [perf-release-profile](#perf-release-profile) - Full release profile settings


## opt-pgo-profile

> Use Profile-Guided Optimization (PGO) for maximum performance

### Why It Matters

PGO uses real runtime behavior to guide compiler optimization decisions. By profiling actual workloads, the compiler learns which code paths are hot, optimizing them aggressively while deprioritizing cold paths. This can yield 10-30% performance improvements beyond standard optimizations.

### The PGO Process

1. **Instrument**: Build with profiling instrumentation
2. **Profile**: Run representative workloads
3. **Optimize**: Rebuild using collected profile data

### Step-by-Step

```bash
### Step 1: Build instrumented binary
RUSTFLAGS="-Cprofile-generate=/tmp/pgo-data" \
    cargo build --release

### Step 2: Run representative workloads
./target/release/my_app < test_data_1.txt
./target/release/my_app < test_data_2.txt
./target/release/my_app < typical_workload.txt

### Step 3: Merge profile data
llvm-profdata merge -o /tmp/pgo-data/merged.profdata /tmp/pgo-data

### Step 4: Build optimized binary using profile
RUSTFLAGS="-Cprofile-use=/tmp/pgo-data/merged.profdata" \
    cargo build --release
```

### Cargo Configuration

```toml
### Cargo.toml
[profile.release]
lto = "fat"
codegen-units = 1
opt-level = 3

### PGO flags set via RUSTFLAGS environment variable
```

### Build Script

```bash
#!/bin/bash
set -e

PGO_DIR=/tmp/pgo-$(date +%s)

### Clean
cargo clean

### Instrumented build
echo "Building instrumented binary..."
RUSTFLAGS="-Cprofile-generate=$PGO_DIR" cargo build --release

### Run workloads
echo "Collecting profile data..."
./target/release/my_app --benchmark-mode
./target/release/my_app < test_fixtures/typical.txt
./target/release/my_app < test_fixtures/stress.txt

### Merge profiles
echo "Merging profile data..."
llvm-profdata merge -o $PGO_DIR/merged.profdata $PGO_DIR

### Optimized build
echo "Building optimized binary..."
RUSTFLAGS="-Cprofile-use=$PGO_DIR/merged.profdata" cargo build --release

echo "Done! Optimized binary at target/release/my_app"
```

### Representative Workloads

```rust
// Create benchmarks that match real usage patterns

// Good: actual data samples
fn profile_workload() {
    for file in real_customer_data_samples() {
        process_file(&file);
    }
}

// Good: synthetic but realistic
fn profile_synthetic() {
    for _ in 0..10000 {
        let data = generate_realistic_data();
        process(&data);
    }
}

// Bad: artificial microbenchmarks
fn profile_bad() {
    for _ in 0..1000000 {
        small_operation();  // Doesn't reflect real hot paths
    }
}
```

### BOLT Post-Link Optimization

For even more gains, combine PGO with BOLT:

```bash
### After PGO build, apply BOLT
llvm-bolt target/release/my_app \
    -o target/release/my_app.bolt \
    -data=perf.data \
    -reorder-blocks=ext-tsp \
    -reorder-functions=hfsort

### BOLT can add another 5-15% on top of PGO
```

### CI/CD Integration

```yaml
### GitHub Actions example
jobs:
  pgo-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install LLVM tools
        run: sudo apt-get install llvm
      
      - name: Instrumented build
        run: RUSTFLAGS="-Cprofile-generate=/tmp/pgo" cargo build --release
      
      - name: Run profiling workloads
        run: ./scripts/run_profiling_workloads.sh
      
      - name: Merge profiles
        run: llvm-profdata merge -o /tmp/pgo/merged.profdata /tmp/pgo
      
      - name: Optimized build
        run: RUSTFLAGS="-Cprofile-use=/tmp/pgo/merged.profdata" cargo build --release
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: optimized-binary
          path: target/release/my_app
```

### When to Use PGO

| Use PGO | Skip PGO |
|---------|----------|
| Production deployments | Development builds |
| Performance-critical apps | Libraries (users can PGO) |
| Stable workload patterns | Highly variable workloads |
| Sufficient profiling data | Quick iteration cycles |

### See Also

- [opt-lto-release](#opt-lto-release) - LTO works well with PGO
- [opt-codegen-units](#opt-codegen-units) - Single codegen unit for PGO
- [perf-profile-first](#perf-profile-first) - Profiling basics


## opt-simd-portable

> Use portable SIMD for vectorized operations across architectures

### Why It Matters

SIMD (Single Instruction, Multiple Data) processes multiple values per instruction—4x, 8x, or more speedup for suitable algorithms. Rust's portable SIMD (nightly) and crates like `wide` provide cross-platform vectorization without architecture-specific intrinsics. For stable Rust, let LLVM auto-vectorize or use platform-specific crates.

### Autovectorization (Stable)

```rust
// LLVM often vectorizes simple patterns automatically
fn sum(data: &[f32]) -> f32 {
    data.iter().sum()  // May vectorize to SIMD
}

fn add_arrays(a: &[f32], b: &[f32], out: &mut [f32]) {
    for ((x, y), o) in a.iter().zip(b).zip(out.iter_mut()) {
        *o = x + y;  // Often vectorizes
    }
}

// Help autovectorization:
// 1. Use iterators over indexing
// 2. Avoid early exits in loops
// 3. Use chunks_exact for aligned access
```

### Portable SIMD (Nightly)

```rust
#![feature(portable_simd)]
use std::simd::*;

fn sum_simd(data: &[f32]) -> f32 {
    let (prefix, middle, suffix) = data.as_simd::<8>();
    
    // Handle unaligned prefix
    let mut sum = prefix.iter().sum::<f32>();
    
    // SIMD loop - 8 floats at a time
    let mut simd_sum = f32x8::splat(0.0);
    for chunk in middle {
        simd_sum += *chunk;
    }
    sum += simd_sum.reduce_sum();
    
    // Handle unaligned suffix
    sum += suffix.iter().sum::<f32>();
    
    sum
}

fn dot_product(a: &[f32], b: &[f32]) -> f32 {
    assert_eq!(a.len(), b.len());
    
    let (a_pre, a_mid, a_suf) = a.as_simd::<8>();
    let (b_pre, b_mid, b_suf) = b.as_simd::<8>();
    
    let scalar: f32 = a_pre.iter().zip(b_pre).map(|(x, y)| x * y).sum();
    
    let mut simd_sum = f32x8::splat(0.0);
    for (av, bv) in a_mid.iter().zip(b_mid) {
        simd_sum += *av * *bv;
    }
    
    let suffix: f32 = a_suf.iter().zip(b_suf).map(|(x, y)| x * y).sum();
    
    scalar + simd_sum.reduce_sum() + suffix
}
```

### wide Crate (Stable)

```rust
use wide::*;

fn process_simd(data: &mut [f32]) {
    // Process 8 floats at a time
    for chunk in data.chunks_exact_mut(8) {
        let v = f32x8::from(chunk);
        let result = v * f32x8::splat(2.0) + f32x8::splat(1.0);
        chunk.copy_from_slice(&result.to_array());
    }
}

fn blend_images(a: &[u8], b: &[u8], alpha: f32, out: &mut [u8]) {
    let alpha_v = f32x8::splat(alpha);
    let one_minus = f32x8::splat(1.0 - alpha);
    
    for ((a_chunk, b_chunk), out_chunk) in 
        a.chunks_exact(8).zip(b.chunks_exact(8)).zip(out.chunks_exact_mut(8)) 
    {
        let av = f32x8::from([
            a_chunk[0] as f32, a_chunk[1] as f32, /* ... */
        ]);
        let bv = f32x8::from([
            b_chunk[0] as f32, b_chunk[1] as f32, /* ... */
        ]);
        
        let result = av * one_minus + bv * alpha_v;
        // Convert back to u8...
    }
}
```

### Platform-Specific (When Needed)

```rust
#[cfg(target_arch = "x86_64")]
use std::arch::x86_64::*;

#[cfg(target_arch = "x86_64")]
#[target_feature(enable = "avx2")]
unsafe fn sum_avx2(data: &[f32]) -> f32 {
    let mut sum = _mm256_setzero_ps();
    
    for chunk in data.chunks_exact(8) {
        let v = _mm256_loadu_ps(chunk.as_ptr());
        sum = _mm256_add_ps(sum, v);
    }
    
    // Horizontal sum
    let high = _mm256_extractf128_ps(sum, 1);
    let low = _mm256_castps256_ps128(sum);
    let sum128 = _mm_add_ps(high, low);
    // ... continue reduction
}
```

### Choosing an Approach

| Approach | Stability | Portability | Control |
|----------|-----------|-------------|---------|
| Autovectorization | Stable | Excellent | Low |
| `wide` crate | Stable | Good | Medium |
| Portable SIMD | Nightly | Excellent | High |
| Intrinsics | Stable | None | Maximum |

### See Also

- [opt-target-cpu](#opt-target-cpu) - Enable SIMD features
- [opt-bounds-check](#opt-bounds-check) - Unchecked access for SIMD
- [perf-profile-first](#perf-profile-first) - Identify vectorization opportunities


## opt-target-cpu

> Use `target-cpu=native` for maximum performance on known deployment targets

### Why It Matters

By default, Rust compiles for a generic x86-64 baseline (roughly Sandy Bridge era). Modern CPUs have SIMD extensions (AVX2, AVX-512), improved instructions, and micro-architectural optimizations that go unused. `target-cpu=native` enables all features of your current CPU, potentially unlocking significant speedups.

### Bad

```toml
### Cargo.toml - compiles for generic x86-64
[profile.release]
### No target-cpu specified
### Binary works everywhere but uses only SSE2
```

### Good

```toml
### .cargo/config.toml - for known deployment target
[build]
rustflags = ["-C", "target-cpu=native"]

### Or specific CPU for cross-compilation
### rustflags = ["-C", "target-cpu=skylake"]
```

### Via Environment

```bash
### Build with native optimizations
RUSTFLAGS="-C target-cpu=native" cargo build --release

### Check what features are enabled
rustc --print cfg -C target-cpu=native | grep target_feature
```

### Common Target CPUs

```bash
### x86-64 targets
target-cpu=native          # Current machine
target-cpu=x86-64          # Baseline (SSE2)
target-cpu=x86-64-v2       # SSE4.2, POPCNT
target-cpu=x86-64-v3       # AVX2, BMI2
target-cpu=x86-64-v4       # AVX-512

### Intel specific
target-cpu=skylake         # 6th gen Core
target-cpu=alderlake       # 12th gen Core

### AMD specific
target-cpu=znver3          # Zen 3
target-cpu=znver4          # Zen 4

### ARM
target-cpu=apple-m1        # Apple Silicon
target-cpu=neoverse-n1     # AWS Graviton2
```

### Feature Detection at Runtime

```rust
// For portable binaries that use native features when available
#[cfg(target_arch = "x86_64")]
fn process_fast(data: &[u8]) -> u64 {
    if is_x86_feature_detected!("avx2") {
        unsafe { process_avx2(data) }
    } else if is_x86_feature_detected!("sse4.2") {
        unsafe { process_sse42(data) }
    } else {
        process_generic(data)
    }
}

#[target_feature(enable = "avx2")]
unsafe fn process_avx2(data: &[u8]) -> u64 {
    // AVX2 optimized implementation
}
```

### Multi-Architecture Builds

```bash
### Build multiple binaries
RUSTFLAGS="-C target-cpu=x86-64" cargo build --release
mv target/release/app target/release/app-generic

RUSTFLAGS="-C target-cpu=x86-64-v3" cargo build --release
mv target/release/app target/release/app-avx2

### Select at runtime
if supports_avx2; then
    ./app-avx2
else
    ./app-generic
fi
```

### Cargo Configuration

```toml
### .cargo/config.toml

### Native builds for development
[target.x86_64-unknown-linux-gnu]
rustflags = ["-C", "target-cpu=native"]

### AWS deployment (Graviton2)
[target.aarch64-unknown-linux-gnu]
rustflags = ["-C", "target-cpu=neoverse-n1"]

### Intel server deployment
[target.x86_64-unknown-linux-gnu.deployment]
rustflags = ["-C", "target-cpu=skylake-avx512"]
```

### What Changes

```rust
// With AVX2 enabled:
// - 256-bit SIMD operations
// - Better autovectorization
// - FMA (fused multiply-add)
// - BMI (bit manipulation)

// Example: sum of squares
fn sum_squares(data: &[f64]) -> f64 {
    data.iter().map(|x| x * x).sum()
}
// Generic: scalar loop
// AVX2: processes 4 f64s per iteration
```

### Checking Enabled Features

```bash
### What's enabled for native?
rustc --print cfg -C target-cpu=native | grep feature

### Compare generic vs native
rustc --print cfg -C target-cpu=x86-64 | grep feature
rustc --print cfg -C target-cpu=native | grep feature

### View generated assembly
cargo asm --rust --release my_crate::hot_function
```

### See Also

- [opt-lto-release](#opt-lto-release) - Combine with LTO
- [opt-simd-portable](#opt-simd-portable) - Portable SIMD
- [opt-codegen-units](#opt-codegen-units) - Single codegen unit
