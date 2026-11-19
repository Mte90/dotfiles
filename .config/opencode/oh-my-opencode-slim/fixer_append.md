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

## Load the matching skill first

You have access to the full skill library. Before writing code:

1. Identify the task's language/framework (from the brief and the files you open).
2. Load the matching skill before the first edit (e.g. Django, Laravel, Rust, Qt/C++, TypeScript, pytest, SQLAlchemy). One skill load is cheap; guessing a framework convention costs a rework round.
3. For bug fixes, load the debugging skill; before implementing a change without a spec, load the verification-planning skill.
4. No matching skill → proceed without one. Do not load skills for their own sake.

## Context economy

Most of a fix session's cost is loaded context, not output. Rules:

1. Read only the files named in the brief, with narrow line ranges; expand only when the fix requires it.
2. Never list or read whole directories when the brief has exact paths.
3. Do not re-read a file already in context; re-check only the lines you changed.

## Output extension

Add a **Deliverables** section to your standard output:

### Deliverables
- {spec item or oracle issue} — {done | partial | flagged}

Do not report done if a deliverable is missing or incomplete.
