# Performance

> Loaded on demand from `SKILL.md` — one rule per `## <rule-id>` section.


## perf-black-box-bench

> Use black_box in benchmarks

### Why It Matters

The compiler aggressively optimizes code, potentially eliminating computations whose results aren't used. In benchmarks, this can lead to measuring nothing instead of the actual code. `std::hint::black_box()` prevents the compiler from optimizing away values, ensuring accurate measurements.

### Bad

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn benchmark_bad(c: &mut Criterion) {
    c.bench_function("compute", |b| {
        b.iter(|| {
            let result = expensive_computation(42);
            // Result unused - compiler may eliminate the call!
        });
    });
}

fn benchmark_also_bad(c: &mut Criterion) {
    let input = 42;  // Constant - compiler may precompute
    
    c.bench_function("compute", |b| {
        b.iter(|| {
            expensive_computation(input)
            // Return value may still be optimized away
        });
    });
}
```

### Good

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn benchmark_good(c: &mut Criterion) {
    c.bench_function("compute", |b| {
        b.iter(|| {
            // black_box on input prevents constant folding
            let result = expensive_computation(black_box(42));
            // black_box on output prevents dead code elimination
            black_box(result)
        });
    });
}

// Or simpler with Criterion's built-in support
fn benchmark_simpler(c: &mut Criterion) {
    c.bench_function("compute", |b| {
        b.iter(|| expensive_computation(black_box(42)))
    });
}
```

### What black_box Does

| Without black_box | With black_box |
|-------------------|----------------|
| Input may be constant-folded | Input treated as unknown |
| Result may be eliminated | Result must be computed |
| Loops may be optimized away | Each iteration runs |
| Functions may be inlined | Call semantics preserved |

### Standard Library Usage

```rust
use std::hint::black_box;

fn main() {
    // In std since Rust 1.66
    let result = black_box(compute_something(black_box(input)));
}
```

### Criterion's black_box

Criterion re-exports `std::hint::black_box`:

```rust
use criterion::black_box;

// Equivalent to std::hint::black_box
```

### Pattern: Benchmark with Setup

```rust
fn benchmark_with_setup(c: &mut Criterion) {
    c.bench_function("process_data", |b| {
        // Setup outside iter - not measured
        let data = generate_test_data(1000);
        
        b.iter(|| {
            // black_box the input reference
            let result = process(black_box(&data));
            black_box(result)
        });
    });
}
```

### Pattern: Benchmark Multiple Inputs

```rust
fn benchmark_sizes(c: &mut Criterion) {
    let mut group = c.benchmark_group("scaling");
    
    for size in [100, 1000, 10000] {
        let data = generate_data(size);
        
        group.bench_with_input(
            BenchmarkId::from_parameter(size),
            &data,
            |b, data| {
                b.iter(|| process(black_box(data)))
            },
        );
    }
    group.finish();
}
```

### Common Mistakes

```rust
// WRONG: black_box inside loop does nothing useful
for _ in 0..1000 {
    black_box(());  // Doesn't help
    compute();
}

// RIGHT: black_box the computation result
for _ in 0..1000 {
    black_box(compute());
}

// WRONG: Only blocking output, not input
let x = 42;  // Constant, may be optimized
black_box(expensive(x));

// RIGHT: Block both
black_box(expensive(black_box(42)));
```

### See Also

