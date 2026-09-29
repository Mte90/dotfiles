---
name: walden
description: "Walden drafts and maintains feature specs in `.walden/specs/` with a gated workflow: EARS requirements, design documents, implementation tasks, and execution of approved tasks. Use when the user asks for Walden, a feature spec, requirements, a design doc, an implementation plan, or work from an existing `.walden/specs/` folder."
metadata:
  short-description: Walden spec workflow
---

# Walden

Use this skill to turn an idea into a reviewed feature spec, or to execute reviewed work from an existing spec.
Reply in the user's preferred language when possible.

## When To Use

- A user wants a new feature specification
- A user wants requirements written in EARS
- A user wants a design document from approved requirements
- A user wants an implementation plan from approved design
- A user wants to execute approved tasks from `.walden/specs/{feature-name}/`

## Prerequisites

The `walden` CLI must be installed and available in `PATH`. The CLI is the single source of truth for all deterministic workflow mechanics. This skill handles authoring, reasoning, and review interaction; it does not re-implement workflow rules.

If `walden` is not available, inform the user and point them to the install instructions before continuing.

## Product Boundary

Walden is an open source spec-driven delivery kernel. It is not a complete enterprise platform. The CLI and this skill together cover the local workflow: requirements, design, tasks, execution, reconciliation, and lessons. Capabilities like GitHub App integration, multi-repo sync, org dashboards, and governance packs are future enterprise scope.

## Deterministic Helpers

- Prefer the `walden` CLI for deterministic workflow mechanics.
- Use `walden repo init` to bootstrap a repository when Walden has not been initialized yet.
- Use `walden feature init <feature-name>` to scaffold the canonical spec files.
- Use `walden status <feature-name> [--json]` to inspect phase, blockers, and next action.
- Use `walden validate [<feature-name>] [--all] [--json]` before phase transitions and before execution; omit the feature name to validate every feature in the repository.
- Use `walden review open <feature-name> --phase requirements|design|tasks` and `walden review approve <feature-name> --phase requirements|design|tasks` for deterministic review-state transitions.
- Use `walden task status <feature-name> [--json]`, `walden task start <feature-name> [task-id] [--json]`, and `walden task complete <feature-name> <task-id> [--json]` for deterministic execution flow.
- Use `walden task complete-all <feature-name> [--json]` to complete all runnable leaf tasks in order, stopping on first failure.
- Use `walden verify <feature-name> [--all] [--check] [--json]` to re-execute completed tasks' proofs against the current code and refresh execution evidence; `--check` reports without persisting anything. Re-verification is pure: a proof that modifies the working tree fails its task naming the changed paths — author proofs as read-only assertions and route build outputs outside the repository (task completion keeps accepting generator mutations; its recorded identity binds the resulting tree). Verify records bind the tree the run started from, so one mutating proof fails alone instead of staling the tasks proven after it; the run warning names both the modified paths and the tasks re-proven on the modified tree.
- Use `walden evidence status <feature-name> [--json]` to inspect each task's derived evidence state: verified, stale-spec, stale-code, failed, unrecorded, or pending.
- Use `walden release check [<feature-name>] [--strict] [--allow-pending --reason "<text>"] [--json]` to certify the repository (or one feature) as releasable in one deterministic verdict; it executes no proofs and writes nothing. Pending leaf tasks block the verdict by default; the waiver flags are the only relaxation and require the user's explicit approval (see Release Certification).
- Use `walden adopt [<feature-name>] [--apply] [--json]` to onboard a repository whose specs predate the current contract: the default is a read-only plan classifying every feature; `--apply` seals recorded approvals and re-proves unrecorded work (see Brownfield Adoption).
- Use `walden reconcile <feature-name> [--json]` when approved upstream documents changed or the approval chain is stale.
- Use `walden lesson log --feature <feature-name> --phase requirements|design|tasks|execute|release --trigger "<event>" --lesson "<pattern>" --guardrail "<rule>" [--json]` after meaningful corrections, failed validation, or execution surprises.
- Use `walden version [--json]` to check the installed CLI version and schema version.

All `--json` commands return a versioned envelope:

```json
{
  "schema_version": "v0beta1",
  "command": "<command-name>",
  "ok": true,
  "result": {}
}
```

## Core Rules

