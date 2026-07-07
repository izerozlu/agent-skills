#!/usr/bin/env bash
#
# install.sh: install agent-skills directly from GitHub into the skills
# directories of the coding agents on your system. This script is self-contained:
# it downloads skill files over the network, so it works when piped straight from
# curl with no local clone of the repo present.
#
# It detects installed coding agents (Claude Code, OpenAI Codex, Gemini CLI,
# Cline, GitHub Copilot CLI, opencode) and asks which of them to install into,
# then which skills to install.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash -s -- --all
#   curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash -s -- --all-agents --all
#
#   ./install.sh                 # interactive: pick agents, then skills
#   ./install.sh --all           # install every skill (agents still resolved)
#   ./install.sh --agent claude finalize-feature
#   ./install.sh --all-agents --all
#   ./install.sh --uninstall     # remove installed skills (all, or named)
#   ./install.sh --dry-run --all # show what would happen, touch nothing
#
# For a coding agent (non-interactive): pass --yes to skip every prompt. With
# no other flags it installs all skills into all detected agents and never
# blocks on a menu. --yes is implied in CI or when there is no terminal.
#   curl -fsSL .../install.sh | bash -s -- --yes
#
# Installing downloads the skill files. Updating means re-running the same
# command again. There is no local clone to git pull.
#
# Skills load when an agent starts, so restart the agent afterwards.

set -eu

REPO="izerozlu/agent-skills"
BRANCH="${IZER_SKILLS_REF:-main}"
API_TREE="https://api.github.com/repos/$REPO/git/trees/$BRANCH?recursive=1"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$BRANCH"
DEST_DIR=""
EXPLICIT_DIR="${CLAUDE_SKILLS_DIR:-${SKILLS_DIR:-}}"

# Registry of known coding agents that read the SKILL.md format, one per line:
#   id|Display Name|marker dirs (comma-separated, relative to $HOME)|binaries|skills dir (relative to $HOME)
# An agent is considered present if any marker dir exists or any binary is on PATH.
AGENTS="claude|Claude Code|.claude|claude|.claude/skills
codex|OpenAI Codex|.codex|codex|.codex/skills
gemini|Gemini CLI|.gemini|gemini|.gemini/skills
cline|Cline|.cline|cline|.cline/skills
copilot|GitHub Copilot CLI|.copilot,.config/github-copilot|copilot|.copilot/skills
opencode|opencode|.config/opencode,.opencode|opencode|.config/opencode/skills"

if command -v curl >/dev/null 2>&1; then
  DOWNLOADER="curl"
elif command -v wget >/dev/null 2>&1; then
  DOWNLOADER="wget"
else
  echo "error: need curl or wget to install skills" >&2
  exit 1
fi

TREE_CACHE=""
esc=$(printf '\033')

ALL=0
ALL_AGENTS=0
MODE="install"
DRY_RUN=0
YES=0
NAMES=""
AGENT_ARGS=""
AGENT_IDS=""

fetch_stdout() {
  url="$1"
  if [ "$DOWNLOADER" = "curl" ]; then
    curl -fsSL "$url"
  else
    wget -qO- "$url"
  fi
}

fetch_to_file() {
  url="$1"
  dest="$2"
  if [ "$DOWNLOADER" = "curl" ]; then
    curl -fsSL -o "$dest" "$url"
  else
    wget -qO "$dest" "$url"
  fi
}

# Fetch the repo's git tree once and cache the list of skill file paths
# (skills/<name>/<file>) in TREE_CACHE. Repeated calls are a no-op.
fetch_tree() {
  if [ -n "$TREE_CACHE" ]; then
    return 0
  fi
  TREE_CACHE="$(fetch_stdout "$API_TREE" \
    | tr -d '\n ' | tr '{' '\n' \
    | grep '"type":"blob"' | grep '"path":"skills/' \
    | sed -e 's/.*"path":"//' -e 's/".*//')"
  if [ -z "$TREE_CACHE" ]; then
    echo "error: could not fetch the skill list from $REPO@$BRANCH (check network access)" >&2
    exit 1
  fi
}

list_available() {
  fetch_tree
  printf '%s\n' "$TREE_CACHE" | cut -d/ -f2 | sort -u
}

