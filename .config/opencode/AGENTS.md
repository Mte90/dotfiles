# Agents.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 0. Session Initialization (Mandatory)

**At the start of every new session (not for sub-agents), before any other work, the agent MUST perform these steps in order.**

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

**Output:** State the detected environment explicitly at the start of the session:
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

### Step 0.3 — Scan available skills

- Search for all `SKILL.md` files in ~/.config/opencode/
- List each skill found with its name and a one-line summary (from the skill's frontmatter or description).
- Do **not** load every skill into context — just catalog them so you know what's available when needed.

**Output format:**
```
Available Skills (N found):
  1. skill-name — Brief description of what it does
  2. another-skill — Brief description
  ...
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
- Don't forget to planning to execute multiple subagents for the various tasks
- Search for skills using the tools that can help you

## 3. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 4. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 5. Goal-Driven Execution

**Define success criteria. Loop until verified (and generate a test to avoid regressions).**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 6. Git Workflow Rules

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

## 7. MCP Servers

This project uses multiple **MCP (Model Context Protocol) servers** that extend the agent's capabilities.
Each server provides a specific type of context or tooling.

Agents should use these tools when appropriate instead of guessing.

---

## Usage Rule

When solving problems, prefer tools over assumptions.

Recommended priority order:

1. `context7` → official documentation
2. `grep_app` → real-world code examples
3. `websearch` / `web-search-prime` → general knowledge
4. `fetch` / `web-reader` → retrieve and inspect specific pages
5. `deepwiki` → understand repositories
6. `zread` → analyze long documents
7. `sequentialthinking` → structured reasoning for complex tasks

---

### context7

**Purpose:** Documentation and library context.

Use it to retrieve:

- framework documentation
- library usage examples
- API references
- configuration details

Use when:

- unsure about library behavior
- needing official usage patterns
- verifying correct API usage

---

### grep_app

**Purpose:** Search real-world code.

Searches across large open-source repositories.

Useful for:

- seeing how APIs are used in real projects
- finding implementation patterns
- discovering edge cases

Think of it as **large-scale code search across public repositories**.

---

### websearch

**Purpose:** General internet search.

Used to retrieve:

- tutorials
- blog posts
- documentation
- technical explanations

Use when:

- official documentation is not enough
- searching for explanations or guides

---

### sequentialthinking

**Purpose:** Structured reasoning.

Helps break complex tasks into logical steps.

Use when:

- solving multi-step problems
- debugging complex logic
- planning implementations
- evaluating tradeoffs

---

### fetch

**Purpose:** Retrieve raw content from URLs.

Used to download:

- web pages
- documentation pages
- API responses
- text resources

Useful when a specific link must be inspected.

---

### deepwiki

**Purpose:** Repository knowledge extraction.

Provides structured understanding of:

- GitHub repositories
- project documentation
- architecture summaries

Useful when exploring unfamiliar projects.

---

### zread

**Purpose:** Long-document reading.

Optimized for processing:

- large documentation
- technical papers
- long markdown files
- long code explanations

Use when documents exceed normal context limits.

---

### web-search-prime

**Purpose:** High-quality web search.

Provides more curated and reliable search results.

Prefer when:

- accuracy matters
- searching for technical information
- needing authoritative sources

---

### web-reader

**Purpose:** Extract and parse webpage content.

Useful for:

- reading full articles
- summarizing documentation
- extracting structured content from webpages

# 8. File & Output Rules

## 8.1 — Temporary files go to /tmp

All test scripts, scratch files, prototypes, intermediate artifacts, and anything the agent writes to try something out must go under /tmp/. This includes: 

     Quick test scripts (test_api.py, debug.ts, etc.)
     Downloaded files used only for inspection
     Intermediate build or transformation artifacts
     Any file the agent creates for its own debugging purposes

Never create these files in the project root, in source directories unless they are the actual deliverable the user asked for. 

## 8.2 — README generation rules 

When generating a README.md for a project: 

     Do not include a "Project Structure" or "Directory Tree" section. File trees go stale fast, add noise, and the user can run tree themselves.
     Focus on: what the project does, how to set it up, how to use it, and any non-obvious conventions.

## Completion Verification Step

Before declaring that a task is complete, the agent **must verify that modified files are syntactically valid**.

Required checks:

- All modified files compile/parse without errors.
- Verify language-specific syntax.
- No unused imports/variables introduced by your changes.

If syntax errors exist, the agent must fix them before reporting completion.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