- New features must progress `Requirements -> Design -> Tasks`.
- Planning stops after approved `tasks.md`.
- Execution is a separate invocation path and starts only when the user explicitly asks to execute a task.
- Existing specs may enter at Design only if `requirements.md` is approved.
- Existing specs may enter at Tasks only if `design.md` is approved.
- Execution requires approved and non-stale `requirements.md`, `design.md`, and `tasks.md`.
- For non-trivial work, start with a short plan that includes the next phase steps and how you will verify them.
- If ambiguity, failed validation, or conflicting constraints appear, stop and re-plan from the earliest affected phase instead of pushing forward.
- Review `.walden/lessons.md` before non-trivial work when the current request resembles earlier mistakes or rejected drafts.
- For deterministic state inspection or mutation, prefer the `walden` CLI over manual frontmatter edits or helper scripts.
- Before closing any revision, correction, or recovery step, make an explicit `Lesson Decision: none|logged`.
- If the work included a user correction, failed validation, rejected draft, re-plan, or unexpected execution issue, default to `Lesson Decision: logged` unless there is a clear reason not to.
- Never treat silence as approval.
- If an upstream document changes, mark dependent downstream documents stale and reset their `status` to `draft` before continuing.

## Files And Naming

- Store documents in `.walden/specs/{feature-name}/`.
- Normalize `{feature-name}` to kebab-case.
- Use exactly these files:
  - `requirements.md`
  - `design.md`
  - `tasks.md`

## Approval And Staleness Model

Every document must begin with YAML frontmatter.

### `requirements.md`

```yaml
---
status: draft
approved_at:
last_modified: 2026-03-19T10:00:00Z
approved_fingerprint:
---
```

### `design.md`

```yaml
---
status: draft
approved_at:
last_modified: 2026-03-19T10:00:00Z
approved_fingerprint:
source_requirements_approved_at:
source_requirements_fingerprint:
---
```

### `tasks.md`

```yaml
---
status: draft
approved_at:
last_modified: 2026-03-19T10:00:00Z
approved_fingerprint:
source_design_approved_at:
source_design_fingerprint:
---
```

Apply these rules consistently:

- Set `status: draft` when first creating a document.
- Set `status: in-review` immediately before presenting a revision to the user.
- Set `status: approved` and populate `approved_at` only after explicit approval — prefer `walden review approve`, which also records the approval fingerprints.
- Update `last_modified` on every edit.
- Never hand-edit fingerprint fields (`approved_fingerprint`, `source_*_fingerprint`): they are computed and verified by the CLI. A fingerprint that does not match its document's content makes the document stale.
- Freshness is decided by fingerprint comparison: an approved document is stale when its body no longer matches its `approved_fingerprint`, and a downstream document is stale when its `source_*_fingerprint` differs from the upstream's current `approved_fingerprint`. Timestamps remain as human-readable context.
- If an approved document is edited later, it is stale until the chain is repaired: run `walden reconcile` (the document resets to draft) and take it through review again.
- Approved documents that lack fingerprints (created by pre-fingerprint CLI versions) are stale by definition; `walden reconcile` plus one re-approval cycle migrates them.

## Phase Router

Before doing any work:

1. Determine the feature name and inspect `.walden/specs/{feature-name}/`.
2. Read `.walden/constitution.md` when it exists for project-wide context (tech stack, conventions, key files). Skip without error when absent. If the file exists but contains only placeholder text (sections with bracket patterns like `[What this project does...]`), stop and ask the user to fill it in before proceeding — an empty constitution means every spec will be written without stable project context.
3. Review `.walden/lessons.md` when it exists and the feature type or failure mode is similar.
4. Read existing frontmatter and approval timestamps.
5. Run `walden status <feature-name>` and `walden validate <feature-name>` when the CLI is available and the feature folder already exists.
6. Choose the earliest phase that is missing, unapproved, or stale.
7. For non-trivial work, state a short plan for the current phase plus the verification gate.
8. Honor the user's requested entry point only if all prerequisites are approved and fresh.
9. For a new feature, always start at Requirements.

## Decision Checkpoint Protocol

Apply this protocol during Phase 1, 2, and 3 drafting. Do not apply during Phase 4.

**Bifurcation Test:** a decision merits a `[decision: <question>]` checkpoint if and only if choosing differently would require discarding or substantially rewriting document content produced after the choice. When in doubt, default to autonomous resolution.

**Explore before asking:** when a decision passes the Bifurcation Test, check whether the codebase, the constitution, or approved upstream documents already answer the question before emitting a checkpoint. If they do, resolve autonomously and record the assumption with its source: `<!-- assumed: <choice> (source: <file or document>) -->`.

