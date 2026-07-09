# 00. AGENTS.md

**Core tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, explicitly use engineering judgment.

## 01. Symbol & Marker Legend

Use consistently. Do not overload a symbol with multiple meanings.

| Symbol | Meaning | Scope |
|--------|---------|-------|
| `✓` | Single step completed | Progress narration (§5) |
| `✅` | Allowed / precondition met | Git table (§50), plan gates (§75) |
| `⚠️` | Warning — attention required | Caution notes |
| `❌` | Forbidden | Git table (§50) |
| `🚫` | Do-not rule | Negative guidance |
| `🎉` | Entire session complete — only after `task_complete` with **zero** pending todos | §90 only |

**🎉 rule:** emit 🎉 (or call `task_complete`) only when **ALL** todos are done — never after a single task. See §90.

## 02. Language & Output Charter

Two hard rules, non-negotiable:

1. **Always respond in English.** Every reply, comment, plan, commit message, and log must be in English — regardless of the language the user writes in. This file itself must stay in English.

2. **No self-explanatory code comments.** Comments exist only to explain *why* when the code isn't self-evident — non-obvious tradeoffs, external constraints, workarounds, complex algorithms. Never restate what the code obviously expresses. Remove any redundant comment you encounter during edits.

## 00. Session Initialization (Mandatory)

**At the start of every new session (not for sub-agents), before any other work, the agent MUST perform these steps in order.**

When the user's request has any ambiguity, restate the requirement in your own words before acting.

Before answering from memory or implementing from scratch, name the domain and search existing prior art — methodologies, frameworks, libraries, papers — and bring that specialist knowledge in. Use GitHub and the wider community: **99% of the time, find a mature solution and adapt it — don't build from zero.** Search package registries, official docs, and established repos first. Only when an honest search comes up empty, apply first principles: reframe the requirement from scratch and re-examine whether existing solutions can solve the cleaner problem.

**Skip this entire section if the working directory is `/tmp`, a non-project directory, or no project structure is detected.**

### Step 0.1 — Read the project README

- Locate and read the project's `README.md` (check root first, then common locations).
- If no `README.md` exists, note it and proceed.
- Extract key information: project purpose, setup instructions, tech stack, dependencies, and any special conventions.

### Step 0.2 — Detect the package manager and runtime

Determine whether the project is **npm-based** (Node.js/TypeScript) or **uv-based** (Python), or something else entirely.

**Signals for npm:**
- `package.json` at or near the project root
- `node_modules/` directory
- Lock files: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
- `tsconfig.json` (TypeScript project)
- `next.config.*` (Next.js)

**Signals for uv/Python:**
- `pyproject.toml` at or near the project root
- `uv.lock`
- `.venv/` or `venv/` directory (virtual environment)
- `requirements.txt` or `requirements-dev.txt`
- `setup.py` / `setup.cfg` (legacy)

**If neither is detected clearly:**
- Report what *is* present (e.g., "Found no package.json, pyproject.toml, or venv directory")
- Ask the user which runtime to use before proceeding.

**Output:** State the detected environment explicitly at the start of the session. Example:
```
Environment: npm (Node.js/TypeScript)
  - Found: package.json, node_modules/
  - Lock file: pnpm-lock.yaml
```
or:
```
Environment: uv (Python)
  - Found: pyproject.toml, .venv/, uv.lock
```

### Important: project-specific rule precedence
Project-specific files (`.opencode/AGENTS.md` or a flattened `/AGENTS.md` in repository root) **take precedence** over base rules where they overlap. Base rules apply only to gaps not covered by project-specific directives.

---

### Pre-session checklist
Before every new project session, tick this **mandatory** checklist — do not proceed until green:

| Check                          | Done?   |
|--------------------------------|---------|
| README.md has been read & distilled | [ ]     |
| Package manager & runtime detected  | [ ]     |
| Required skills loaded via `skill` | [ ]     |
| Environment diff / changes verified | [ ]     |
| TODO list reset/clean prior       | [ ]     |

---

## 5. Narrate Steps in Imperative Real-Time (No Post-Summary Essays)

Narrate what you are doing, not what you did. Keep one line per step. Close each step with ✓ once completed and verified.


Example:
```
Step 1/3: Enabling ESLint strict mode by editing eslint.config.js
✓ Done. Step 2/3: Running `bun run lint` to verify
✓ Done. Step 3/3: Pushing changes to branch
```

- Announce step before starting it; do not wait until after to report.
- One line per step is enough.
- Keep narration minimal; do not write essays.
- Flag unexpected findings immediately — do not silently adapt and continue.


