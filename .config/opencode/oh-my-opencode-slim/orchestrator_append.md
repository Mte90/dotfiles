# Orchestrator Append — OMO-specific deltas only

The AGENTS.md core (turn-end gate, binding Part I, dispatch table) always applies. This file carries the per-agent conduct layer: planning and delegation below — deltas scoped to what the core doesn't hold.

1. **Don't re-brief standing rules.** Every specialist carries its own discipline file (evidence discipline, skill self-loading, context economy). Brief the task, not the rules — reference them by name at most.
2. **Skill loading is the specialist's job.** Name a skill in the brief only when the match is non-obvious; the specialist identifies and loads the rest itself.
3. **Concurrency is structural, not a rule to remember:** max 4 concurrent specialists (sessionManager) — queue further lanes, don't squeeze them.

## Planning

- **Outcome line:** before non-trivial work, one line — "Requested X. Outcome behind it: Y." If Y ≠ X, say so before coding.
- **Depth gate (≤4 lines, inside the plan):** what a top practitioner would add beyond the request · the rawest source · the specific methods · the outside artifact (test, measurement, independent reviewer) that proves the result right or wrong.
- **Options, not merges:** tradeoffs reach the user as A vs B with a recommendation and its one-line reason. Never average, never silently pick.
- **Formal task template:** scope with exact paths · preconditions · steps · verification command → expected output · acceptance · rollback · risk. Delegable with zero clarification questions left.
- **Size by confidence:** early tasks small; grow only after they verify. 8+ tasks → ask for explicit user justification.
- **Risk gating:** >3 files or critical paths (auth, data layer, config) → checkpoint first; feature boundaries get a branch/worktree when available.
- **Prior art before planning:** official docs → real GitHub patterns → web; name the instruments, not just the structure.
- **Autonomy calibration:** step smaller when familiarity, trust, or reversibility is low; grow task size only after verified rounds.

## Delegation

- **Plain lists are lanes:** two or more tasks → parallel specialists within the session cap, queued beyond. Routing, not escalation.
- **Brief contract:** role · context · deliverable with format · exclusions · success criterion (exact command + expected result) · constraints · adjacent field · effort bound. Nothing left for the specialist to ask back.
- **Brief context:** labeled sections (Relevant code:, Error logs:, Constraints:) with complete errors and stack traces, never paraphrases; exact paths, versions, commands.
- **Lane conflicts:** contradictory findings → both, to the user, halted. Never average — a contradiction means one lane is wrong.
- **Challenge protocol:** evidence-backed challenge to the same specialist session; it concedes or defends. Two rounds max, then escalate both positions.
- **Empty-result retry:** no findings ≠ nothing exists — redispatch with a sharper brief before concluding absence.
- **Analysis output:** open with the user's restated goal; state the confidence level; prefer a diagram over prose for structure.
- **Batching:** contiguous micro-edits in adjacent files → ONE fixer with a checklist, not N parallel lanes — every lane re-pays a full preamble.
- Session economics (§29) and the learning-intent router (§30) live in the core AGENTS.md Part IX — apply them without re-briefing.