**On TRUE — checkpoint detected:** emit `[decision: <question>]` in the document, explain the fork in plain language, and state your recommended option with a one-line rationale — if no option is defensibly better, present the fork without a recommendation. Stop generating further content. Wait for the user's response. On receiving a response, state how the answer will be applied to the document before resuming content generation in the same conversation turn. If the user's response surfaces a previously unidentified bifurcation-significant decision, emit a new `[decision: <question>]` marker for the newly identified fork before generating content that depends on it.

**On FALSE — autonomous resolution:** record the chosen assumption as `<!-- assumed: <choice> -->` inline in the document and continue drafting without interruption.

**Autonomous-at-checkpoint:** if the user asks the skill to decide autonomously at a checkpoint, record the resolution as `<!-- assumed: <choice> -->` in the document and continue drafting without emitting further checkpoints for decisions within the same scope.

**Constraints:** emit no more than five `[decision:]` checkpoints across a single phase drafting session. If a `[decision:]` checkpoint is left unresolved at the end of a conversation turn, the document remains in `draft` status and the skill shall not present it for phase-transition review.

## Phase 1: Requirements

Generate a first draft before asking clarifying questions. Then iterate with the user.

### Requirements Standard

- Apply the Decision Checkpoint Protocol during drafting.
- Give every requirement a stable ID: `R1`, `R2`, `R3`.
- Give every acceptance criterion a stable ID: `R1.AC1`, `R1.AC2`, `R2.AC1`.
- Use EARS syntax for every acceptance criterion. The CLI validates keyword-level structure: single SHALL, form classification (WHEN, WHILE/DURING, WHERE, IF/THEN before SHALL), IF/THEN pairing, non-empty template slots, and warns on likely inverted forms. It does not validate semantic quality of slot content. The skill guides content quality; the CLI enforces structural conformance.
- Use user stories as context, not as the acceptance contract.
- Give non-functional requirements stable IDs: `NFR1`, `NFR2`.
- Give constraints and dependencies stable IDs: `C1`, `C2`.
- Include explicit out-of-scope items when scope risk is high.

### Mutation Ownership

A spec that mutates shared state without naming who owns each mutation produces silent conflicts. Before approval, complete this checklist for every piece of state the feature touches:

- **State inventory**: List every model, table, file, flag, or cache entry the feature creates or modifies.
- **Actor per mutation**: For each state item, name exactly one actor (admin, cron, API caller, signal handler, migration) that owns the write. If two actors can write the same field, split the field or document the precedence rule.
- **Conflated flag check**: If a single boolean field gates behavior driven by different actors, split it into per-actor fields or a discriminated status. A `blocked` flag set by both an admin and an automated process makes unblocking opaque and races on intent.
- **Clear-ownership rule**: State who may clear the flag and under what condition. An automated process must never clear an admin-set flag unless the spec says so explicitly.

### EARS Forms

- Ubiquitous: `The system SHALL [response]`
- Event-driven: `WHEN [trigger], the system SHALL [response]`
- State-driven: `WHILE [precondition], the system SHALL [response]`
- Optional feature: `WHERE [feature], the system SHALL [response]`
- Unwanted behavior: `IF [trigger], THEN the system SHALL [response]`
- Complex: `WHILE [precondition], WHEN [trigger], the system SHALL [response]`

### EARS Quality Rules

Apply these rules during drafting, not only during review.

**Form selection.** Choose the form that matches the behavioral nature of the criterion:
- If the behavior is always true regardless of user action (invariants, automatic behaviors, system properties), use **ubiquitous**. Example: "The system SHALL ensure no two players receive identical cards." Do not force a WHEN trigger on something that has no external trigger.
- If the behavior responds to a specific user action or system event, use **event-driven**. The trigger must name what happens, not just that something happens.
- If the behavior is active only while a condition holds, use **state-driven** (WHILE or DURING).
- If the behavior handles a failure, invalid input, or error condition, use **unwanted** (IF/THEN).
- If the behavior requires both a precondition and a trigger, use **complex** (WHILE + WHEN).

**One behavior per criterion.** Each AC must describe exactly one observable system response. If the response slot contains "and" connecting two distinct behaviors, split into separate ACs. Example — split this: "the system SHALL generate cards server-side and send them to each player via WebSocket" into two ACs: one for generation, one for delivery. **Self-check after each AC**: before writing the next criterion, re-read the response slot just drafted. If it contains "and" connecting two independently observable behaviors, split immediately. Do not defer to review — splitting later requires ID renumbering that cascades through the entire spec.

