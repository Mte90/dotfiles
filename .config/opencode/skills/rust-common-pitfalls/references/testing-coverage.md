<!-- This file is loaded on demand from the main SKILL.md Deep Dives section -->

## Part 3: Test Organization

### Module Structure

```text
my_crate/
├── src/
│   └── lib.rs
├── tests/
│   ├── integration_test.rs    # One file = one test binary
│   └── common/
│       └── mod.rs             # Shared test utilities
└── src/
    └── some_module.rs         # Inline tests below
```

### Inline Tests in Source

```rust
// src/some_module.rs

pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;

    // Unit tests for this module
    #[test]
    fn test_add_positive() {
        assert_eq!(add(2, 3), 5);
    }

    #[test]
    fn test_add_negative() {
        assert_eq!(add(-1, 1), 0);
    }

    #[test]
    fn test_add_returns_error_when_overflow() {
        // Test error conditions
        let result = add(i32::MAX, 1);
        assert!(result.is_negative());  // Wraps to negative
    }
}
```

### Integration Tests

```rust
// tests/integration_test.rs
use my_crate::{add, User, UserBuilder};

#[test]
fn test_full_user_flow() {
    // Integration test - tests components working together
    let user = UserBuilder::new()
        .name("Test")
        .email("test@example.com")
        .age(25)
        .build()
        .unwrap();

    assert_eq!(user.name(), "Test");
}

#[test]
fn test_invalid_email_rejected() {
    let result = UserBuilder::new()
        .name("Test")
        .email("invalid-email")
        .build();

    assert!(result.is_err());
}
```

### Test Modules Inside impl Blocks (Advanced)

**⚠️ Rare pattern - use only when necessary:**

```rust
pub struct Config {
    value: i32,
}

impl Config {
    pub fn new(value: i32) -> Self {
        Self { value }
    }

    #[cfg(test)]
    mod tests {
        use super::*;

        #[test]
        fn test_new_creates_config() {
            let cfg = Config::new(42);
            assert_eq!(cfg.value, 42);
        }
    }
}
```

### Test Naming Conventions

```rust
#[cfg(test)]
mod tests {
    use super::*;

    // DESCRIPTIVE: test_function_scenario_expected_behavior
    #[test]
    fn test_user_new_rejects_empty_email() {
        assert!(User::new("name", "").is_err());
    }

    #[test]
    fn test_builder_provides_defaults_for_optional_fields() {
        let user = UserBuilder::new()
            .name("Test")
            .email("test@example.com")
            .build()
            .unwrap();
        assert_eq!(user.age(), 0);  // default
    }

    // Group related tests with prefix
    #[test]
    fn test_vulnerability_sql_injection_severity_is_high() {
        let finding = VulnerabilityFinding::sql_injection(
            Location::new("test.rs", 1),
            "SELECT * FROM users"
        );
        assert!(matches!(finding.severity(), Severity::High));
    }
}
```

---

## Part 4: Code Coverage Enforcement

### Cargo Configuration

```toml
# .cargo/config.toml
[profile.release]
lto = true
opt-level = 3

[profile.dev]
debug = true
```

### CI Integration with cargo-llvm-cov

```yaml
# .github/workflows/coverage.yml
name: Coverage

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Rust
        uses: dtolnay/rust-toolchain@stable
        with:
          components: llvm-tools-preview
      
      - name: Install cargo-llvm-cov
        uses: taiki-e/install-action@cargo-llvm-cov
      
      - name: Generate coverage
        run: cargo llvm-cov --workspace --lcov --output-path lcov.info
      
      - name: Upload to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: lcov.info
          fail_ci_if_error: true
          threshold: 80%
```

### Coverage with Failure Threshold

```bash
# Run with minimum coverage requirement
cargo llvm-cov --fail-under-lines 80

# Or in CI with specific targets
cargo llvm-cov --fail-under-lines 80 \
  --fail-under-functions 70 \
  --fail-under-regions 60
```

### Excluding Code from Coverage

```rust
// Exclude generated code
#[cfg(test)]
mod generated_tests {
    // Tests for generated code - exclude from coverage
    include!("generated.rs");
}

// Exclude platform-specific code
#[cfg(target_os = "linux")]
fn linux_only_function() { /* ... */ }

#[cfg(not(target_os = "linux"))]
fn linux_only_function() {
    unreachable!("Linux only");
}
```

### Coverage Reports

```bash
# HTML report
cargo llvm-cov --html

# Terminal summary
cargo llvm-cov

# JSON for CI tools
cargo llvm-cov --json --output-path coverage.json
```