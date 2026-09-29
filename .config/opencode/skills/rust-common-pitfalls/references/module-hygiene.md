<!-- This file is loaded on demand from the main SKILL.md Deep Dives section -->

## Part 6: Module Splitting Strategies and Dead Code Detection

### Field Log from baco: Undeclared Modules and #[ignore] Accumulation

**Pitfall #1: Module file exists but never declared in lib.rs** (ses_125f87e23ffe)

Silent dead code: 9 dead modules, 3274 lines in baco (e.g., attack_scenarios.rs:474, endpoints.rs:248).

**Detection**:
```bash
# Audit mod declarations vs file existence
cargo-modules tree --format json  # Requires cargo-modules crate

# Manual grep: find .rs files without corresponding `mod` in lib.rs
find src -name "*.rs" -exec grep -L "mod {}" lib.rs \;

# Check for orphaned modules
grep -r "^mod " src/ | cut -d: -f2 | sed 's/mod //;s/;//' | sort > /tmp/declared_mods.txt
find src -name "*.rs" | sed 's|.*/||;s/\.rs$//' | sort > /tmp/files.txt
comm -23 /tmp/files.txt /tmp/declared_mods.txt  # Shows undeclared files
```

**Pitfall #8: Disabled #[ignore]/#[cfg] tests as dead weight** (ses_125f87e23ffe)

3 tests, 208 lines of dead code in baco from accumulated `#[ignore]` tests.

**Detection**:
```bash
# Find ignored tests
grep -rn "#\[ignore\]" src/ tests/

# Find cfg-gated dead code
grep -rn "#\[cfg(not(test))\]" src/ | grep -v "// "

# Count disabled tests
cargo test -- --list 2>/dev/null | grep -c "ignored"
```

### Duplicate Code Detection

**Pitfall #5-7 from baco** (ses_125f87e23ffe, ses_1015b0539ffe):

- Cross-phase boilerplate duplication: LLM client config x3 → deduplicated to `create_llm_client_with_metrics()` in src/llm.rs (-36 lines)
- Intra-file duplicate blocks: conflict_resolver.rs:24-33 == :37-41 (39 tokens)
- Cross-file duplicates: indexing.rs:46-51 == llm_static.rs:83-88 (44 tokens; 73 groups total)

**Detection with aft_inspect**:
```bash
# Run inspect to find duplicate groups
aft_inspect --sections duplicates
```

**Manual detection**:
```bash
# Use fdupes or rdfind for exact duplicates
fdupes -r src/

# For semantic duplicates: use cargo-deny or custom diff scripts
# Pattern: extract function, check if same logic appears elsewhere
grep -rn "fn create_llm_client" src/  # Should be 1, not 3
```

**Fix pattern**: Extract common logic to shared helper:
```rust
// Before: 3 copies of LLM client creation
async fn scan_llm_client() -> LLMClient { ... }
async fn index_llm_client() -> LLMClient { ... }
async fn report_llm_client() -> LLMClient { ... }

// After: Single source of truth
async fn create_llm_client_with_metrics(phase: &str) -> LLMClient {
    // Shared logic with phase-specific metrics
}
```

### When to Split a Module

Signs a module has outgrown its single file:
- **>300 lines** — readability degrades, navigation becomes painful
- **Multiple responsibilities** — scanner logic mixed with staging, error handling, and output formatting
- **Frequent merge conflicts** — multiple developers editing the same large file
- **Hard to test** — too many internal dependencies to isolate units

### The `mod.rs` vs `mod/` Directory Pattern

**Before** (single large file):
```rust
// scanner.rs (500 lines)
pub fn scan_phase(phase: ScanPhase) -> Result<Vec<Finding>, ScanError> { ... }
pub fn stage_results(findings: &[Finding]) -> StagedResults { ... }
pub fn run_semgrep(path: &Path) -> Result<SemgrepOutput, SemgrepError> { ... }
// ... 490 more lines
```

**After** (split into submodules):
```rust
// scanner/mod.rs
pub mod phases;
pub mod staging;
pub mod semgrep;

// Re-export public API so callers see no difference
pub use phases::scan_phase;
pub use staging::stage_results;
pub use semgrep::run_semgrep;

// Also re-export types used in public signatures
pub use phases::ScanPhase;
pub use staging::StagedResults;
```

```rust
// scanner/phases.rs
use crate::scanner::{ScanPhase, Finding, ScanError};

pub fn scan_phase(phase: ScanPhase) -> Result<Vec<Finding>, ScanError> {
    // Implementation
}
```

### Visibility Strategy

| Visibility | Use Case |
|------------|----------|
| `pub` | True public API — stable across versions |
| `pub(crate)` | Internal cross-module access within the crate |
| (no `pub`) | Private to the module — implementation detail |

```rust
// scanner/mod.rs
pub mod phases;
mod staging_internal;  // Private helper module

pub use phases::scan_phase;

// Internal function, not exposed
pub(crate) fn internal_helper() -> Result<(), ScanError> {
    // Used by multiple modules but not part of public API
}
```

```rust
// scanner/phases.rs
use crate::scanner::internal_helper;  // Can access pub(crate)

pub fn scan_phase(phase: ScanPhase) -> Result<Vec<Finding>, ScanError> {
    internal_helper()?;  // Cross-module internal access
    // ...
}
```

### Preserving API Compatibility During Refactor

When splitting a module, maintain the **public facade**:

```rust
// Before split — callers import from scanner
use scanner::scan_phase;
use scanner::ScanPhase;

// After split — same imports still work
use scanner::scan_phase;  // Re-exported from scanner/mod.rs
use scanner::ScanPhase;   // Re-exported type
```

**Key steps:**
1. Create `scanner/mod.rs` with `pub mod` declarations
2. Move functions/types to appropriate submodules
3. Add `pub use` re-exports in `mod.rs` for all public symbols
4. Run tests — integration tests should pass without modification

### Common Pitfalls

| Pitfall | Consequence | Fix |
|---------|-------------|-----|
| Forgetting to re-export types in public signatures | Callers get "type not found" errors | Add `pub use submodule::TypeName` in `mod.rs` |
| Using `mod` instead of `pub mod` | Submodule not accessible outside parent | Change to `pub mod` if submodule is part of public API |
| Circular dependencies between submodules | Compilation error | Restructure — extract shared code to a separate module |
| Forgetting `pub` on items in submodules | Items not visible even with `pub use` | Ensure items are `pub` in their defining module |
| Integration test imports break | Test fails to compile | Verify `mod.rs` re-exports match the old single-file API |

### Integration Test Imports

After splitting, integration tests continue to work if `mod.rs` re-exports correctly:

```rust
// tests/integration_test.rs
use my_crate::scanner::{scan_phase, ScanPhase};  // Still works!

#[test]
fn test_scan_phase() {
    let results = scan_phase(ScanPhase::Semgrep).unwrap();
    assert!(!results.is_empty());
}
```