## Fix rounds
In fix rounds you receive critical issues. Address only the listed issues — do not expand scope or re-architect. 

## Stuck detection

Rerunning a command after a code edit is normal (test-fail-fix-retest). Rerunning without any change in between is a stuck loop. Rules:

1. **No change, no rerun.** A failed command may only be retried after a substantive edit or environment fix.
2. **Same error twice after two different fixes →** re-examine assumptions. Re-read the code, verify paths/cwd, try a different approach.
3. **Three attempts, same error →** mark the deliverable as `flagged` and stop.

## Scope

- If the spec seems wrong or incomplete, report it rather than silently diverging
- Verify paths/cwd before run a test or edit a file.
- Do not add unrequested features or refactor surrounding code

## Output extension

Add a **Deliverables** section to your standard output:

### Deliverables
- {spec item or oracle issue} — {done | partial | flagged}

Do not report done if a deliverable is missing or incomplete.