- [test-criterion-bench](#test-criterion-bench) - Using Criterion
- [perf-profile-first](#perf-profile-first) - Profile before optimize
- [perf-release-profile](#perf-release-profile) - Release settings


## perf-chain-avoid

> Avoid chain in hot loops

### Why It Matters

`Iterator::chain()` adds overhead for checking which iterator is active on every `.next()` call. In hot loops, this branch prediction overhead can impact performance. For performance-critical code, prefer single iterators or pre-combined collections.

### Bad

```rust
// Chain in hot inner loop
fn process_hot_path(a: &[i32], b: &[i32]) -> i64 {
    let mut sum = 0i64;
    
    // Called millions of times
    for _ in 0..1_000_000 {
        for x in a.iter().chain(b.iter()) {  // Branch every iteration
            sum += *x as i64;
        }
    }
    sum
}

// Chaining multiple small slices in tight loop
fn combine_results(parts: &[&[u8]]) -> Vec<u8> {
    let mut result = Vec::new();
    for part in parts {
        for byte in std::iter::once(&0u8).chain(part.iter()) {
            result.push(*byte);
        }
    }
    result
}
```

### Good

```rust
// Separate loops - branch-free inner loops
fn process_hot_path(a: &[i32], b: &[i32]) -> i64 {
    let mut sum = 0i64;
    
    for _ in 0..1_000_000 {
        for x in a {
            sum += *x as i64;
        }
        for x in b {
            sum += *x as i64;
        }
    }
    sum
}

// Pre-combine outside hot loop
fn combine_results(parts: &[&[u8]]) -> Vec<u8> {
    let mut result = Vec::new();
    for part in parts {
        result.push(0u8);
        result.extend_from_slice(part);
    }
    result
}
```

### When Chain Is Fine

Chain is perfectly acceptable when:

```rust
// One-time iteration, not in hot path
fn collect_all(a: Vec<i32>, b: Vec<i32>) -> Vec<i32> {
    a.into_iter().chain(b).collect()
}

// Lazy evaluation with short-circuit
fn find_in_either(a: &[Item], b: &[Item], target: i32) -> Option<&Item> {
    a.iter().chain(b.iter()).find(|x| x.id == target)
}

// Small number of elements
fn get_prefixes() -> impl Iterator<Item = &'static str> {
    ["Mr.", "Mrs.", "Dr."].iter().copied()
        .chain(["Prof."].iter().copied())
}
```

### Alternative Patterns

### Pre-allocate and Extend

```rust
fn merge_slices(slices: &[&[i32]]) -> Vec<i32> {
    let total: usize = slices.iter().map(|s| s.len()).sum();
    let mut result = Vec::with_capacity(total);
    for slice in slices {
        result.extend_from_slice(slice);
    }
    result
}
```

### Use append for Vecs

```rust
fn combine_vecs(mut a: Vec<i32>, mut b: Vec<i32>) -> Vec<i32> {
    a.append(&mut b);  // Moves elements, no reallocation if a has capacity
    a
}
```

### Flatten Instead of Chain

```rust
// Instead of: a.iter().chain(b.iter()).chain(c.iter())
let all = [a, b, c];
for item in all.iter().flat_map(|slice| slice.iter()) {
    process(item);
}
```

### Performance Impact

| Pattern | Per-Item Overhead |
|---------|-------------------|
| Single iterator | None |
| `chain(a, b)` | 1 branch per item |
| `chain(a, b, c)` | 2 branches per item |
| Nested chains | Compounds |
| Separate loops | None (but code duplication) |

### See Also

- [perf-iter-over-index](#perf-iter-over-index) - Prefer iterators
- [perf-extend-batch](#perf-extend-batch) - Batch insertions
- [opt-cache-friendly](#opt-cache-friendly) - Cache-friendly patterns


## perf-collect-into

> Use collect_into for reusing containers

### Why It Matters

`collect_into()` (stabilized in Rust 1.83) allows collecting iterator results into an existing collection, reusing its allocation. This avoids the allocation that `collect()` would make for a new collection.

### Bad

```rust
// Allocates new Vec each time
fn process_batches(batches: Vec<Vec<i32>>) -> Vec<Vec<i32>> {
    batches.into_iter()
        .map(|batch| {
            batch.into_iter()
                .filter(|x| *x > 0)
                .collect::<Vec<_>>()  // New allocation per batch
        })
        .collect()
}

// Can't reuse cleared buffer
fn filter_loop(data: &[Vec<i32>]) {
    for batch in data {
        let filtered: Vec<_> = batch.iter()
            .filter(|&&x| x > 0)
            .copied()
            .collect();  // New allocation each iteration
        process(&filtered);
    }
}
```

### Good

```rust
// Reuse buffer with collect_into
fn filter_loop(data: &[Vec<i32>]) {
    let mut buffer = Vec::new();
    
    for batch in data {
        buffer.clear();  // Keep allocation
        batch.iter()
            .filter(|&&x| x > 0)
            .copied()
            .collect_into(&mut buffer);
        process(&buffer);
    }
}

// Also works with extend pattern
fn filter_loop_extend(data: &[Vec<i32>]) {
    let mut buffer = Vec::new();
    
    for batch in data {
        buffer.clear();
        buffer.extend(
            batch.iter()
                .filter(|&&x| x > 0)
                .copied()
        );
        process(&buffer);
    }
}
```

### Pre-1.83 Alternative: extend

Before `collect_into()` was stabilized, use `extend()`:

```rust
fn reuse_buffer(data: &[Vec<i32>]) {
    let mut buffer = Vec::new();
    
    for batch in data {
        buffer.clear();
        buffer.extend(batch.iter().filter(|&&x| x > 0).copied());
        process(&buffer);
    }
}
```

### Pattern: Transform and Reuse

```rust
fn transform_batches(batches: &[Vec<RawData>]) -> Vec<ProcessedData> {
    let mut temp = Vec::new();
    let mut all_results = Vec::new();
    
    for batch in batches {
        temp.clear();
        batch.iter()
            .map(ProcessedData::from)
            .collect_into(&mut temp);
        
        // Process temp, append to results
        all_results.extend(temp.drain(..).filter(|p| p.is_valid()));
    }
    
    all_results
}
```

### Supported Collections

`collect_into()` works with any type implementing `Extend`:

```rust
use std::collections::{HashSet, HashMap, VecDeque};

let mut vec = Vec::new();
let mut set = HashSet::new();
let mut deque = VecDeque::new();

(0..10).collect_into(&mut vec);
(0..10).collect_into(&mut set);
(0..10).collect_into(&mut deque);
```

### Comparison

| Method | Allocation | Buffer Reuse |
|--------|------------|--------------|
| `.collect()` | New each time | No |
| `.collect_into(&mut buf)` | Reuses buffer | Yes |
| `buf.extend(iter)` | Reuses buffer | Yes |

### See Also

- [perf-drain-reuse](#perf-drain-reuse) - Drain for reuse
- [mem-reuse-collections](#mem-reuse-collections) - Collection reuse
- [perf-extend-batch](#perf-extend-batch) - Batch extensions


## perf-collect-once

> Don't collect intermediate iterators

### Why It Matters

Each `.collect()` allocates a new collection. Chaining multiple operations with intermediate collections wastes memory and CPU cycles. Keep iterator chains lazy and collect only once at the end.

### Bad

```rust
// Three allocations, three passes
fn process_users(users: Vec<User>) -> Vec<String> {
    let active: Vec<_> = users.into_iter()
        .filter(|u| u.is_active)
        .collect();
    
    let verified: Vec<_> = active.into_iter()
        .filter(|u| u.is_verified)
        .collect();
    
    verified.into_iter()
        .map(|u| u.name)
        .collect()
}

// Collecting to count
fn count_valid(items: &[Item]) -> usize {
    items.iter()
        .filter(|i| i.is_valid())
        .collect::<Vec<_>>()  // Unnecessary!
        .len()
}
```

### Good

```rust
// One allocation, one pass
fn process_users(users: Vec<User>) -> Vec<String> {
    users.into_iter()
        .filter(|u| u.is_active)
        .filter(|u| u.is_verified)
        .map(|u| u.name)
        .collect()
}

// No allocation needed
fn count_valid(items: &[Item]) -> usize {
    items.iter()
        .filter(|i| i.is_valid())
        .count()
}
```

### Pattern: Deferred Collection

```rust
// Create the iterator chain
fn prepare_data(raw: Vec<RawData>) -> impl Iterator<Item = ProcessedData> {
    raw.into_iter()
        .filter(|d| d.is_valid())
        .map(ProcessedData::from)
}

// Collect only when needed
let data: Vec<_> = prepare_data(input).collect();

// Or consume without collecting
prepare_data(input).for_each(|d| process(d));
```

### When Intermediate Collection Is Needed

```rust
// Need to iterate multiple times
let items: Vec<_> = data.iter()
    .filter(|x| x.is_valid())
    .collect();

let count = items.len();
let first = items.first();
for item in &items {
    process(item);
}

// Need to sort (requires concrete collection)
let mut sorted: Vec<_> = data.iter()
    .filter(|x| x.is_active)
    .collect();
sorted.sort_by_key(|x| x.priority);
```

### Comparison

| Approach | Allocations | Passes | Memory |
|----------|-------------|--------|--------|
| Multiple `.collect()` | N | N | O(N × data) |
| Single chain + `.collect()` | 1 | 1 | O(data) |
| No `.collect()` (streaming) | 0 | 1 | O(1) |

### Pattern: Collect with Capacity

When you must collect, pre-allocate:

```rust
// With estimated capacity
let mut result = Vec::with_capacity(items.len());
result.extend(
    items.iter()
        .filter(|x| x.is_valid())
        .map(|x| x.clone())
);
```

### See Also

- [perf-iter-lazy](#perf-iter-lazy) - Keep iterators lazy
- [mem-with-capacity](#mem-with-capacity) - Pre-allocate collections
- [anti-collect-intermediate](#anti-collect-intermediate) - Anti-pattern


## perf-drain-reuse

> Use drain to reuse allocations

### Why It Matters

`drain()` removes elements from a collection while keeping its allocated capacity. This allows reusing the same allocation across iterations, avoiding repeated allocate/deallocate cycles in loops.

### Bad

```rust
// Allocates new Vec every iteration
fn process_batches(data: Vec<Item>) {
    let mut remaining = data;
    
    while !remaining.is_empty() {
        let batch: Vec<_> = remaining.drain(..100.min(remaining.len())).collect();
        process_batch(batch);
        // remaining keeps its capacity - good
        // but batch allocates new every time - bad
    }
}

// Clears and reallocates
fn reuse_buffer() {
    for _ in 0..1000 {
        let mut buffer = Vec::new();  // Allocates each iteration
        fill_buffer(&mut buffer);
        process(&buffer);
    }
}
```

### Good

```rust
// Reuses allocation with drain
fn process_batches(mut data: Vec<Item>) {
    let mut batch = Vec::with_capacity(100);
    
    while !data.is_empty() {
        batch.extend(data.drain(..100.min(data.len())));
        process_batch(&batch);
        batch.clear();  // Keeps capacity
    }
}

// Reuses buffer across iterations
fn reuse_buffer() {
    let mut buffer = Vec::new();
    
    for _ in 0..1000 {
        buffer.clear();  // Keeps capacity
        fill_buffer(&mut buffer);
        process(&buffer);
    }
}
```

### Drain Methods

| Collection | Method | Behavior |
|------------|--------|----------|
| `Vec<T>` | `.drain(range)` | Remove range, shift remaining |
| `Vec<T>` | `.drain(..)` | Remove all (like clear) |
| `VecDeque<T>` | `.drain(range)` | Remove range |
| `String` | `.drain(range)` | Remove char range |
| `HashMap<K,V>` | `.drain()` | Remove all entries |
| `HashSet<T>` | `.drain()` | Remove all elements |

### Pattern: Batch Processing

```rust
fn process_in_chunks(mut items: Vec<Item>, chunk_size: usize) {
    while !items.is_empty() {
        let chunk: Vec<_> = items.drain(..chunk_size.min(items.len())).collect();
        process_chunk(chunk);
    }
}
```

### Pattern: Transfer Between Collections

```rust
// Move all elements without reallocation
fn transfer_all(src: &mut Vec<Item>, dst: &mut Vec<Item>) {
    dst.extend(src.drain(..));
    // src is now empty but keeps capacity
}

// Move matching elements
fn transfer_matching(src: &mut Vec<Item>, dst: &mut Vec<Item>, predicate: impl Fn(&Item) -> bool) {
    let matching: Vec<_> = src.drain(..).filter(predicate).collect();
    dst.extend(matching);
}
```

### Pattern: HashMap Drain

```rust
use std::collections::HashMap;

fn process_and_clear(map: &mut HashMap<String, Value>) {
    // Process all entries, clearing the map
    for (key, value) in map.drain() {
        process(key, value);
    }
    // map is now empty but keeps capacity
}
```

### drain vs clear vs take

| Operation | Elements | Capacity | Returns |
|-----------|----------|----------|---------|
| `.clear()` | Removed | Kept | Nothing |
| `.drain(..)` | Removed | Kept | Iterator |
| `std::mem::take()` | Moved out | Reset to 0 | Owned collection |

```rust
// clear: just empty
vec.clear();

// drain: empty and iterate
for item in vec.drain(..) {
    process(item);
}

// take: swap with empty, get ownership
let old_vec = std::mem::take(&mut vec);
```

### See Also

- [mem-reuse-collections](#mem-reuse-collections) - Reusing collections
- [perf-extend-batch](#perf-extend-batch) - Batch insertions
- [mem-with-capacity](#mem-with-capacity) - Pre-allocation


## perf-entry-api

> Use entry API for map insert-or-update

### Why It Matters

The entry API performs a single lookup for insert-or-update operations. Without it, you lookup twice: once to check existence, once to insert. For `HashMap` and `BTreeMap`, the entry API is both faster and more idiomatic.

### Bad

```rust
use std::collections::HashMap;

// Double lookup: contains_key + insert
fn increment(map: &mut HashMap<String, u32>, key: String) {
    if map.contains_key(&key) {
        *map.get_mut(&key).unwrap() += 1;
    } else {
        map.insert(key, 1);
    }
}

// Double lookup with get + insert
fn get_or_insert(map: &mut HashMap<String, Vec<i32>>, key: String) -> &mut Vec<i32> {
    if !map.contains_key(&key) {
        map.insert(key.clone(), Vec::new());
    }
    map.get_mut(&key).unwrap()
}

// Triple lookup pattern
fn update_or_default(map: &mut HashMap<String, Config>, key: &str, value: i32) {
    match map.get(key) {
        Some(config) => {
            let mut new_config = config.clone();
            new_config.value = value;
            map.insert(key.to_string(), new_config);
        }
        None => {
            map.insert(key.to_string(), Config::default());
        }
    }
}
```

### Good

```rust
use std::collections::HashMap;
use std::collections::hash_map::Entry;

// Single lookup with entry
fn increment(map: &mut HashMap<String, u32>, key: String) {
    *map.entry(key).or_insert(0) += 1;
}

// Single lookup, returns mutable reference
fn get_or_insert(map: &mut HashMap<String, Vec<i32>>, key: String) -> &mut Vec<i32> {
    map.entry(key).or_insert_with(Vec::new)
}

// Single lookup with and_modify
fn update_or_default(map: &mut HashMap<String, Config>, key: String, value: i32) {
    map.entry(key)
        .and_modify(|config| config.value = value)
        .or_insert_with(Config::default);
}
```

### Entry API Methods

| Method | Behavior |
|--------|----------|
| `.or_insert(val)` | Insert `val` if empty |
| `.or_insert_with(f)` | Insert `f()` if empty (lazy) |
| `.or_default()` | Insert `Default::default()` if empty |
| `.and_modify(f)` | Apply `f` if occupied |
| `.or_insert_with_key(f)` | Insert `f(&key)` if empty |

### Pattern: Count Occurrences

```rust
fn word_count(text: &str) -> HashMap<&str, usize> {
    let mut counts = HashMap::new();
    for word in text.split_whitespace() {
        *counts.entry(word).or_insert(0) += 1;
    }
    counts
}
```

### Pattern: Group By

```rust
fn group_by_category(items: Vec<Item>) -> HashMap<Category, Vec<Item>> {
    let mut groups: HashMap<Category, Vec<Item>> = HashMap::new();
    for item in items {
        groups.entry(item.category.clone())
            .or_default()
            .push(item);
    }
    groups
}
```

### Pattern: Complex Entry Logic

```rust
match map.entry(key) {
    Entry::Occupied(mut entry) => {
        let value = entry.get_mut();
        if should_update(value) {
            *value = new_value;
        }
    }
    Entry::Vacant(entry) => {
        entry.insert(default_value);
    }
}
```

### Performance

| Pattern | Lookups | Hash Computations |
|---------|---------|-------------------|
| `contains_key` + `insert` | 2 | 2 |
| `get` + `insert` | 2 | 2 |
| `entry().or_insert()` | 1 | 1 |

### See Also

- [perf-extend-batch](#perf-extend-batch) - Batch insertions
- [mem-with-capacity](#mem-with-capacity) - Pre-allocate maps
- [perf-drain-reuse](#perf-drain-reuse) - Reuse map allocations


## perf-extend-batch

> Use extend for batch insertions

### Why It Matters

`extend()` can pre-allocate capacity for the incoming elements and insert them in a single operation. Individual `push()` calls may trigger multiple reallocations as the collection grows. For adding multiple elements, `extend()` is both faster and clearer.

### Bad

```rust
// Multiple potential reallocations
fn collect_results(sources: Vec<Source>) -> Vec<Result> {
    let mut results = Vec::new();
    
    for source in sources {
        for result in source.get_results() {
            results.push(result);  // May reallocate
        }
    }
    results
}

// Loop with push for known data
fn build_list() -> Vec<i32> {
    let mut list = Vec::new();
    for i in 0..1000 {
        list.push(i);  // Many reallocations
    }
    list
}

// Appending another collection
fn combine(mut a: Vec<i32>, b: Vec<i32>) -> Vec<i32> {
    for item in b {
        a.push(item);
    }
    a
}
```

### Good

```rust
// Single extend with size hint
fn collect_results(sources: Vec<Source>) -> Vec<Result> {
    let mut results = Vec::new();
    
    for source in sources {
        results.extend(source.get_results());
    }
    results
}

// Direct collection from iterator
fn build_list() -> Vec<i32> {
    (0..1000).collect()
}

// Extend for combining
fn combine(mut a: Vec<i32>, b: Vec<i32>) -> Vec<i32> {
    a.extend(b);
    a
}
```

### Extend with Capacity

For best performance, combine with `reserve()`:

```rust
fn merge_all(chunks: Vec<Vec<Item>>) -> Vec<Item> {
    // Calculate total size
    let total: usize = chunks.iter().map(|c| c.len()).sum();
    
    let mut result = Vec::with_capacity(total);
    for chunk in chunks {
        result.extend(chunk);
    }
    result
}
```

### Extend Methods

| Method | Description |
|--------|-------------|
| `.extend(iter)` | Add all elements from iterator |
| `.extend_from_slice(&[T])` | Add from slice (for `Copy` types) |
| `.append(&mut Vec)` | Move all from another Vec |

### Pattern: Building Strings

```rust
// Bad: multiple allocations
fn build_message(parts: &[&str]) -> String {
    let mut result = String::new();
    for part in parts {
        result.push_str(part);  // May reallocate
    }
    result
}

// Good: extend with known parts
fn build_message(parts: &[&str]) -> String {
    let total_len: usize = parts.iter().map(|s| s.len()).sum();
    let mut result = String::with_capacity(total_len);
    for part in parts {
        result.push_str(part);
    }
    result
}

// Better: collect/join
fn build_message(parts: &[&str]) -> String {
    parts.concat()  // or parts.join("")
}
```

### HashMap/HashSet Extend

```rust
use std::collections::HashMap;

// Extend from iterator of tuples
fn merge_maps(mut base: HashMap<String, i32>, other: HashMap<String, i32>) -> HashMap<String, i32> {
    base.extend(other);  // Moves entries from other
    base
}

// Extend from iterator
let mut set = HashSet::new();
set.extend(items.iter().map(|i| i.id));
```

### Performance

| Operation | Allocations | Complexity |
|-----------|-------------|------------|
| N × `push()` | O(log N) | O(N) amortized |
| `extend(iter)` | O(1)* | O(N) |
| `with_capacity` + `extend` | 1 | O(N) |

*When iterator provides accurate `size_hint()`

### See Also

- [mem-with-capacity](#mem-with-capacity) - Pre-allocation
- [perf-drain-reuse](#perf-drain-reuse) - Reusing allocations
- [mem-reuse-collections](#mem-reuse-collections) - Collection reuse


## perf-iter-lazy

> Keep iterators lazy, collect only when needed

### Why It Matters

Rust iterators are lazy—they compute values on demand. This enables single-pass processing, avoids intermediate allocations, and allows short-circuiting. Calling `.collect()` too early forces evaluation and allocates unnecessarily.

### Bad

```rust
// Collects intermediate results unnecessarily
fn process(data: Vec<i32>) -> Vec<i32> {
    let filtered: Vec<_> = data.into_iter()
        .filter(|x| *x > 0)
        .collect();  // Unnecessary allocation
    
    let mapped: Vec<_> = filtered.into_iter()
        .map(|x| x * 2)
        .collect();  // Another unnecessary allocation
    
    mapped.into_iter()
        .take(10)
        .collect()
}

// Collects before checking existence
fn has_positive(data: &[i32]) -> bool {
    let positives: Vec<_> = data.iter()
        .filter(|&&x| x > 0)
        .collect();  // Allocates entire filtered result
    
    !positives.is_empty()
}
```

### Good

```rust
// Single chain, single collect
fn process(data: Vec<i32>) -> Vec<i32> {
    data.into_iter()
        .filter(|x| *x > 0)
        .map(|x| x * 2)
        .take(10)
        .collect()
}

// Short-circuits on first match
fn has_positive(data: &[i32]) -> bool {
    data.iter().any(|&x| x > 0)
}
```

### Lazy Iterator Methods

These methods return iterators (lazy):

| Method | Description |
|--------|-------------|
| `.filter()` | Keep matching elements |
| `.map()` | Transform elements |
| `.take(n)` | Limit to n elements |
| `.skip(n)` | Skip first n elements |
| `.zip()` | Pair with another iterator |
| `.chain()` | Concatenate iterators |
| `.flat_map()` | Map and flatten |
| `.enumerate()` | Add index |

### Consuming Methods

These methods consume the iterator (evaluate immediately):

| Method | Description |
|--------|-------------|
| `.collect()` | Gather into collection |
| `.for_each()` | Execute side effect |
| `.count()` | Count elements |
| `.sum()` | Sum elements |
| `.fold()` | Accumulate value |
| `.any()` | Check if any match |
| `.all()` | Check if all match |
| `.find()` | Find first match |

### Short-Circuit Benefits

```rust
// Without lazy: processes ALL items
let found: Vec<_> = items.iter()
    .filter(|x| expensive_check(x))
    .collect();
let result = found.first();

// With lazy: stops at first match
let result = items.iter()
    .find(|x| expensive_check(x));
```

### Pattern: Process Without Collecting

```rust
// Print all matches without allocating
data.iter()
    .filter(|x| x.is_valid())
    .for_each(|x| println!("{}", x));

// Count without collecting
let count = data.iter()
    .filter(|x| x.is_valid())
    .count();

// Sum without intermediate collection
let total: i64 = data.iter()
    .filter(|x| x.is_valid())
    .map(|x| x.value as i64)
    .sum();
```

### See Also

- [perf-collect-once](#perf-collect-once) - Single collect
- [perf-iter-over-index](#perf-iter-over-index) - Prefer iterators
- [anti-collect-intermediate](#anti-collect-intermediate) - Anti-pattern


## perf-iter-over-index

> Prefer iterators over manual indexing

### Why It Matters

Iterators are the idiomatic way to traverse collections in Rust. They enable bounds check elimination, SIMD auto-vectorization, and cleaner code. Manual indexing (`for i in 0..len`) often prevents these optimizations and introduces off-by-one error risks.

### Bad

```rust
// Manual indexing - bounds checked every iteration
fn sum_squares(data: &[i32]) -> i64 {
    let mut sum = 0i64;
    for i in 0..data.len() {
        sum += (data[i] as i64) * (data[i] as i64);
    }
    sum
}

// Index-based iteration with multiple collections
fn dot_product(a: &[f64], b: &[f64]) -> f64 {
    let mut sum = 0.0;
    for i in 0..a.len().min(b.len()) {
        sum += a[i] * b[i];
    }
    sum
}

// Mutating with indices
fn double_values(data: &mut [i32]) {
    for i in 0..data.len() {
        data[i] *= 2;
    }
}
```

### Good

```rust
// Iterator - bounds checks eliminated, SIMD-friendly
fn sum_squares(data: &[i32]) -> i64 {
    data.iter()
        .map(|&x| (x as i64) * (x as i64))
        .sum()
}

// Zip iterators - no manual length handling
fn dot_product(a: &[f64], b: &[f64]) -> f64 {
    a.iter()
        .zip(b.iter())
        .map(|(&x, &y)| x * y)
        .sum()
}

// Mutable iteration
fn double_values(data: &mut [i32]) {
    for x in data.iter_mut() {
        *x *= 2;
    }
}
```

### When Indexing Is Needed

Sometimes you genuinely need indices:

```rust
// Need the index for output or processing
for (i, value) in data.iter().enumerate() {
    println!("Index {}: {}", i, value);
}

// Non-sequential access patterns
fn interleave(data: &mut [i32]) {
    let mid = data.len() / 2;
    for i in 0..mid {
        data.swap(i * 2, mid + i);
    }
}
```

### Performance Comparison

| Pattern | Bounds Checks | SIMD Potential | Clarity |
|---------|---------------|----------------|---------|
| `for i in 0..len` | Every access | Limited | Medium |
| `for &x in slice` | None | High | High |
| `.iter().enumerate()` | None | Medium | High |
| `get_unchecked` | None (unsafe) | High | Low |

### Iterator Advantages

```rust
// Chaining operations - single pass
let result: Vec<_> = data.iter()
    .filter(|x| **x > 0)
    .map(|x| x * 2)
    .collect();

// Early termination optimized
let found = data.iter().any(|&x| x == target);

// Parallel iteration (with rayon)
use rayon::prelude::*;
let sum: i64 = data.par_iter().map(|&x| x as i64).sum();
```

### See Also

- [perf-iter-lazy](#perf-iter-lazy) - Keep iterators lazy
- [opt-bounds-check](#opt-bounds-check) - Bounds check elimination
- [anti-index-over-iter](#anti-index-over-iter) - Anti-pattern


## perf-profile-first

> Profile before optimizing

### Why It Matters

Intuition about performance is often wrong. The code you think is slow frequently isn't, while actual bottlenecks hide in unexpected places. Profiling shows you exactly where time is spent, preventing wasted effort on optimizations that don't matter.

### Bad

```rust
// Optimizing without measuring
fn process(data: &[Item]) -> Vec<Output> {
    // "I bet this clone is slow..."
    let cloned: Vec<_> = data.iter().cloned().collect();
    
    // Actually, 99% of time is spent here:
    cloned.iter().map(|x| expensive_computation(x)).collect()
}

// Over-engineering rarely-called code
#[inline(always)]
fn rarely_called() {
    // This runs once at startup...
}
```

### Good

```rust
// 1. Profile first
// cargo flamegraph --bin myapp
// cargo instruments -t time --bin myapp (macOS)

// 2. Find the actual bottleneck
// Flamegraph shows expensive_computation takes 95% of time

// 3. Optimize the hot spot
fn process(data: &[Item]) -> Vec<Output> {
    // Clone is fine - only 1% of time
    let cloned: Vec<_> = data.iter().cloned().collect();
    
    // Focus optimization HERE
    cloned.par_iter()  // Parallelize the expensive part
        .map(|x| expensive_computation(x))
        .collect()
}
```

### Profiling Tools

#### Flamegraphs (Recommended Start)

```bash
### Install
cargo install flamegraph

### Profile
cargo flamegraph --bin myapp -- <args>

### Opens flamegraph.svg showing call stacks by time
```

#### perf (Linux)

```bash
### Record
perf record -g cargo run --release

### Report
perf report

### Or generate flamegraph
perf script | inferno-collapse-perf | inferno-flamegraph > flamegraph.svg
```

#### Instruments (macOS)

```bash
### Install cargo-instruments
cargo install cargo-instruments

### Time profiler
cargo instruments -t time --release

### Allocations profiler
cargo instruments -t alloc --release
```

#### DHAT (Heap Profiling)

```bash
### In your code
#[global_allocator]
static ALLOC: dhat::Alloc = dhat::Alloc;

fn main() {
    let _profiler = dhat::Profiler::new_heap();
    // ... your code
}

### Run and get allocation report
cargo run --release
```

#### criterion (Micro-benchmarks)

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn bench_my_function(c: &mut Criterion) {
    c.bench_function("my_function", |b| {
        b.iter(|| my_function(black_box(input)))
    });
}

criterion_group!(benches, bench_my_function);
criterion_main!(benches);
```

### What to Look For

```
Flamegraph Reading:
├── Width = time spent
├── Height = call stack depth
└── Look for:
    ├── Wide bars (time hogs)
    ├── malloc/free (allocation heavy)
    ├── memcpy (copying data)
    └── Unexpected functions taking time
```

### Common Findings

```rust
// Finding: HashMap operations are slow
// Fix: Use FxHashMap or AHashMap for non-crypto hashing

// Finding: String allocation in hot loop
// Fix: Pre-allocate with capacity, use &str

// Finding: Clone in hot path
// Fix: Use references or Cow

// Finding: Bounds checks visible in profile
// Fix: Use iterators instead of indexing

// Finding: Lock contention
// Fix: Reduce critical section, use RwLock, or partition data
```

### Optimization Workflow

```
1. Write correct code first
2. Write benchmarks for hot paths
3. Profile under realistic load
4. Identify actual bottlenecks
5. Optimize ONE thing
6. Measure improvement
7. Repeat if needed
```

### Evidence: Rust Performance Book

> "The biggest performance improvements often come from changes to algorithms or data structures, rather than low-level optimizations."

> "It is worth understanding which Rust data structures and operations cause allocations, because avoiding them can greatly improve performance."

### See Also

- [opt-lto-release](#opt-lto-release) - Enable LTO for release builds
- [test-criterion-bench](#test-criterion-bench) - Use criterion for benchmarking
- [anti-premature-optimize](#anti-premature-optimize) - Don't optimize without data


## perf-release-profile

> Optimize release profile settings

### Why It Matters

The default release profile prioritizes compile speed over runtime performance. For production binaries, tuning the release profile can yield significant performance improvements (10-40% in some cases) at the cost of longer compile times.

### Default Profile

```toml
[profile.release]
opt-level = 3
debug = false
lto = false
codegen-units = 16
```

### Optimized Profile

```toml
[profile.release]
opt-level = 3          # Maximum optimization
lto = "fat"            # Full link-time optimization
codegen-units = 1      # Better optimization, slower compile
panic = "abort"        # Smaller binary, no unwinding
strip = true           # Remove symbols

[profile.release.package."*"]
### Keep dependencies optimized even if main crate changes
opt-level = 3
```

### Profile Options

| Option | Values | Effect |
|--------|--------|--------|
| `opt-level` | 0-3, "s", "z" | Optimization level |
| `lto` | false, "thin", "fat" | Link-time optimization |
| `codegen-units` | 1-256 | Parallel compilation units |
| `panic` | "unwind", "abort" | Panic behavior |
| `strip` | true, false, "symbols", "debuginfo" | Binary stripping |
| `debug` | true, false, 0-2 | Debug info level |

### Optimization Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| `0` | No optimization | Debug builds |
| `1` | Basic optimization | Fast compile |
| `2` | Most optimizations | Balanced |
| `3` | All optimizations | Maximum performance |
| `"s"` | Optimize for size | Embedded |
| `"z"` | Minimize size | Smallest binary |

### LTO Options

| Option | Compile Time | Performance | Binary Size |
|--------|--------------|-------------|-------------|
| `false` | Fast | Baseline | Larger |
| `"thin"` | Medium | Good | Smaller |
| `"fat"` | Slow | Best | Smallest |

### Custom Profiles

```toml
### Fast release builds for development
[profile.release-dev]
inherits = "release"
lto = false
codegen-units = 16

### Maximum performance for production
[profile.release-prod]
inherits = "release"
lto = "fat"
codegen-units = 1
strip = true

### Profiling with symbols
[profile.profiling]
inherits = "release"
debug = true
strip = false
```

Use with: `cargo build --profile release-prod`

### Dev Dependencies Optimization

Speed up tests and dev builds:

```toml
[profile.dev]
opt-level = 0

### Optimize dependencies even in dev
[profile.dev.package."*"]
opt-level = 3
```

### Benchmarking Profile

```toml
[profile.bench]
inherits = "release"
debug = true      # For profiling
strip = false     # Keep symbols for flamegraphs
lto = "fat"       # Consistent with release-prod
```

### Size vs Speed Trade-offs

```toml
### Smallest binary
[profile.min-size]
inherits = "release"
opt-level = "z"
lto = "fat"
codegen-units = 1
panic = "abort"
strip = true

### Balance size and speed
[profile.balanced]
inherits = "release"
opt-level = "s"
lto = "thin"
```

### Workspace Configuration

```toml
### In workspace Cargo.toml
[profile.release]
lto = "fat"
codegen-units = 1

### Override for specific package
[profile.release.package.fast-compile-lib]
lto = false
codegen-units = 16
```

### See Also

- [opt-lto-release](#opt-lto-release) - LTO details
- [opt-codegen-units](#opt-codegen-units) - Codegen units
- [opt-pgo-profile](#opt-pgo-profile) - Profile-guided optimization