files_for_skill() {
  printf '%s\n' "$TREE_CACHE" | grep "^skills/$1/" || true
}

# Print the registry line for an agent id, or return 1 if the id is unknown.
agent_line() {
  printf '%s\n' "$AGENTS" | awk -F'|' -v id="$1" '$1==id{print; f=1} END{exit !f}'
}

agent_field()    { agent_line "$1" | cut -d'|' -f"$2"; }
agent_name()     { agent_field "$1" 2; }
agent_skilldir() { agent_field "$1" 5; }
all_agent_ids()  { printf '%s\n' "$AGENTS" | cut -d'|' -f1 | tr '\n' ' '; }

# Return 0 if the agent described by a registry line is present on this system
# (any of its marker dirs exists, or any of its binaries is on PATH).
agent_present() {
  markers="$(printf '%s' "$1" | cut -d'|' -f3)"
  bins="$(printf '%s' "$1" | cut -d'|' -f4)"
  OLDIFS="$IFS"
  IFS=,
  for m in $markers; do
    if [ -e "$HOME/$m" ]; then IFS="$OLDIFS"; return 0; fi
  done
  for b in $bins; do
    if command -v "$b" >/dev/null 2>&1; then IFS="$OLDIFS"; return 0; fi
  done
  IFS="$OLDIFS"
  return 1
}

# Print the ids of every detected agent, one per line, in registry order.
detect_agents() {
  printf '%s\n' "$AGENTS" | while IFS= read -r line; do
    [ -n "$line" ] || continue
    if agent_present "$line"; then
      printf '%s' "$line" | cut -d'|' -f1
      printf '\n'
    fi
  done
}

# Resolve which agents to install into, populating AGENT_IDS. Honors --agent and
# --all-agents; otherwise detects agents and (when a terminal is available) shows
# a menu. Non-interactive with several detected agents defaults to Claude Code if
# present, else all detected.
resolve_agents() {
  detected="$(detect_agents)"

  if [ -n "${AGENT_ARGS# }" ]; then
    AGENT_IDS=""
    for id in $AGENT_ARGS; do
      if agent_line "$id" >/dev/null 2>&1; then
        AGENT_IDS="$AGENT_IDS $id"
      else
        echo "  ! unknown agent: $id (known: $(all_agent_ids))" >&2
      fi
    done
    return
  fi

  if [ "$ALL_AGENTS" = "1" ]; then AGENT_IDS="$detected"; return; fi

  if [ -z "$detected" ]; then
    echo "error: no known coding agents detected on this system." >&2
    echo "Known agents: $(all_agent_ids)" >&2
    echo "Install one, or target a directory directly with --dir PATH." >&2
    exit 1
  fi

  dcount="$(printf '%s\n' "$detected" | grep -c .)"
  if [ "$dcount" -eq 1 ]; then
    AGENT_IDS="$detected"
    echo "Detected one agent: $(agent_name "$detected"). Installing there."
    return
  fi

  if [ "$NONINTERACTIVE" = "0" ]; then
    name_arr=()
    for id in $detected; do name_arr+=("$(agent_name "$id")"); done
    sel="$(interactive_select "Select coding agents to install skills into:" "${name_arr[@]}")"
    AGENT_IDS=""
    for id in $detected; do
      nm="$(agent_name "$id")"
      if printf '%s\n' "$sel" | grep -qxF "$nm"; then AGENT_IDS="$AGENT_IDS $id"; fi
    done
  else
    # Non-interactive: target every detected agent.
    AGENT_IDS="$detected"
  fi
}

