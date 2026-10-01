---
name: ast-grep
description: Use when doing structural code search and rewriting - ast-grep linting, refactoring, multi-language patterns
metadata:
  author: mte90
  version: 1.0.1
  tags:
    - ast-grep
    - code-search
    - linting
    - refactoring
    - cli
    - ast
---

# ast-grep

Fast and user-friendly tool for large-scale code searching, linting, and rewriting using AST patterns.

## Overview

ast-grep (sg) is a CLI tool that searches code based on Abstract Syntax Tree patterns, similar to syntax-aware grep/sed. It supports multiple languages and can perform automated code refactoring.

- **Fast** - Written in Rust, processes code quickly
- **Polyglot** - Supports JavaScript, TypeScript, Python, Go, Rust, Java, C, C++, and more
- **Structural** - Matches code by AST patterns, not regex
- **Rewrite** - Automated code refactoring with metavariables

---

## Installation

```bash
# Via cargo
cargo install ast-grep

# Via npm
npm install -g ast-grep

# Download pre-built binary
curl -L https://github.com/ast-grep/ast-grep/releases/download/nightly/ast-grep-x86_64-unknown-linux-musl.tar.gz | tar xz
```

---

## Worked Rules: Real Defect Classes

This section shows three real-world rules that caught actual defects. Each demonstrates why ast-grep succeeds where grep fails.

### Security Rule: Unsafed SQL String Concatenation (Python)

Detects SQL queries built by string concatenation with user input — a SQL injection vulnerability.

```yaml
# rules/sql-injection.yml
id: sql-injection-concat
message: "SQL query built with string concatenation — possible injection vulnerability"
severity: error
language: Python
rule:
  all:
    - pattern: '$CURSOR.execute($SQL, $$$)'
    - has:
        pattern: '$USER_INPUT + $SQL'
        inside:
          pattern: '$SQL'
constraints:
  # $SQL must contain concatenation operator
  $SQL:
    kind: binary_expression
    has:
      pattern: '+'
severity: error
```

**Why grep cannot express this:**
- grep matches text patterns like `+` but cannot verify the context is a SQL execute call
- grep cannot distinguish `user_input + "hello"` from `user_input + "SELECT * FROM users"`
- ast-grep uses `inside` to confirm the concatenation feeds into `execute()`, and `kind` to verify it's a binary expression

**Test command:**
```bash
ast-grep scan --rule rules/sql-injection.yml src/
```

**What this catches:**
```python
# BAD — flagged
user_id = request.GET['id']
query = "SELECT * FROM users WHERE id = " + user_id
cursor.execute(query)

# OK — not flagged (parameterized query)
user_id = request.GET['id']
cursor.execute("SELECT * FROM users WHERE id = %s", [user_id])
```

---

### Correctness Rule: Empty Exception Handler

Detects `except Exception: pass` blocks that silently swallow errors — a common correctness bug.

```yaml
# rules/empty-except.yml
id: empty-except-block
message: "Empty exception handler swallows errors silently"
severity: warning
language: Python
rule:
  all:
    - pattern: 'except $EXC: pass'
    constraints:
      # $EXC must be Exception or a specific exception type
      $EXC:
        kind: identifier
        # Match 'Exception' or specific exception names
        regex: '^Exception$|^[A-Z][a-zA-Z]*Error$'
```

**Why grep cannot express this:**
- grep pattern `except.*: pass` matches too broadly (comments, multi-line, different contexts)
- grep cannot verify the `pass` is the only statement in the block
- ast-grep uses `all` to ensure both the exception clause AND the pass statement exist together structurally

**Test command:**
```bash
ast-grep scan --rule rules/empty-except.yml src/
```

**What this catches:**
```python
# BAD — flagged
try:
    process_data()
except Exception: pass  # Silent failure!

# BAD — flagged
try:
    connect_db()
except ConnectionError:
    pass  # Still silent!

# OK — not flagged (has logging)
try:
    process_data()
except Exception as e:
    logger.error(e)
```

---

### Convention Rule: `== None` vs `is None` (Python)

Detects Python code using `== None` instead of the idiomatic `is None`.

```yaml
# rules/none-comparison.yml
id: prefer-is-none
message: "Use 'is None' instead of '== None' for Pythonic code"
severity: warning
language: Python
rule:
  pattern: '$VALUE == None'
constraints:
  # Exclude None comparisons in comments
  $VALUE:
    kind:
      - identifier
      - attribute
      - call
    not:
      inside:
        kind: comment
```