**Concrete triggers.** Every event-driven trigger must name the specific interaction: clicks, taps, submits, opens, presses, types, drags, scrolls, navigates — not generic verbs like triggers, initiates, requests, performs, executes. If you cannot name the interaction, the requirement may be underspecified.

**Failure mode coverage.** For each constraint, ask: "what happens if this fails or is unavailable?" Draft at least one IF/THEN criterion per constraint that has a realistic failure mode. A spec with constraints but zero unwanted forms is almost certainly missing error handling.

**NFR promotion.** If an NFR contains IF/THEN language describing a specific system behavior, it is not a non-functional requirement — it is a functional requirement that belongs in the Requirements section with its own ACs. Move the behavioral specification to a new requirement, and reduce the NFR to the quality attribute it represents. Example: "IF a player loses connection, THEN the system SHALL reconnect" belongs in a Reconnection Handling requirement, not in an NFR. The NFR should say: "The system SHALL tolerate intermittent network connectivity without data loss."

**NFR-to-AC bridge.** After writing all requirements and before writing NFRs, draft the NFR list. Then, for each NFR: identify the concrete user-facing behavior it implies and draft at least one AC in the appropriate requirement. If the NFR mentions accessibility, draft ACs for keyboard navigation and screen reader announcements. If the NFR mentions offline support or reliability, draft ACs for what the user sees in degraded conditions. If you cannot identify a concrete behavior, the NFR may be too vague — ask the user what observable outcome they expect. An NFR without a corresponding testable AC is a wish, not a requirement.

### `requirements.md` Template

```markdown
---
status: draft
approved_at:
last_modified: 2026-03-19T10:00:00Z
---

# Requirements Document

## Introduction

[Short problem statement and scope]

## Requirements

### R1 [Short title]

**User Story:** As a [role], I want [capability], so that [benefit]

#### Acceptance Criteria

1. `R1.AC1` WHEN [trigger], the system SHALL [response]
2. `R1.AC2` IF [failure trigger], THEN the system SHALL [response]

### R2 [Short title]

**User Story:** As a [role], I want [capability], so that [benefit]

#### Acceptance Criteria

1. `R2.AC1` WHILE [precondition], WHEN [trigger], the system SHALL [response]

## Non-Functional Requirements

- `NFR1` [Performance, security, accessibility, reliability, or scalability requirement]

## Constraints And Dependencies

- `C1` [Technical, team, infrastructure, or external dependency constraint]

## Out Of Scope

- [Explicitly excluded work for this iteration]
```

### Review Loop

- Draft or update `requirements.md`.
- Re-plan from Requirements if the problem statement, scope boundary, or EARS structure becomes ambiguous during review.
- Run `walden validate <feature-name> --json` before presenting for review. Read `warnings`, `ears_validation`, and `ears_distribution` from the JSON output.
- Verify the EARS Quality Rules were applied during drafting. Specifically check:
  - **Form selection**: Read `ears_distribution` for form counts. The CLI reports counts but does not validate whether forms are appropriate -- that is your responsibility. Ask: are invariants expressed as ubiquitous? Are event responses tied to specific triggers? A spec with zero ubiquitous forms may be forcing everything into event-driven.
  - **One behavior per AC**: Scan each AC response slot for "and" connecting two distinct behaviors. Split if found.
  - **Concrete triggers**: Scan event-driven ACs for generic verbs without a concrete interaction. Suggest replacements.
  - **Failure mode coverage**: If CLI warns "no unwanted-behavior criteria found", or if `ears_distribution.unwanted` is zero with multiple constraints, ask the user to consider failure modes.
  - **NFR-to-AC bridge**: For each NFR, confirm at least one AC specifies the concrete testable behavior. Flag NFRs that remain untestable.
  - **Persistence balance**: If constraints mention storage, check ACs cover both read and write sides.
  - **Domain-specific gaps**: Use the constitution and constraint list to surface missing coverage the rules above do not catch.
- Prefer `walden review open <feature-name> --phase requirements` for the deterministic state change to `in-review`.
- Ask for approval.
- After explicit approval, prefer `walden review approve <feature-name> --phase requirements` for the deterministic state change to `approved`.
- If the user corrects the scope or the validator exposes a recurring defect pattern, log a lesson before revising again with `walden lesson log ...` when available.
- Before closing the review step, report `Lesson Decision: none|logged`.
- Do not proceed to Design without explicit approval.

## Phase 2: Design

Design starts only from approved and non-stale requirements.

### Design Standard

