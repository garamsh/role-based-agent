#!/usr/bin/env sh
# Install role definitions for Claude Code and opencode.
#
#   curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/install.sh | sh
#
# Run from a clone instead, and that clone is used in place.
# Idempotent: safe to re-run. Pass --uninstall to remove the links.
set -eu

REPO_URL="https://github.com/garamsh/role-based-agent.git"
INSTALL_DIR="${ROLE_AGENT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/role-based-agent}"

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/agents"
OPENCODE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/agents"

MODE="install"
case "${1:-}" in
  --uninstall) MODE="uninstall" ;;
  --help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  "") ;;
  *) echo "unknown option: $1" >&2; exit 2 ;;
esac

die() { echo "error: $*" >&2; exit 1; }

# Resolve the source. A clone next to this script wins; otherwise fetch one.
SRC_DIR=""
case "$0" in
  */install.sh|install.sh)
    if [ -f "$0" ]; then
      _dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
      [ -d "$_dir/agents" ] && SRC_DIR="$_dir"
    fi
    ;;
esac

if [ -z "$SRC_DIR" ]; then
  [ "$MODE" = "uninstall" ] && die "run --uninstall from a clone, or set ROLE_AGENT_DIR"
  command -v git >/dev/null 2>&1 || die "git is required to install from a URL"

  if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating $INSTALL_DIR"
    git -C "$INSTALL_DIR" pull --ff-only -q || die "could not fast-forward $INSTALL_DIR"
  else
    echo "Cloning into $INSTALL_DIR"
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone -q "$REPO_URL" "$INSTALL_DIR" || die "clone failed"
  fi
  SRC_DIR="$INSTALL_DIR"
fi

[ -d "$SRC_DIR/agents" ] || die "no agents/ directory in $SRC_DIR"

link_one() {
  src="$1"
  dest="$2"

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
  for src in "$SRC_DIR"/agents/*.md; do
    link_one "$src" "$target/$(basename "$src")"
  done
done

if [ "$MODE" = "install" ]; then
  echo
  echo "Source: $SRC_DIR"
  echo "Start a session in a role with:"
  echo "  claude --agent pm      |  opencode --agent pm"
fi
