# agent-skills

A personal collection of agent skills
for wrapping up and delivering features. They install as **standalone skills**,
so you invoke them by their bare names, `/finalize-feature`,
`/commit-in-logical-groups`, `/generate-feature-documentation`,
`/orchestrated-delivery`, with no plugin prefix.

## Skills

| Skill | What it does |
|-------|--------------|
| `finalize-feature` | Wrap up a completed feature: document the uncommitted diff under `docs/features/`, then commit everything in logical thematic groups. |
| `generate-feature-documentation` | Inspect uncommitted changes and write a concise feature-status doc under `docs/features/`, without committing. |
| `commit-in-logical-groups` | Split pending changes into separate, focused commits grouped by theme, one commit per reason to change. |
| `orchestrated-delivery` | Deliver a large, multi-part feature as a pure orchestrator of sub-agents: split into non-overlapping units, implement them in parallel in isolated worktrees, review each unit as it lands, run a dedicated standards-compliance audit, dispatch targeted fixes, then consolidate a final report. The orchestrator coordinates and verifies but does not write feature code itself. |

`finalize-feature` runs the first two as a single wrap-up flow (document, then
commit). `orchestrated-delivery` is a separate flow for delivering a plan or
spec across several repos, services, or modules with sub-agents.

## Install

Install with the [`skills`](https://github.com/vercel-labs/skills) CLI. No clone
is needed. It finds every `SKILL.md` under `skills/`, detects the coding agents
on your machine (Claude Code, Codex, Gemini CLI, Cursor, Cline, Copilot,
opencode, and more), and asks where to install:

```bash
# list the available skills
npx skills add izerozlu/agent-skills --list

# install all of them (interactive: pick agents)
npx skills add izerozlu/agent-skills

# install one skill only
npx skills add izerozlu/agent-skills --skill finalize-feature

# no prompts: every skill into every detected agent
npx skills add izerozlu/agent-skills -y
```

Restart the affected agents after installing so they pick up the new skills, then
invoke them:

```
/finalize-feature
/generate-feature-documentation
/commit-in-logical-groups
/orchestrated-delivery
```

Claude also triggers a skill automatically when your request matches its
description (for example, "finalize this feature").

## Install via your coding agent

Want the agent you're already talking to install these for you? Copy the block
below into its conversation. The `-y` flag makes the CLI fully non-interactive,
which is what lets an agent run it unattended:

```text
Please install the agent-skills feature-wrap-up skills by running:
npx skills add izerozlu/agent-skills -y
This installs every skill into every coding agent detected on this machine. When it finishes, restart so the new skills load.
```

## Updating

Re-run the same install command. The CLI re-downloads the latest skill files:

```bash
npx skills add izerozlu/agent-skills -y
```

## Manual install

If you prefer not to use the CLI, copy any skill folder straight into an
agent's skills directory (for Claude Code that is `~/.claude/skills`):

```bash
cp -R skills/finalize-feature ~/.claude/skills/
```

## Repository layout

```
agent-skills/
└── skills/
    ├── finalize-feature/SKILL.md
    ├── generate-feature-documentation/SKILL.md
    ├── commit-in-logical-groups/SKILL.md
    └── orchestrated-delivery/SKILL.md
```

## License

[MIT](LICENSE) © İzer Özlü
