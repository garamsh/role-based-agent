#!/usr/bin/env sh
# Install role definitions for Claude Code and opencode.
#
#   curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/install.sh | sh
#
# Pick the tools in the prompt: arrows move, space toggles, enter installs.
# Roles are symlinked, so `--update` is enough to refresh every tool at once.
# A real file you put at a target path is never replaced without --force.
#
#   --update                 pull the source and refresh installed tools
#   --tool claude,opencode   install only to these, skipping the picker
#   --yes                    accept the detected tools without prompting
#   --force                  replace a real file sitting at a target path
#   --list                   show what would be targeted, then exit
#   --uninstall              remove the symlinks from every known target
set -eu

REPO_URL="https://github.com/garamsh/role-based-agent.git"
INSTALL_DIR="${ROLE_AGENT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/role-based-agent}"

SUPPORTED="claude opencode"

MODE="install"
TOOLS=""
FORCE=0
ASSUME_YES=0
MODIFIED=0
CHANGED=0

die() { echo "error: $*" >&2; exit 1; }

# Where each tool keeps user-level agent definitions.
tool_dir() {
  case "$1" in
    claude)   echo "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/agents" ;;
    opencode) echo "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/agents" ;;
    *) die "unknown tool: $1 (supported: $SUPPORTED)" ;;
  esac
}

tool_skills_dir() {
  case "$1" in
    claude)   echo "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills" ;;
    opencode) echo "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills" ;;
  esac
}

tool_label() {
  case "$1" in
    claude)   echo "Claude Code" ;;
    opencode) echo "opencode" ;;
  esac
}

# Present if its binary is on PATH or its config directory exists.
tool_present() {
  case "$1" in
    claude)   command -v claude >/dev/null 2>&1 && return 0
              [ -d "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" ] && return 0 ;;
    opencode) command -v opencode >/dev/null 2>&1 && return 0
              [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/opencode" ] && return 0 ;;
  esac
  return 1
}

