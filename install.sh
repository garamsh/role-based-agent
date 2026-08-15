#!/usr/bin/env sh
# Install, update, or remove role definitions for Claude Code and opencode.
#
#   curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/install.sh | sh
#
# One command covers the lifecycle. The picker lists every supported tool with
# the installed set pre-selected (the detected set on first run); confirming
# links the kept tools and removes ours from the unchecked ones. Check none to
# remove everything, or run uninstall.sh. Without a terminal it just refreshes.
# A real file you put at a target path is never replaced without --force.
#
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
DROPPED=""
FORCE=0
ASSUME_YES=0
MODIFIED=0
CHANGED=0
REPOINTED=""

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

# Already has at least one role symlink installed. A real file at a target path
# is the user's own, so it does not count as ours and still needs the picker.
tool_installed() {
  d=$(tool_dir "$1")
  [ -d "$d" ] || return 1
  for f in "$SRC_DIR"/agents/*.md; do
    [ -L "$d/$(basename "$f")" ] && return 0
  done
  return 1
}

# The shell opens `< /dev/tty` before stty runs, so a failure to open it is the
# shell's message on the script's stderr, not stty's, and stty's own 2>&1 comes
# too late to catch it. The group's redirect is in place first, so it does.
have_tty() { [ -c /dev/tty ] && { stty -g < /dev/tty >/dev/null; } 2>/dev/null; }

# ---------------------------------------------------------------- picker ----

# Keys as raw byte values: $( ) strips trailing newlines, so a control key
# carried through as text is indistinguishable from an empty read.
KEY_CR=0d
KEY_LF=0a
KEY_SPACE=20
KEY_Q=71
KEY_K=6b
KEY_J=6a
KEY_ESC=1b
KEY_BRACKET=5b                        # arrows arrive as ESC [ A / ESC [ B
KEY_UP=41
KEY_DOWN=42
KEY_NONE=                             # end of input: the terminal went away

# Read one keystroke from the terminal, as two hex digits, or nothing at EOF.
read_key() {
  dd if=/dev/tty bs=1 count=1 2>/dev/null | od -An -tx1 | tr -d '[:space:]'
}

# Interactive multi-select. PICKER_TITLE is the heading; the arguments name
# the pre-selected tools (none pre-selected when called with none). Writes the
# chosen tools to stdout.
pick_tools() {
  count=0
  for t in $SUPPORTED; do
    count=$((count + 1))
    eval "item_$count=\$t"
    case " $* " in
      *" $t "*) eval "sel_$count=1" ;;
      *)          eval "sel_$count=0" ;;
    esac
  done
  cursor=1

  saved=$(stty -g < /dev/tty)
  # shellcheck disable=SC2064
  trap "stty '$saved' < /dev/tty 2>/dev/null; printf '\033[?25h' > /dev/tty; exit 130" INT TERM
  stty raw -echo < /dev/tty
  printf '\033[?25l' > /dev/tty

  printf '\r\n  %s\r\n\r\n' "$PICKER_TITLE" > /dev/tty
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
      "$KEY_ESC")
        if [ "$(read_key)" = "$KEY_BRACKET" ]; then
          case "$(read_key)" in
            "$KEY_UP")   [ "$cursor" -gt 1 ] && cursor=$((cursor - 1)) ;;
            "$KEY_DOWN") [ "$cursor" -lt "$count" ] && cursor=$((cursor + 1)) ;;
          esac
        fi
        ;;
      "$KEY_K") [ "$cursor" -gt 1 ] && cursor=$((cursor - 1)) ;;
      "$KEY_J") [ "$cursor" -lt "$count" ] && cursor=$((cursor + 1)) ;;
      "$KEY_SPACE") eval "s=\$sel_$cursor"; [ "$s" -eq 1 ] && eval "sel_$cursor=0" || eval "sel_$cursor=1" ;;
      "$KEY_CR"|"$KEY_LF") break ;;
      "$KEY_Q"|"$KEY_NONE") stty "$saved" < /dev/tty; printf '\033[?25h\r\n' > /dev/tty; trap - INT TERM; return 1 ;;
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
    --list) MODE="list" ;;
    --force) FORCE=1 ;;
    --yes|-y) ASSUME_YES=1 ;;
    --tool) [ $# -ge 2 ] || die "--tool needs a value"
            TOOLS=$(echo "$2" | tr ',' ' '); shift ;;
    --tool=*) TOOLS=$(echo "${1#--tool=}" | tr ',' ' ') ;;
    # Lines 2-16 are the header block above; keep the range in sync with it.
    --help|-h) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
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
fi

[ -d "$SRC_DIR/agents" ] || die "no agents/ directory in $SRC_DIR"

# ----------------------------------------------------------------- tools ----

# Re-running the install command is the update path. With a terminal attached,
# the picker lists every supported tool pre-selected with what is installed;
# unchecking a tool removes our symlinks from it, unchecking all removes
# everything. Without a terminal (CI, cron) the run refreshes in place and
# never blocks on a prompt. --yes still means "every detected tool", which is
# how you add one to an existing install without a terminal.
INSTALLED=""
if [ "$MODE" = "install" ]; then
  for t in $SUPPORTED; do tool_installed "$t" && INSTALLED="$INSTALLED $t"; done
fi

if [ -n "$TOOLS" ]; then
  :                                   # explicit --tool wins
elif [ "$MODE" = "uninstall" ]; then
  TOOLS="$SUPPORTED"                  # sweep everything so nothing is orphaned
elif [ -n "$INSTALLED" ] && [ "$ASSUME_YES" -eq 0 ]; then
  if have_tty; then
    PICKER_TITLE="Installed tools (uncheck one to remove it):"
    # shellcheck disable=SC2086 # word splitting turns the list into args
    TOOLS=$(pick_tools $INSTALLED) || die "cancelled"
    if [ -z "$TOOLS" ]; then
      MODE="uninstall"                # unchecked everything: remove all
      TOOLS="$SUPPORTED"              # sweep everything so nothing is orphaned
    else
      # A tool dropped from the set keeps nothing of ours behind.
      for t in $INSTALLED; do
        case " $TOOLS " in
          *" $t "*) ;;
          *) DROPPED="$DROPPED $t" ;;
        esac
      done
    fi
  else
    TOOLS="$INSTALLED"                # the update path
    echo "Refreshing:$TOOLS"
  fi
elif [ "$MODE" = "install" ] && [ "$ASSUME_YES" -eq 0 ] && have_tty; then
  PRESENT=""
  for t in $SUPPORTED; do tool_present "$t" && PRESENT="$PRESENT $t"; done
  PICKER_TITLE="Install role definitions into:"
  # shellcheck disable=SC2086 # word splitting turns the list into args
  TOOLS=$(pick_tools $PRESENT) || die "cancelled"
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

# <clone>/agents/pm.md and <clone>/skills/foo both give <clone>.
link_source_root() {
  case "$1" in
    */agents/*.md|*/skills/*) dirname "$(dirname "$1")" ;;
  esac
}

# Repointing changes which files the tools read, so name each clone left, once.
announce_repoint() {
  old=$(link_source_root "$1")
  [ -n "$old" ] || return 0
  [ "$old" != "$SRC_DIR" ] || return 0
  case " $REPOINTED " in
    *" $old "*) return 0 ;;           # already reported this clone
  esac
  REPOINTED="$REPOINTED $old"
  echo "  repointed from $old"
}

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
    [ -L "$dest" ] || return 0      # nothing of ours here; not an error
    rm "$dest"
    echo "  removed   $dest"
    return
  fi

  if [ -L "$dest" ]; then
    current=$(readlink "$dest")
    [ "$current" = "$src" ] && return # already current, say nothing
    announce_repoint "$current"
  fi

  ln -sfn "$src" "$dest"
  CHANGED=$((CHANGED + 1))
  echo "  linked    $dest"
}

# Link every role (and skill) into one tool's directories, or, with
# MODE=uninstall, remove ours from it.
sync_tool() {
  t=$1
  echo "$(tool_label "$t")"

  target=$(tool_dir "$t")
  [ "$MODE" = "uninstall" ] || mkdir -p "$target"
  if [ -d "$target" ]; then
    for src in "$SRC_DIR"/agents/*.md; do
      install_one "$src" "$target/$(basename "$src")"
    done
  fi

  [ -d "$SRC_DIR/skills" ] || return 0
  target=$(tool_skills_dir "$t")
  [ "$MODE" = "uninstall" ] || mkdir -p "$target"
  [ -d "$target" ] || return 0
  for src in "$SRC_DIR"/skills/*/; do
    src=${src%/}
    install_one "$src" "$target/$(basename "$src")"
  done
}

if [ -n "$DROPPED" ]; then
  saved_mode=$MODE
  MODE="uninstall"
  for t in $DROPPED; do sync_tool "$t"; done
  MODE=$saved_mode
fi

for t in $TOOLS; do
  sync_tool "$t"
done

case "$MODE" in
  install)
    echo
    [ "$CHANGED" -eq 0 ] && echo "Already up to date."
    [ "$MODIFIED" -gt 0 ] && echo "$MODIFIED path(s) left alone because a real file sits there."
    echo "Source: $SRC_DIR"
    echo "Start a session in a role with:  claude --agent pm  |  opencode --agent pm"
    ;;
esac
