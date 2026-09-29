<!-- This file is loaded on demand from the main SKILL.md Deep Dives section -->

## Part 7: Error Design with thiserror

### When to Use `thiserror` vs `anyhow`

| Tool | Best For | Example |
|------|----------|---------|
| **`thiserror`** | Library errors, enum-based errors, public APIs | `ScanError::FileNotFound`, `ConfigError::InvalidPath` |
| **`anyhow`** | Application-level error aggregation, CLI tools | `Result<T, anyhow::Error>` in `main()` |

baco uses `thiserror` 9:1 over `anyhow` (225 vs 26 mentions) — this is the standard pattern for libraries.

### Designing Error Enums

```rust
use thiserror::Error;
use std::path::PathBuf;

#[derive(Debug, Error)]
pub enum ScanError {
    #[error("file not found: {path}")]
    FileNotFound { path: PathBuf },

    #[error("invalid configuration: {0}")]
    InvalidConfig(String),

    #[error("scan failed: {source}")]
    ScanFailed {
        #[from]
        source: std::io::Error,
    },

    #[error("semgrep error: {0}")]
    Semgrep(#[from] SemgrepError),

    #[error("phase {phase} timed out after {duration}s")]
    Timeout { phase: String, duration: u64 },
}
```

### The `#[from]` Attribute

Automatically implements `From<E>` for your error type, enabling the `?` operator:

```rust
// With #[from]
#[derive(Debug, Error)]
pub enum ScanError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}

// Now this works:
fn read_file(path: &Path) -> Result<String, ScanError> {
    let content = std::fs::read_to_string(path)?;  // Auto-converts io::Error
    Ok(content)
}

// Without #[from], you'd need:
fn read_file(path: &Path) -> Result<String, ScanError> {
    let content = std::fs::read_to_string(path)
        .map_err(ScanError::Io)?;  // Manual conversion
    Ok(content)
}
```

### Error Context Chaining

Wrap errors at each layer with structured context:

```rust
fn load_config(path: &Path) -> Result<Config, ScanError> {
    // Layer 1: IO error → FileNotFound
    let content = std::fs::read_to_string(path)
        .map_err(|e| ScanError::FileNotFound { path: path.to_path_buf() })?;
    
    // Layer 2: Parse error → InvalidConfig
    let config: Config = serde_json::from_str(&content)
        .map_err(|e| ScanError::InvalidConfig(format!("JSON parse: {}", e)))?;
    
    Ok(config)
}
```

### Unifying Errors Across Modules

When multiple modules produce different error types, create a top-level enum:

```rust
// scanner/error.rs
use thiserror::Error;

#[derive(Debug, Error)]
pub enum ScanError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("semgrep error: {0}")]
    Semgrep(#[from] semgrep::SemgrepError),

    #[error("config error: {0}")]
    Config(#[from] config::ConfigError),

    #[error("scan failed: {message}")]
    ScanFailed { message: String },
}

// semgrep/error.rs
#[derive(Debug, Error)]
pub enum SemgrepError {
    #[error("semgrep not found")]
    NotInstalled,
    #[error("semgrep exited with code {code}")]
    ExitCode { code: i32 },
}

// config/error.rs
#[derive(Debug, Error)]
pub enum ConfigError {
    #[error("missing field: {field}")]
    MissingField { field: String },
}
```

### Common Pitfalls

| Pitfall | Consequence | Fix |
|---------|-------------|-----|
| Forgetting `#[from]` and writing manual `From` impls | Boilerplate, error-prone | Use `#[from]` for automatic conversion |
| Using `String` error messages instead of structured variants | Lost context, hard to match on | Use enum variants with typed fields |
| Not deriving `Debug` on the error enum | Compilation error (required by `Error` trait) | Add `#[derive(Debug, Error)]` |
| Flat enum with 20+ variants | Hard to navigate, unclear domain boundaries | Nest by domain — create submodule error types |
| Mixing `thiserror` and `anyhow` in the same module | Confusing error handling strategy | Pick one per module — `thiserror` for libraries, `anyhow` for app entry points |

### Example: Complete Error Design

```rust
use thiserror::Error;
use std::path::PathBuf;

// Domain-specific error types
#[derive(Debug, Error)]
pub enum ConfigError {
    #[error("config file not found: {0}")]
    NotFound(PathBuf),

    #[error("invalid config: {0}")]
    ParseError(String),
}

#[derive(Debug, Error)]
pub enum ScanError {
    #[error("config error: {0}")]
    Config(#[from] ConfigError),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("no findings")]
    NoFindings,
}

// Usage with context
fn run_scan(config_path: &Path) -> Result<(), ScanError> {
    let config = load_config(config_path)?;  // ConfigError auto-converted
    let results = scan(&config)?;            // Io error auto-converted
    
    if results.is_empty() {
        return Err(ScanError::NoFindings);
    }
    
    Ok(())
}
```