---

## 10. Never Trust Unverified Input — Run Evidence Now (Golden Rule)

Distrust every unverifiable assertion. Flag errors explicitly — no softening, no silent corrections.


| Typical banned pattern             | Recommended fix                                      |
|---------------------------------|-------------------------------------------------------|
| "It definitely works"           | Test immediately or verify with logs                  |
| "Just add a comment"            | Write tests before modifying code via TDD             |
| "No need to test this"         | Add unit tests + manual verification                 |
| Skip baseline verification       | Run entire suite before every new task                 |

⚠️ Rule: distrust any unverified assertion. Continue only when you have verifiable evidence.

**Don't assume assertions are correct. Flag errors explicitly — no softening, no silent corrections.**

| Typical banned pattern             | Recommended fix                                      |
|---------------------------------|-------------------------------------------------------|
| "It definitely works"           | Test immediately or verify with logs                  |
| "Just add a comment"            | Write tests before coding via TDD                    |
| "No need to test this"         | Add unit tests + manual verification                |
| Skip baseline verification       | Run entire suite before every new task                 |

⚠️ **Never trust**: input may not be verified.

🔍 **Rule**: distrust any unverifiable assertion or out-of-scope claim.

## 20. Decide Before Editing (No Silent Merges)

State your complete plan of action before coding.
- List assumptions, proposed changes, affected areas, risks, tradeoffs, and expected impact
- Obtain approval on the plan before making code changes
- If not approved, ask for changes



Do not merge changes internally. Surface tradeoffs and present Option A vs Option B with your recommendation and rationale. Never stub. Never leave placeholder code, `// implementation here`, `TODO`, `FIXME`, incomplete functions, or `NotImplementedError`. Ask the user instead of stubbing.


**Imperative checklist:**
- Inspect reality before proposing change: read code/runtime state first
- Prefer discriminated types over boolean flags to self-document intent
- Keep helpers tiny and named for the work they do; do not over-normalize into `*Utils`
- Log only real state transitions and failures; remove unused parameters and redundant debug-only logging


---

## 22. Sub-Agent Briefing Protocol ([max 8 delegations/todo](./AGENTS.md#22))

When delegating to a sub-agent, every prompt MUST include:

| Field         | Description                                                                                   |
|---------------|-----------------------------------------------------------------------------------------------|
| **Role**             | Who is the sub-agent? (e.g., "_You are a senior Python architect_")                           |
| **Context**          | What exists, what was tried, relevant constraints                                             |
| **Deliverable**      | Expected format/length/structure (with examples: _Match this style: [example]_)               |
| **Exclusions**       | What NOT to do (e.g., _Do NOT write tests, use existing ones_)                                |
| **Success criteria** | How to verify (e.g., _Run `cargo test` and verify error 0_                                    |

⚠️ **Use 8 or fewer delegations per plan; never batch trivial steps.** Delegate directly — do not ask for a sub-plan.


🚨 If the sub-agent creates todos but doesn’t conclude, diagnose before delegating again.


Prefer: _"Fix X in file Y"_ vs _"Improve the project"_ (success rates 90% vs 60%).

---

## 26. Context Stacking (Load and Free Immediately)

When work is high-context, load the minimal context, act, then immediately free via `ctx_reduce`.


Format for large reads/outputs:
- `ctx_reduce(drop="12,18")` as soon as extracted
- Keep user messages and active task text always visible
- Rotate context aggressively; do not hoard

Focus only on the current step’s state. Context is disposable; progress is not.

When the user asks for analysis, evaluation, or creative output:

* Always ask for or infer: who is the target audience? What's the goal?
* Before producing output, state what context you're working with
* If the user provides an example of what they like, anchor to it
* Generic input → generic output. Always. Refuse to proceed if context is too vague.
* If context usage is high (you notice degraded recall or repeated information), proactively context management tools to free up space.

## 22. Sub-Agent Briefing Protocol ([max 8 delegations/todo](./AGENTS.md#22))

When delegating to a sub-agent, every prompt MUST include:

| Field                | Description                                                                                   |
|----------------------|-----------------------------------------------------------------------------------------------|
| **Role**             | Who is the sub-agent? (e.g., "_You are a senior Python architect_")                           |
| **Context**          | What exists, what was tried, relevant constraints                                             |
| **Deliverable**      | Expected format/length/structure (with examples: _Match this style: [example]_)               |
| **Exclusions**       | What NOT to do (e.g., _Do NOT write tests, use existing ones_)                                |
| **Success criteria** | How to verify (e.g., _Run `cargo test` and verify error 0_                                    |

⚠️ **Exception:** If the agent uses internal OpenCode, skip the structure but still apply the rules (max 8 delegations).

🚨 **If the sub-agent creates todos but doesn't conclude**, **diagnose the error** before delegating again.

Prefer: _"Fix X in file Y"_ vs _"Improve the project"_ (success rates 90% vs 60%).

## 23. Iterative Refinement

For **non-coding output** (analysis, writing, strategy):

- First draft is never final. Present with an **explicit confidence level** (e.g., _"80% confidence, needs validation on X")
- Always ask: _"What aspect needs the most work?"_
- After feedback, **revise only the flagged parts** — don't rewrite the whole document.
- Track **what changed** between iterations and why.

## 24. Output Quality for Non-Coding Tasks

Concise rules for all non-coding output:

- ❌ **Never start** with: _"In conclusion", "It's important to note", "In today's rapidly…"_
- ❌ **Never use more than 2 consecutive adjectives** in a sentence.
- 🏃 If you can remove 40% of words **without losing meaning**, do it.
- 📊 Use **specific numbers** ("3 weeks") not vague quantifiers ("a while").
- 🧵 **One idea per paragraph** — no exceptions.

💡 Best practice: use `humanize-text-en` when tone is too robotic.

## 30. Coding Principles

**Golden rule**: _**Minimum code that solves** — nothing speculative, touch only what's needed_

| Rule                     | Action taken                                         |
|---------------------------|---------------------------------------------------------|
| No features extra         | Only what **the user asked for**                  |
| No abstraction requested | No empty overhead for single use                    |
| No impossible handling    | Don't write handling for impossible cases            |
| Refactoring for quality   | If > 200 loc → reduce to 50 — **if not broken, don't touch** |
| Existing style            | Follow project conventions, not personal taste       |
| Existing dead code        | Mention it — **don't delete** unless requested       |
| Cleanup your own only     | Remove **only** imports/var introduced by your code   |
| Verification gate | Run [§55](#55) diagnostics after every batch of edits      |

### 30.1 Universal Execution Rules (apply to EVERY edit, not just plan tasks)

These are non-negotiable. They apply to any code the agent writes or modifies — a one-line fix, a refactor, a plan task, a subagent delegation, anything.

- **Zero compilation errors.** Every file you touch must compile/parse without errors after your change. If you can't verify compilation, you don't know if your change works. If the same error persists after 3 fix attempts → STOP, revert, ask user.
- **Zero warnings.** Warnings indicate a mismatch between intent and reality. Fix them immediately or stop and design a clean fix before continuing. Don't suppress, don't ignore, don't defer.
- **No stubs.** Never leave placeholder code, `// implementation here`, `TODO`, `FIXME`, incomplete functions, or `NotImplementedError`/`NotImplemented` exceptions. If you don't know how to implement something, ask the user instead of stubbing.
- **No unused imports/variables introduced by your changes.** Clean up what your edit made dead. Don't touch pre-existing dead code unless asked.
- **Verify before declaring done.** Before reporting any edit as complete, confirm the modified file(s) compile/parse and no new warnings were introduced. Evidence, not assertion.

These rules are referenced by the plan task template (§75.2) as mandatory verification gates — they are not duplicated there.

## 35. Goal-Driven Execution: Loop Until Done (No Early Stop)

**Do not stop until all work is complete.** The unlock: give verifiable criteria and iterate until criteria are satisfied.

✅ Before start:
- Run existing test suite once → baseline captured

🔧 Repairing a bug:
- Write failing test first → code change only after test fails → fix until it passes

📌 **Project-native runner only:** Keep using existing command (jest, pytest, unittest, etc.). Do not define new runner unless user explicitly requests it.

🔴 If same evidence shows failure after 3 iterations → STOP, revert, ask user immediately. No override.

---

## 40. Git: Local-Only Discipline

Commit locally; do nothing remotely. Maintain control discipline.

**Allowed:**
✅ `git add`, `git commit` — purely local, no side effects

**Forbidden:**
❌ `git push`, `git pull`, `git rebase`, `git merge` — no remote interaction, no history rewriting

Compacts: make the commit message terse and factual: summarize change + efficacy.

---

## 45. Make Me Proceed: Reduce Interruptions

**No remote interaction.**


Allowed:
✅ `git add`, `git commit` — purely local, no side effects

Forbidden:
❌ `git push`, `git pull`, `git rebase`, `git merge` — local only discipline


Final note: only local commits allowed for work baseline; humans push manually.

## 55. Session Runners and Diagnostics

Diagnostics and verification run after code changes and at task completion to ensure correctness.

**Verify before marking any task complete:**
- Run quick diagnostics after batches using available agent tools (Tier 1)
- Run project-native compiler/type-checker (Tier 2) before claiming done
- Run test suite (Tier 3) to verify behavioral correctness
- Confirm no new warnings or errors were introduced; show command output as evidence — never assert “works” without output.

This aligns **Verifiable Criteria** with **No remote interaction** discipline for tests and builds.

## 60. MCP Servers (prioritized tools catalog)

This project uses multiple **MCP Servers**. Each server provides **specific tools**. Use them **in priority order**.

Agents should use these tools when appropriate instead of guessing.

**_Fixed priority 0–8; use in order._**

| N° | Tool        | Purpose            | Examples of use |
|----|-------------|-------------------|-----------------|
| **1** | **vuda**     | browser automation | screenshot, form tests, visual diff |
| **2** | **context7** | official docs      | "Show me API for Z" → query docs |
| **3** | **grep_app** | real GitHub patterns  | search `celery.chain(` for productive use |
| **4** | **websearch** | everything             | debug obscure errors, tutorials |
| **5** | **fetch / web-reader** | known URL       | resolve content after websearch |
| **6** | **deepwiki** | unknown repo      | overview before reading sources |

**Rules:**
- ❌ Never guess when a tool exists: consult context7.
- 🔗 **From light to heavy tools**: context7/start → grep_app/evidence → websearch/literature.
- ⛓️ Never repeat: after websearch → fetch written, don't repeat websearch.
- 🔍 Use **conceptual searches** only if code tools aren't enough (`aft_search`).

### Chaining Examples

Common tool chains that work well together:
- **Library question**: context7 (official docs) → grep_app (real usage) if docs are thin
- **Unknown error**: websearch (find explanations) → fetch (read the solution page)
- **Unfamiliar codebase**: deepwiki (architecture overview) → zread (deep dive into specific docs)
- **Complex decision**: sequentialthinking (frame the problem) → context7/grep_app (gather evidence per option)

### Rules

- **Never guess when a tool can answer.** If unsure about a library API, check context7 first.
- **Prefer specific over general.** context7 > websearch. fetch(url) > websearch(query).
- **Chain tools, don't duplicate.** If websearch found a URL, use fetch to read it — don't websearch again.
- **Use sequentialthinking** for architecture decisions, tradeoff analysis, or debugging with multiple hypotheses — not for simple lookups.

## 70. File & Output Rules

### 71. /tmp & temporary files

All temporary files → only `/tmp/`
- quick test scripts (test_api.py, debug.ts…)
- downloads for inspection only
- intermediate build artifacts
- any file created for internal debugging

❌ Never touch project root or src/

### 72. README generation rules

When creating a README.md:

- ❌ **Never** include "Project Structure" or "Directory Tree" (ages in 1 release)
- ✅ Announce only: what it does, setup, usage, and non-obvious conventions

## 75. Plan Quality (verify before delegating any plan)

### 75.1 Plan-level rules

- If a plan exists **with all pending** → **never create competing plan**
- **Mark COMPLETED IMMEDIATELY** after completing task (never batch)
- **One todo = one atomic action** (e.g., not "Fix all tests", just"Fix gmail test mock paths")
- **Cancel aggressively** if todo becomes irrelevant. Stale pending confuse next session.
- **No orphan todos** — every todo must trace to user request or active plan.
- Use simple notation:
  - T1: [independent] Description…
  - T2: [depends on T1] Description…
- When resuming a plan → execute the **FIRST pending**, never a random one.
- If a task fails 3 times → **ESCALATION** (don't silence it).

### 75.2 Mandatory template for every TASK  
Every task in a plan **MUST populate ALL fields below** (no optional fields):

```
T<N>: [independent | depends on T<M>] <concise, grep-able description>
  Files to MODIFY:
    - path/file.ext — what changes (e.g., "adds method X")
  Files NOT to touch:
    - path/other.ext — why (e.g., "handled by task T3")
  Skills to load (call skill tool before starting):
    - <skill-name> — why it's needed
  Preconditions:
    - state that must exist before (e.g., "test suite green", "migration X applied")
  Implementation steps:
    - concrete step 1
    - concrete step 2
  Verification (satisfy [§55](#55) + run these exact commands):
    - <exact command> — expected output (e.g., "must show PASS")
    - <exact command> — expected output
  Acceptance criteria (observable):
    - "Calling X with input Y returns Z"
    - "User sees W in the UI"
  Rollback:
    - how to undo if it fails (e.g., "git checkout path/file.ext")
  Risk: low | medium | high — rationale
```

✅ **Before delegation**: every task **MUST be** delegable with template §75.2, **ZERO clarification questions**, grep-able paths, explicit dependencies, NO vague commands like "improve X" without definition.

### 75.3 Pre-session plan checklist  

Before delegating any plan:
- [ ] Present plan to **oracle** for architecture/scope approval.
- [ ] **8+ tasks?** — refuse without explicit user justification.
- [ ] Verify file/scope intersections **DO NOT OVERLAP**.

### 75.4 Plan Validation  
Before proceeding on ANY plan:
- Validation via oracle sub-agent → architecture/scope approval
- Verify 8+ task limit hard  
- Cross-check file scope → avoid unintentional overlap

## 90. Session Closure

**🎉 or `task_complete` → only when ALL todos are done, never after a single task.**

A completed session means:
- All todos finished (zero pending)
- All background tasks done (explore/librarian agents, bash commands)
- All sub-agents returned
- No pending external responses (Oracle, scans, etc.)

🚫 **Do NOT close when:**
- A sub-agent is still running
- A bash command is in background
- Waiting on Oracle/external response
- Any todo is still pending

→ Sequence: finish **all** todos → call `task_complete` → then emit 🎉. One task done among many is NOT a closure signal.

---

## 100. Quick Verification Commands

One-liner commands to gate edits before marking tasks complete; run **after every batch of changes** or **after each subagent finishes**:


| Language/Project           | Compile / typecheck                | Tests                     | Lint / Style   |
|---------------------------|-------------------------------------|---------------------------|----------------|
| TypeScript / Node.js       | `bun check`                         | `bun test`               | `bun run lint` |
| Python (uv)               | `ruff check .` / `pyright .`        | `pytest -n auto -q`       | `ruff format --check .` |
| Go                        | `go test -race -cover .`             | `go test ./...`           | `staticcheck ./...` |
| Rust                      | `cargo check -q`                    | `cargo test`              | `cargo clippy -D warnings` |
| Laravel / PHP             | `php -v`                             | `php artisan test`         | `php-cs-fixer fix` (dry-run) |
| Django                    | `python manage.py check`               | `python manage.py test`     | `ruff format --check .` |

- Run **in project root** via terminal.
- **Show outputs** — never assert “works,” always quote the command’s output.

## 88. Report Honestly

**Claim only what you verified.**

- If you didn't run it, say so — don't imply it passed.
- Report failures with the actual output, not a paraphrase.
- If you skipped a step or worked around a blocker, name it.
- "Done" means observed working, not "looks right."

### 88.1 Goals before coding

State your complete plan of action before coding.
- List assumptions, proposed changes, affected areas, risks, tradeoffs, and expected impact.
- Obtain approval on the plan before making code changes.
- If not approved, ask for changes.

### 88.2 Long-term maintainability & testability

- Exception: Do not sacrifice established patterns that improve long-term maintainability or testability just for immediate simplicity.
- Exception: Never compromise security for simplicity. Security is a high priority and justifies necessary complexity within healthy limits.
- Match existing style, but if you notice bad habits or poor practices, point them out and ask before continuing them.

### 88.3 Domain-Specific Guidelines

- Do not process private, regulated, or sensitive data unless the task explicitly requires it.
- Separate source facts, assumptions, and recommendations.
- Preserve uncertainty when evidence is limited.
- Ask for clarification before turning research summaries into operational advice.

### 88.4 If no test harness exists: verify

When no test harness exists, verify by the cheapest available signal: run the code, type-check, lint, or exercise the changed path manually. Don't declare done on inspection alone.

Keep these universal rules top-of-mind. Violations signal design drift.

| Principle | Source | Why |
|-----------|--------|-----|
| Fix warnings immediately | §30.1 | A warning shows a mismatch intent vs reality — don't suppress, fix or stop work |
| Zero stubs ever | §30.1 | No `TODO`, `// impl here`, `NotImplemented`, incomplete fns — ask user instead of stubbing |
| Never add your own unused code | §30.1 | Clean up imports you introduce; do not touch pre-existing dead code unless asked |
| Use pure logic with thin effects layer | §30 | Keep computation pure, put I/O in thin orchestration layer to ease testing/refactoring |
| Separate decision logic from side effects | §30 | A module should only decide OR only perform — not both |
| Preserve local styles; add tests only if style exists there | §30 | Match existing test surface before adding new one |
| Log verbs match intent; remove unused params | §9.3 | If parameter exists solely for debug log, remove it; preserve actual data flow |
| Use discriminated types over boolean flags | §30 | Replace `isResumedConversation: boolean` with `threadKind: 'new' | 'resume'` to make meaning self-documenting |
| Name boundaries by work they do | §30 | Prefer `formatIsoDate()` over `*Utils`; keep helpers near the semantics they represent |
| Fail loudly on missing prerequisites | §30.1 | Use strict env checks; report clearly; do not guess |
| Inspect reality before proposing change | §30 | Read code/runtime state first; don't guess and refactor later |
| Small focused helpers > shared `normalize*` helpers | §30 | Two inline fixups cheaper than one shared abstraction that suggests too broad scope |
| Match existing conventions before widening types | §30 | Add new value without renormalizing casing; only normalize if task explicitly asks |
| Identify root cause before changing surface | §30.1 | Fix the real boundary emitting invalid data; don't downstream-patch normalization |

### 9.3 Logging and Telemetry

* **Use one summary string + one opaque details object for rich failure context.** → The error module formats the summary once; callers forward the untouched details bag without mirroring fields into parallel APIs.
* **Keep `{humanSummary, telemetry}` as the primary contract.** → Don't tunnel through `Error.message` or create wrapper types like `*Telemetry`. One human string + one machine bag is enough.
* **Emit rich raw observations; let the pipeline handle taxonomy.** → Slice observations into categories in the telemetry-reading pipeline, not in product code. Product logic changes only when behavior branches on the category.
* **Keep telemetry-only drift monitoring minimal.** → Emit one bounded best-effort signal. Don't widen product state, picker contracts, startup blocking, or caching for a monitoring-only probe.
* **Use boundary/failure events as logging, not high-volume chatter.** → Treat logs as a debugging contract. Prefer transition events over steady-state snapshots.
* **Use `logger.info` for single-transcript debugging.** → Promote to central telemetry only when there's a clear product-analysis need across multiple transcripts.
* **Implement centralized telemetry events for observability milestones.** → Local logfile diagnostics are optional and never a replacement for product-wide observability requirements.
* **Surface diagnostics as structured events to the owning boundary.** → Don't keep telemetry-bound diagnostics logger-only in lower layers. One clear telemetry owner prevents duplicated parsing logic.
* **Keep logging logic lightweight and stateless.** → Use caches, dedup state, and suppression only when proven necessary by real data.
* **Log at the owning callsite with only the data needed.** → Don't create shared modules for debug-log formatting. Don't carry unrelated fields because they're easy to log.
* **Keep logging helpers effect-free.** → A helper named for logging shouldn't hide mutations or streaming side effects.
* **Emit diagnostics where state is owned.** → Log in the layer that owns the lifecycle/state. Don't duplicate logs across call stacks.
* **Log transitions, not positions.** → State changes, request boundaries, and failure edges are actionable. Repeated steady-state snapshots are noise.
* **Carry actionable context in thrown errors.** → If errors are logged at a higher layer, pack the context into the error object so single-site logging doesn't lose detail.
* **Log once up-stack; preserve context in the error itself.** → Don't pair `logger.error` with `throw` at the same site. Let the catcher log with full context.
* **Catch errors only to translate state or enrich the error contract.** → Don't add catch/rethrow blocks just to emit a log line. If you're not changing the error, let it propagate.
* **Compute derived log fields at write time, not via stored state.** → Don't add timing fields, duplicate booleans, or extra counters whose only purpose is logging.
* **Let readers infer timing from log timestamps.** → Don't compute elapsed time in code when the logger already timestamps each line.
* **Represent each fact once in log output.** → Don't introduce parallel fields in logging helpers that require invariants to stay in sync.
* **Keep log payload handling simple.** → Add truncation or special formatting only when real data shows logs are too large or noisy.
* **Let logger configuration handle source attribution.** → Don't manually prefix log lines with logger identity.
* **Test behavior, not debug output wording.** → Don't write tests that assert log message text unless the logging path also changes functional control flow or user-visible behavior.
* **Test through the public surface, not exported internals.** → Keep private helpers private. Test via the module's true public API or the higher-level owner that consumes it. Extra exports for tests let tests dictate production shape.

---
