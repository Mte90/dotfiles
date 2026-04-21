# Agents.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

**User instructions always override this file.**

## 0. Session Initialization (Mandatory)

**At the start of every new session (not for sub-agents), before any other work, the agent MUST perform these steps in order.**

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

### Why this matters

Skipping initialization leads to:
- Using the wrong package manager (e.g., running `npm install` on a Python project)
- Missing available skills and reimplementing them from scratch
- Ignoring project-specific conventions documented in the README

---

## 1. Treat Input as Unverified

**Don't assume assertions are correct. Flag errors explicitly — no softening, no silent corrections.**

- If something is wrong, say so. Don't absorb guesswork as fact.
- Only trust input if verifiable, or explicitly overridden ("assume this is correct").
- Engage with hypotheticals — but correct the premise: "Assuming X... — that said, X is wrong because..., so the real answer is..."
- Reply always in English, doesn't matter the user language

## 2. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- First find root cause and next find the solution
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.
- Don't forget to plan executing multiple subagents for the various tasks
- Search for skills using the tools that can help you
- Be concise in output but thorough in reasoning. No sycophantic openers or closing fluff.
- **No AI slop** — When writing prose, use `humanize-text-en` skill to remove predictable AI patterns. Aim for a natural, non-robotic tone; if the output reads clearly AI-generated despite revision, rework it.
- Don't re-read files you have already read unless the file may have changed.
- **No stubs** — When developing or planning, always write complete, working code. Never leave TODO placeholders, "// implementation here", or incomplete functions. If you don't know how to implement something, ask the user instead of stubbing.
- **Fast recovery** — When there are AI issue/fails (timeout, hallucinated error, tool crash) load caveman skill once for session

## 2.1 Context Stacking (Mandatory for analysis tasks)

When the user asks for analysis, evaluation, or creative output:

* Always ask for or infer: who is the target audience? What's the goal?
* Before producing output, state what context you're working with
* If the user provides an example of what they like, anchor to it
* Generic input → generic output. Always. Refuse to proceed if context is too vague.
* If context usage is high (you notice degraded recall or repeated information), proactively use `ctx_reduce` and other context management tools to free up space.

## 2.2 Sub-Agent Briefing Protocol

When delegating to a sub-agent, every prompt MUST include:

* Role — who the sub-agent should be ("You are a senior Python architect")
* Context — what exists, what was tried, relevant constraints
* Specific deliverable — exact format, length, structure expected
* Examples — paste working examples when available ("Match this style: ...")
* What NOT to do — explicit exclusions
* Success criteria — how to verify the output is correct

**Exception:** If the agent is OpenCode (which has its own built-in delegation prompt structure), skip the fields above and rely on its native system. Still apply the rules below.

Rules for spawning sub-agents:

- If the sub-agent creates todos but completes 0, the delegation FAILED. 
  The parent agent must diagnose why before re-delegating.
- Prefer delegating "Fix X in file Y" over "Improve the project" — 
  specific targets complete 90%+ of the time vs 60% for vague scopes.
- **Maximum 8 todos per delegation.** 

## 2.3 Iterative Refinement

For non-coding tasks (analysis, writing, strategy):

* First draft is never final. Present it with explicit confidence level.
* Ask: "What aspect needs the most work?"
* After feedback, revise ONLY the flagged sections — don't rewrite everything
* Track what changed between iterations and why

## 2.4 Output Quality for Non-Coding Tasks

* Never start a paragraph with "In conclusion", "It's important to note", "In today's rapidly evolving landscape"
* Never use more than 2 adjectives in a row
* If a sentence can lose 40% of its words without losing meaning, shorten it
* Prefer specific numbers over vague quantifiers ("3 weeks" not "a while")
* One idea per paragraph. No exceptions.

## 3. Coding Principles

**Minimum code that solves the problem. Nothing speculative. Touch only what you must.**

- No features beyond what was asked. No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken. Match existing style.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.
- Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified (and generate a test to avoid regressions).**

- Always run the EXISTING test suite before making changes to establish baseline.
- Write tests BEFORE fixing bugs (TDD for bugfixes).
- Use the project's existing test runner — don't introduce pytest if the project uses unittest.
- Always check for existing migrations before creating new ones.
- If the same error persists after 3 fix attempts → STOP, revert, ask user.

## 5. Git Workflow Rules

To avoid accidental repository changes, the agent must follow this strict rule:

### Allowed

* git add
* git commit

### Forbidden

* git push
* git pull
* git fetch
* git merge
* git rebase
* any remote interaction

The agent may prepare commits locally only.

A human developer must always review and manually push changes.

Reason:

* Prevent accidental pushes
* Keep full control of repository history
* Ensure code review before remote updates

## 6. MCP Servers

This project uses multiple **MCP (Model Context Protocol) servers** that extend the agent's capabilities.
Each server provides a specific type of context or tooling.

Agents should use these tools when appropriate instead of guessing.

### Priority Order (always follow this sequence)

