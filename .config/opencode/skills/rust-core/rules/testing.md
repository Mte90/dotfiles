# Testing

> Loaded on demand from `SKILL.md` — one rule per `## <rule-id>` section.


## test-arrange-act-assert

> Structure tests with clear Arrange, Act, Assert sections

### Why It Matters

The AAA pattern makes tests readable and maintainable. Each section has a clear purpose: set up test data, execute the code under test, verify the results. This structure helps identify what's being tested and makes tests easier to debug when they fail.

### Bad

```rust
#[test]
fn test_user() {
    assert_eq!(User::new("alice", "alice@example.com").unwrap().name(), "alice");
    assert!(User::new("", "email@example.com").is_err());
    let u = User::new("bob", "bob@example.com").unwrap();
    assert!(u.validate());
    assert_eq!(u.email(), "bob@example.com");
}
// Multiple concerns, hard to understand, hard to debug
```

### Good

```rust
#[test]
fn new_user_has_correct_name() {
    // Arrange
    let name = "alice";
    let email = "alice@example.com";
    
    // Act
    let user = User::new(name, email).unwrap();
    
    // Assert
    assert_eq!(user.name(), "alice");
}

#[test]
fn user_creation_fails_with_empty_name() {
    // Arrange
    let name = "";
    let email = "email@example.com";
    
    // Act
    let result = User::new(name, email);
    
    // Assert
    assert!(result.is_err());
    assert!(matches!(result, Err(UserError::EmptyName)));
}
```

### With Comments

```rust
#[test]
fn order_total_includes_tax() {
    // Arrange
    let mut order = Order::new();
    order.add_item(Item::new("Widget", 100.00));
    order.add_item(Item::new("Gadget", 50.00));
    let tax_rate = 0.10;
    
    // Act
    let total = order.calculate_total(tax_rate);
    
    // Assert
    let expected = (100.00 + 50.00) * 1.10;
    assert_eq!(total, expected);
}
```

### Complex Arrange

```rust
#[test]
fn search_returns_matching_documents() {
    // Arrange
    let mut index = SearchIndex::new();
    index.add_document(Document::new(1, "rust programming"));
    index.add_document(Document::new(2, "python programming"));
    index.add_document(Document::new(3, "rust web development"));
    
    let query = Query::new("rust");
    
    // Act
    let results = index.search(&query);
    
    // Assert
    assert_eq!(results.len(), 2);
    assert!(results.iter().any(|d| d.id == 1));
    assert!(results.iter().any(|d| d.id == 3));
}
```

### Async Tests

```rust
#[tokio::test]
async fn fetch_user_returns_user_data() {
    // Arrange
    let client = TestClient::new();
    let user_id = 42;
    
    // Act
    let result = client.fetch_user(user_id).await;
    
    // Assert
    assert!(result.is_ok());
    let user = result.unwrap();
    assert_eq!(user.id, user_id);
}
```

### Helper Functions

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    // Arrange helpers
    fn create_test_user() -> User {
        User::new("test", "test@example.com").unwrap()
    }
    
    fn create_order_with_items(items: &[(&str, f64)]) -> Order {
        let mut order = Order::new();
        for (name, price) in items {
            order.add_item(Item::new(name, *price));
        }
        order
    }
    
    // Assert helpers
    fn assert_order_total(order: &Order, expected: f64) {
        let total = order.calculate_total(0.0);
        assert!((total - expected).abs() < 0.01);
    }
    
    #[test]
    fn order_total_sums_items() {
        // Arrange
        let order = create_order_with_items(&[
            ("A", 10.0),
            ("B", 20.0),
        ]);
        
        // Act & Assert
        assert_order_total(&order, 30.0);
    }
}
```

### See Also

- [test-descriptive-names](#test-descriptive-names) - Test naming
- [test-fixture-raii](#test-fixture-raii) - Test setup/teardown
- [test-mock-traits](#test-mock-traits) - Mocking dependencies


## test-cfg-test-module

> Put unit tests in `#[cfg(test)] mod tests { }` within each module

### Why It Matters

The `#[cfg(test)]` attribute ensures test code is only compiled during `cargo test`, not in release builds. Placing tests in a `tests` submodule within the same file keeps tests close to the code they test while maintaining separation. This is Rust's idiomatic unit test pattern.

### Bad

```rust
// Tests without cfg(test) - compiled into release binary
mod tests {
    #[test]
    fn test_something() { ... }  // Included in release build!
}

// Tests in separate file without access to private items
// src/my_module.rs
fn private_helper() { ... }

// tests/my_module_test.rs
// Can't access private_helper!
```

### Good

```rust
// src/my_module.rs

fn public_api() -> i32 {
    private_helper() * 2
}

fn private_helper() -> i32 {
    21
}

#[cfg(test)]
mod tests {
    use super::*;  // Access to private items
    
    #[test]
    fn test_public_api() {
        assert_eq!(public_api(), 42);
    }
    
    #[test]
    fn test_private_helper() {
        assert_eq!(private_helper(), 21);  // Can test private!
    }
}
```

### Module Structure

```rust
// src/lib.rs
mod parser;
mod lexer;
mod ast;

// src/parser.rs
pub fn parse(input: &str) -> Result<Ast, Error> {
    let tokens = tokenize(input)?;
    build_ast(tokens)
}

fn tokenize(input: &str) -> Result<Vec<Token>, Error> { ... }
fn build_ast(tokens: Vec<Token>) -> Result<Ast, Error> { ... }

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_parse_simple() {
        let ast = parse("1 + 2").unwrap();
        assert_eq!(ast.evaluate(), 3);
    }
    
    #[test]
    fn test_tokenize() {
        let tokens = tokenize("1 + 2").unwrap();
        assert_eq!(tokens.len(), 3);
    }
}
```

