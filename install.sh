#!/usr/bin/env sh
# Install, update, or remove role definitions for Claude Code and opencode.
#
#   curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/install.sh | sh
#
# One command covers the lifecycle. With a terminal attached it lists every
# supported tool, marking the installed set (the detected set on a first run);
# enter takes that set and numbers narrow it. Without a terminal it just
# refreshes. A real file or directory you put at a target path is never
# replaced -- move it yourself and re-run.
#
# Removing takes only symlinks of ours: a link is ours when its target names
# <checkout>/agents/<name>.md or <checkout>/skills/<name> and the link carries
# that same <name>. The target need not still exist, so a link left dangling by
# deleting the checkout is still removed; while the checkout is on disk it has
# to still hold agents/{pm,qa,worker}.md, so a link into an unrelated tree of
# the same shape is left alone. uninstall.sh removes by that same definition.
#
#   --tool claude,opencode   install only to these, skipping the prompt
#   --yes                    accept the detected tools without prompting
#   --list                   show what would be targeted, then exit
#   --uninstall              remove our symlinks from every known target
set -eu

REPO_URL="https://github.com/garamsh/role-based-agent.git"
INSTALL_DIR="${ROLE_AGENT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/role-based-agent}"

SUPPORTED="claude opencode"

MODE="install"
TOOLS=""
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

# Already has at least one role symlink installed. A real file at a target path
# is the user's own, so it does not count as ours and still needs the prompt.
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

# ---------------------------------------------------------------- prompt ----

# Ask which tools to target. $1 is the default set, marked in the list with
# PROMPT_TAG and returned on empty input; the chosen tools go to stdout, so
# every line of the prompt itself goes to the terminal. Reading /dev/tty rather
# than stdin is what leaves `curl ... | sh` able to ask at all.
choose_tools() {
  _default=$1
  { echo; echo "  $PROMPT_TITLE"; echo; } > /dev/tty
  _i=0
  for _t in $SUPPORTED; do
    _i=$((_i + 1))
    case " $_default " in *" $_t "*) _tag="  [$PROMPT_TAG]" ;; *) _tag="" ;; esac
    printf '    %d) %-12s %s/{agents,skills}/%s\n' \
      "$_i" "$(tool_label "$_t")" "$(dirname "$(tool_dir "$_t")")" "$_tag" > /dev/tty
  done

  _try=0
  while [ "$_try" -lt 3 ]; do
    _try=$((_try + 1))
    printf '\n  Enter to accept the marked set, or numbers to narrow (e.g. 1): ' > /dev/tty
    read -r _reply < /dev/tty || _reply=""
    [ -n "$_reply" ] || { printf '%s' "$_default"; return 0; }
    _picked=""
    for _n in $(echo "$_reply" | tr ',' ' '); do
      _j=0
      _t=""
      for _s in $SUPPORTED; do _j=$((_j + 1)); [ "$_n" = "$_j" ] && _t=$_s; done
      [ -n "$_t" ] || { _picked=""; break; }
      case " $_picked " in *" $_t "*) ;; *) _picked="$_picked $_t" ;; esac
    done
    [ -n "$_picked" ] && { printf '%s' "$_picked"; return 0; }
    echo "  not a choice on the list: $_reply" > /dev/tty
  done
  die "no valid choice after 3 tries; name the tools with --tool instead"
}

# ------------------------------------------------------------------ args ----

while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) MODE="uninstall" ;;
    --list) MODE="list" ;;
    --yes|-y) ASSUME_YES=1 ;;
    --tool) [ $# -ge 2 ] || die "--tool needs a value"
            TOOLS=$(echo "$2" | tr ',' ' '); shift ;;
    --tool=*) TOOLS=$(echo "${1#--tool=}" | tr ',' ' ') ;;
    # Lines 2-22 are the header block above; keep the range in sync with it.
    --help|-h) sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
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
      # shellcheck disable=SC1007 # CDPATH= prefixes cd, it is not an assignment of its own
      _dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
      [ -d "$_dir/agents" ] && SRC_DIR="$_dir"
    fi
    ;;
esac

if [ -z "$SRC_DIR" ]; then
  if [ "$MODE" = "uninstall" ]; then
    # Uninstalling needs a checkout only for the names to sweep, so an existing
    # one at INSTALL_DIR will do -- cloning the repo in order to delete symlinks
    # would be absurd, and updating it would be pointless. This is the only
    # place the piped form can honour ROLE_AGENT_DIR for --uninstall: the
    # clone-or-update block below never runs in this mode.
    [ -d "$INSTALL_DIR/agents" ] ||
      die "run --uninstall from a clone, point ROLE_AGENT_DIR at one, or use uninstall.sh"
    SRC_DIR="$INSTALL_DIR"
  else
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
fi

[ -d "$SRC_DIR/agents" ] || die "no agents/ directory in $SRC_DIR"

# ----------------------------------------------------------------- tools ----

