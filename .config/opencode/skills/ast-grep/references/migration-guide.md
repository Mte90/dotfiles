# Migration Guide

> Loaded on demand from tool/ast-grep/SKILL.md when upgrading ast-grep versions.

## Version Compatibility

Check current version:
```bash
ast-grep --version
```

## Breaking Changes

### v0.25.0+

- `--json` output format changed — field names normalized
- `constraints` syntax tightened — nested constraints require explicit `kind`

### v0.20.0+

- `where` clause deprecated — use `constraints` instead
- `scope` field removed — rules apply to entire file by default

## Migration Checklist

1. Run `ast-grep scan` with existing rules
2. Check for deprecation warnings
3. Update `where` → `constraints` syntax
4. Verify JSON output parsing in CI scripts
5. Test patterns with `--debug-query=ast`