### Test Helpers

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    // Test-only helpers
    fn create_test_data() -> Data {
        Data {
            id: 1,
            name: "test".into(),
            values: vec![1, 2, 3],
        }
    }
    
    fn assert_valid(data: &Data) {
        assert!(data.id > 0);
        assert!(!data.name.is_empty());
    }
    
    #[test]
    fn test_processing() {
        let data = create_test_data();
        let result = process(&data);
        assert_valid(&result);
    }
}
```

### Multiple Test Modules

```rust
// For larger test suites, use submodules
#[cfg(test)]
mod tests {
    use super::*;
    
    mod parsing {
        use super::*;
        
        #[test]
        fn test_parse_number() { ... }
        
        #[test]
        fn test_parse_string() { ... }
    }
    
    mod validation {
        use super::*;
        
        #[test]
        fn test_validate_range() { ... }
    }
}
```

### See Also

- [test-use-super](#test-use-super) - Importing from parent module
- [test-integration-dir](#test-integration-dir) - Integration tests
- [test-descriptive-names](#test-descriptive-names) - Test naming


## test-criterion-bench

> Use `criterion` for benchmarking

### Why It Matters

Criterion provides statistically rigorous benchmarking with warmup, multiple iterations, outlier detection, and comparison between runs. It's far more reliable than simple timing with `Instant::now()`.

### Setup

```toml
### Cargo.toml
[dev-dependencies]
criterion = "0.5"

[[bench]]
name = "my_benchmark"
harness = false
```

### Basic Benchmark

```rust
// benches/my_benchmark.rs
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn fibonacci(n: u64) -> u64 {
    match n {
        0 => 0,
        1 => 1,
        n => fibonacci(n - 1) + fibonacci(n - 2),
    }
}

fn bench_fibonacci(c: &mut Criterion) {
    c.bench_function("fib 20", |b| {
        b.iter(|| fibonacci(black_box(20)))
    });
}

criterion_group!(benches, bench_fibonacci);
criterion_main!(benches);
```

### black_box is Critical

```rust
// BAD: Compiler may optimize away the computation
b.iter(|| fibonacci(20));  // Result unused, might be eliminated

// GOOD: black_box prevents optimization
b.iter(|| fibonacci(black_box(20)));

// Also wrap the result if needed
b.iter(|| black_box(fibonacci(black_box(20))));
```

### Comparing Implementations

```rust
fn bench_comparison(c: &mut Criterion) {
    let mut group = c.benchmark_group("String concat");
    
    let data = "hello";
    
    group.bench_function("format!", |b| {
        b.iter(|| format!("{}{}", black_box(data), " world"))
    });
    
    group.bench_function("push_str", |b| {
        b.iter(|| {
            let mut s = String::from(black_box(data));
            s.push_str(" world");
            s
        })
    });
    
    group.bench_function("concat", |b| {
        b.iter(|| [black_box(data), " world"].concat())
    });
    
    group.finish();
}
```

### Parameterized Benchmarks

```rust
fn bench_vec_push(c: &mut Criterion) {
    let mut group = c.benchmark_group("Vec::push");
    
    for size in [100, 1000, 10000].iter() {
        group.bench_with_input(
            BenchmarkId::from_parameter(size),
            size,
            |b, &size| {
                b.iter(|| {
                    let mut v = Vec::new();
                    for i in 0..size {
                        v.push(black_box(i));
                    }
                    v
                });
            },
        );
    }
    
    group.finish();
}
```

### Throughput Measurement

```rust
use criterion::Throughput;

fn bench_parse(c: &mut Criterion) {
    let input = "a]ong string to parse...";
    
    let mut group = c.benchmark_group("Parser");
    group.throughput(Throughput::Bytes(input.len() as u64));
    
    group.bench_function("parse", |b| {
        b.iter(|| parse(black_box(input)))
    });
    
    group.finish();
}
```

### Running Benchmarks

```bash
### Run all benchmarks
cargo bench

### Run specific benchmark
cargo bench -- fib

### Save baseline for comparison
cargo bench -- --save-baseline main

### Compare against baseline
cargo bench -- --baseline main
```

### Evidence from tokio

```rust
// https://github.com/tokio-rs/tokio/blob/master/benches/sync_mpsc.rs
use criterion::{criterion_group, criterion_main, Criterion};

fn send_data<T: Default, const SIZE: usize>(
    g: &mut BenchmarkGroup<WallTime>, 
    prefix: &str
) {
    let rt = rt();
    g.bench_function(format!("{prefix}_{SIZE}"), |b| {
        b.iter(|| {
            let (tx, mut rx) = mpsc::channel::<T>(SIZE);
            rt.block_on(tx.send(T::default())).unwrap();
            rt.block_on(rx.recv()).unwrap();
        })
    });
}
```

### See Also

- [perf-profile-first](#perf-profile-first) - Profile before optimizing
- [perf-black-box-bench](#perf-black-box-bench) - Use black_box in benchmarks


## test-descriptive-names

> Use descriptive test names that explain what is being tested

### Why It Matters

Test names appear in test output and serve as documentation. A good test name tells you what behavior is being verified without reading the test body. When a test fails, a descriptive name immediately tells you what broke.

### Bad

```rust
#[test]
fn test1() { ... }

#[test]
fn test_parse() { ... }  // Parse what? What behavior?

#[test]
fn it_works() { ... }

#[test]
fn test_function() { ... }

// Failure output: "test test_parse ... FAILED"
// What failed? No idea.
```

### Good

```rust
#[test]
fn parse_returns_error_for_empty_input() { ... }

#[test]
fn parse_handles_unicode_characters() { ... }

#[test]
fn user_creation_requires_valid_email() { ... }