# Interactive multi-select menu, drawn on the terminal (/dev/tty) so it keeps
# working when this script is piped through `curl | bash`. First argument is the
# prompt title; the rest are the selectable items. Prints the chosen items,
# space-separated, to stdout. Controls: up/down (or k/j) move, space toggles,
# a selects/clears all, enter confirms, q cancels.
interactive_select() {
  title="$1"
  shift
  tty=/dev/tty
  items=("$@")
  n=${#items[@]}
  cursor=0
  checked=()
  i=0
  while [ "$i" -lt "$n" ]; do checked[i]=0; i=$((i + 1)); done

  draw_menu() {
    i=0
    while [ "$i" -lt "$n" ]; do
      if [ "$i" -eq "$cursor" ]; then pointer='›'; else pointer=' '; fi
      if [ "${checked[i]}" -eq 1 ]; then box='[x]'; else box='[ ]'; fi
      printf '\r\033[K %s %s %s\n' "$pointer" "$box" "${items[i]}" > "$tty"
      i=$((i + 1))
    done
  }

  printf '%s\n' "$title" > "$tty"
  printf '  ↑/↓ move · space toggle · a select all · enter confirm · q cancel\n\n' > "$tty"
  printf '\033[?25l' > "$tty"   # hide cursor
  draw_menu

  while true; do
    # -t is a backstop: an unattended menu cancels instead of hanging forever.
    IFS= read -rsn1 -t 120 key < "$tty" || break
    if [ "$key" = "$esc" ]; then
      read -rsn2 -t 0.01 rest < "$tty" || rest=""
      key="$key$rest"
    fi
    case "$key" in
      "$esc[A" | k) cursor=$(((cursor - 1 + n) % n)) ;;
      "$esc[B" | j) cursor=$(((cursor + 1) % n)) ;;
      ' ')
        if [ "${checked[cursor]}" -eq 1 ]; then checked[cursor]=0; else checked[cursor]=1; fi
        ;;
      a | A)
        want=0
        i=0
        while [ "$i" -lt "$n" ]; do
          if [ "${checked[i]}" -eq 0 ]; then want=1; fi
          i=$((i + 1))
        done
        i=0
        while [ "$i" -lt "$n" ]; do checked[i]="$want"; i=$((i + 1)); done
        ;;
      q | Q)
        printf '\033[?25h\n' > "$tty"   # show cursor
        return 0
        ;;
      '')   # enter
        break
        ;;
    esac
    printf '\033[%dA' "$n" > "$tty"
    draw_menu
  done

  printf '\033[?25h\n' > "$tty"   # show cursor

  i=0
  while [ "$i" -lt "$n" ]; do
    if [ "${checked[i]}" -eq 1 ]; then printf '%s\n' "${items[i]}"; fi
    i=$((i + 1))
  done
}

usage() {
  cat <<EOF
Install agent-skills (from https://github.com/$REPO) into your coding agents'
skills directories. Detects installed agents and asks which to target.

Usage:
  curl -fsSL https://raw.githubusercontent.com/$REPO/$BRANCH/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/$REPO/$BRANCH/install.sh | bash -s -- --all
  curl -fsSL https://raw.githubusercontent.com/$REPO/$BRANCH/install.sh | bash -s -- --all-agents --all

  ./install.sh [options] [skill ...]

Options:
  --all           Install every skill without prompting
  --agent ID      Target a specific agent (repeatable). See ids below.
  --all-agents    Target every detected agent without prompting
  -y, --yes       Non-interactive: never prompt. With no other flags, install
                  all skills into all detected agents. (Implied in CI / no TTY.)
  --uninstall     Remove installed skills (named ones, or all if none named)
  --dry-run       Print what would happen without touching the filesystem
  --dir PATH      Install into PATH directly, skipping agent detection
  -h, --help      Show this help

Known agents (id -> skills dir):
$(printf '%s\n' "$AGENTS" | awk -F'|' '{printf "  - %-9s %s (~/%s)\n", $1, $2, $5}')

Available skills:
$(list_available | sed 's/^/  - /')

Override the target dir with CLAUDE_SKILLS_DIR=/path or --dir PATH.

Skills load when an agent starts, so restart it afterwards.
Updating a skill just means re-running the command above.
EOF
}

install_one() {
  name="$1"
  files="$(files_for_skill "$name")"
  if [ -z "$files" ]; then
    echo "  ! unknown skill: $name" >&2
    return 0
  fi
  dest="$DEST_DIR/$name"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
    if [ "$DRY_RUN" = "1" ]; then
      echo "  ~ $name: would move existing aside -> $(basename "$backup")"
    else
      mv "$dest" "$backup"
      echo "  ~ $name: moved existing aside -> $(basename "$backup")"
    fi
  fi
  if [ "$DRY_RUN" = "1" ]; then
    count="$(printf '%s\n' "$files" | wc -l | tr -d ' ')"
    echo "  + $name (would install $count file(s))"
    return 0
  fi
  printf '%s\n' "$files" | while IFS= read -r path; do
    rel="${path#skills/}"
    target="$DEST_DIR/$rel"
    mkdir -p "$(dirname "$target")"
    fetch_to_file "$RAW_BASE/$path" "$target"
  done
  echo "  + $name (installed)"
}

uninstall_one() {
  name="$1"
  dest="$DEST_DIR/$name"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ "$DRY_RUN" = "1" ]; then
      echo "  - $name (would remove)"
    else
      rm -rf "$dest"
      echo "  - $name (removed)"
    fi
  else
    echo "  = $name (not installed)"
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --all)        ALL=1 ;;
    --all-agents) ALL_AGENTS=1 ;;
    --uninstall)  MODE="uninstall" ;;
    --dry-run)    DRY_RUN=1 ;;
    -y|--yes)     YES=1 ;;
    --agent)
      shift
      if [ $# -eq 0 ]; then
        echo "error: --agent requires an id argument" >&2
        exit 1
      fi
      AGENT_ARGS="$AGENT_ARGS $1"
      ;;
    --dir)
      shift
      if [ $# -eq 0 ]; then
        echo "error: --dir requires a path argument" >&2
        exit 1
      fi
      EXPLICIT_DIR="$1"
      ;;
    -h|--help)    usage; exit 0 ;;
    -*)           echo "unknown option: $1" >&2; usage; exit 1 ;;
    *)            NAMES="$NAMES $1" ;;
  esac
  shift