**Why grep cannot express this:**
- grep pattern `== None` matches everywhere including comments and strings
- grep cannot distinguish `value == None` from `"x == None" in docstring`
- ast-grep uses `kind` constraints to match only actual comparison expressions

**Test command:**
```bash
ast-grep scan --rule rules/none-comparison.yml src/
```

**What this catches:**
```python
# BAD — flagged
if data == None:
    data = []

# OK — not flagged
if data is None:
    data = []

# OK — not flagged (in string, not actual comparison)
doc = "Check if value == None"
```

---

## False Positives: Practical Discipline

A bare pattern like `$X.foo()` matches thousands of hits across a codebase. This section explains how to narrow effectively.

### Why Patterns Blow Up

```yaml
# BAD — matches everything
rule:
  pattern: '$X.method()'
```

This matches every method call because `$X` is unconstrained. You get noise, not signal.

### Narrowing Strategies

**1. Use `constraints` to restrict metavariables:**

```yaml
rule:
  pattern: '$OBJ.value'
  constraints:
    $OBJ:
      kind: identifier  # Only simple names, not properties
      regex: '^data'    # Names starting with 'data'
```

**2. Use `inside` to require context:**

```yaml
rule:
  pattern: 'fetch($URL)'
  inside:
    pattern: 'useEffect(() => { $$$ }, $$$)'  # Only inside React effects
```

**3. Use `follows` / `precedes` for ordering:**

```yaml
rule:
  pattern: 'console.log($MSG)'
  follows:
    pattern: 'import $$$'  # Only after imports (debug logs at top)
```

**4. Use `has` for internal structure:**

```yaml
rule:
  pattern: 'function $NAME($$$)'
  has:
    pattern: 'await $$$'  # Async functions only
```

**5. Use `#` to trim leading context:**

When your pattern accidentally captures too much from the left, use `#` to anchor:

```yaml
# Matches only the statement, not the preceding line
rule:
  pattern: '# $X = $Y'  # The # anchors to statement start
```

### Filtering Results with `--json`

Pipe results into external filters for complex queries:

```bash
# Find matches in specific directories only
ast-grep -p 'console.log($$$)' --json src/ | \
  jq -r '.[] | select(.file_path | contains("component")) | .file_path'

# Count matches per file
ast-grep -p 'TODO' --json src/ | \
  jq -r '.[].file_path' | sort | uniq -c | sort -rn
```

### The Discipline

**Write rules against a known-bad sample, not against the codebase.**

1. Create a test file with the exact defect you want to catch
2. Write the rule to match that file
3. Add positive cases (should match) and negative cases (should not match)
4. Only then run against the full codebase

This avoids tuning rules on noise and ensures they catch what you intend.

---

## When NOT to Use ast-grep

Not every code search problem needs AST parsing. Use the right tool.

### Use grep/ripgrep Instead

| Scenario | Tool | Reason |
|----------|------|--------|
| Plain text search (comments, strings, literals) | `grep` / `rg` | Faster, simpler, no parsing overhead |
| Formatting/whitespace questions | `grep` | AST ignores whitespace |
| Simple literal patterns | `grep` | No AST needed for `TODO` or `FIXME` |
| Whole-file rewrites | `sed` / formatter | Safer, more predictable |
| Languages with poor parser support | `grep` | ast-grep may not parse correctly |

### The Check

- **If the pattern needs to ignore syntax** (searching text anywhere, including comments) → use grep
- **If the pattern needs to respect syntax** (only match actual function calls, not strings containing function calls) → use ast-grep

### Languages with Weaker Parsing

ast-grep parses most C-family languages well. Some languages have limitations:

| Language | Status | Notes |
|----------|--------|-------|
| JavaScript, TypeScript, Python, Go, Rust | ✅ Solid | Full AST support |
| Java, C, C++ | ✅ Good | Mature parsers |
| PHP, Ruby, Kotlin | ⚠️ Partial | Some edge cases |
| Scala, Haskell | ⚠️ Limited | Complex grammar challenges |
| Custom DSLs | ❌ Not supported | No parser available |

Check if your language parses correctly:

```bash
ast-grep -p 'pattern' --lang python --debug-query=ast file.py
```

If the query fails or produces unexpected AST nodes, the language support may be incomplete.

---

## CI Integration

### Pre-commit Hook

Run rules on staged files before commits:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/ast-grep/ast-grep
    rev: v0.25.0
    hooks:
      - id: ast-grep
        args: [scan, --config, sgconfig.yml]
