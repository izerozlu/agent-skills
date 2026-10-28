---
name: orchestrated-delivery
description: Deliver a multi-part feature by orchestrating sub-agents end to end. Use when the user wants a plan/spec implemented across several repos, services, or modules with sub-agents, asks to "orchestrate", "parallelize", "use sub-agents", or run implement-then-review as one flow.
argument-hint: "plan/spec path(s), branch name"
---

# Orchestrated Delivery

You are the **orchestrator, nothing more**. You decompose the work, launch sub-agents, verify their output, and consolidate. You do **not** write feature code yourself. Delegate implementation, review, and fixes to sub-agents.

## Inputs

Expect some of these from the invocation (ask only for what is missing and cannot be inferred):

- A **plan** and/or a **spec** file. The plan drives work separation; the spec gives big-picture context. Read both fully before decomposing.
- A **branch name** for the feature (default: derive one, e.g. `feat/<slug>`).
- **Base branch** (default `main`).

## Agents

Use these predefined agents. Always launch them by `subagent_type`. Do not use `general-purpose` for these roles.

- `delivery-worker`: implements a unit, or fixes findings in it. Read + write, commits.
- `delivery-reviewer`: Spec + contract-seam review. Read-only.
- `delivery-standards-auditor`: documented-rule compliance audit. Read-only.

Each agent already holds its standing instructions (standards discovery, TDD, verification, git rules, report format, severity scale). Your prompts carry only the **per-unit data** listed in the phases below. Do not repeat the standing instructions in the prompt.

The agent definitions ship with this skill in [agents/](agents/). If an agent type is not available:

- Offer to install them: copy `agents/*.md` into `.claude/agents/` (this project) or `~/.claude/agents/` (all projects). Installed agents load in the next session.
- For this run, fall back to `general-purpose` and paste the body of the matching file (for example `agents/delivery-worker.md`) into the prompt.

Give each Agent call a `description` that names the unit and role, for example `worker: billing-api` or `review: billing-api`, so the user can tell agents apart.

## Rules (hard constraints)

- Split work into **non-overlapping units**. Never let two sub-agents touch the same files or overlapping scope. A repo, service, or independent module is a natural unit.
- Each unit works in its **own isolated worktree**. Create worktrees repo-local at `.worktrees/<branch-name>` (add `.worktrees` to `.gitignore` first if not ignored). Do not place worktrees as siblings of the repo.
- All feature branches are **based from the base branch** (`main` unless told otherwise).
- **Do not push.** Branches stay local; the user pushes later. Never force-push, never merge.
- No `Co-Authored-By` lines in commits. No em dashes in commit messages, PR bodies, or docs.
- **Parallelize aggressively.** Launch independent unit agents in a single batch so they run concurrently. Do not serialize independent work.
- Speed never trades away quality: same rigor, same verification, same "done means done".
- Do not fabricate or predict a pending sub-agent's results. Wait for its completion notification. Review finished units as they land - do **not** wait for every unit before reviewing the ones already done.

## Phase 0 - Decompose and set up

1. Read the plan and spec. Identify the work units and the **cross-unit contracts** (API shapes, field names, event payloads, shared types). Write these contracts down explicitly - they are what parallel agents get wrong.
2. Check each target repo's git state: on base branch, clean tree, base branch exists.
3. Create one worktree + feature branch per unit, from the base branch. Do this yourself (deterministic) rather than making agents run git plumbing.

## Phases 1-3 - Implement, review, fix

Every prompt carries the unit's **absolute worktree path**, **branch**, and **base branch**, plus:

| Phase | Agent | Start | Extra prompt data |
|---|---|---|---|
| 1 Implement | `delivery-worker` | One per unit, all in one batch | Plan slice; spec (or its path); cross-unit contracts verbatim; the spec's testing decisions and TDD seams, if any; unit notes (e.g. known test commands) |
| 2 Review | `delivery-reviewer` + `delivery-standards-auditor` | Both per unit, in parallel, as soon as that unit's worker reports | Reviewer only: plan slice; spec; cross-unit contracts; sibling worktree paths; risk areas the worker flagged as guessed |
| 3 Fix | `delivery-worker` (fix mode) | One per unit with blocker/important findings | The exact findings to fix, each with file:line, problem, fix, and rule source for audit findings |

- Contract mismatches between units are blockers.
- Surface rule-vs-code conflicts from the auditor to the user. Do not resolve them silently.
- Skip minor/nit findings unless the user wants them, but report them.
- Check each fix worker's report confirms re-verification (typecheck/lint/tests) and commits.

## Phase 4 - Report

Give the user an actionable summary: per unit - branch, worktree path, commit hashes, test results; the consolidated review verdict; the **standards compliance verdict** (per unit: clean, or the documented-rule violations found and whether each was fixed, with the rule source cited); what was fixed vs left as noted minors; and the next command if one is needed (integration check, PR, merge). Keep paths and commands exact.

## Phase 5 - Human review (optional)

After the report, ask the user if they want to review the output themselves. If they say no, stop. If they say yes, read [references/human-review.md](references/human-review.md) and follow it.
