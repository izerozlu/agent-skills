---
name: generate-feature-documentation
description: Use when the user asks to write feature documentation for staged, unstaged, or otherwise uncommitted changes under docs/features/.
---

# Generate Feature Documentation

## Overview

Inspect all uncommitted changes, infer the feature or behavior they introduce,
and create a concise feature-status document under `docs/features/`.

**Core principle:** Document the change as it exists in the working tree. Do not
invent verification, scope, or production readiness that is not supported by the
diff or commands actually run.

## Process

### Step 1: Fetch Uncommitted Changes

Inspect both staged and unstaged changes from the repository root:

```bash
git status --short
git diff --stat
git diff --cached --stat
git diff
git diff --cached
```

Also inspect new untracked files that are relevant to the feature. Do not modify
or revert unrelated user changes.


IF there's no changes staged or unstaged, look for the diff between the current branch
and the main branch:

```bash
git fetch origin main
git diff origin/main...HEAD --stat
git diff origin/main...HEAD
```

### Step 2: Understand the Feature

Identify:

- The feature title and user-facing or operational purpose.
- The changed files and what each contributes.
- Behavior that remains unchanged for compatibility.
- Tests, commands, or inspections that were actually performed.
- Verification that still requires a live, non-prod, or production-like
  environment.
- Follow-ups that are out of scope for the current diff.
- Risks and constraints that remain active.

If the diff includes multiple unrelated features, ask whether to create one doc
per feature or one combined doc before writing files.

### Step 3: Create the Feature Doc

Create `docs/features/` if it does not exist.

Name the file with this convention:

```text
YYYYMMDD_short-feature-slug.md
```

Use the current date for `YYYYMMDD`. Use lowercase kebab-case for the slug.

### Step 4: Follow the Required Layout

- [OPTIONAL] sections are not required but can be included if relevant information is available.
- Do no include the [OPTIONAL] label in the actual document. It is only a prompt for whether to include the section.

Use the following structure:

```markdown
# <Feature Title> — Status & Follow-ups

<Short summary of what changed, why it exists, and what existing behavior
remains unchanged.>

---

## Implemented

- `<path/to/file>`
  - <Specific behavior or contract added/changed.>
  - <Important compatibility or ownership detail.>
- `<path/to/another-file>`
  - <Specific behavior or contract added/changed.>

---

## Real-environment verification status

<State what environment or dependencies are needed to verify end-to-end. Be
explicit about whether verification is complete or pending.>

### Verified

1. **<Verification name>.** <What was verified and how.>
2. **<Verification name>.** <What was verified and how.>

<Short readiness statement.>

---

## [OPTIONAL] Out of scope / tracked follow-ups

- **<Follow-up title>** — <What remains to do and why it is outside this diff.>
- **<Follow-up title>** — <What remains to do and why it is outside this diff.>

---

## [OPTIONAL] Risks and constraints (still active)

- **<Risk title>.** <Why it matters and what condition triggers it.>
- **<Risk title>.** <Why it matters and what condition triggers it.>
```

### Writing Rules

- Keep statements factual and traceable to the diff or executed verification.
- Prefer file-path bullets under `Implemented`.
- Include test command names and results only if they were actually run.
- If no tests were run, say so clearly in the verification section.
- Keep follow-ups out of the implemented section.
- Avoid nested bullets deeper than the shown layout.
- Do not stage, commit, or push unless the user explicitly asks.

## Quick Reference

```text
inspect git status + diffs -> infer feature -> write docs/features/YYYYMMDD_slug.md -> report file path
```

## Common Mistakes

**Documenting only staged changes when unstaged changes exist**
- Fix: Always inspect both `git diff` and `git diff --cached`.

**Claiming live verification from unit tests**
- Fix: Separate local/unit verification from real-environment verification.

**Creating vague follow-ups**
- Fix: State the concrete missing verification, infrastructure work, test, or
  operational decision.

**Overstating compatibility**
- Fix: Only claim compatibility when the diff shows a default, fallback, or
  unchanged path that supports it.
