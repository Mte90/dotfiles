## Mandatory Planning and Execution Protocol

### 0. Plain Lists Fast Path

When the user gives two or more tasks, or a plain list of things to do, without asking for a plan, skip the plan-first steps below: build the todo list (one todo per item) and dispatch subagents in parallel, up to the concurrency limit. Each subagent prompt embeds the complete task: goal, exact paths and scope, constraints, and verification. Confirm with the user before dispatching items that touch auth, data layer/migrations, config files, or secrets; serialize lanes with conflicting write scopes.

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

### 9. Analysis and Planning Rigor (delegate the legwork)

When asked for analysis or planning, dispatch the reading and research to subagents first. The orchestrator verifies and integrates results — it does not read the whole codebase in its own context.

- Exploration subagents: README/docs distillation, tech-stack detection, codebase structure, relevant patterns.
- Research subagents: prior art, library docs, how others solve the problem.
- Spot-check load-bearing claims from subagent results against source before concluding — never assume, verify each key fact from returned evidence.
- If gaps remain, dispatch sharper follow-ups rather than reading everything inline. Only conclude after reconciling the returned evidence.

### 10. Communication Style
- Be concise, no flattery
- State concerns explicitly with alternatives
- Report progress at task boundaries
- Surface tradeoffs before making decisions
