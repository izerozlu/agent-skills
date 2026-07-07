# agent-skills

A personal collection of agent skills
for wrapping up features. They install as **standalone skills**, so you invoke
them by their bare names, `/finalize-feature`, `/commit-in-logical-groups`,
`/generate-feature-documentation`, with no plugin prefix.

## Skills

| Skill | What it does |
|-------|--------------|
| `finalize-feature` | Wrap up a completed feature: document the uncommitted diff under `docs/features/`, then commit everything in logical thematic groups. |
| `generate-feature-documentation` | Inspect uncommitted changes and write a concise feature-status doc under `docs/features/`, without committing. |
| `commit-in-logical-groups` | Split pending changes into separate, focused commits grouped by theme, one commit per reason to change. |

`finalize-feature` runs the other two as a single wrap-up flow (document, then
commit).

## Install

Run the installer straight from GitHub, no clone required. It detects the coding
agents on your system and asks which of them to install into, then which skills
to install. Supported agents and their skills directories:

| Agent | id | Skills directory |
|-------|----|------------------|
| Claude Code | `claude` | `~/.claude/skills` |
| OpenAI Codex | `codex` | `~/.codex/skills` |
| Gemini CLI | `gemini` | `~/.gemini/skills` |
| Cline | `cline` | `~/.cline/skills` |
| GitHub Copilot CLI | `copilot` | `~/.copilot/skills` |
| opencode | `opencode` | `~/.config/opencode/skills` |

```bash
curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash
```

That runs interactively: pick the target agents from a menu, then the skills.
Pass flags and skill names after `-- ` to skip the prompts:

```bash
# every skill into every detected agent
curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash -s -- --all-agents --all

# specific skills into a specific agent (--agent is repeatable)
curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash -s -- --agent claude finalize-feature commit-in-logical-groups

# preview without touching the filesystem
curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash -s -- --all-agents --dry-run --all

# remove installed skills (all, or named)
curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash -s -- --all-agents --uninstall
```

If you have cloned the repo, the same script works locally:

```bash
./install.sh                          # interactive: pick agents, then skills
./install.sh --all-agents --all       # every skill into every detected agent
./install.sh --agent claude finalize-feature
./install.sh --uninstall              # remove installed skills
```

Restart the affected agents after installing so they pick up the new skills, then
invoke them:

```
/finalize-feature
/generate-feature-documentation
/commit-in-logical-groups
```

Claude also triggers a skill automatically when your request matches its
description (for example, "finalize this feature").

## Updating

There is no local clone to `git pull`. Updating is just re-running the same
install command, which re-downloads the latest skill files:

```bash
curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash -s -- --all-agents --all
```

## Manual install

If you prefer not to run the script, copy any skill folder straight into an
agent's skills directory (see the table above for each agent's path):

```bash
cp -R skills/finalize-feature ~/.claude/skills/
```

## Repository layout

```
agent-skills/
├── install.sh
└── skills/
    ├── finalize-feature/SKILL.md
    ├── generate-feature-documentation/SKILL.md
    └── commit-in-logical-groups/SKILL.md
```

## License

[MIT](LICENSE) © İzer Özlü
