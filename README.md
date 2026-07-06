# izer-skills

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

Clone the repo and run the installer. It symlinks the skills you choose into
`~/.claude/skills/`, so a later `git pull` updates them in place.

```bash
git clone https://github.com/izerozlu/izer-skills.git
cd izer-skills
./install.sh            # interactive: choose per skill
```

Other modes:

```bash
./install.sh --all                                  # install everything
./install.sh finalize-feature commit-in-logical-groups   # install specific skills
./install.sh --copy --all                           # copy instead of symlink
./install.sh --uninstall                            # remove installed skills
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

Because skills are symlinked, updating is just:

```bash
cd izer-skills
git pull
```

(If you installed with `--copy`, re-run `./install.sh` after pulling.)

## Manual install

If you prefer not to run the script, copy any skill folder straight into your
skills directory:

```bash
cp -R skills/finalize-feature ~/.claude/skills/
```

## Repository layout

```
izer-skills/
├── install.sh
└── skills/
    ├── finalize-feature/SKILL.md
    ├── generate-feature-documentation/SKILL.md
    └── commit-in-logical-groups/SKILL.md
```

## License

[MIT](LICENSE) © İzer Özlü
