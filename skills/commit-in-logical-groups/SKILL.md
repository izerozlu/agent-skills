---
name: commit-in-logical-groups
description: Use when there are multiple uncommitted changes (modified files, untracked files, or a mix) that should be split into separate commits by theme rather than committed all at once
---

# Commit in Logical Groups

## Overview

Analyse all pending changes, identify thematic groups, and create one commit per group — each with a focused, purposeful message. EXCEPT files under `docs/plans` or `docs/spec` folders. DO NOT include these files in the commit if any.

**Core principle:** One commit = one reason to change. Reviewers should be able to read commits independently and understand exactly what changed and why.

## Scope Boundary

When this skill is triggered, do not make code, project, configuration, documentation, formatting, or dependency updates. The skill is only for analysing existing changes, grouping them, committing them, and optionally running non-mutating verification commands.

If verification or review finds something wrong, report it to the user instead of fixing it. Do not modify files to make commits cleaner, make tests pass, satisfy hooks, or improve the project as part of this skill.

## Process

### Step 1: Survey All Changes

Run both commands to see the full picture:

```bash
git status          # shows modified + untracked files
git diff HEAD       # shows content of modifications
```

Also inspect new files whose purpose isn't obvious from the name:

```bash
cat <untracked-file>
```

### Step 2: Group by Theme

Mentally (or explicitly) assign every changed/untracked file to a group. Common groupings:

| Theme | Typical files |
|-------|--------------|
| Repo hygiene | `.gitignore`, `.editorconfig` |
| CI/CD | `.gitlab-ci.yml`, `.github/workflows/` |
| Infrastructure / manifests | `k8s/`, `docker-compose.yml`, `Dockerfile` |
| App logic | `src/`, `lib/` |
| Config / environment | `*.yaml`, `*.env.example` |
| Tests | `tests/`, `spec/` |
| Documentation | `README.md`, `docs/` |

**Rules:**
- Files that are only meaningful together go in the same commit (e.g. a kustomize base + its overlays).
- Files with different audiences or purposes go in separate commits (e.g. a deployment script and a CI pipeline both "deploy" but serve different contexts).
- Repo hygiene files (`.gitignore`) almost always stand alone.

### Step 3: Commit Each Group

For each group, in dependency order (foundational changes first):

```bash
git add <file1> <file2> ...   # never git add -A or git add .
git commit -m "$(cat <<'EOF'
Imperative-mood summary under 72 chars

Optional body explaining WHY, not what (the diff already shows what).
EOF
)"
```

**Commit message rules:**
- Imperative mood: "Add", "Fix", "Migrate", "Remove" — not "Added" / "Adding"
- First line ≤ 72 characters
- Body only when "why" isn't obvious
- No `Co-Authored-By` lines

### Step 4: Verify

```bash
git log --oneline -<n>   # n = number of new commits
```

Confirm each commit has a single, clear purpose.

## Quick Reference

```
survey → group → commit (repeat per group) → verify log
```

| Group size | Commit count |
|-----------|-------------|
| 1 theme   | 1 commit    |
| N themes  | N commits   |

## Common Mistakes

**Committing everything at once**
- Problem: History becomes a blob; impossible to revert one change independently.
- Fix: Always run `git status` + `git diff` before committing.

**Splitting too finely**
- Problem: A base manifest and its overlays are useless without each other.
- Fix: Files that only make sense together belong in the same commit.

**Using `git add -A` or `git add .`**
- Problem: May include secrets, build artifacts, or unrelated files.
- Fix: Always name files explicitly.

**Vague commit messages**
- Problem: "update stuff", "wip", "fix"
- Fix: State *what* changed and *why* in imperative mood.
