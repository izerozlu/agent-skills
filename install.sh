#!/usr/bin/env bash
#
# install.sh: install agent-skills directly from GitHub into your Claude Code
# skills directory. This script is self-contained: it downloads skill files
# over the network, so it works when piped straight from curl with no local
# clone of the repo present.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash -s -- --all
#   curl -fsSL https://raw.githubusercontent.com/izerozlu/agent-skills/main/install.sh | bash -s -- finalize-feature
#
#   ./install.sh                 # interactive: pick from a menu
#   ./install.sh --all           # install every skill
#   ./install.sh finalize-feature commit-in-logical-groups
#   ./install.sh --uninstall     # remove installed skills (all, or named)
#   ./install.sh --dry-run --all # show what would happen, touch nothing
#
# Installing downloads the skill files. Updating means re-running the same
# command again. There is no local clone to git pull.
#
# Skills load when Claude Code starts, so restart your session afterwards.

set -eu

REPO="izerozlu/agent-skills"
BRANCH="${IZER_SKILLS_REF:-main}"
API_TREE="https://api.github.com/repos/$REPO/git/trees/$BRANCH?recursive=1"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$BRANCH"
DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

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
MODE="install"
DRY_RUN=0
NAMES=""

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

# Interactive multi-select menu, drawn on the terminal (/dev/tty) so it keeps
# working when this script is piped through `curl | bash`. Takes the available
# skill names as arguments and prints the chosen names, space-separated, to
# stdout. Controls: up/down (or k/j) move, space toggles, a selects/clears all,
# enter confirms, q cancels.
interactive_select() {
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

  printf 'Select skills to install:\n' > "$tty"
  printf '  ↑/↓ move · space toggle · a select all · enter confirm · q cancel\n\n' > "$tty"
  printf '\033[?25l' > "$tty"   # hide cursor
  draw_menu

  while true; do
    IFS= read -rsn1 key < "$tty" || break
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
    if [ "${checked[i]}" -eq 1 ]; then printf '%s ' "${items[i]}"; fi
    i=$((i + 1))
  done
}

usage() {
  cat <<EOF
Install agent-skills (from https://github.com/$REPO) into: $DEST_DIR

Usage:
  curl -fsSL https://raw.githubusercontent.com/$REPO/$BRANCH/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/$REPO/$BRANCH/install.sh | bash -s -- --all
  curl -fsSL https://raw.githubusercontent.com/$REPO/$BRANCH/install.sh | bash -s -- finalize-feature

  ./install.sh [options] [skill ...]

Options:
  --all         Install every skill without prompting
  --uninstall   Remove installed skills (named ones, or all if none named)
  --dry-run     Print what would happen without touching the filesystem
  --dir PATH    Install into PATH instead of $DEST_DIR
  -h, --help    Show this help

Available skills:
$(list_available | sed 's/^/  - /')

Override the target dir with CLAUDE_SKILLS_DIR=/path or --dir PATH.

Skills load when Claude Code starts, so restart your session afterwards.
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
    --all)       ALL=1 ;;
    --uninstall) MODE="uninstall" ;;
    --dry-run)   DRY_RUN=1 ;;
    --dir)
      shift
      if [ $# -eq 0 ]; then
        echo "error: --dir requires a path argument" >&2
        exit 1
      fi
      DEST_DIR="$1"
      ;;
    -h|--help)   usage; exit 0 ;;
    -*)          echo "unknown option: $1" >&2; usage; exit 1 ;;
    *)           NAMES="$NAMES $1" ;;
  esac
  shift
done

fetch_tree
AVAILABLE="$(list_available)"

if [ "$MODE" = "uninstall" ]; then
  if [ -z "${NAMES# }" ]; then NAMES="$AVAILABLE"; fi
  header="Uninstalling from $DEST_DIR:"
  if [ "$DRY_RUN" = "1" ]; then header="[dry-run] $header"; fi
  echo "$header"
  for s in $NAMES; do uninstall_one "$s"; done
  echo "Done. Restart Claude Code to unload them."
  exit 0
fi

# install mode
if [ -z "${NAMES# }" ]; then
  if [ "$ALL" = "1" ]; then
    NAMES="$AVAILABLE"
  elif [ -r /dev/tty ]; then
    NAMES="$(interactive_select $AVAILABLE)"
  else
    echo "No skills specified. Pass names, use --all, or run interactively." >&2
    echo "Under curl, pass flags after --, e.g.: curl -fsSL <url> | bash -s -- --all" >&2
    exit 1
  fi
fi

if [ -z "${NAMES# }" ]; then
  echo "Nothing selected. Exiting."
  exit 0
fi

header="Installing into $DEST_DIR:"
if [ "$DRY_RUN" = "1" ]; then header="[dry-run] $header"; fi
echo "$header"
for s in $NAMES; do install_one "$s"; done
echo "Done. Restart Claude Code, then invoke e.g. /finalize-feature"
