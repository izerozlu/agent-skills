# agent-skills

A personal collection of [Claude Code](https://claude.com/claude-code) skills
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

Run the installer straight from GitHub. It downloads the skills you choose into
`~/.claude/skills/`, no clone required.

```bash
curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash
```

That runs interactively, prompting per skill. Pass flags and skill names after
`-- ` to skip the prompts:

```bash
# install everything
curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash -s -- --all

# install specific skills
curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash -s -- finalize-feature commit-in-logical-groups

# preview without touching the filesystem
curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash -s -- --dry-run --all

# remove installed skills (all, or named)
curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash -s -- --uninstall
```

If you have cloned the repo, the same script works locally:

```bash
./install.sh                 # interactive: choose per skill
./install.sh --all           # install everything
./install.sh finalize-feature commit-in-logical-groups
./install.sh --uninstall     # remove installed skills
```

Restart Claude Code after installing so it picks up the new skills, then invoke
them:

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
curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash -s -- --all
```

## Manual install

If you prefer not to run the script, copy any skill folder straight into your
skills directory:

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
