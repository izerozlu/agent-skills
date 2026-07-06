#!/usr/bin/env bash
#
# install.sh — install izer-skills into your Claude Code skills directory.
#
# Each skill is symlinked by default, so a later `git pull` in this repo
# updates the installed skill in place. Use --copy for standalone copies.
#
# Usage:
#   ./install.sh                 # interactive: choose per skill
#   ./install.sh --all           # install every skill
#   ./install.sh finalize-feature commit-in-logical-groups
#   ./install.sh --copy --all    # copy instead of symlink
#   ./install.sh --uninstall     # remove installed skills (all, or named)
#
# Skills load when Claude Code starts, so restart your session afterwards.

set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$REPO_DIR/skills"
DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

COPY=0
ALL=0
MODE="install"
NAMES=""

list_available() {
  find "$SRC_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
    | while IFS= read -r d; do basename "$d"; done | sort
}

usage() {
  cat <<EOF
Install izer-skills into: $DEST_DIR

Usage: ./install.sh [options] [skill ...]

Options:
  --all         Install every skill without prompting
  --copy        Copy instead of symlink (no auto-update on git pull)
  --uninstall   Remove installed skills (named ones, or all if none named)
  -h, --help    Show this help

Available skills:
$(list_available | sed 's/^/  - /')

Override the target dir with CLAUDE_SKILLS_DIR=/path ./install.sh
EOF
}

link_one() {
  name="$1"
  src="$SRC_DIR/$name"
  dest="$DEST_DIR/$name"
  if [ ! -d "$src" ]; then
    echo "  ! unknown skill: $name" >&2
    return 0
  fi
  mkdir -p "$DEST_DIR"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "  = $name (already linked)"
    return 0
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$backup"
    echo "  ~ $name: moved existing aside -> $(basename "$backup")"
  fi
  if [ "$COPY" = "1" ]; then
    cp -R "$src" "$dest"
    echo "  + $name (copied)"
  else
    ln -s "$src" "$dest"
    echo "  + $name (linked)"
  fi
}

uninstall_one() {
  name="$1"
  dest="$DEST_DIR/$name"
  if [ -L "$dest" ]; then
    rm "$dest"
    echo "  - $name (removed link)"
  elif [ -e "$dest" ]; then
    echo "  ! $name exists but is not a symlink; leaving it untouched" >&2
  else
    echo "  = $name (not installed)"
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --all)       ALL=1 ;;
    --copy)      COPY=1 ;;
    --uninstall) MODE="uninstall" ;;
    -h|--help)   usage; exit 0 ;;
    -*)          echo "unknown option: $1" >&2; usage; exit 1 ;;
    *)           NAMES="$NAMES $1" ;;
  esac
  shift
done

AVAILABLE="$(list_available)"

if [ "$MODE" = "uninstall" ]; then
  if [ -z "${NAMES# }" ]; then NAMES="$AVAILABLE"; fi
  echo "Uninstalling from $DEST_DIR:"
  for s in $NAMES; do uninstall_one "$s"; done
  echo "Done. Restart Claude Code to unload them."
  exit 0
fi

# install mode
if [ -z "${NAMES# }" ]; then
  if [ "$ALL" = "1" ]; then
    NAMES="$AVAILABLE"
  elif [ -t 0 ] || [ -e /dev/tty ]; then
    SELECTED=""
    for s in $AVAILABLE; do
      printf "Install %s? [Y/n] " "$s" > /dev/tty
      read -r ans < /dev/tty || ans=""
      case "$ans" in
        n|N|no|NO|No) ;;
        *) SELECTED="$SELECTED $s" ;;
      esac
    done
    NAMES="$SELECTED"
  else
    echo "No skills specified. Pass names, use --all, or run interactively." >&2
    usage
    exit 1
  fi
fi

if [ -z "${NAMES# }" ]; then
  echo "Nothing selected. Exiting."
  exit 0
fi

echo "Installing into $DEST_DIR:"
for s in $NAMES; do link_one "$s"; done
echo "Done. Restart Claude Code, then invoke e.g. /finalize-feature"