# Re-running the install command is the update path. With a terminal attached
# the prompt lists every supported tool with the installed set marked, and
# enter refreshes exactly that set; narrowing only limits what is refreshed,
# since removing is what --uninstall is for. Without a terminal (CI, cron) the
# run refreshes in place and never blocks on a prompt. --yes still means "every
# detected tool", which is how you add one to an existing install unattended.
INSTALLED=""
if [ "$MODE" = "install" ]; then
  for t in $SUPPORTED; do tool_installed "$t" && INSTALLED="$INSTALLED $t"; done
fi
DETECTED=""
for t in $SUPPORTED; do tool_present "$t" && DETECTED="$DETECTED $t"; done

if [ -n "$TOOLS" ]; then
  :                                   # explicit --tool wins
elif [ "$MODE" = "uninstall" ]; then
  TOOLS="$SUPPORTED"                  # sweep everything so nothing is orphaned
elif [ -n "$INSTALLED" ] && [ "$ASSUME_YES" -eq 0 ]; then
  if have_tty; then
    PROMPT_TITLE="Update role definitions in:"
    PROMPT_TAG="installed"
    TOOLS=$(choose_tools "$INSTALLED")
  else
    TOOLS="$INSTALLED"                # the update path
    echo "Refreshing:$TOOLS"
  fi
elif [ "$MODE" = "install" ] && [ "$ASSUME_YES" -eq 0 ] && have_tty; then
  PROMPT_TITLE="Install role definitions into:"
  PROMPT_TAG="detected"
  TOOLS=$(choose_tools "$DETECTED")
else
  TOOLS="$DETECTED"
  [ -n "$TOOLS" ] && echo "Detected:$TOOLS"
fi

[ -n "$TOOLS" ] || die "no supported tool found (looked for: $SUPPORTED). Use --tool to force one."

if [ "$MODE" = "list" ]; then
  for t in $TOOLS; do echo "$t  ->  $(tool_dir "$t")"; done
  exit 0
fi

# --------------------------------------------------------------- install ----

# A symlink is ours when its target names <root>/agents/<name>.md or
# <root>/skills/<name> and the link carries that same <name> -- which is how
# install.sh writes them, and nothing else does. The check is on the link text,
# not on what it resolves to, because deleting the checkout before uninstalling
# is the normal order and leaves every link of ours dangling but still named.
# While <root> is on disk it still has to look like a checkout, so a link into
# an unrelated tree that happens to share the shape is not claimed.
#
# uninstall.sh is curl-piped standalone and cannot source install.sh, so the
# two scripts carry byte-identical copies of ours(). Change one, change the
# other; each script's header states this definition.
ours() {
  [ -L "$1" ] || return 1
  _target=$(readlink "$1")
  case "$_target" in */agents/*.md|*/skills/*) ;; *) return 1 ;; esac
  [ "$(basename "$_target")" = "$(basename "$1")" ] || return 1
  _root=$(dirname "$(dirname "$_target")")
  [ -d "$_root" ] || return 0         # checkout gone: the link text is all there is
  [ -f "$_root/agents/pm.md" ] && [ -f "$_root/agents/qa.md" ] &&
    [ -f "$_root/agents/worker.md" ]
}

# Only symlinks of ours are ours to manage. A real file or directory at a target
# path belongs to the user and is left alone.
#
# Every branch ends by checking the disk rather than trusting the command it
# just ran: the reported outcome is what is at $dest now, not which branch got
# there. That is what kept `linked` from being printed over an untouched
# directory, and what keeps a removal from claiming a link it left behind.
install_one() {
  src="$1"
  dest="$2"

  if [ "$MODE" = "uninstall" ]; then
    ours "$dest" || return 0          # nothing of ours here; not an error
    rm "$dest"
    if ours "$dest"; then die "could not remove $dest"; fi
    echo "  removed   $dest"
    return
  fi

  # `ln -sfn` cannot replace a real directory: -n only stops it following a
  # *symlink* to one, so against a real directory it drops the link inside it
  # instead. Nothing here clears the path, so nothing here may link at it.
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    if [ -d "$dest" ]; then _what="directory"; else _what="file"; fi
    echo "  kept      $dest (your own $_what; move it and re-run)" >&2
    MODIFIED=$((MODIFIED + 1))
    return
  fi

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    return                            # already current, say nothing
  fi

  ln -sfn "$src" "$dest"
  if [ ! -L "$dest" ] || [ "$(readlink "$dest")" != "$src" ]; then
    die "could not link $dest -> $src"
  fi
  CHANGED=$((CHANGED + 1))
  echo "  linked    $dest"
}

# Link every role (and skill) into one tool's directories, or, with
# MODE=uninstall, remove ours from it.
sync_tool() {
  t=$1
  tool_label "$t"

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

for t in $TOOLS; do
  sync_tool "$t"
done

case "$MODE" in
  install)
    echo
    [ "$CHANGED" -eq 0 ] && echo "Already up to date."
    [ "$MODIFIED" -gt 0 ] && echo "$MODIFIED path(s) left alone because something of yours sits there."
    echo "Source: $SRC_DIR"
    echo "Start a session in a role with:  claude --agent pm  |  opencode --agent pm"
    ;;
esac
