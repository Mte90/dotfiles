---
name: ast-grep
description: "ast-grep - Fast structural code search, linting, and rewriting CLI tool"
metadata:
  author: mte90
  version: 1.0.0
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
- **Debug AST** - Visualize AST and CST structures
- **Logical Queries** - Composite queries using `all`, `any`, and `not` operators
- **AI-assisted** - Convert natural language to YAML rules
- **Relational Search** - Find patterns using `inside`, `has`, `precedes`

---

## Installation

```bash
# Via cargo
cargo install ast-grep

# Via npm
npm install -g ast-grep

# Via pip
pip install ast-grep

# Download pre-built binary
curl -L https://github.com/ast-grep/ast-grep/releases/download/nightly/ast-grep-x86_64-unknown-linux-musl.tar.gz | tar xz
```

---

## CLI Commands

### Pattern Search

```bash
# Basic pattern search - find all console.log calls
ast-grep run --pattern 'console.log($ARG)' --lang javascript src/

# Short form with language inference from file extensions
ast-grep -p 'console.log($ARG)' src/

# Search with multiple arguments using multi-metavariable
ast-grep -p 'console.log($$$ARGS)' src/

# Search for function declarations
ast-grep -p 'function $NAME($$$PARAMS) { $$$ }' --lang typescript src/

# Debug pattern parsing
ast-grep -p 'console.log($A)' --lang javascript --debug-query=ast

# Show context around matches
ast-grep -p 'TODO' --context 3 src/
```

### Rewrite Operations

```bash
# Search and rewrite - add optional chaining
ast-grep -p '$OBJ.val && $OBJ.val()' --rewrite '$OBJ.val?.()' src/

# Interactive mode - confirm each replacement
ast-grep -p '$PROP && $PROP()' -r '$PROP?.()' --interactive src/

# Apply all rewrites without confirmation
ast-grep -p 'var $X' -r 'let $X' --update-all src/

# Output results as JSON for piping to other tools
ast-grep -p 'import $$$' --json src/ | jq '.[] | .text'
```

### Linting with Rules

```bash
# Scan with a single rule file
ast-grep scan --rule rules/no-console.yml src/

# Scan with project configuration (sgconfig.yml)
ast-grep scan --config sgconfig.yml src/

# Scan with inline rule (no file needed)
ast-grep scan --inline-rules '
id: no-debugger
language: JavaScript
rule:
  pattern: debugger
' src/

# Filter rules by ID pattern
ast-grep scan --filter 'security-*' src/

# Output in SARIF format for CI integration
ast-grep scan --format sarif src/

# Set rule severity via CLI
ast-grep scan --error=no-console --warning=prefer-const src/

# GitHub Actions compatible output
ast-grep scan --format github src/
```

---

## Pattern Syntax

### Metavariables

- `$VAR` - Matches single AST node
- `$$$VARGS` - Matches zero or more AST nodes (variadic)

### Basic Patterns

```python
# JavaScript/TypeScript
'console.log($MSG)'           # Single argument
'console.log($$$ARGS)'        # Multiple arguments
'function $NAME($$$PARAMS) { $$$ }'  # Function declaration
'const $X = $Y'               # Variable declaration
'$X && $X()'                  # Conditional call

# Python
'def $FUNC($$$ARGS): $$$'     # Function definition
'class $NAME($$$BASE): $$$'   # Class definition
'import $X from $Y'          # Named import
'from $X import $$$'         # From import
'for $X in $Y: $$$'          # For loop
```

### Language Detection

```bash
# Explicit language
ast-grep -p 'pattern' --lang typescript src/

# Auto-detect from file extension
ast-grep -p 'pattern' src/
```

---

## Rule Configuration

### YAML Rule File

```yaml
# rules/no-console.yml
id: no-console
message: "Do not use console.log in production"
severity: warning
language: JavaScript
rule:
  pattern: console.log($ARG)
```

### sgconfig.yml

```yaml
# sgconfig.yml
rules:
  - id: no-var
    message: "Use let/const instead of var"
    severity: warning
    language: JavaScript
    rule:
      pattern: var $X
    fix:
      rewrite: let $X

  - id: prefer-const
    message: "Use const for variables not reassigned"
    severity: warning
    language: JavaScript
    rule:
      pattern: let $X = $Y
    from: $Y
    where:
      - $Y
    fix:
      rewrite: const $X = $Y
```