```

Or invoke directly:

```bash
#!/bin/bash
# .git/hooks/pre-commit
ast-grep scan --config sgconfig.yml --error-on-match $(git diff --cached --name-only)
```

### CI Job (GitHub Actions)

Fail the build on rule violations:

```yaml
# .github/workflows/lint.yml
name: ast-grep lint
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install ast-grep
        run: npm install -g ast-grep
      - name: Scan with rules
        run: |
          ast-grep scan --config sgconfig.yml --error-on-match src/
```

The `--error-on-match` flag causes non-zero exit on any error-severity finding.

### Baseline Workflow for Existing Codebases

Adding rules to a large existing codebase creates noise — hundreds of matches on day one. Use baselining:

**Day 1: Capture existing findings as baseline**

```bash
ast-grep scan --config sgconfig.yml --json src/ > baseline-findings.json
```

**CI: Only fail on NEW findings**

```bash
ast-grep scan --config sgconfig.yml --json src/ | \
  jq -S '. - (input | .)' baseline-findings.json > new-findings.json

if [ "$(jq length new-findings.json)" -gt 0 ]; then
  echo "New issues detected:"
  jq -r '.[] | "\(.file_path):\(.range.start.line) \(.message)"' new-findings.json
  exit 1
fi
```

**Gradual cleanup:** Fix findings incrementally, updating the baseline after each batch.

---

## CLI Commands Reference

### Pattern Search

```bash
# Basic pattern search
ast-grep run --pattern 'console.log($ARG)' --lang javascript src/

# Short form
ast-grep -p 'console.log($$$ARGS)' src/

# Show context around matches
ast-grep -p 'TODO' --context 3 src/
```

### Rewrite Operations

```bash
# Search and rewrite
ast-grep -p '$OBJ.val && $OBJ.val()' --rewrite '$OBJ.val?.()' src/

# Interactive mode
ast-grep -p '$PROP && $PROP()' -r '$PROP?.()' --interactive src/

# Apply all without confirmation
ast-grep -p 'var $X' -r 'let $X' --update-all src/
```

### Linting

```bash
# Scan with rules file
ast-grep scan --rule rules/no-console.yml src/

# Scan with config
ast-grep scan --config sgconfig.yml src/

# Inline rule
ast-grep scan --inline-rules '
id: no-debugger
language: JavaScript
rule:
  pattern: debugger
' src/

# SARIF output for CI
ast-grep scan --format sarif src/
```

---

## Pattern Syntax Quick Reference

### Metavariables

| Syntax | Matches |
|--------|---------|
| `$VAR` | Single AST node |
| `$$$VARGS` | Zero or more nodes (variadic) |

### Relational Operators

| Operator | Meaning |
|----------|---------|
| `inside` | Pattern must be inside another pattern |
| `has` | Pattern must contain a sub-pattern |
| `follows` | Pattern appears after another |
| `precedes` | Pattern appears before another |
| `all` | All sub-patterns must match |
| `any` | At least one sub-pattern must match |
| `not` | Negation |

---

## Rule Configuration

### YAML Rule Structure

```yaml
id: unique-rule-id
message: "Human-readable message"
severity: error|warning|info
language: JavaScript|Python|Rust|...
rule:
  pattern: 'code pattern with $METAVARIABLES'
  # Optional relational operators
  inside:
    pattern: 'containing context'
  constraints:
    $METAVARIABLE:
      kind: node_kind
      regex: 'pattern'
fix:
  rewrite: 'replacement pattern'
```

### Project Configuration (sgconfig.yml)

```yaml
rules:
  - id: no-console
    message: "No console.log in production"
    severity: warning
    language: JavaScript
    rule:
      pattern: console.log($ARG)
```

---

## Best Practices

1. **Test patterns before rewriting** — Run without `--update-all` first
2. **Use `--interactive` for important changes** — Confirm each replacement
3. **Explicit language flag** — Avoid ambiguity with `--lang`
4. **Commit before mass rewrites** — Easy rollback if needed
5. **Write rules against known-bad samples** — Not against full codebase

---

## Deep Dives

For advanced topics, load these reference files on demand:

- **references/rule-authoring.md** — Deep dive into rule syntax, constraints, and advanced patterns (load when writing complex rules)
- **references/migration-guide.md** — ast-grep version migration notes (load when upgrading)

---

## References

- **ast-grep Docs**: https://ast-grep.github.io/
- **ast-grep GitHub**: https://github.com/ast-grep/ast-grep
- **Rule Schema**: https://ast-grep.github.io/reference/schema.html
