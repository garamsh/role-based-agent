#!/usr/bin/env sh
# Install role definitions for Claude Code and opencode.
#
#   curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/install.sh | sh
#
# Targets every supported tool detected on this host. Pass --tool to choose
# explicitly. Run from a clone and that clone is used in place.
# Idempotent: safe to re-run. Pass --uninstall to remove the links.
#
#   --tool claude,opencode   install only to these (skips detection)
#   --list                   show what would be targeted, then exit
#   --uninstall              remove links from every known target
set -eu

REPO_URL="https://github.com/garamsh/role-based-agent.git"
INSTALL_DIR="${ROLE_AGENT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/role-based-agent}"

SUPPORTED="claude opencode"

MODE="install"
TOOLS=""

die() { echo "error: $*" >&2; exit 1; }

# Where each tool keeps user-level agent definitions.
tool_dir() {
  case "$1" in
    claude)   echo "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/agents" ;;
    opencode) echo "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/agents" ;;
    *) die "unknown tool: $1 (supported: $SUPPORTED)" ;;
  esac
}

# A tool counts as present if its binary is on PATH or its config dir exists.
tool_present() {
  case "$1" in
    claude)   command -v claude >/dev/null 2>&1 && return 0
              [ -d "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" ] && return 0 ;;
    opencode) command -v opencode >/dev/null 2>&1 && return 0
              [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/opencode" ] && return 0 ;;
  esac
  return 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) MODE="uninstall" ;;
    --list) MODE="list" ;;
    --tool) [ $# -ge 2 ] || die "--tool needs a value"
            TOOLS=$(echo "$2" | tr ',' ' '); shift ;;
    --tool=*) TOOLS=$(echo "${1#--tool=}" | tr ',' ' ') ;;
    --help|-h) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

# Uninstall sweeps every known target so nothing is orphaned.
if [ "$MODE" = "uninstall" ]; then
  TOOLS="$SUPPORTED"
elif [ -n "$TOOLS" ]; then
  for t in $TOOLS; do tool_dir "$t" >/dev/null; done   # validate names
else
  for t in $SUPPORTED; do
    tool_present "$t" && TOOLS="$TOOLS $t"
  done
  [ -n "$TOOLS" ] && echo "Detected:$TOOLS"
fi

[ -n "$TOOLS" ] || die "no supported tool found (looked for: $SUPPORTED). Use --tool to force one."

if [ "$MODE" = "list" ]; then
  for t in $TOOLS; do echo "$t  ->  $(tool_dir "$t")"; done
  exit 0
fi

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

for t in $TOOLS; do
  target=$(tool_dir "$t")
  [ "$MODE" = "install" ] && mkdir -p "$target"
  [ -d "$target" ] || continue
  echo "$t  $target"
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
