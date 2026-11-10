# Milestone review mode

Use this mode when the user picks **milestone reviews** in Phase 0. The user reviews small groups of commits while the work runs. They do not review the whole feature at the end.

The commit rules do not change: atomic commits, the repo's commit format, no push.

## Plan the milestones (Phase 0)

1. Split each unit into **milestones**. A milestone is a small group of atomic commits (about 2 to 6) that the user can review in one sitting. Each milestone must leave the branch green (build, lint, tests pass).
2. Good stop points: a contract is in place (route, event, schema), a removal is done, a step of a pipeline is complete, a risky area is done.
3. Put contract-producing milestones first, so the user reviews a contract before other units build on it.
4. Show the milestone list per unit to the user. Let them add, merge, split, or move milestones before the start.
5. Ask how the units run. Give these options and recommend one:
   - **One unit at a time**, in deploy order. One stop at a time. Slowest, calmest.
   - **All units in parallel, with a queue.** Stops wait in a queue, and you show them one by one. Fastest, but stops can pile up.
   - **Contracts first, then parallel.** The unit that owns the shared contracts runs first, until its contract milestones pass review. Then the other units run in parallel with a queue. Usually the best choice when units depend on one unit's contracts.
6. Write the milestone list into the review state file (see below) before you start.

## Loop per milestone

1. **Implement.** Launch (or continue, with `SendMessage`) the unit's `delivery-worker`. Give it only the current milestone: its scope, the plan slice for it, and the contracts. Tell it to stop and report when this milestone is committed. Continue the same worker for the next milestone, so it keeps its context.
2. **Agent review.** Run `delivery-reviewer` and `delivery-standards-auditor` in parallel on the milestone's commit range only (`<previous stop commit>..HEAD`), not the whole branch.
3. **Fix.** Run a `delivery-worker` in fix mode for blocker and important findings (Phase 3 rules apply). Fixes are new commits in the same milestone.
4. **Human stop.** Show the user:
   - the unit, the milestone name, and the commit range;
   - the commits (hash and subject);
   - a short summary of what changed and why;
   - the agent review verdict, what was fixed, and the minors that are left;
   - the exact commands to look at it, for example `git -C <worktree> log --oneline <from>..<to>` and `git -C <worktree> diff <from>..<to>`.
5. **User feedback.** The user says **go**, or gives comments.
   - On comments: run a fix worker with the comments verbatim, then show the new commits. Repeat until the user says go.
   - On go: mark the milestone done in the state file and start the next one.
6. A worker can also stop early when it finds a better review point than the plan. Accept it, and adjust the next milestones in the state file.

Do not start the next milestone of a unit before the user says go on the current one. In parallel modes, other units can continue while one unit waits for the user.

## Review state file

Use the same file as [human-review.md](human-review.md) (location, gitignore, resume rules). Add a **Milestones** section:

```markdown
## Milestones
Status: `[ ]` not started, `[>]` in progress, `[r]` waiting for user review, `[!]` user comments being fixed, `[x]` approved.

### <unit>
1. `[x]` <milestone name>. Commits: <from>..<to>.
2. `[r]` <milestone name>. Commits: <from>..<to>. Feedback: <user's words, if any>.
3. `[ ]` <milestone name>.
```

Update the file at each status change, before you do anything else.

## End

When all milestones are approved, give the Phase 4 report. Skip Phase 5, because the user already reviewed every milestone. Ask once if they want a final pass over the whole branch. If yes, follow [human-review.md](human-review.md).
