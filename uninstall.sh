#!/usr/bin/env sh
# Remove the role-definition symlinks for Claude Code and opencode.
#
#   curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/uninstall.sh | sh
#
# Only symlinks pointing into a role-based-agent checkout are removed; real
# files are never touched. install.sh --uninstall does the same from a clone.
set -eu

SUPPORTED="claude opencode"

tool_dirs() {
  case "$1" in
    claude)   echo "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/agents"
              echo "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills" ;;
    opencode) echo "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/agents"
              echo "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills" ;;
  esac
}

# A symlink is ours when its target sits in a checkout of this repo — a
# directory whose agents/ holds the three role files.
ours() {
  target=$(readlink "$1") || return 1
  case "$target" in
    */agents/*.md|*/skills/*) root=$(dirname "$(dirname "$target")") ;;
    *) return 1 ;;
  esac
  [ -f "$root/agents/pm.md" ] && [ -f "$root/agents/qa.md" ] && [ -f "$root/agents/worker.md" ]
}

REMOVED=0
for t in $SUPPORTED; do
  for d in $(tool_dirs "$t"); do
    [ -d "$d" ] || continue
    for f in "$d"/*; do
      [ -L "$f" ] || continue
      if ours "$f"; then
        rm "$f"
        REMOVED=$((REMOVED + 1))
        echo "  removed   $f"
      fi
    done
  done
done

if [ "$REMOVED" -eq 0 ]; then
  echo "Nothing to remove."
fi