- Apply the Decision Checkpoint Protocol during drafting.
- Read the approved requirements first.
- Research only when a design decision depends on current external facts, library behavior, or official documentation.
- Keep the design traceable to requirement IDs.
- Compare the preferred design against at least one viable alternative.
- Include `## Options Considered`, `## Simplicity And Elegance Review`, `## Failure Modes And Tradeoffs`, and `## Verification Plan`.
- Challenge the first draft once before showing it: ask whether a simpler shape, lower coupling, or fewer moving parts would satisfy the same requirements.
- Use diagrams only when they clarify decisions.
- Approve with `walden review approve`, which records the upstream approval timestamp and fingerprint (`source_requirements_approved_at`, `source_requirements_fingerprint`).
- In the Requirement Coverage table, wrap every ID in backticks (e.g., `| `R1` |`, `| `NFR1` |`). The deterministic validator matches this exact format and will reject rows without backticks.
- Enforce a single entry point for any operation with a canonical output (invoice numbers, sequence generation, ID assignment). If two code paths can produce the same artifact, one will diverge. Name the single function or service in the design.
- In `## Data Models`, annotate every non-default model field (a `Field` without a `default` or `auto_now_add` that callers must supply). A field the design does not mark as mandatory will be omitted by the implementer who assumes the database supplies it.

### Batch Processing Integrity

When the design includes a batch or cron job that processes multiple items (customers, records, files):

- Wrap each item's processing in a database savepoint so a single item's failure does not poison the batch transaction.
- The error handler for a failed item must not itself trigger a database write on the poisoned inner transaction — either use a fresh transaction for error logging or accept the savepoint rollback before logging.
- Specify which model fields are mandatory on creation (fields without a default value). A batch job that creates `JobLog` records must provide every required field explicitly — a missing `started_at` with no default surfaces only at runtime.
- Count every item in the batch result, including items that raise exceptions, so the reported total matches the processed set.

### `design.md` Template

```markdown
---
status: draft
approved_at:
last_modified: 2026-03-19T10:00:00Z
approved_fingerprint:
source_requirements_approved_at:
source_requirements_fingerprint:
---

# Feature Design

## Overview

[High-level approach and key design choices]

## Architecture

[Components, boundaries, and data flow]

## Options Considered

### Option A

- Summary: [Preferred approach]
- Why chosen: [Why it is the best fit]

### Option B

- Summary: [Viable alternative]
- Why rejected: [Why it is less suitable]

## Simplicity And Elegance Review

- Simplest viable shape: [How the design minimizes moving parts]
- Coupling check: [How boundaries stay clean]
- Future-proofing: [What is intentionally deferred]

## Components And Interfaces

### [Component name]

- Purpose: [What it does]
- Inputs/Outputs: [Interface contract]
- Dependencies: [What it relies on]
- Requirements: `R1`, `R2`

## Data Models

[Entities, schemas, state, or storage decisions]

## Error Handling

[Validation, retries, failure modes, logging]

## Security Considerations

[Only when relevant]

## Failure Modes And Tradeoffs

- Failure mode: [What can go wrong]
- Mitigation: [How the system contains it]
- Tradeoff: [What was accepted and why]

## Testing Strategy

[Unit, integration, and end-to-end scope]

## Verification Plan

- Requirement proof: [How each critical requirement will be demonstrated]
- Test evidence: [Which tests or checks prove the design]
- Operational evidence: [Logs, metrics, alerts, or dashboards if relevant]

## Requirement Coverage

<!-- Every ID MUST be wrapped in backticks — the validator rejects rows without them -->
| Requirement | Covered By |
| --- | --- |
| `R1` | [Component/flow] |
| `R2` | [Component/flow] |
| `NFR1` | [Control/test/monitoring] |
```

### Review Loop

- Draft or update `design.md`.
- Re-plan from Requirements if the design exposes new scope, contradictory requirements, or missing acceptance contracts.
- Run `walden validate <feature-name>` before showing the design for approval when the CLI is available.
- Prefer `walden review open <feature-name> --phase design` for the deterministic state change to `in-review`.
- Ask for approval.
- After explicit approval, prefer `walden review approve <feature-name> --phase design` for the deterministic state change to `approved`.
- If the user rejects the design or asks for a simpler approach, log the lesson before the next revision with `walden lesson log ...` when available.
- Before closing the review step, report `Lesson Decision: none|logged`.
- Do not proceed to Tasks without explicit approval.
- If requirements change, prefer `walden reconcile <feature-name>` rather than resetting downstream approval state by hand.

## Phase 3: Tasks

Task generation starts only from approved and non-stale design.

### Task Standard

