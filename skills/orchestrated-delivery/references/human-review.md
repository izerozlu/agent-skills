# Human review (Phase 5)

Run the review from one **review state file**. This file is the source of truth for the review. Chat messages are not.

## Review state file

**Location:** `<repo-root>/docs/human-review/YYYYMMDD_<slug>.md`. Use the repo that holds the plan or spec. If no repo fits (for example, the plan is outside all target repos), ask the user where to put it.

**Gitignore:** before you create the file, make sure `docs/human-review/` is in that repo's `.gitignore`. If it is not, add the line `docs/human-review/`. Never commit the state file.

**Resume:** at the start, check `docs/human-review/` for an existing file on the same feature. If one exists, read it and continue from it. Do not ask again about items that are already complete.

**When to write:**
- Create the file before you show the review plan to the user.
- After each piece of user feedback, update the item's status and notes right away, before you do anything else.
- When a fix worker starts or finishes, update the item (fix in progress, then commit hash and back to open).
- When the user adds or drops an item, update the list.

**Shape** (keep entries short; record locations with paths, file:line, and commit hashes):

```markdown
# <Feature>: human review (YYYY-MM-DD)

## State
In progress / done. Last updated date. Plan and spec paths. Base branch.

## Units
| Unit | Branch | Worktree |
|---|---|---|
| <unit> | <branch> | <absolute worktree path> |

## Review items
Status: `[ ]` open, `[x]` complete, `[!]` needs fix, `[~]` fix in progress.

1. `[ ]` <What to check, one line>.
   Where: <worktree path, file:line or commit hash>.
   How: <command, screen, or endpoint, if useful>.
   Feedback: <user's words, if any>. Fix: <commit hash, if any>.

## Dropped items
- <item>: <reason>
```

## Flow

1. Generate the **review plan** into the state file: a numbered list of the parts of the implementation to check. One item per reviewable part (per unit, then per contract seam or risky area inside it). Keep the list short. Put the riskiest parts first: contract seams, guessed areas from worker reports, and findings that were fixed in Phase 3.
2. Show the user the file path and the list.
3. The user reviews at their own pace and gives feedback per item: **complete**, or **not complete** with what is wrong. Record it in the file.
4. For each **not complete** item, set it to `[!]`, then launch a `delivery-worker` in fix mode on that unit's worktree (Phase 3 rules apply: one fix agent per unit, non-overlapping). Pass the item and the user's feedback verbatim. Set the item to `[~]` while the fix runs. When the fix lands, record the commit hash and set the item back to `[ ]` for the user to re-check.
5. After each round, show the updated list from the file.
6. The phase ends when every item is `[x]`, or when the user stops it. Set State to done and report the final list.

**Cleanup:** when the user confirms the review is done, delete the state file. If `docs/human-review/` is then empty, delete the folder too. Keep the `.gitignore` line.
