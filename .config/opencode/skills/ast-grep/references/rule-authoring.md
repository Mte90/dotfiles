# Rule Authoring Deep Dive

> Loaded on demand from tool/ast-grep/SKILL.md when writing complex rules.

## Advanced Constraint Patterns

### Nested Constraints

```yaml
rule:
  pattern: '$X.method($ARG)'
  constraints:
    $X:
      kind: call_expression
      has:
        pattern: 'new $$$'  # X must be a constructor call
    $ARG:
      kind: string_fragment
      regex: '^test'  # Argument must be test-related string
```

### Multiple Constraints on Same Metavariable

```yaml
rule:
  pattern: '$VAR'
  constraints:
    $VAR:
      kind: identifier
      all:
        - regex: '^_'  # Starts with underscore
        - not:
            regex: '^__'  # But not double underscore
```

## Relational Operators Deep Dive

### `inside` Variants

```yaml
# Direct parent
inside:
  pattern: 'function $$$'

# Any ancestor (transitive)
inside:
  pattern: 'class $$$'
  kind: class_declaration  # Must be direct class node

# With kind filter
inside:
  kind: return_statement
  pattern: '$VALUE'
```

### Combining Relations

```yaml
rule:
  all:
    - pattern: 'console.log($MSG)'
    - inside:
        pattern: 'if ($COND) { $$$ }'  # Inside conditionals only
    - follows:
        pattern: 'const $X = $$$'  # After variable declarations
```

## Testing Rules

Create a test file with positive and negative cases:

```python
# test-rules.py — positive cases (should match)
# rule: empty-except-block

try:
    process()
except Exception: pass  # MATCH

try:
    connect()
except ConnectionError:
    pass  # MATCH

# Negative cases (should NOT match)
try:
    process()
except Exception as e:
    logger.error(e)  # No match — has handler

try:
    process()
except Exception:
    raise  # No match — re-raises
```

Test with:
```bash
ast-grep scan --rule rules/empty-except.yml test-rules.py
```

## Performance Tips

1. **Be specific with `kind`** — Reduces search space
2. **Avoid `$$$` when `$` suffices** — Variadic is slower
3. **Order `all` clauses** — Put most selective first
4. **Use `constraints` early** — Filters before matching