- Apply the Decision Checkpoint Protocol during drafting.
- Produce only implementation tasks that write, modify, or test code.
- Use a maximum two-level hierarchy.
- Keep tasks incremental and testable.
- Reference acceptance criteria IDs (e.g., `R1.AC1`, `R1.AC2`) on every leaf task, not just parent requirement IDs.
- Reference design sections on every leaf task.
- Add a `Verification:` block on every leaf task using the structured `command` format (Kubernetes pattern). The CLI executes commands via `exec.Command` without a shell, so use JSON arrays for exact argument control.
- Optionally add a `covers:` field on proof steps to declare which acceptance criteria the proof demonstrates.
- Prefer an `expect_output` assertion on test-running proof steps so a pattern that matches zero tests cannot pass vacuously.
- Declare `timeout:` on proof steps that legitimately run long; every step is otherwise bounded by the executor's 10-minute default, and exceeding the budget is a proof failure. The CLI tracks proof reference coverage separately from task reference coverage and reports both in `walden validate --json`.
- Approve with `walden review approve`, which records the upstream approval timestamp and fingerprint (`source_design_approved_at`, `source_design_fingerprint`).
- One task = one flow. If a task touches two independent user flows (e.g., deleting a plan AND migrating its subscribers), split it into two tasks. A coarse task hides incomplete coverage behind a single checkbox.

### Verification Strength Tiers

Not all tasks need the same proof. Match the verification to the task type:

- **Tier 1 — Static**: For config, schema, or import-only tasks. Proof: `manage.py check`, `ruff check`, import assertion. Sufficient when no runtime behavior changes.
- **Tier 2 — Unit**: For logic, calculation, or model-behavior tasks. Proof: targeted test that exercises the changed code path and fails if the behavior breaks. `expect_output` assertion required.
- **Tier 3 — Behavioral**: For admin UI, view-layer, or any task where the user sees a change. Proof: integration test or browser test that exercises the full request/response cycle. `manage.py check` alone is **not** Tier 3 and must not be the sole proof for a UI task.

Mark each leaf task's `Verification:` with its tier. A task below Tier 3 that changes user-visible behavior is under-verified — escalate or split.

### Verification Format

Use the structured `command:` format (follows the Kubernetes `command` pattern):

```markdown
    - Verification:
      - command: ["go", "test", "-run", "TestExample", "./pkg/example"]
```

For negative assertions (command must fail), use `expect_exit`:

```markdown
    - Verification:
      - command: ["grep", "-rq", "old_pattern", "."]
        expect_exit: 1
```

For output assertions — and to prevent vacuous passes where a test pattern matches zero tests — add `expect_output`:

```markdown
    - Verification:
      - command: ["go", "test", "-run", "TestExample", "./pkg/example"]
        expect_output: "--- PASS: TestExample"
```

For shell operators (pipes, &&, globbing), use the Kubernetes shell pattern:

```markdown
    - Verification:
      - command: ["sh", "-c", "test -d .walden && go test ./..."]
```

Multi-step verification runs steps in order, stopping on first failure:

```markdown
    - Verification:
      - command: ["go", "build", "./..."]
      - command: ["go", "test", "./..."]
```

For proof reference coverage, add `covers:` to declare which acceptance criteria a proof step demonstrates:

```markdown
    - Verification:
      - command: ["go", "test", "-run", "TestAuth", "./internal/auth"]
        covers: ["R1.AC1", "R1.AC2"]
```

The CLI validates that `covers:` IDs reference known acceptance criteria and reports proof reference coverage separately from task reference coverage in the JSON output.

Per-step `timeout:` (a positive Go duration string) bounds a slow proof; steps without one run under the executor's 10-minute default, and exceeding the budget is a proof failure:

```markdown
    - Verification:
      - command: ["go", "test", "-run", "TestSlowIntegration", "./internal/integration"]
        timeout: 30m
```

Prefer the read-only variant of ecosystem commands when one exists — the assertion stays, the mutation goes:

```markdown
    - Verification:
      - command: ["go", "mod", "tidy", "-diff"]   # asserts tidiness, writes nothing
```

`["go", "mod", "tidy"]` would rewrite `go.mod` mid-run and fail its task as a side effect; the `-diff` form proves the same fact and keeps re-verification pure.

Legacy single-line format (`Verification: go test ./...`) still works but does not support quotes, pipes, or shell operators.

### `tasks.md` Template

