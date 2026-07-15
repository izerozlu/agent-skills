---
name: finalize-feature
description: Use when a feature's changes are complete and ready to wrap up — generates a feature-status doc under docs/features/ from the uncommitted diff, then commits all changes (including the doc) in logical thematic groups. Use when the user asks to "finalize", "wrap up", or "finish" a feature, or to document-and-commit pending work.
---

# Finalize Feature

Wrap up a completed feature in two phases: **(1) document** the uncommitted
changes under `docs/features/`, then **(2) commit** everything in logical groups.

**Core principles:**
- Document the change as it exists in the working tree. Do not invent
  verification, scope, or readiness not supported by the diff or commands run.
- One commit = one reason to change. Reviewers should read each commit
  independently and understand what changed and why.
- Do not modify, fix, or refactor code as part of this skill. If verification
  finds something wrong, report it to the user instead of fixing it.

## Phase 1: Generate Feature Documentation

### 1.1 Inspect changes

From the repository root, inspect both staged and unstaged changes:

```bash
git status --short
git diff --stat
git diff --cached --stat
git diff
git diff --cached
```

Also inspect relevant untracked files (`cat <untracked-file>`). Do not modify or
revert unrelated user changes.

IF there's no changes staged or unstaged, look for the diff between the current branch
and the main branch:

```bash
git fetch origin main
git diff origin/main...HEAD --stat
git diff origin/main...HEAD
```

### 1.2 Understand the feature

Identify: the feature title and purpose; each changed file's contribution;
behavior unchanged for compatibility; tests/commands actually run; verification
still needing a live/prod-like environment; out-of-scope follow-ups; active risks.

If the diff includes multiple unrelated features, ask whether to create one doc
per feature or one combined doc before writing.

### 1.3 Write the doc

Create `docs/features/` if needed. Name the file `YYYYMMDD_short-feature-slug.md`
(current date, lowercase kebab-case slug). Use this layout — `[OPTIONAL]`
sections may be omitted; do not print the `[OPTIONAL]` label in the file:

```markdown
# <Feature Title> — Status & Follow-ups

<Short summary of what changed, why it exists, and what existing behavior
remains unchanged.>

---

## Implemented

- `<path/to/file>`
  - <Specific behavior or contract added/changed.>
  - <Important compatibility or ownership detail.>

---

## Real-environment verification status

<What environment/dependencies are needed to verify end-to-end. Be explicit
about whether verification is complete or pending.>

### Verified

1. **<Verification name>.** <What was verified and how.>

<Short readiness statement.>

---

## [OPTIONAL] Out of scope / tracked follow-ups

- **<Follow-up title>** — <What remains and why it is outside this diff.>

---

## [OPTIONAL] Risks and constraints (still active)

- **<Risk title>.** <Why it matters and what condition triggers it.>
```

**Writing rules:** Keep statements factual and traceable to the diff or executed
verification. Prefer file-path bullets under `Implemented`. Include test command
names/results only if actually run; if no tests were run, say so. Keep follow-ups
out of `Implemented`. Avoid nesting deeper than shown.

### 1.4 Update the feature index

`docs/features/INDEX.md` is an agent-readable lookup over all feature docs in the
repo: a single markdown table, **newest-first**, one row per doc. It lets an agent
find the relevant doc by grep without opening every file. Columns:

```markdown
| Date | Doc | Title | Summary | Files | Tokens |
|------|-----|-------|---------|-------|--------|
| 2026-06-11 | [evaluation-audit](20260611_evaluation-audit.md) | Evaluation audit record | Emits an audit record per evaluation | handlers/http.py, audit.py | audit, template_version, GIT_SHA, suitability_score |
```

Decide between two paths:

- **Rebuild** (regenerate the whole table from every `YYYYMMDD_*.md` in the
  folder) when any of these hold: `INDEX.md` is missing; its data-row count does
  not match the number of `YYYYMMDD_*.md` files; or the new doc's date is older
  than the current top row. Rebuild also backfills pre-existing docs.