done

# Run without any prompts (and so without ever blocking on a menu) when asked
# with --yes, in CI, or when there is no terminal to read from. This is the
# path a coding agent should use: `... | bash -s -- --yes` installs every skill
# into every detected agent, deterministically and without hanging.
NONINTERACTIVE=0
if [ "$YES" = "1" ] || [ -n "${CI:-}" ] || [ ! -r /dev/tty ]; then
  NONINTERACTIVE=1
fi

# Install/uninstall every selected skill into DEST_DIR, with a labelled header.
install_into() {
  DEST_DIR="$2"
  header="Installing into $1 ($2):"
  if [ "$DRY_RUN" = "1" ]; then header="[dry-run] $header"; fi
  echo "$header"
  for s in $NAMES; do install_one "$s"; done
}

uninstall_from() {
  DEST_DIR="$2"
  header="Uninstalling from $1 ($2):"
  if [ "$DRY_RUN" = "1" ]; then header="[dry-run] $header"; fi
  echo "$header"
  for s in $NAMES; do uninstall_one "$s"; done
}

# Run an action ("install_into"/"uninstall_from") for each resolved target: the
# explicit --dir/env override, or one per chosen agent.
for_each_target() {
  fn="$1"
  if [ -n "$EXPLICIT_DIR" ]; then
    "$fn" "custom directory" "$EXPLICIT_DIR"
    return
  fi
  for aid in $AGENT_IDS; do
    "$fn" "$(agent_name "$aid")" "$HOME/$(agent_skilldir "$aid")"
  done
}

fetch_tree
AVAILABLE="$(list_available)"

# Resolve target agents (unless an explicit directory was given).
if [ -z "$EXPLICIT_DIR" ]; then
  resolve_agents
  if [ -z "${AGENT_IDS# }" ]; then
    echo "No agent selected. Exiting."
    exit 0
  fi
fi

if [ "$MODE" = "uninstall" ]; then
  if [ -z "${NAMES# }" ]; then NAMES="$AVAILABLE"; fi
  for_each_target uninstall_from
  echo "Done. Restart the affected agents to unload them."
  exit 0
fi

# install mode: resolve which skills to install
if [ -z "${NAMES# }" ]; then
  if [ "$ALL" = "1" ]; then
    NAMES="$AVAILABLE"
  elif [ "$NONINTERACTIVE" = "0" ]; then
    NAMES="$(interactive_select "Select skills to install:" $AVAILABLE)"
  else
    # Non-interactive with nothing named: install every skill.
    NAMES="$AVAILABLE"
  fi
fi

if [ -z "${NAMES# }" ]; then
  echo "Nothing selected. Exiting."
  exit 0
fi

for_each_target install_into
echo "Done. Restart the affected agents, then invoke e.g. /finalize-feature"