```markdown
---
status: draft
approved_at:
last_modified: 2026-03-19T10:00:00Z
approved_fingerprint:
source_design_approved_at:
source_design_fingerprint:
---

# Implementation Plan

- [ ] 1. [Top-level implementation objective]
  - [ ] 1.1 [Concrete coding step]
    - Requirements: `R1.AC1`, `R1.AC2`, `NFR1`
    - Design: [Relevant section]
    - Verification:
      - command: ["go", "test", "-run", "TestExample", "./pkg/example"]
        covers: ["R1.AC1", "R1.AC2"]

- [ ] 2. [Next incremental objective]
  - [ ] 2.1 [Concrete coding step]
    - Requirements: `R2.AC1`
    - Design: [Relevant section]
    - Verification:
      - command: ["grep", "-rq", "old_pattern", "."]
        expect_exit: 1
        covers: ["R2.AC1"]
```

### Review Loop

- Draft or update `tasks.md`.
- Re-plan from Design if the implementation sequence exposes missing architecture, missing interfaces, or untestable steps.
- Run `walden validate <feature-name>` before showing the task plan for approval when the CLI is available.
- Prefer `walden review open <feature-name> --phase tasks` for the deterministic state change to `in-review`.
- Ask for approval.
- After explicit approval, prefer `walden review approve <feature-name> --phase tasks` for the deterministic state change to `approved`.
- If the user corrects sequencing or coverage, log a lesson before revising again with `walden lesson log ...` when available.
- Before closing the review step, report `Lesson Decision: none|logged`.
- Stop after approval. Do not start implementation unless the user explicitly asks.

## Phase 4: Execute

Execution is for approved specs only.

### Execution Standard

- Read `requirements.md`, `design.md`, and `tasks.md` before writing code.
- Use `walden task status <feature-name>` to verify that execution is allowed and to resolve the next runnable task when the CLI is available.
- For non-trivial implementation work or a requested batch, start with a short execution plan and the verification steps you will use.
- If the user names a task, execute only that task unless they explicitly request a batch.
- If the user does not name a task, use `walden task status <feature-name>` to identify the next unchecked task and wait for confirmation before implementing.
- Use `walden task start <feature-name> [task-id]` to obtain normalized execution context before writing code.
- Complete sub-tasks before their parent task.
- Write the minimum production code needed for the requested task.
- Write thorough tests for the task.
- Run targeted tests for the changed area. Do not run the full suite unless the user asks.
- Treat the task's `Verification:` line as mandatory proof. Prefer `walden task complete <feature-name> <task-id>` so proof execution and checkbox mutation remain deterministic.
- Task completion records execution evidence in `.walden/evidence/<feature-name>.json`; commit it with the work — it is shared repository state, reviewed like the specs it proves.
- If `walden task status` warns that completed tasks are no longer verified (stale-spec, stale-code, failed, unrecorded), run `walden verify <feature-name>` before building on top of them; never dismiss an evidence warning.
- If a test fails or the proof is weaker than expected, stop and re-plan instead of hand-waving the result.
- Before closing the execution step, report `Lesson Decision: none|logged`.
- Stop after the requested task or batch and wait for review.

### Spec Drift

- If implementation reveals a gap in the approved spec, pause execution.
- Update the earliest affected document.
- Re-run the approval gate from that phase forward.
- Prefer `walden reconcile <feature-name>` when upstream approval metadata or freshness is no longer valid.
- After reconciliation and re-approval, run `walden verify <feature-name>`: completed tasks whose evidence went stale-spec must be re-proven against the updated contract, not assumed.
- Log a lesson if the gap came from a missed pattern, missing guardrail, or design blind spot.
- Do not silently rewrite approved requirements or design during implementation.

## Release Certification

- When the user asks whether the work is releasable — or before any tag, release branch, or delivery hand-off — run `walden release check` and report its verdict; do not assemble the answer from separate status checks.
- The gate certifies and never releases: approved fresh chains, full-spec validation, decision markers in approved documents, execution evidence, and a clean worktree outside `.walden/` fold into one exit code. Tags, changelogs, and publishing stay with you and the user, after certification passes.
- Read a failed certification as a work list: every blocker names its remedy. Apply the remedies and rerun the gate; never edit state by hand to silence a blocker.
- Pending leaf tasks block certification by default: the plan is a promise the release must keep or visibly defer. The only relaxation is `--allow-pending --reason "<text>"`, which waives them for that verdict and records the reason and the waived task ids in the output. **Never pass `--allow-pending` unless the user explicitly approves the waiver and its reason in the current conversation** — a waiver is the user's recorded decision, not a convenience; report the waived tasks back after the run.
- The verdict names the certified commit and a completion class — `complete` when every planned leaf task is executed, `with-pending` when pending work blocks, `with-waivers` when it was explicitly waived; JSON carries `certified_commit`, `completion`, and the `waiver` record for pipeline policy.
- `--strict` requires committed `.walden/` state — commit specs and evidence before a final certification; it composes with a waiver (committed state stays required, pending stays waived).
- The dirty-worktree blocker has no bypass by design: the remedy is committing the work. Do not look for a flag. Certification also fails closed without usable git — a verdict must name the code identity it certified — and on unterminated HTML comments in approved documents.
- Compose production and judgment: `walden verify <feature-name>` re-proves execution, then `walden release check` judges the result. In CI, gate the pipeline on the exit code and use `--json` for structure.