#[test]
fn expired_token_is_rejected() { ... }

// Failure output: "test parse_returns_error_for_empty_input ... FAILED"
// Immediately know what broke!
```

### Naming Patterns

```rust
// Pattern: function_condition_expected_result
#[test]
fn parse_valid_json_returns_document() { ... }

#[test]
fn parse_invalid_json_returns_syntax_error() { ... }

// Pattern: scenario_expectation
#[test]
fn empty_cart_has_zero_total() { ... }

#[test]
fn adding_item_increases_cart_total() { ... }

// Pattern: when_given_then (BDD-style)
#[test]
fn when_user_not_found_then_returns_404() { ... }
```

### Edge Cases

```rust
#[test]
fn handles_empty_string() { ... }

#[test]
fn handles_max_length_input() { ... }

#[test]
fn handles_unicode_emoji() { ... }

#[test]
fn handles_null_bytes() { ... }

#[test]
fn handles_concurrent_access() { ... }
```

### Error Cases

```rust
#[test]
fn rejects_negative_quantity() { ... }

#[test]
fn returns_error_for_invalid_email_format() { ... }

#[test]
fn panics_on_double_initialization() { ... }

#[test]
fn timeout_returns_timeout_error() { ... }
```

### Module Organization

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    mod parsing {
        use super::*;
        
        #[test]
        fn accepts_valid_json() { ... }
        
        #[test]
        fn rejects_trailing_comma() { ... }
    }
    
    mod validation {
        use super::*;
        
        #[test]
        fn requires_name_field() { ... }
        
        #[test]
        fn email_must_contain_at_symbol() { ... }
    }
}

// Test output:
// tests::parsing::accepts_valid_json
// tests::parsing::rejects_trailing_comma
// tests::validation::requires_name_field
```

### See Also

