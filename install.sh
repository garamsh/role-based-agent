#!/usr/bin/env bash
# Link the role definitions in agents/ into Claude Code and opencode.
# Idempotent: safe to re-run after `git pull`.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$REPO_DIR/agents"

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/agents"
OPENCODE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/agents"

MODE="install"
[ "${1:-}" = "--uninstall" ] && MODE="uninstall"
[ "${1:-}" = "--help" ] && { echo "usage: $0 [--uninstall]"; exit 0; }

link_one() {
  local src="$1" dest="$2"

  if [ "$MODE" = "uninstall" ]; then
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      rm "$dest"
      echo "  removed  $dest"
    fi
    return
  fi

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "  SKIP     $dest (regular file, not managed here)" >&2
    return
  fi

  ln -sfn "$src" "$dest"
  echo "  linked   $dest"
}

for target in "$CLAUDE_DIR" "$OPENCODE_DIR"; do
  [ "$MODE" = "install" ] && mkdir -p "$target"
  [ -d "$target" ] || continue
  echo "$target"
  for src in "$SRC_DIR"/*.md; do
    link_one "$src" "$target/$(basename "$src")"
  done
done

if [ "$MODE" = "install" ]; then
  echo
  echo "Done. Start a session in a role with:"
  echo "  claude --agent pm      |  opencode --agent pm"
fi