- **Append** otherwise: prepend the new doc's row at the top of the table.

Per-column extraction (for both the new row and any rebuilt rows):

- **Date** ← the `YYYYMMDD` filename prefix, rendered `YYYY-MM-DD`.
- **Doc** ← a link `[slug](YYYYMMDD_slug.md)` (slug = filename without date/ext).
- **Title** ← the doc's `# ` H1.
- **Summary** ← the first sentence of the paragraph after the H1, newlines
  collapsed to spaces, hard-trimmed to ~120 chars.
- **Files** ← the backtick-wrapped paths under `## Implemented`, comma-separated.
- **Tokens** ← agent judgment: lowercased domain nouns plus symbol/file stems
  drawn from the title and `Implemented` section, comma-separated. This requires
  reading the doc, not a regex.

**Row integrity:** keep each row on one physical line; replace any literal `|` in
Title, Summary, or Tokens with `/` so the table cannot be corrupted.

## Phase 2: Commit in Logical Groups

The new feature doc and the updated `docs/features/INDEX.md` are now part of the
working tree — include both in Phase 2 as a single Documentation-themed commit.

### 2.1 Survey changes

```bash
git status
git diff HEAD
```

Inspect new files whose purpose isn't obvious (`cat <untracked-file>`).

### 2.2 Group by theme

Assign every changed/untracked file to a group:

| Theme | Typical files |
|-------|--------------|
| Repo hygiene | `.gitignore`, `.editorconfig` |
| CI/CD | `.gitlab-ci.yml`, `.github/workflows/` |
| Infrastructure / manifests | `k8s/`, `docker-compose.yml`, `Dockerfile` |
| App logic | `src/`, `lib/` |
| Config / environment | `*.yaml`, `*.env.example` |
| Tests | `tests/`, `spec/` |
| Documentation | `README.md`, `docs/` (incl. the feature doc + `INDEX.md` from Phase 1) |

**Rules:** Files meaningful only together go in one commit (e.g. a kustomize base
+ its overlays). Files with different audiences/purposes go in separate commits.
Repo hygiene files almost always stand alone. **Exclude** files under
`docs/plans` or `docs/spec` — do not commit them.

### 2.3 Commit each group

In dependency order (foundational changes first):

```bash
git add <file1> <file2> ...   # never git add -A or git add .
git commit -m "$(cat <<'EOF'
Imperative-mood summary under 72 chars

Optional body explaining WHY, not what (the diff already shows what).
EOF
)"
```

**Message rules:** Imperative mood ("Add", "Fix", "Remove" — not "Added"). First
line ≤ 72 chars. Body only when "why" isn't obvious. No `Co-Authored-By` lines.

### 2.4 Verify

```bash
git log --oneline -<n>   # n = number of new commits
```

Confirm each commit has a single, clear purpose. Do not push unless asked.

## Quick Reference

```
inspect diff → write docs/features/YYYYMMDD_slug.md → update INDEX.md → survey → group → commit per group → verify log
```

## Common Mistakes

- **Documenting only staged changes** → inspect both `git diff` and `git diff --cached`.
- **Claiming live verification from unit tests** → separate local/unit from real-environment verification.
- **Committing everything at once** → always `git status` + `git diff` before committing.
- **Splitting too finely** → base manifest + overlays belong together.
- **Using `git add -A` / `git add .`** → name files explicitly to avoid secrets/artifacts.
- **Vague commit messages** → state what changed and why, in imperative mood.
- **Committing `docs/plans` or `docs/spec`** → these are excluded; never commit them.
- **Appending to a stale `INDEX.md`** → if row count ≠ doc count or the new date isn't newest, rebuild instead of appending.
- **Multi-line / pipe-broken index rows** → one physical line per doc; replace literal `|` in text columns with `/`.