## Brownfield Adoption

- When a repository carries specs that predate the current contract — approved documents without approval fingerprints (stale chains, `walden verify` gate-blocked) or completed tasks without evidence (`unrecorded` blockers) — use `walden adopt`, not manual reconciliation: reconcile-and-re-approve ceremony across a portfolio is exactly what the lane eliminates.
- Always run the read-only plan first and present it to the user before `--apply`. The plan classifies every feature: `backfill` (approved documents to seal), `re-prove` (fresh chain, evidence to record), `complete` (nothing to adopt), `blocked` (a present fingerprint contradicts the content — human reconcile territory; adopt never writes there).
- Sealing trusts recorded approvals: it stamps the fingerprint of the document's current body under the approval already recorded. State this assumption when presenting the plan — an edit made between the old approval and the seal is invisible to pre-fingerprint history, and the seal grandfathers it in.
- `--apply` seals, then re-proves through the verify machinery. The verified/failed partition is the honest work list: failures record real evidence with execution profiles, so environment drift is diagnosable per task. Rerunning `--apply` resumes — verified tasks are skipped, failed ones retry.
- The adoption diff (sealed documents, new evidence ledgers) is ordinary repository state: review and commit it like any other change. Exit code 1 means the partition contains failures to triage, not that adoption must be repeated from scratch.
- When the failed partition reflects a superseded product generation rather than broken code, those specs are candidates for retirement, not repair: delete their directories (history lives in git) and record each in `.walden/RETIRED.md` — one line naming the retirement commit and the successor. The `walden-history` companion skill officiates the ceremony and narrates the history it preserves.

## Environment Probes

- `.walden/environment.md` declares named probes — commands whose trimmed output joins every evidence record's execution profile, alongside the always-present `platform` and `walden` (CLI version) keys:

```markdown
# Environment Probes

- go: ["go", "version"]
- node: ["node", "--version"]
```

- Declare probes for the toolchains the project's proofs depend on when initializing or adopting a repository; prefer commands that print stable version strings — nondeterministic output (timestamps, paths) reads as permanent drift.
- Probe names are lowercase kebab; `platform` and `walden` are reserved. A malformed declaration fails evidence-producing commands loudly; a failing or hung probe degrades to a marker value (`probe failed: …`, `probe timed out`) and never blocks the run.
- Read drift before blaming code: `walden evidence status` prints recorded-versus-current profile differences, and a failed re-verification appends `environment drift: go: recorded "go1.25.0" → current "go1.24.0"` to the failure. Fix the environment (or knowingly re-record on the current one); never edit proofs to paper over drift.
- Profiles are diagnostic only: they never change a derived evidence state, and records written before profiles existed read as `legacy record: no profile`.

## Self-Improvement Loop

- Review `.walden/lessons.md` before non-trivial work when earlier patterns are relevant.
- After any user correction, failed validation, rejected design, or execution surprise, append a lesson with `walden lesson log ...` when available.
- Treat these as automatic lesson triggers: user correction, failed validation, rejected draft, explicit simplification request, re-plan, failed test caused by a wrong assumption, or spec gap discovered during execution.
- Record three things in every lesson: the trigger, the mistake pattern, and a guardrail that would have prevented it.
- Apply the new guardrail in the next revision before presenting it.
- If no trigger occurred, still make and report the explicit decision: `Lesson Decision: none`.

## Output Standards

- Be concise, decisive, and developer-to-developer.
- Explain the reasoning behind recommendations when it matters.
- Prefer small examples over long exposition.
- Keep production code minimal and tests thorough.
- Cite sources in the design phase when external research informed a decision.
- In every phase summary, include `Lesson Decision: none` or `Lesson Decision: logged`.
<!-- walden-skill-version: v0.11.0 -->