- [test-arrange-act-assert](#test-arrange-act-assert) - Test structure
- [test-cfg-test-module](#test-cfg-test-module) - Test module organization
- [doc-examples-section](#doc-examples-section) - Documentation tests


## test-doctest-examples

> Keep documentation examples as executable doctests

### Why It Matters

Doctests are examples in documentation that are automatically tested. They serve dual purposes: demonstrating usage to readers and verifying the examples compile and work. When your API changes, failing doctests catch outdated documentation.

### Bad

```rust
/// Parses a number from a string.
/// 
/// Example:
/// let n = parse("42");  // Not tested!
/// assert_eq!(n, 42);
pub fn parse(s: &str) -> i32 {
    s.parse().unwrap()
}

// Documentation can become outdated:
/// Adds two numbers.
/// 
/// ```
/// let sum = add(1, 2, 3);  // Wrong number of args - not caught!
/// ```
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

### Good

```rust
/// Parses a number from a string.
/// 
/// # Examples
/// 
/// ```
/// use my_crate::parse;
/// 
/// let n = parse("42");
/// assert_eq!(n, 42);
/// ```
pub fn parse(s: &str) -> i32 {
    s.parse().unwrap()
}

/// Adds two numbers.
/// 
/// # Examples
/// 
/// ```
/// use my_crate::add;
/// 
/// let sum = add(1, 2);
/// assert_eq!(sum, 3);
/// ```
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

### Hiding Setup Code

```rust
/// Processes data from a file.
/// 
/// # Examples
/// 
/// ```
/// # use std::io::Write;
/// # let mut file = tempfile::NamedTempFile::new().unwrap();
/// # writeln!(file, "test data").unwrap();
/// # let path = file.path();
/// use my_crate::process_file;
/// 
/// let result = process_file(path)?;
/// assert!(!result.is_empty());
/// # Ok::<(), Box<dyn std::error::Error>>(())
/// ```
pub fn process_file(path: &Path) -> Result<String, Error> {
    std::fs::read_to_string(path).map_err(Error::from)
}
```

### Showing Error Handling

```rust
/// Parses and validates an email address.
/// 
/// # Examples
/// 
/// ```
/// use my_crate::Email;
/// 
/// let email = Email::parse("user@example.com")?;
/// assert_eq!(email.domain(), "example.com");
/// # Ok::<(), my_crate::EmailError>(())
/// ```
/// 
/// # Errors
/// 
/// Returns error for invalid format:
/// 
/// ```
/// use my_crate::Email;
/// 
/// assert!(Email::parse("not-an-email").is_err());
/// ```
pub fn parse(s: &str) -> Result<Email, EmailError> {
    // ...
}
```

### no_run and ignore

```rust
/// Starts the server.
/// 
/// ```no_run
/// use my_crate::Server;
/// 
/// // This compiles but doesn't run (would block forever)
/// Server::new().run();
/// ```
pub fn run(&self) { ... }

/// Platform-specific example.
/// 
/// ```ignore
/// // This might not compile on all platforms
/// use windows_specific::Feature;
/// ```
```

### compile_fail

```rust
/// This type is not Clone.
/// 
/// ```compile_fail
/// use my_crate::UniqueHandle;
/// 
/// let a = UniqueHandle::new();
/// let b = a.clone();  // Error: Clone not implemented
/// ```
pub struct UniqueHandle { ... }
```

### Running Doctests

```bash
### Run all tests including doctests
cargo test

### Run only doctests
cargo test --doc

### Run doctests for specific item
cargo test --doc my_function
```

### See Also

- [doc-examples-section](#doc-examples-section) - Documentation structure
- [doc-hidden-setup](#doc-hidden-setup) - Hiding setup code
- [doc-question-mark](#doc-question-mark) - Error handling in examples


## test-fixture-raii

> Use RAII pattern (Drop trait) for automatic test cleanup

### Why It Matters

Tests often need setup and teardown—creating temp files, starting servers, setting environment variables. Using RAII (Resource Acquisition Is Initialization) with Drop ensures cleanup happens automatically, even if the test panics. This prevents test pollution and resource leaks.

### Bad

```rust
#[test]
fn test_with_temp_file() {
    let path = "/tmp/test_file.txt";
    std::fs::write(path, "test data").unwrap();
    
    let result = process_file(path);
    
    std::fs::remove_file(path).unwrap();  // Might not run if test panics!
    assert!(result.is_ok());
}

#[test]
fn test_with_env_var() {
    std::env::set_var("MY_VAR", "test_value");
    
    let result = read_config();
    
    std::env::remove_var("MY_VAR");  // Might not run if test panics!
    assert!(result.is_ok());
}
```

### Good

```rust
use tempfile::NamedTempFile;

#[test]
fn test_with_temp_file() {
    // Arrange - file deleted automatically when `file` drops
    let file = NamedTempFile::new().unwrap();
    std::fs::write(file.path(), "test data").unwrap();
    
    // Act
    let result = process_file(file.path());
    
    // Assert - file cleaned up even if assertion panics
    assert!(result.is_ok());
}

// Custom RAII guard for environment variables
struct EnvGuard {
    key: String,
    original: Option<String>,
}

impl EnvGuard {
    fn set(key: &str, value: &str) -> Self {
        let original = std::env::var(key).ok();
        std::env::set_var(key, value);
        EnvGuard {
            key: key.to_string(),
            original,
        }
    }
}

impl Drop for EnvGuard {
    fn drop(&mut self) {
        match &self.original {
            Some(v) => std::env::set_var(&self.key, v),
            None => std::env::remove_var(&self.key),
        }
    }
}

#[test]
fn test_with_env_var() {
    let _guard = EnvGuard::set("MY_VAR", "test_value");
    
    let result = read_config();
    
    assert!(result.is_ok());
}  // MY_VAR automatically restored
```

### Common RAII Patterns

```rust
// Temporary directory
use tempfile::TempDir;

#[test]
fn test_with_temp_dir() {
    let dir = TempDir::new().unwrap();
    let file_path = dir.path().join("test.txt");
    std::fs::write(&file_path, "data").unwrap();
    
    // dir and all contents deleted on drop
}

// Server guard
struct TestServer {
    handle: std::thread::JoinHandle<()>,
    shutdown: std::sync::mpsc::Sender<()>,
}

impl Drop for TestServer {
    fn drop(&mut self) {
        let _ = self.shutdown.send(());
        // Wait for server to stop
    }
}

// Database transaction rollback
struct TestTransaction<'a> {
    conn: &'a mut Connection,
}

impl Drop for TestTransaction<'_> {
    fn drop(&mut self) {
        self.conn.execute("ROLLBACK").unwrap();
    }
}
```

### scopeguard Crate

```rust
use scopeguard::defer;

#[test]
fn test_with_defer() {
    let path = "/tmp/test_file.txt";
    std::fs::write(path, "data").unwrap();
    
    defer! {
        std::fs::remove_file(path).ok();
    }
    
    // Test logic here
    // File removed when scope exits
}
```

### See Also

- [test-arrange-act-assert](#test-arrange-act-assert) - Test structure
- [test-tokio-async](#test-tokio-async) - Async test cleanup
- [test-mock-traits](#test-mock-traits) - Mocking with RAII


## test-integration-dir

> Put integration tests in the `tests/` directory

### Why It Matters

Integration tests live in `tests/` at the crate root, separate from `src/`. Each file in `tests/` is compiled as a separate crate, testing your library's public API as external users would. This separation ensures you're testing the real public interface, not implementation details.

### Structure

```
my_project/
├── Cargo.toml
├── src/
│   ├── lib.rs
│   └── internal.rs
└── tests/
    ├── integration_test.rs    # Each file is a separate test binary
    ├── api_tests.rs
    └── common/                 # Shared test utilities
        └── mod.rs
```

### Bad

```rust
// src/lib.rs
// Mixing integration test logic in library code
#[test]
fn integration_test_full_workflow() {
    // This is a unit test location, not integration
}
```

### Good

```rust
// tests/integration_test.rs
use my_crate::{Client, Config};  // Uses public API only

#[test]
fn test_full_workflow() {
    let config = Config::default();
    let client = Client::new(config);
    
    let result = client.process("input");
    assert!(result.is_ok());
}

#[test]
fn test_error_handling() {
    let client = Client::new(Config::strict());
    
    let result = client.process("invalid");
    assert!(matches!(result, Err(Error::InvalidInput { .. })));
}
```

### Shared Test Utilities

```rust
// tests/common/mod.rs
use my_crate::Config;

pub fn test_config() -> Config {
    Config {
        timeout: Duration::from_secs(5),
        retries: 3,
        debug: true,
    }
}

pub fn setup_test_environment() {
    // Set up test fixtures
}

// tests/api_tests.rs
mod common;

use my_crate::Client;

#[test]
fn test_with_shared_config() {
    common::setup_test_environment();
    let client = Client::new(common::test_config());
    // ...
}
```

### Organizing Many Tests

```rust
// tests/api/mod.rs
mod auth;
mod users;
mod orders;

// tests/api/auth.rs
use my_crate::auth::{login, logout};

#[test]
fn test_login_success() { ... }

#[test]
fn test_login_invalid_credentials() { ... }

// tests/api/users.rs
use my_crate::users::{create_user, get_user};

#[test]
fn test_create_user() { ... }
```

### Integration vs Unit Tests

| Unit Tests | Integration Tests |
|------------|-------------------|
| In `src/` with `#[cfg(test)]` | In `tests/` directory |
| Access private items | Public API only |
| Test individual functions | Test module interactions |
| Fast, isolated | May be slower |
| `cargo test --lib` | `cargo test --test '*'` |

### Running Specific Tests

```bash
### Run all tests
cargo test

### Run only integration tests
cargo test --test '*'

### Run specific integration test file
cargo test --test integration_test

### Run tests matching pattern
cargo test --test api_tests test_login
```

### See Also

- [test-cfg-test-module](#test-cfg-test-module) - Unit test modules
- [test-descriptive-names](#test-descriptive-names) - Test naming
- [test-tokio-async](#test-tokio-async) - Async integration tests


## test-mock-traits

> Use traits for dependencies to enable mocking in tests

### Why It Matters

Concrete dependencies make testing hard—you can't easily test error paths, timeouts, or edge cases without real external systems. Extracting dependencies behind traits lets you inject test doubles (mocks, fakes, stubs), enabling isolated unit tests that run fast and cover edge cases.

### Bad

```rust
struct UserService {
    db: PostgresConnection,  // Concrete type - hard to test
}

impl UserService {
    async fn get_user(&self, id: u64) -> Result<User, Error> {
        // Directly calls Postgres - needs real database to test
        self.db.query("SELECT * FROM users WHERE id = $1", &[&id]).await
    }
}

// Test requires real Postgres instance
#[tokio::test]
async fn test_get_user() {
    let db = PostgresConnection::connect("postgres://...").await?;
    let service = UserService { db };
    // Slow, flaky, can't test error paths
}
```

### Good

```rust
// Define trait for dependency
#[async_trait]
trait UserRepository: Send + Sync {
    async fn find_by_id(&self, id: u64) -> Result<Option<User>, DbError>;
    async fn save(&self, user: &User) -> Result<(), DbError>;
}

// Production implementation
struct PostgresUserRepo {
    pool: PgPool,
}

#[async_trait]
impl UserRepository for PostgresUserRepo {
    async fn find_by_id(&self, id: u64) -> Result<Option<User>, DbError> {
        sqlx::query_as("SELECT * FROM users WHERE id = $1")
            .bind(id)
            .fetch_optional(&self.pool)
            .await
    }
    // ...
}

// Service depends on trait, not concrete type
struct UserService<R: UserRepository> {
    repo: R,
}

impl<R: UserRepository> UserService<R> {
    async fn get_user(&self, id: u64) -> Result<User, Error> {
        self.repo.find_by_id(id).await?
            .ok_or(Error::NotFound)
    }
}

// Test with mock
#[cfg(test)]
mod tests {
    struct MockUserRepo {
        users: HashMap<u64, User>,
    }
    
    #[async_trait]
    impl UserRepository for MockUserRepo {
        async fn find_by_id(&self, id: u64) -> Result<Option<User>, DbError> {
            Ok(self.users.get(&id).cloned())
        }
        // ...
    }
    
    #[tokio::test]
    async fn test_get_user_found() {
        let mut mock = MockUserRepo { users: HashMap::new() };
        mock.users.insert(1, User { id: 1, name: "Alice".into() });
        
        let service = UserService { repo: mock };
        let user = service.get_user(1).await.unwrap();
        
        assert_eq!(user.name, "Alice");
    }
    
    #[tokio::test]
    async fn test_get_user_not_found() {
        let mock = MockUserRepo { users: HashMap::new() };
        let service = UserService { repo: mock };
        
        let result = service.get_user(999).await;
        assert!(matches!(result, Err(Error::NotFound)));
    }
}
```

### mockall Crate

```rust
use mockall::*;
use mockall::predicate::*;

#[automock]
#[async_trait]
trait Database: Send + Sync {
    async fn query(&self, sql: &str) -> Result<Vec<Row>, Error>;
}

#[tokio::test]
async fn test_with_mockall() {
    let mut mock = MockDatabase::new();
    
    mock.expect_query()
        .with(eq("SELECT 1"))
        .times(1)
        .returning(|_| Ok(vec![Row::new()]));
    
    let result = mock.query("SELECT 1").await;
    assert!(result.is_ok());
}
```

### Testing Error Paths

```rust
#[async_trait]
trait HttpClient: Send + Sync {
    async fn get(&self, url: &str) -> Result<Response, HttpError>;
}

struct FailingClient;

#[async_trait]
impl HttpClient for FailingClient {
    async fn get(&self, _url: &str) -> Result<Response, HttpError> {
        Err(HttpError::Timeout)  // Always fails
    }
}

#[tokio::test]
async fn test_handles_timeout() {
    let client = FailingClient;
    let service = ApiService { client };
    
    let result = service.fetch_data().await;
    assert!(matches!(result, Err(Error::NetworkError(_))));
}
```

### Dynamic Dispatch Alternative

```rust
// When you don't want generics everywhere
struct UserService {
    repo: Box<dyn UserRepository>,
}

impl UserService {
    fn new(repo: impl UserRepository + 'static) -> Self {
        Self { repo: Box::new(repo) }
    }
}

// Slight runtime cost but cleaner API
```

### Cargo.toml

```toml
[dev-dependencies]
mockall = "0.11"
async-trait = "0.1"  # For async trait mocking
```

### See Also

- [api-sealed-trait](#api-sealed-trait) - Trait design
- [test-proptest-properties](#test-proptest-properties) - Property-based testing
- [proj-lib-main-split](#proj-lib-main-split) - Testable architecture


## test-mockall-mocking

> Use mockall for trait mocking

### Why It Matters

Unit tests should isolate the code under test from external dependencies (databases, APIs, file systems). Mockall generates mock implementations of traits, allowing you to control and verify behavior without real dependencies.

### Setup

```toml
### Cargo.toml
[dev-dependencies]
mockall = "0.12"
```

### Basic Usage

```rust
use mockall::automock;

#[automock]
trait Database {
    fn get_user(&self, id: u64) -> Option<User>;
    fn save_user(&self, user: &User) -> Result<(), Error>;
}

#[cfg(test)]
mod tests {
    use super::*;
    use mockall::predicate::*;
    
    #[test]
    fn test_get_user() {
        let mut mock = MockDatabase::new();
        
        mock.expect_get_user()
            .with(eq(42))
            .returning(|_| Some(User { id: 42, name: "Alice".into() }));
        
        let service = UserService::new(mock);
        let user = service.find_user(42);
        
        assert_eq!(user.unwrap().name, "Alice");
    }
}
```

### Expectations

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_save_calls() {
        let mut mock = MockDatabase::new();
        
        // Expect exactly one call
        mock.expect_save_user()
            .times(1)
            .returning(|_| Ok(()));
        
        // Expect call with specific argument
        mock.expect_get_user()
            .with(eq(42))
            .returning(|_| Some(User::default()));
        
        // Expect multiple calls
        mock.expect_get_user()
            .times(3..)  // At least 3 times
            .returning(|_| None);
        
        // Expectations are verified on drop
    }
}
```

### Predicates

```rust
use mockall::predicate::*;

mock.expect_process()
    .with(eq(42))                    // Exact match
    .returning(|_| Ok(()));

mock.expect_validate()
    .with(function(|s: &str| s.len() > 5))  // Custom predicate
    .returning(|_| true);

mock.expect_search()
    .withf(|query, limit| {           // Multiple args
        query.len() < 100 && *limit <= 1000
    })
    .returning(|_, _| vec![]);
```

### Sequences

```rust
use mockall::Sequence;

#[test]
fn test_ordered_calls() {
    let mut seq = Sequence::new();
    let mut mock = MockDatabase::new();
    
    mock.expect_connect()
        .times(1)
        .in_sequence(&mut seq)
        .returning(|| Ok(()));
    
    mock.expect_query()
        .times(1)
        .in_sequence(&mut seq)
        .returning(|_| Ok(vec![]));
    
    mock.expect_disconnect()
        .times(1)
        .in_sequence(&mut seq)
        .returning(|| Ok(()));
}
```

### Return Values

```rust
// Fixed value
mock.expect_count().returning(|| 42);

// Based on input
mock.expect_double().returning(|x| x * 2);

// Different values per call
mock.expect_next()
    .times(3)
    .returning(|| 1)
    .returning(|| 2)
    .returning(|| 3);

// Return owned values
mock.expect_get_name()
    .returning(|| "Alice".to_string());
```

### Mocking External Traits

```rust
// For traits you don't own
#[cfg_attr(test, mockall::automock)]
trait HttpClient {
    fn get(&self, url: &str) -> Result<Response, Error>;
}

// In production
struct RealHttpClient;
impl HttpClient for RealHttpClient {
    fn get(&self, url: &str) -> Result<Response, Error> { /* ... */ }
}

// In tests
#[cfg(test)]
fn mock_client() -> MockHttpClient {
    let mut mock = MockHttpClient::new();
    mock.expect_get()
        .returning(|_| Ok(Response::new(200, "OK")));
    mock
}
```

### Async Mocking

```rust
#[automock]
#[async_trait]
trait AsyncDatabase {
    async fn fetch(&self, id: u64) -> Option<Data>;
}

#[tokio::test]
async fn test_async() {
    let mut mock = MockAsyncDatabase::new();
    
    mock.expect_fetch()
        .returning(|_| Some(Data::default()));
    
    let result = mock.fetch(1).await;
    assert!(result.is_some());
}
```

### Design for Testability

```rust
// Accept trait, not concrete type
struct Service<D: Database> {
    db: D,
}

impl<D: Database> Service<D> {
    fn new(db: D) -> Self {
        Self { db }
    }
}

// Tests use mock
#[test]
fn test_service() {
    let mock = MockDatabase::new();
    let service = Service::new(mock);
}

// Production uses real implementation
fn main() {
    let db = PostgresDatabase::connect();
    let service = Service::new(db);
}
```

### See Also

- [test-mock-traits](#test-mock-traits) - Mock trait design
- [test-proptest-properties](#test-proptest-properties) - Property testing
- [test-arrange-act-assert](#test-arrange-act-assert) - Test structure


## test-proptest-properties

> Use proptest for property-based testing

### Why It Matters

Property-based testing generates random inputs to verify that properties hold across all possible values, not just hand-picked examples. Proptest finds edge cases you wouldn't think to test manually—empty strings, integer overflows, unicode edge cases.

### Setup

```toml
### Cargo.toml
[dev-dependencies]
proptest = "1.0"
```

### Basic Usage

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn test_reverse_reverse_is_identity(s in ".*") {
        let reversed: String = s.chars().rev().collect();
        let double_reversed: String = reversed.chars().rev().collect();
        assert_eq!(s, double_reversed);
    }
    
    #[test]
    fn test_sort_is_idempotent(mut v in prop::collection::vec(any::<i32>(), 0..100)) {
        v.sort();
        let sorted = v.clone();
        v.sort();
        assert_eq!(v, sorted);
    }
}
```

### Common Strategies

```rust
use proptest::prelude::*;

proptest! {
    // Any type implementing Arbitrary
    #[test]
    fn test_i32(x in any::<i32>()) { }
    
    // Regex-based string generation
    #[test]
    fn test_email(email in "[a-z]+@[a-z]+\\.[a-z]{2,3}") { }
    
    // Ranges
    #[test]
    fn test_range(x in 0..100i32) { }
    
    // Collections
    #[test]
    fn test_vec(v in prop::collection::vec(any::<i32>(), 0..10)) { }
    
    // Optionals
    #[test]
    fn test_option(opt in prop::option::of(any::<i32>())) { }
}
```

### Custom Strategies

```rust
use proptest::prelude::*;

#[derive(Debug, Clone)]
struct User {
    name: String,
    age: u8,
}

fn user_strategy() -> impl Strategy<Value = User> {
    ("[a-zA-Z]{1,20}", 0..120u8)
        .prop_map(|(name, age)| User { name, age })
}

proptest! {
    #[test]
    fn test_user(user in user_strategy()) {
        assert!(user.age < 150);
        assert!(!user.name.is_empty());
    }
}

// Or derive Arbitrary
use proptest_derive::Arbitrary;

#[derive(Debug, Arbitrary)]
struct Point {
    x: i32,
    y: i32,
}
```

### Properties to Test

| Property | Example |
|----------|---------|
| Roundtrip | `decode(encode(x)) == x` |
| Idempotence | `f(f(x)) == f(x)` |
| Commutativity | `f(a, b) == f(b, a)` |
| Associativity | `f(f(a, b), c) == f(a, f(b, c))` |
| Identity | `f(x, identity) == x` |
| Invariants | `len(push(v, x)) == len(v) + 1` |

### Example: Parser Roundtrip

```rust
proptest! {
    #[test]
    fn parse_roundtrip(config in valid_config_strategy()) {
        let serialized = config.to_string();
        let parsed = Config::parse(&serialized).unwrap();
        assert_eq!(config, parsed);
    }
}
```

### Shrinking

Proptest automatically shrinks failing inputs to minimal cases:

```rust
// If this fails with vec![100, 50, 75, 25, 0]
// Proptest will shrink to vec![1, 0] (minimal failing case)
proptest! {
    #[test]
    fn test_sorted(v in prop::collection::vec(0..1000i32, 1..100)) {
        let sorted = is_sorted(&v);
        // This will fail and shrink
    }
}
```

### Configuration

```rust
proptest! {
    #![proptest_config(ProptestConfig {
        cases: 1000,  // More test cases
        max_shrink_iters: 10000,  // More shrinking
        ..ProptestConfig::default()
    })]
    
    #[test]
    fn extensive_test(x in any::<i32>()) { }
}
```

### See Also

- [test-criterion-bench](#test-criterion-bench) - Benchmarking
- [test-mockall-mocking](#test-mockall-mocking) - Mocking
- [test-arrange-act-assert](#test-arrange-act-assert) - Test structure


## test-should-panic

> Use `#[should_panic]` to test that code panics as expected

### Why It Matters

Some code should panic on invalid inputs or invariant violations. `#[should_panic]` verifies the panic occurs, optionally checking the panic message. This ensures defensive panics work correctly and documents expected panic conditions.

### Bad

```rust
#[test]
fn test_panic() {
    // Just calling panicking code makes test fail
    divide(1, 0);  // Test fails with panic
}

// Using catch_unwind is verbose
#[test]
fn test_panic_manual() {
    let result = std::panic::catch_unwind(|| divide(1, 0));
    assert!(result.is_err());
}
```

### Good

```rust
#[test]
#[should_panic]
fn divide_by_zero_panics() {
    divide(1, 0);  // Test passes when this panics
}

// With expected message
#[test]
#[should_panic(expected = "division by zero")]
fn divide_by_zero_panics_with_message() {
    divide(1, 0);  // Panics with "division by zero"
}

// Partial message match
#[test]
#[should_panic(expected = "index out of bounds")]
fn index_panic_contains_message() {
    let v = vec![1, 2, 3];
    let _ = v[100];  // Message contains "index out of bounds"
}
```

### Testing Invariants

```rust
struct NonEmpty<T>(Vec<T>);

impl<T> NonEmpty<T> {
    fn new(items: Vec<T>) -> Self {
        assert!(!items.is_empty(), "NonEmpty cannot be empty");
        NonEmpty(items)
    }
}

#[test]
#[should_panic(expected = "NonEmpty cannot be empty")]
fn non_empty_rejects_empty_vec() {
    NonEmpty::new(Vec::<i32>::new());
}

#[test]
fn non_empty_accepts_non_empty_vec() {
    let ne = NonEmpty::new(vec![1, 2, 3]);
    assert_eq!(ne.0.len(), 3);
}
```

### With expect() Messages

```rust
fn get_config_value(key: &str) -> String {
    CONFIG.get(key)
        .expect(&format!("missing required config: {}", key))
        .to_string()
}

#[test]
#[should_panic(expected = "missing required config: DATABASE_URL")]
fn missing_config_panics_with_key() {
    get_config_value("DATABASE_URL");
}
```

### When NOT to Use should_panic

```rust
// ❌ For recoverable errors - use Result
#[test]
#[should_panic]  // Wrong: this should return Err, not panic
fn invalid_input_panics() {
    parse_config("invalid");  // Should return Err, not panic
}

// ✅ Return Result and test the error
#[test]
fn invalid_input_returns_error() {
    let result = parse_config("invalid");
    assert!(result.is_err());
}
```

### Combining with Result

```rust
#[test]
#[should_panic]
fn test_panics() -> Result<(), Error> {
    // Can combine with Result for setup
    let data = setup_test_data()?;
    
    // This should panic
    process_invalid(&data);
    
    Ok(())  // Never reached
}
```

### See Also

- [err-result-over-panic](#err-result-over-panic) - Panic vs Result
- [err-expect-bugs-only](#err-expect-bugs-only) - When to use expect
- [test-descriptive-names](#test-descriptive-names) - Test naming


## test-tokio-async

> Use `#[tokio::test]` for async tests

### Why It Matters

Async functions can't be called directly—they need a runtime to drive them. `#[tokio::test]` provides a Tokio runtime for your test, handling setup automatically. This is simpler than manually creating a runtime and essential for testing async code.

### Bad

```rust
// Won't compile - async fn can't be called without runtime
#[test]
async fn test_async_function() {  // Error!
    let result = fetch_data().await;
    assert!(result.is_ok());
}

// Manual runtime - verbose and error-prone
#[test]
fn test_async_function() {
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(async {
        let result = fetch_data().await;
        assert!(result.is_ok());
    });
}
```

### Good

```rust
#[tokio::test]
async fn test_async_function() {
    let result = fetch_data().await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_concurrent_operations() {
    let (a, b) = tokio::join!(
        fetch_user(1),
        fetch_user(2),
    );
    assert!(a.is_ok());
    assert!(b.is_ok());
}
```

### Runtime Configuration

```rust
// Multi-threaded runtime (default)
#[tokio::test]
async fn test_default_runtime() {
    // Uses multi-thread runtime
}

// Single-threaded (current_thread)
#[tokio::test(flavor = "current_thread")]
async fn test_single_threaded() {
    // Simpler, deterministic
}

// With specific thread count
#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn test_with_workers() {
    // Exactly 2 worker threads
}

// With time control
#[tokio::test(start_paused = true)]
async fn test_with_time_control() {
    // Time starts paused for deterministic testing
    tokio::time::advance(Duration::from_secs(60)).await;
}
```

### Testing Timeouts

```rust
use tokio::time::{timeout, Duration};

#[tokio::test]
async fn test_operation_completes_in_time() {
    let result = timeout(
        Duration::from_secs(5),
        slow_operation()
    ).await;
    
    assert!(result.is_ok(), "Operation timed out");
}

#[tokio::test]
async fn test_timeout_triggers() {
    let result = timeout(
        Duration::from_millis(100),
        never_completes()
    ).await;
    
    assert!(result.is_err(), "Expected timeout");
}
```

### Testing Channels

```rust
use tokio::sync::mpsc;

#[tokio::test]
async fn test_channel_communication() {
    let (tx, mut rx) = mpsc::channel(10);
    
    tokio::spawn(async move {
        tx.send("hello").await.unwrap();
        tx.send("world").await.unwrap();
    });
    
    assert_eq!(rx.recv().await, Some("hello"));
    assert_eq!(rx.recv().await, Some("world"));
    assert_eq!(rx.recv().await, None);
}
```

### Testing with Mocks

```rust
use mockall::*;

#[automock]
#[async_trait::async_trait]
trait Database {
    async fn get_user(&self, id: u64) -> Option<User>;
}

#[tokio::test]
async fn test_with_mock_database() {
    let mut mock = MockDatabase::new();
    mock.expect_get_user()
        .with(eq(42))
        .returning(|_| Some(User { id: 42, name: "Alice".into() }));
    
    let service = UserService::new(mock);
    let user = service.find_user(42).await;
    
    assert_eq!(user.unwrap().name, "Alice");
}
```

### See Also

- [async-tokio-runtime](#async-tokio-runtime) - Runtime configuration
- [test-mock-traits](#test-mock-traits) - Mocking async traits
- [test-fixture-raii](#test-fixture-raii) - Async test cleanup


## test-use-super

> Use `use super::*;` in test modules to access parent module items

### Why It Matters

The test module is a child of the module being tested. `use super::*` imports all items from the parent module, including private ones. This gives tests access to both public API and internal implementation details for thorough testing.

### Bad

```rust
// Verbose imports
#[cfg(test)]
mod tests {
    use crate::my_module::public_function;
    use crate::my_module::MyStruct;
    // Can't access private items this way!
    
    #[test]
    fn test_function() {
        let result = public_function();
        // ...
    }
}
```

### Good

```rust
// src/my_module.rs
pub struct PublicStruct { ... }
struct PrivateStruct { ... }  // Private

pub fn public_function() -> i32 { ... }
fn private_helper() -> i32 { ... }  // Private

#[cfg(test)]
mod tests {
    use super::*;  // Imports everything from parent
    
    #[test]
    fn test_public_struct() {
        let s = PublicStruct::new();
        // ...
    }
    
    #[test]
    fn test_private_struct() {
        let s = PrivateStruct::new();  // Can access private!
        // ...
    }
    
    #[test]
    fn test_private_helper() {
        assert_eq!(private_helper(), 42);  // Can test private!
    }
}
```

### Selective Imports

```rust
#[cfg(test)]
mod tests {
    // When you want to be explicit
    use super::{parse, ParseError, Token};
    
    // Or import all plus test utilities
    use super::*;
    use std::fs;
    use tempfile::TempDir;
    
    #[test]
    fn test_parse() { ... }
}
```

### Nested Modules

```rust
mod outer {
    pub fn outer_fn() -> i32 { 1 }
    
    mod inner {
        pub fn inner_fn() -> i32 { 2 }
        
        #[cfg(test)]
        mod tests {
            use super::*;           // Gets inner's items
            use super::super::*;    // Gets outer's items
            
            #[test]
            fn test_inner() {
                assert_eq!(inner_fn(), 2);
                assert_eq!(outer_fn(), 1);
            }
        }
    }
}
```

### With External Dependencies

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    // Test-only dependencies
    use proptest::prelude::*;
    use mockall::predicate::*;
    
    proptest! {
        #[test]
        fn test_property(s: String) {
            let result = process(&s);
            prop_assert!(result.is_ok());
        }
    }
}
```

### See Also

- [test-cfg-test-module](#test-cfg-test-module) - Test module structure
- [test-integration-dir](#test-integration-dir) - Integration tests
- [proj-pub-crate-internal](#proj-pub-crate-internal) - Visibility modifiers