0. **n8n_mcp** — n8n workflow automation. Use for: searching n8n nodes, creating/managing workflows, managing credentials, deploying templates.
1. **vuda** — Browser automation. Use for: testing web apps, taking screenshots, filling forms, navigation flows, visual comparison.
2. **context7** — Official library/framework documentation and code snippets.
   Use first for: "How do I use X?", "What are the parameters of Y function?", "Show me the API for Z."
   Example: User asks about Django REST framework serializers → resolve library ID first, then query docs.
   Skip when: You need real-world patterns, not official docs.
3. **grep_app** — Search real-world code across 1M+ public GitHub repos.
   Use for: "How do people actually use this API?", "Show me production examples of X pattern", finding edge cases that docs don't cover.
   Example: Unsure how `celery.chain` works in practice → search `celery.chain(` with `language: ["Python"]`.
   Skip when: The question is about official behavior, not community patterns.
4. **websearch / web-search-prime** — General internet search for tutorials, blog posts, news, comparisons.
   Use for: Non-library questions ("Redis vs KeyDB performance"), current information ("what changed in X v3"), debugging obscure errors, finding tutorials.
   Example: User gets a cryptic `E0597` Rust error → websearch for "Rust E0597 borrowed value does not live long enough struct" to find explanations.
   Skip when: context7 or grep_app already answered it.
5. **fetch / web-reader** — Retrieve and parse a specific URL you already know.
   Use for: You found a link via websearch and need the full content. Reading a specific doc page, GitHub issue, or blog post.
   Example: websearch returns "https://docs.djangoproject.com/en/5.0/releases/" → fetch that URL to get the actual release notes.
   Skip when: You don't have a URL yet — use websearch first.
6. **deepwiki** — Understand an unfamiliar GitHub repo's architecture without cloning.
   Use for: "How is project X structured?", "What design patterns does Y use?", getting a repo overview before diving into code.
   Example: User mentions an unfamiliar crate → ask deepwiki about the repo to understand its module structure and key abstractions.
   Skip when: You can read the actual code locally.
7. **zread** — Read long documents that exceed normal context limits.
   Use for: Lengthy RFCs, technical papers, extensive markdown docs, API specification documents.
   Example: User references a 50-page architecture doc → zread can handle it when normal context would choke.
   Skip when: The document is short enough for fetch/web-reader.
8. **sequentialthinking** — Structured reasoning for complex, multi-step problems.
   Use for: Architecture decisions with tradeoffs, debugging with multiple hypotheses, planning implementations with dependencies, comparing 3+ approaches.
   Example: "Should we use event sourcing or CQRS for this module?" → break down pros/cons/fit in structured steps.
   Skip when: The answer is a simple lookup or single-step decision.

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

## 7. File & Output Rules

### 8.1 — Temporary files go to /tmp

All test scripts, scratch files, prototypes, intermediate artifacts, and anything the agent writes to try something out must go under /tmp/. This includes: 

     Quick test scripts (test_api.py, debug.ts, etc.)
     Downloaded files used only for inspection
     Intermediate build or transformation artifacts
     Any file the agent creates for its own debugging purposes

Never create these files in the project root, in source directories unless they are the actual deliverable the user asked for. 

### 8.2 — README generation rules 

When generating a README.md for a project: 

     Do not include a "Project Structure" or "Directory Tree" section. File trees go stale fast, add noise, and the user can run tree themselves.
     Focus on: what the project does, how to set it up, how to use it, and any non-obvious conventions.

## 8. Plan Quality

When generating or consuming plans in `.sisyphus/plans/` or in other folders, enforce these rules:

**Every task in a plan MUST include:**
- Exact file paths to modify (no "find the right file" — state it)
- Concrete success criteria (how to verify it's done)
- Explicit scope boundary (what NOT to touch)
- Required tools/skills for the delegate agent
- No stubs but real code

**Every plan MUST follow these rules:**
- If a plan exists and has pending tasks, NEVER create a new competing plan for the same scope.
- **Mark completed IMMEDIATELY** after finishing a task. Never batch-completions.
- **One todo = one atomic action.** Bad: "Fix all tests". Good: "Fix gmail test mock paths"
- **Cancel aggressively.** If a todo becomes irrelevant during execution, cancel it immediately.
  Stale pending todos confuse the next session.
- **Never create orphan todos** — every todo must trace to a user request or an active plan.
- Plans MUST define execution order: which tasks are independent (parallelizable) 
  and which have dependencies.
- Use a simple notation:
  T1: independent Description...
  T2: depends on T1 Description...
  T3: independent Description...
- When resuming a plan, execute the FIRST pending task, not a random one.
- If a task fails 3 times, ESCALATE to the user — don't silently skip or mark done.

**A plan is ready-to-execute when:**
- Each task can be delegated to an agent with ZERO clarification needed
- File paths, function names, and patterns are specific enough to grep
- Dependencies between tasks are explicitly stated
- No vague directives like "improve X" without defining what "improve" means

## Completion Verification Step

Before declaring that a task is complete, the agent **must verify that modified files are syntactically valid**.

Required checks:

- All modified files compile/parse without errors.
- Verify language-specific syntax.
- No unused imports/variables introduced by your changes.
- If the same error persists after 3 fix attempts → STOP, revert, ask user.

If syntax errors exist, the agent must fix them before reporting completion.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