### Complete Rule Example

```yaml
id: security-no-inner-html
message: "Setting innerHTML can lead to XSS attacks"
severity: error
language: TypeScript
rule:
  pattern: |
    $EL.innerHTML = $SOURCE
fix:
  rewrite: |
    $EL.textContent = $SOURCE
scope: script
```

---

## Integration

### GitHub Actions

```yaml
# .github/workflows/lint.yml
name: ast-grep
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run ast-grep
        uses: ast-grep/ast-grep-action@latest
        with:
          args: scan --format github src/
```

### pre-commit

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/ast-grep/ast-grep
    rev: stable
    hooks:
      - id: ast-grep
        args: ['--config', 'sgconfig.yml', 'scan']
```

### VS Code Extension

Install from VS Code Marketplace: ast-grep

Features:
- Inline diagnostics
- Quick fixes on hover
- Search panel

---

## Use Cases

### Find All TODO Comments

```bash
ast-grep -p 'TODO' --lang typescript src/
```

### Remove All console.log

```bash
ast-grep -p 'console.log($$$ARGS)' --rewrite '' --update-all src/
```

### Replace var with let/const

```bash
ast-grep -p 'var $X' -r 'const $X' --lang javascript --update-all src/
```

### Add Error Boundaries in React

```bash
ast-grep -p 'class $NAME extends React.Component { $$$ }' \
  --rewrite 'class $NAME extends React.Component {
  componentDidCatch(error, info) {
    console.error(error, info);
  }
  $$$ }' \
  --lang javascript --update-all src/
```

### Find Unused Variables

```bash
# Define rule in YAML
# rules/no-unused-vars.yml
id: no-unused-vars
language: TypeScript
rule:
  pattern: |
    const $NAME = $VALUE
where:
  - $VALUE
scope: code
```

### Advanced: Find API Patterns in Class Methods

```yaml
# Find fetch calls inside useEffect
id: fetch-in-useeffect
language: TypeScript
rule:
  all:
    - pattern: 'fetch($ARGS)'
    - inside:
        pattern: 'useEffect(() => { $$$ }, $$$)'
```

### Advanced: Find Async Functions Without Try-Catch

```yaml
# Find async functions that use await but lack try-catch
id: async-without-try
language: TypeScript
rule:
  all:
    - pattern: 'async function $F($$$) { $$$ }'
    - has:
        pattern: 'await $EXPR'
    - not:
        inside:
          pattern: 'try { $$$ } catch { $$$ }'
```

### Advanced: Find Security Anti-Patterns

```yaml
# Detect eval() usage
id: no-eval
language: JavaScript
message: "eval() is dangerous - potential code injection"
severity: error
rule:
  pattern: 'eval($ARG)'

# Detect hardcoded passwords
id: hardcoded-secret
language: Python
message: "Hardcoded credentials detected"
severity: error
rule:
  pattern: |
    password = '$PASS'
```

---

## Best Practices

### Always Test Patterns First

```bash
# Test pattern without rewriting
ast-grep -p 'pattern' src/

# Then run with --dry-run equivalent (no --update-all)
ast-grep -p 'pattern' --rewrite 'new_pattern' --interactive src/
```

### Use Language Flag

```bash
# Explicit language avoids ambiguity
ast-grep -p '$X' --lang python src/
```

### Use JSON Output for Scripts

```bash
ast-grep -p 'console.log' --json src/ | jq '.[] | .file_path'
```

### Combine with Other Tools

```bash
# Find files modified in git and search
git diff --name-only HEAD~1 | xargs ast-grep -p 'pattern'

# Search and format
ast-grep -p 'pattern' --json src/ | jq -r '.[].file_path' | xargs prettier --write
```

---

## Do

- Test patterns with `ast-grep run --pattern` before applying fixes
- Use `--interactive` mode for important rewrites
- Configure `sgconfig.yml` for project-wide rules
- Use `--lang` flag to avoid ambiguity

## Don't

- Don't use `--update-all` without testing pattern first
- Don't rely on regex when structural patterns are needed
- Don't forget to commit before mass rewrites

---

## References

- **ast-grep Docs**: https://ast-grep.github.io/
- **ast-grep GitHub**: https://github.com/ast-grep/ast-grep
- **Rule Schema**: https://ast-grep.github.io/reference/schema.html
- **Tutorial**: https://ast-grep.github.io/tutorial/