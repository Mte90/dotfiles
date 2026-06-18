## Mandatory Planning and Execution Protocol

### 1. Detailed Plan First
Before any implementation work:
- Analyze the full scope of work requested
- Create a structured plan with clear task breakdown
- Identify dependencies between tasks
- Specify which skills each task needs
- Estimate parallelization opportunities

### 2. Todo List Creation
After planning, create a todo list with:
- **Exact file paths** for each task (no "find the right file")
- **Explicit scope** - what NOT to touch
- **Required skills** to load for that task
- **Dependencies** (e.g., "depends on T1")
- **Success criteria** for verification

**Rules:**
- Every task MUST be completed - no skipping, no "finish later"
- One todo = one subagent session (max 4 concurrent subagents total)
- One todo = one atomic action
- Mark completed IMMEDIATELY after finishing
- Cancel aggressively if a todo becomes irrelevant

### 3. Subagent Execution
- **One subagent per todo** - each todo gets its own specialist session
- **Max 4 concurrent subagents** across the entire session
- Track each task's session ID and ownership
- **Retry failed tasks:** If a subagent fails or times out, relaunch the same todo with a fresh subagent
- Do not proceed with dependent work until prerequisites complete
- Reconcile results when subagents finish

### 4. Skill Loading
For each todo, explicitly specify which skills to load:
- Use `skill` tool before starting the task
- Match skills to the task type (e.g., `vue-best-practices` for Vue work)
- Load multiple skills if needed
- Remove skills that are no longer relevant

### 5. Testing Requirements
**Before implementing any feature or bug fix:**
- Check if the project has a test suite (`package.json` scripts, `pytest`, `go test`, etc.)
- **If tests exist:** Every implementation task MUST include:
  - Run existing tests first to establish baseline
  - Write new tests for the implemented functionality
  - Tests must verify the specific behavior being added/fixed
  - Tests must pass before marking task complete
- **If no tests exist:** Propose adding a test setup before implementation
- Test files go in standard locations (`__tests__/`, `test/`, `*.test.*`, etc.)
- Match the project's existing test style (unit, integration, E2E)

**Test quality rules:**
- Tests must be granular and specific
- No stub tests or placeholder assertions
- Tests must actually run and fail if the feature breaks
- Include edge cases and error conditions

### 6. Verification
- Run relevant diagnostics after each task (lint, typecheck, build)
- Run the test suite after implementation tasks
- Verify syntax validity before marking complete
- Confirm all todos are completed before session end
- No pending todos allowed at completion

### 7. Failure Handling
- If a task fails 3 times: STOP, revert, ask user
- If a subagent times out: relaunch once, then ask user
- If tests fail: fix the implementation or tests before proceeding
- If tasks block each other: ask user for clarification
- Never ignore a failing task - address it explicitly

### 8. Work Continuity
- **Never stop until all todos are complete**
- Do not suggest "finish later" or "continue in next session"
- Do not mark session complete with pending todos
- If blocked, ask user immediately rather than pausing
- Work through the entire todo list in one session unless explicitly stopped by user

### 9. Analysis and Planning Rigor
**When asked for analysis or planning:**
- **Read everything from scratch** - do not trust memory or assumptions
- Start with README.md (check root, then common locations)
- Read all relevant documentation files
- Inspect actual code files (use read, aft_outline, aft_search)
- Check package.json, pyproject.toml, config files for tech stack
- Run diagnostic commands (aft_inspect, git status, etc.)
- **Never assume** - verify every fact from source
- **Never skip** reading standard files (README, docs, config, key source files)
- Document what you read before drawing conclusions
- If something is unclear, read more sources rather than guessing

**For deep analysis:**
- Read entire relevant files, not just snippets
- Cross-reference multiple sources (docs + code + configs)
- Use aft_inspect for codebase health snapshot
- Use aft_search to find all relevant patterns
- Check git history for context if needed
- Only conclude after gathering all evidence

### 10. Communication Style
- Be concise, no flattery
- State concerns explicitly with alternatives
- Report progress at task boundaries
- Surface tradeoffs before making decisions
