---
name: orchestrated-delivery
description: Deliver a multi-part feature by orchestrating sub-agents end to end - parallel implementation in isolated worktrees, then independent code reviews, then targeted fixes. Use when the user wants a plan/spec implemented across several repos, services, or modules with sub-agents, asks to "orchestrate", "parallelize", "use sub-agents", or run implement-then-review as one flow.
argument-hint: "plan/spec path(s), branch name, and any model tiers"
---

# Orchestrated Delivery

You are the **orchestrator, nothing more**. You decompose the work, launch sub-agents, verify their output, and consolidate. You do **not** write feature code yourself. Delegate implementation, review, and fixes to sub-agents.

## Inputs

Expect some of these from the invocation (ask only for what is missing and cannot be inferred):

- A **plan** and/or a **spec** file. The plan drives work separation; the spec gives big-picture context. Read both fully before decomposing.
- A **branch name** for the feature (default: derive one, e.g. `feat/<slug>`).
- **Model tiers** (defaults below; honor any override):
  - worker (implementation + fixes): a mid-tier reasoning model at medium effort (e.g. Sonnet).
  - reviewer: a high-tier reasoning model at medium effort (e.g. Opus).
- **Base branch** (default `main`).

## Rules (hard constraints)

- Split work into **non-overlapping units**. Never let two sub-agents touch the same files or overlapping scope. A repo, service, or independent module is a natural unit.
- Each unit works in its **own isolated worktree**. Create worktrees repo-local at `.worktrees/<branch-name>` (add `.worktrees` to `.gitignore` first if not ignored). Do not place worktrees as siblings of the repo.
- All feature branches are **based from the base branch** (`main` unless told otherwise). Set each branch's **upstream to itself** (the feature branch), never to the base.
- **Never** push to `main`/`master`, never force-push, never merge.
- No `Co-Authored-By` lines in commits. No em dashes in commit messages, PR bodies, or docs.
- **Parallelize aggressively.** Launch independent unit agents in a single batch so they run concurrently. Do not serialize independent work.
- Speed never trades away quality: same rigor, same verification, same "done means done".
- Do not fabricate or predict a pending sub-agent's results. Wait for its completion notification. Review finished units as they land - do **not** wait for every unit before reviewing the ones already done.

## Phase 0 - Decompose and set up

1. Read the plan and spec. Identify the work units and the **cross-unit contracts** (API shapes, field names, event payloads, shared types). Write these contracts down explicitly - they are what parallel agents get wrong.
2. Check each target repo's git state: on base branch, clean tree, remote present, base branch exists.
3. Create one worktree + feature branch per unit, from the base branch. Do this yourself (deterministic) rather than making agents run git plumbing.

## Phase 1 - Implement (worker agents, parallel)

Launch one worker sub-agent per unit, all in one batch. Each prompt MUST include:

- The **absolute worktree path**; instruct the agent to work only there, using absolute paths (a sub-agent cannot persist `cd`).
- Its **slice of the plan** plus the **spec** for big-picture context, and the **fixed cross-unit contracts** verbatim, so parallel units agree on names/shapes.
- **Standards discovery**: read this repo's `AGENTS.md`/`CLAUDE.md`/`CONTRIBUTING.md`/`.editorconfig`/linter+formatter configs and match neighboring files; local configs override root; surface (do not silently resolve) conflicts between documented standards and existing code. Pass this instruction explicitly - do not assume the agent finds standards on its own.
- **Tests**: follow TDD at pre-agreed seams where practical; assert behavior at the highest practical seam using existing fixture patterns; cite the spec's testing decisions if it has them.
- **Verify before finishing**: run typecheck + lint, single relevant test files as they go, and the full suite at the end. Everything must pass.
- **Git**: commit on the feature branch in logical thematic groups; then `push -u origin <branch>` so upstream tracks the feature branch itself. Never main/force/merge. No Co-Authored-By, no em dashes.
- **Report back** (this is data for the orchestrator, not a user-facing note): files changed, tests + pass/fail, commit hashes, push result, and any deviations or standards conflicts. Tell the agent to flag anything it had to guess (especially cross-unit contracts).

## Phase 2 - Review (reviewer agents, as units finish)

As each implementation agent reports, launch a reviewer sub-agent on that unit. Do not wait for all units. Each review prompt MUST include:

- The unit's diff against the base branch (`git -C <worktree> diff <base>...<branch>`), read-only - the reviewer reports findings, it does not edit.
- The spec and plan slice for the **Spec** axis, and standards for the **Standards** axis.
- **Explicit scrutiny of the cross-unit contract seams**: have the reviewer read the *other* unit's actual output (sibling worktree) and confirm the shapes match. Contract mismatches between parallel units are the highest-value finding; call them out as blockers.
- Any risk areas the implementation report flagged as guessed.
- Output: findings ranked most-severe first, each with severity (blocker/important/minor/nit), file:line, concrete problem, one-line fix. Verify each claim against real code; drop plausible-but-unreal issues.

## Phase 3 - Fix (worker agents, for important findings only)

- Consolidate findings across reviews. For **blocker/important** findings, dispatch worker sub-agents into the **same worktrees**, scoped narrowly to those findings. Keep unit boundaries non-overlapping.
- Skip minors/nits unless the user wants them, but report them.
- After fixes, re-verify (typecheck/lint/tests) and, if the branch was pushed, push the fix commits.

## Phase 4 - Report

Give the user an actionable summary: per unit - branch, worktree path, commit hashes, push/upstream state, test results; the consolidated review verdict; what was fixed vs left as noted minors; and the next command if one is needed (integration check, PR, merge). Keep paths and commands exact.
