# Compiler Errors Quick Reference

## Borrow Checker

| Error | Meaning | Fix |
|-------|---------|-----|
| E0382 | Use of moved value | Borrow instead of move, or clone |
| E0502 | Borrow conflicts (mutable + immutable) | Restructure to avoid simultaneous borrows |
| E0507 | Cannot move out of borrowed content | Clone or restructure ownership |
| E0716 | Temporary value dropped while borrowed | Bind to a variable first |

## Type Mismatches

| Error | Meaning | Fix |
|-------|---------|-----|
| E0308 | Mismatched types | Check expected vs actual type |
| E0277 | Trait bound not satisfied | Add bound or implement trait |
| E0282 | Type annotations needed | Add explicit type annotation |

## Method Resolution

| Error | Meaning | Fix |
|-------|---------|-----|
| E0596 | Cannot borrow as mutable | Add `mut` to binding |
| E0599 | No method found | Check trait imports, type correctness |
| E0615 | Attempted to take method as field | Use `()` to call: `obj.method()` |

## Edition 2024 Specific

| Error | Meaning | Fix |
|-------|---------|-----|
| `unsafe_op_in_unsafe_fn` | Unsafe op in unsafe fn without `unsafe` block | Wrap in `unsafe { ... }` |
| `extern` without `unsafe` | Extern blocks now require `unsafe` | `unsafe { extern "C" { ... } }` |
| `gen` keyword conflict | `gen` reserved in edition 2024 | Rename variable |

## Quick Fixes

```bash
cargo check              # Fast compile check
cargo check --message-format=short  # Concise errors
cargo fix                 # Auto-fix some errors
cargo fix --edition       # Edition migration fixes
```
