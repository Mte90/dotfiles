# Amber Skills Reference Guide

This guide helps contributors to Amber understand the various skills and knowledge areas needed to effectively contribute to the project. Whether you're working on the compiler, standard library, documentation, or tooling, this reference will help you navigate the ecosystem.

## Table of Contents
- [Compiler Development](#compiler-development)
- [Standard Library](#standard-library)
- [Language Syntax](#language-syntax)
- [Testing](#testing)
- [Tooling](#tooling)

---

## Compiler Development

The Amber compiler is written in Rust and follows a multi-stage compilation pipeline. Understanding the compiler architecture is essential for any significant contributions.

### Core Compiler Modules

| Module | Location | Purpose |
|--------|----------|---------|
| `main.rs` | `src/main.rs` | CLI entry point, argument parsing with `clap` |
| `compiler.rs` | `src/compiler.rs` | Main compiler driver, orchestrates pipeline |
| `rules.rs` | `src/rules.rs` | Lexical rules for tokenization |
| `modules/` | `src/modules/` | Syntax modules (parser/translator) |
| `translate/` | `src/translate/` | IR generation and Bash translation |

### Compilation Pipeline

```
Lexer → Parser → TypeChecker → Translator → Optimizer → Renderer
```

1. **Tokenization**: Converts source code into tokens using `rules.rs`
2. **Parsing**: Builds AST using Heraclitus framework
3. **Type Checking**: Validates and infers types
4. **Translation**: Converts AST to `FragmentKind` IR
5. **Optimization**: Removes redundant code
6. **Rendering**: Generates final Bash script

### Key Compiler Concepts

#### Syntax Modules
Syntax modules implement the `SyntaxModule<T>` trait with methods:
- `parse()`: Parses tokens into AST nodes (returns `SyntaxResult`)
- `typecheck()`: Validates types (returns `SyntaxResult`)
- `translate()`: Converts to `FragmentKind` IR

#### Parsing Helpers (Heraclitus Framework)
| Function | Purpose |
|----------|---------|
| `token(meta, "keyword")` | Match and consume specific token (returns Quiet error if missing) |
| `token_by(meta, predicate)` | Match token by predicate function |
| `syntax(meta, submodule)` | Recursively parse nested module |
| `error!(meta, token, ...)` | Generate Loud error (halt compilation) |
| `error_pos!(meta, pos => ...)` | Generate error at specific position |

#### Failure Handling
- **Quiet Error**: "This doesn't match, try another module" - caught and backtracked
- **Loud Error**: "This matches but code is invalid" - halts compilation

#### Fragments (IR)
| Fragment Type | Bash Output | Purpose |
|---------------|-------------|---------|
| `RawFragment` | `echo "hello"` | Raw shell code |
| `BlockFragment` | `{ ... }` | Code blocks |
| `ListFragment` | `a; b; c` | Sequence of fragments |
| `SubprocessFragment` | `$(...)` | Command substitution |
| `VarExprFragment` | `$VAR` | Variable access |
| `VarStmtFragment` | `VAR=...` | Variable assignment |
| `ArithmeticFragment` | `(( expr ))` | Arithmetic context |

### Compiler Flags

Compiler flags can customize behavior per function:

```ab
#[allow_nested_if_else]
fun foo() {
    // ...
}

#[allow_generic_return]
fun bar(): Text? {
    // ...
}

#[allow_absurd_cast]
fun baz() {
    // ...
}
```

Available flags:
- `allow_nested_if_else`: Disable if-chain warnings
- `allow_generic_return`: Suppress generic return type warnings
- `allow_absurd_cast`: Disable absurd cast warnings

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `AMBER_DEBUG_PARSER` | Enable parser AST tracing |
| `AMBER_DEBUG_TIME` | Show compilation phase timing |
| `AMBER_NO_OPTIMIZE` | Disable optimizer (value: `1`) |
| `AMBER_HEADER` | Custom header in generated scripts |
| `AMBER_FOOTER` | Custom footer in generated scripts |

---

## Standard Library

The standard library is written in Amber itself and located in `src/std/`. Each module provides utilities for common tasks.

### Standard Library Modules

| Module | Path | Key Functions |
|--------|------|---------------|
| **text** | `src/text.ab` | String manipulation, regex |
| **env** | `src/env.ab` | Environment variables, user input |
| **fs** | `src/fs.ab` | File operations, directories |
| **http** | `src/http.ab` | HTTP requests |
| **array** | `src/array.ab` | Array manipulation |
| **math** | `src/math.ab` | Mathematical operations |
| **date** | `src/date.ab` | Date/time utilities |
| **test** | `src/test.ab` | Testing utilities |

### Standard Library Patterns

#### Importing
```ab
// Single function
import { capitalize } from "std/text"

// All functions
import * from "std/http"

// Aliasing (not supported - use full module path)
```

#### Failable Functions
Many stdlib functions are failable (return `Type?`):

```ab
// Before (0.4.x)
if dir_create("mydir") {
    // success
} else {
    // failure
}

// After (0.5.x)
dir_create("mydir") exited(code) {
    if code == 0 {
        echo "Success"
    } else {
        echo "Failed with code {code}"
    }
}
```

### Text Module (`std/text`)

| Function | Description |
|----------|-------------|
| `capitalize(text)` | Capitalize first letter |
| `char_at(text, index)` | Get character at index |
| `ends_with(text, suffix)` | Check suffix |
| `join(list, delimiter)` | Join array with delimiter |
| `lowercase(text)` | Convert to lowercase |
| `lpad(text, pad, length)` | Left padding |
| `match_regex(source, search, extended)` | Regex matching |
| `parse_int(text)` | Parse to Integer (failable) |
| `parse_num(text)` | Parse to Number (failable) |
| `replace(source, search, replace)` | Replace all occurrences |
| `replace_regex(source, search, replace, extended)` | Regex replace |
| `reversed(text)` | Reverse string |
| `rpad(text, pad, length)` | Right padding |
| `slice(text, index, length)` | Extract substring |
| `split(text, delimiter)` | Split by delimiter |
| `split_chars(text)` | Split into characters |
| `split_lines(text)` | Split by newlines |
| `starts_with(text, prefix)` | Check prefix |
| `text_contains(source, search)` | Check substring |
| `trim(text)` | Trim whitespace |
| `uppercase(text)` | Convert to uppercase |
| `zfill(text, length)` | Zero-padding |

### Array Module (`std/array`)

| Function | Description |
|----------|-------------|
| `array_contains(array, value)` | Check if value exists |
| `array_extract_at(ref array, index)` | Remove and return element |
| `array_filled(size, value)` | Create filled array |
| `array_find(array, value)` | Find first index |
| `array_find_all(array, value)` | Find all indices |
| `array_first(array)` | Get first element |
| `array_last(array)` | Get last element |
| `array_pop(ref array)` | Remove last element |
| `array_remove_at(ref array, index)` | Remove at index |
| `array_shift(ref array)` | Remove first element |

### File System Module (`std/fs`)

| Function | Description |
|----------|-------------|
| `dir_create(path)` | Create directory recursively |
| `dir_exists(path)` | Check if directory exists |
| `file_append(path, content)` | Append to file |
| `file_chmod(path, mode)` | Change permissions |
| `file_chown(path, user)` | Change owner |
| `file_exists(path)` | Check if file exists |
| `file_extract(path, target)` | Extract archive |
| `file_glob(path)` | Find matching files |
| `file_read(path)` | Read file contents |
| `file_write(path, content)` | Write file |
| `symlink_create(origin, dest)` | Create symlink |
| `temp_dir_create(template, auto_delete, force_delete)` | Create temp directory |

---

## Language Syntax

### Data Types

| Type | Description |
|------|-------------|
| `Text` | String of characters |
| `Int` | 64-bit signed integer |
| `Num` | Floating-point number |
| `Bool` | Boolean (`true`/`false`) |
| `Null` | Nothing value |
| `[T]` | Array of type T |

### Type System

#### Union Types
 Functions can accept multiple types:
```ab
fun process(data: [Bool] | [Int]) {
    // ...
}
```

#### Type Casting
```ab
// Valid cast
let num = true as Int  // 0 or 1

// Absurd cast (warning)
let num = "123" as Int  // Use parse_int() instead
```

#### Type Condition
Runtime type checking:
```ab
fun getObject(value) {
    if {
        value is Text: getByName(value)
        value is Num: getById(value)
    }
}
```

### Variables

```ab
// Declaration
let name = "John"
let age: Int = 30

// Reassignment
name = "Rob"

// Constant
const PI = 3.14159

// Type inference with empty arrays
let arr = []  // Type inferred later
arr += [1]    // Now [Int]
```

### Functions

```ab
// Basic function
fun myFunction(arg1, arg2) {
    return arg1 + arg2
}

// Typed function
fun add(a: Int, b: Int): Int {
    return a + b
}

// Default parameters
fun greet(name: Text = "World"): Text {
    return "Hello {name}"
}

// Failable function
fun mightFail(): Text? {
    fail 1  // Explicit failure
    return "success"?
}

// Reference parameter
fun push(ref array, value) {
    array += [value]
}
```

### Control Flow

#### If Statements
```ab
if age < 18 {
    echo "Minor"
} else if age < 65 {
    echo "Adult"
} else {
    echo "Senior"
}
```

#### Loops
```ab
// For loop
for fruit in ["apple", "banana"] {
    echo fruit
}

// Range
for i in 0..3 {
    echo i  // 0, 1, 2
}

// While loop
while condition {
    // ...
}
```

#### Switch-like with Type Condition
```ab
if {
    value is Text: handleText(value)
    value is Int: handleInt(value)
}
```

### Commands

```ab
// Command statement
$ mv file.txt dest.txt $ failed(code) {
    echo "Failed with code {code}"
}

// Command expression
let result = $ cat file.txt $ succeeded {
    echo "Success: {result}"
}

// Modifiers
sudo trust $ apt update $  // Privilege escalation + no failure check
silent $ apt update $      // Suppress output
```

#### Command Modifiers
| Modifier | Purpose |
|----------|---------|
| `silent` | Suppress stdout/stderr |
| `trust` | No failure handling required |
| `sudo` | Runtime privilege escalation |
| `failed` | Handle failure case |
| `succeeded` | Handle success case |
| `exited` | Handle both cases with exit code |

---

## Testing

### Test Blocks

```ab
import { assert } from "std/test"

test "can multiply numbers" {
    let result = 10 * 2
    assert(result == 20)
}

test {
    let sum = 1 + 2
    assert(sum == 3)
}
```

### Running Tests

```bash
# Run all tests
amber test

# Filter by filename/test name
amber test "variable"

# Run specific file
amber test main.ab

# Filter specific file
amber test main.ab "zip"
```

### Test File Organization

Tests are in `src/tests/`:
- `validity/`: Expected success cases
- `erroring/`: Expected compilation errors
- `stdlib/`: Standard library functionality

---

## Tooling

### CLI Commands

| Command | Description |
|---------|-------------|
| `amber run file.ab` | Compile and execute |
| `amber build file.ab -o out.sh` | Compile to Bash |
| `amber check file.ab` | Validate without output |
| `amber eval 'code'` | Execute inline code |
| `amber docs file.ab` | Generate documentation |
| `amber completion` | Generate shell completions |
| `amber test` | Run tests |

### Global Options

| Option | Description |
|--------|-------------|
| `--no-proc <pattern>` | Disable postprocessor |
| `--minify` | Compress output |

### Postprocessors

| Postprocessor | Purpose |
|---------------|---------|
| `bshchk` | Bash validation and best practices checker |

### Editor Integrations

| Editor | Extension |
|--------|-----------|
| VS Code | [amber-language](https://marketplace.visualstudio.com/items?itemName=Ph0enixKM.amber-language) |
| Zed | [zed-amber-extension](https://github.com/amber-lang/zed-amber-extension) |
| Helix | Native support |
| Nova | [besya.amber](https://extensions.panic.com/extensions/besya/besya.amber/) |
| Vim | [amber-vim](https://github.com/amber-lang/amber-vim) |

### LSP Support

Amber LSP provides:
- Autocompletion
- Real-time error checking
- Smart suggestions
- Go-to definition
- Hover documentation

Available for VS Code, Zed, and Helix.

---

## Contributing Guide

### PR Process

1. **Create an issue** discussing the proposed changes
2. **Fork the repository** and create a branch
3. **Implement changes** following project conventions
4. **Add tests** in `src/tests/`
5. **Open a PR** targeting the `staging` branch
6. **Await review** (minimum 2 maintainer approvals)

### Development Setup

```bash
# Clone and build
git clone https://github.com/amber-lang/amber
cd amber
cargo build

# Run Amber code
cargo run run script.ab

# Build to Bash
cargo run build input.ab output.sh

# Debug
AMBER_DEBUG_PARSER=true cargo run run script.ab
AMBER_DEBUG_TIME=true cargo run run script.ab

# Profile
cargo flamegraph -- script.ab
```

### Testing in Codebase

```bash
# All tests
cargo test

# Specific module
cargo test stdlib

# Single test
cargo test function_with_wrong_typed_return
```

### Code Style

- Follow existing patterns in `src/modules/`
- Use Heraclitus macros (`syntax_name!`, `parse_statement!`, etc.)
- Add tests for new features
- Ensure shellcheck compliance in generated Bash

---

## Migration Notes

### 0.4.0-alpha → 0.5.0-alpha

| Change | Before | After |
|--------|--------|-------|
| Integer type | `Num` | `Int` for indices, ranges, loops |
| Text to Bool/Int | Direct cast | Use `parse_int()`/`parse_num()` |
| Array subscript | `arr[12.0]` | `arr[12]` (Int only) |
| Range | `10.0..15.0` | `10..15` (Int only) |
| Reversed range | Not supported | `6..3` supported |
| `parse_number` | Function name | Renamed to `parse_num` |
| `env_const_get` | Function name | Removed, use `env_var_get` |

---

## Resources

### Official Documentation
- [Amber Website](https://amber-lang.com/)
- [Documentation](https://docs.amber-lang.com/)
- [GitHub Repository](https://github.com/amber-lang/amber)
- [Amber LSP](https://github.com/amber-lang/amber-lsp)

### Community
- [Discord](https://discord.com/invite/cjHjxbsDvZ)
- [Discussions](https://github.com/amber-lang/Amber/discussions)

### Key Files for Reference

| File | Purpose |
|------|---------|
| `src/main.rs` | CLI entry point |
| `src/compiler.rs` | Compiler driver |
| `src/rules.rs` | Lexical rules |
| `src/modules/` | Syntax modules |
| `src/translate/` | Bash translation |
| `src/std/*.ab` | Standard library |
| `src/tests/` | Test suite |

---

## Quick Reference

### Common Tasks

| Task | How to |
|------|--------|
| Add new builtin | Create `src/modules/builtin/*.rs` |
| Add new stdlib function | Add to `src/std/*.ab` |
| Add test case | Add to `src/tests/validity/`, `erroring/`, or `stdlib/` |
| Generate docs | `amber docs file.ab` |
| Check syntax | `amber check file.ab` |
| Compile to Bash | `amber build file.ab -o out.sh` |

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Parser not matching | Check `SyntaxResult` return (Quiet vs Loud error) |
| Type checking failure | Verify `TypeCheckModule` implementation |
| Bash output invalid | Run `bshchk` manually on output |
| Confusing error | Set `AMBER_DEBUG_PARSER=true` |
| Slow compile | Set `AMBER_NO_OPTIMIZE=1` to disable optimizer |

---

**Last updated**: 2026-02-18
**Version**: 0.5.1-alpha