# Already has at least one role file installed.
tool_installed() {
  d=$(tool_dir "$1")
  [ -d "$d" ] || return 1
  for f in "$SRC_DIR"/agents/*.md; do
    [ -e "$d/$(basename "$f")" ] && return 0
  done
  return 1
}

have_tty() { [ -c /dev/tty ] && stty -g < /dev/tty >/dev/null 2>&1; }

# ---------------------------------------------------------------- picker ----

# Read one keystroke from the terminal. The X sentinel survives $( ) stripping
# whitespace, so space and newline come through intact.
read_key() {
  k=$(dd if=/dev/tty bs=1 count=1 2>/dev/null; printf X)
  printf '%s' "${k%X}"
}

# Interactive multi-select. Writes the chosen tools to stdout.
pick_tools() {
  count=0
  for t in $SUPPORTED; do
    count=$((count + 1))
    eval "item_$count=\$t"
    if tool_present "$t"; then eval "sel_$count=1"; else eval "sel_$count=0"; fi
  done
  cursor=1

  saved=$(stty -g < /dev/tty)
  # shellcheck disable=SC2064
  trap "stty '$saved' < /dev/tty 2>/dev/null; printf '\033[?25h' > /dev/tty; exit 130" INT TERM
  stty raw -echo < /dev/tty
  printf '\033[?25l' > /dev/tty

  printf '\r\n  Install role definitions into:\r\n\r\n' > /dev/tty
  first=1
  while :; do
    [ "$first" -eq 1 ] || printf '\033[%dA' "$((count + 2))" > /dev/tty
    first=0

    i=0
    for t in $SUPPORTED; do
      i=$((i + 1))
      eval "s=\$sel_$i"
      [ "$s" -eq 1 ] && mark="x" || mark=" "
      [ "$i" -eq "$cursor" ] && pointer="\033[36m>\033[0m" || pointer=" "
      printf '\033[2K  %b [%s] %-12s %s\r\n' \
        "$pointer" "$mark" "$(tool_label "$t")" "$(tool_dir "$t")" > /dev/tty
    done
    printf '\033[2K\r\n\033[2K  \033[2mspace\033[0m toggle  \033[2m%s\033[0m move  \033[2menter\033[0m confirm  \033[2mq\033[0m cancel\r\n' \
      "up/down" > /dev/tty

    key=$(read_key)
    case "$key" in
      "$(printf '\033')")
        k2=$(read_key)
        if [ "$k2" = "[" ]; then
          k3=$(read_key)
          case "$k3" in
            A) [ "$cursor" -gt 1 ] && cursor=$((cursor - 1)) ;;
            B) [ "$cursor" -lt "$count" ] && cursor=$((cursor + 1)) ;;
          esac
        fi
        ;;
      k) [ "$cursor" -gt 1 ] && cursor=$((cursor - 1)) ;;
      j) [ "$cursor" -lt "$count" ] && cursor=$((cursor + 1)) ;;
      " ") eval "s=\$sel_$cursor"; [ "$s" -eq 1 ] && eval "sel_$cursor=0" || eval "sel_$cursor=1" ;;
      q) stty "$saved" < /dev/tty; printf '\033[?25h\r\n' > /dev/tty; trap - INT TERM; return 1 ;;
      "")  break ;;   # enter arrives as CR, which $( ) strips to empty
    esac
  done

  stty "$saved" < /dev/tty
  printf '\033[?25h\r\n' > /dev/tty
  trap - INT TERM

  chosen=""
  i=0
  for t in $SUPPORTED; do
    i=$((i + 1))
    eval "s=\$sel_$i"
    [ "$s" -eq 1 ] && chosen="$chosen $t"
  done
  printf '%s' "$chosen"
}

# ------------------------------------------------------------------ args ----

while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) MODE="uninstall" ;;
    --update) MODE="update" ;;
    --list) MODE="list" ;;
    --force) FORCE=1 ;;
    --yes|-y) ASSUME_YES=1 ;;
    --tool) [ $# -ge 2 ] || die "--tool needs a value"
            TOOLS=$(echo "$2" | tr ',' ' '); shift ;;
    --tool=*) TOOLS=$(echo "${1#--tool=}" | tr ',' ' ') ;;
    --help|-h) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

[ -n "$TOOLS" ] && for t in $TOOLS; do tool_dir "$t" >/dev/null; done

# ---------------------------------------------------------------- source ----

# A clone next to this script wins; otherwise fetch or refresh one.
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
  case "$MODE" in
    uninstall) die "run --uninstall from a clone, or set ROLE_AGENT_DIR" ;;
  esac
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
elif [ "$MODE" = "update" ] && [ -d "$SRC_DIR/.git" ]; then
  echo "Updating $SRC_DIR"
  git -C "$SRC_DIR" pull --ff-only -q || die "could not fast-forward $SRC_DIR"
fi

[ -d "$SRC_DIR/agents" ] || die "no agents/ directory in $SRC_DIR"

# ----------------------------------------------------------------- tools ----

if [ -n "$TOOLS" ]; then
  :                                   # explicit --tool wins
elif [ "$MODE" = "uninstall" ]; then
  TOOLS="$SUPPORTED"                  # sweep everything so nothing is orphaned
elif [ "$MODE" = "update" ]; then
  for t in $SUPPORTED; do tool_installed "$t" && TOOLS="$TOOLS $t"; done
  [ -n "$TOOLS" ] || die "nothing installed yet; run without --update first"
elif [ "$MODE" = "install" ] && [ "$ASSUME_YES" -eq 0 ] && have_tty; then
  TOOLS=$(pick_tools) || die "cancelled"
  [ -n "$TOOLS" ] || die "no tool selected"
else
  for t in $SUPPORTED; do tool_present "$t" && TOOLS="$TOOLS $t"; done
  [ -n "$TOOLS" ] && echo "Detected:$TOOLS"
fi

[ -n "$TOOLS" ] || die "no supported tool found (looked for: $SUPPORTED). Use --tool to force one."

if [ "$MODE" = "list" ]; then
  for t in $TOOLS; do echo "$t  ->  $(tool_dir "$t")"; done
  exit 0
fi

# --------------------------------------------------------------- install ----

# Only symlinks are ours to manage. A real file at a target path belongs to the
# user and is left alone unless --force says otherwise.
install_one() {
  src="$1"
  dest="$2"

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    if [ "$MODE" = "uninstall" ] || [ "$FORCE" -eq 0 ]; then
      echo "  kept      $dest (your own file; --force to replace)" >&2
      MODIFIED=$((MODIFIED + 1))
      return
    fi
  fi

  if [ "$MODE" = "uninstall" ]; then
    [ -L "$dest" ] || return
    rm "$dest"
    echo "  removed   $dest"
    return
  fi

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    return                            # already current, say nothing
  fi

  ln -sfn "$src" "$dest"
  CHANGED=$((CHANGED + 1))
  echo "  linked    $dest"
}

for t in $TOOLS; do
  echo "$(tool_label "$t")"

  target=$(tool_dir "$t")
  [ "$MODE" = "uninstall" ] || mkdir -p "$target"
  if [ -d "$target" ]; then
    for src in "$SRC_DIR"/agents/*.md; do
      install_one "$src" "$target/$(basename "$src")"
    done
  fi

  [ -d "$SRC_DIR/skills" ] || continue
  target=$(tool_skills_dir "$t")
  [ "$MODE" = "uninstall" ] || mkdir -p "$target"
  [ -d "$target" ] || continue
  for src in "$SRC_DIR"/skills/*/; do
    src=${src%/}
    install_one "$src" "$target/$(basename "$src")"
  done
done

case "$MODE" in
  install|update)
    echo
    [ "$CHANGED" -eq 0 ] && echo "Already up to date."
    [ "$MODIFIED" -gt 0 ] && echo "$MODIFIED path(s) left alone because a real file sits there."
    echo "Source: $SRC_DIR"
    echo "Start a session in a role with:  claude --agent pm  |  opencode --agent pm"
    ;;
esac
