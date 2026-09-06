#!/usr/bin/env sh
# Install or update role definitions for Claude Code and opencode.
#
#   curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/install.sh | sh
#
# Installing is all this does, and it takes no arguments. With a terminal
# attached it lists the tools it finds on this machine as a checkbox list:
# numbers toggle a row, enter installs whatever is checked. Without a terminal
# it just refreshes. ROLE_AGENT_TOOLS or ROLE_AGENT_NONINTERACTIVE skips the
# prompt for a caller that has a terminal but wants no question. A real file or
# directory you put at a target path is never replaced -- move it yourself and
# re-run.
#
# Removing is uninstall.sh, the only script here that deletes anything:
#
#   curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/uninstall.sh | sh
set -eu

REPO_URL="https://github.com/garamsh/role-based-agent.git"
INSTALL_DIR="${ROLE_AGENT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/role-based-agent}"

SUPPORTED="claude opencode"

MODIFIED=0
CHANGED=0

die() { echo "error: $*" >&2; exit 1; }

# No flags at all: this script installs, uninstall.sh removes. An argument is a
# caller reaching for an option that no longer exists, and ignoring it would be
# worse than refusing -- a stale `--uninstall` would install where it was meant
# to remove.
[ $# -eq 0 ] || die "install.sh takes no arguments (got: $1); to remove, run uninstall.sh"

# Two ways past the prompt, both by environment rather than by flag: the line
# above refuses arguments, and a flag passed through `curl ... | sh` would need
# `sh -s --` plumbing most callers do not know. ROLE_AGENT_DIR set the
# precedent for saying this by environment instead.
#
# ROLE_AGENT_TOOLS names the set outright and wins where both are set;
# ROLE_AGENT_NONINTERACTIVE, any non-empty value, takes the set this run would
# otherwise have offered. An unknown name is caught here rather than in the
# install loop, so it stops the run before the clone and leaves nothing behind.
NONINTERACTIVE="${ROLE_AGENT_NONINTERACTIVE:-}"
REQUESTED=""
set -f                              # a bare * names no tool, and must not glob
for t in $(echo "${ROLE_AGENT_TOOLS:-}" | tr ',' ' '); do
  case " $SUPPORTED " in
    *" $t "*) ;;
    *) die "ROLE_AGENT_TOOLS: unknown tool: $t (supported: $SUPPORTED)" ;;
  esac
  case " $REQUESTED " in *" $t "*) continue ;; esac   # named twice, linked once
  REQUESTED="$REQUESTED $t"
done
set +f
# Set to nothing but separators, which asks for an empty install: a provisioning
# script means something by setting this, so guessing at the prompt is worse.
[ -z "${ROLE_AGENT_TOOLS:-}" ] || [ -n "$REQUESTED" ] ||
  die "ROLE_AGENT_TOOLS names no tool (supported: $SUPPORTED)"

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

# Ask which of $DETECTED to install into. $1 is the set that starts checked;
# the chosen tools go to stdout, so every line of the prompt itself goes to the
# terminal. Reading /dev/tty rather than stdin is what leaves `curl ... | sh`
# able to ask at all.
#
# The list is reprinted after every entry instead of redrawn in place. Seeing
# what is checked is the whole point of a checkbox, and reprinting buys that
# for the price of a few lines of output -- no raw mode, no cursor control, no
# escape sequence anywhere in this script.
choose_tools() {
  _checked=$1
  _wrong=0
  while :; do
    { echo; echo "  $PROMPT_TITLE"; echo; } > /dev/tty
    _i=0
    for _t in $DETECTED; do
      _i=$((_i + 1))
      case " $_checked " in *" $_t "*) _box=x ;; *) _box=" " ;; esac
      printf '    %d) [%s] %-12s %s/{agents,skills}/\n' \
        "$_i" "$_box" "$(tool_label "$_t")" "$(dirname "$(tool_dir "$_t")")" > /dev/tty
    done
    printf '\n  Toggle by number, Enter to install: ' > /dev/tty

    _eof=0; _reply=""
    read -r _reply < /dev/tty || _eof=1
    if [ -z "$_reply" ]; then
      [ -n "$_checked" ] && { printf '%s' "$_checked"; return 0; }
      # Re-asking a terminal that has gone away only spins, so EOF stops here.
      [ "$_eof" -eq 0 ] || die "nothing selected"
      echo "  nothing selected -- toggle a number to pick one" > /dev/tty
      continue
    fi

    # An entry is taken whole or not at all, so the typo in "1 3" does not
    # leave 1 toggled behind it. set -f keeps a bare * from expanding into
    # filenames, one of which could be named for a row.
    _next=$_checked
    _bad=$_reply                      # cleared by the first number that parses
    set -f
    for _n in $(echo "$_reply" | tr ',' ' '); do
      _j=0; _t=""
      for _s in $DETECTED; do _j=$((_j + 1)); [ "$_n" = "$_j" ] && _t=$_s; done
      [ -n "$_t" ] || { _bad=$_n; break; }
      _bad=""
      # Rebuilt in row order with this one row flipped, so the set that gets
      # installed always reads in the order the list on screen just showed.
      _rebuilt=""
      for _s in $DETECTED; do
        case " $_next " in *" $_s "*) _on=1 ;; *) _on=0 ;; esac
        [ "$_s" = "$_t" ] && _on=$((1 - _on))
        case "$_on" in 1) _rebuilt="$_rebuilt $_s" ;; esac
      done
      _next=$_rebuilt
    done
    set +f

    if [ -n "$_bad" ]; then
      _wrong=$((_wrong + 1))
      [ "$_wrong" -lt 3 ] || die "no valid choice after 3 tries"
      echo "  not a number on the list: $_reply" > /dev/tty
      continue
    fi
    _checked=$_next
    _wrong=0                          # consecutive, so a good entry forgives
  done
}

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

# The clone's commit and the date on it. Both messages below have to say how
# old the text they are about to leave installed might be, and a second copy of
# this is a second thing to keep in step.
clone_at() {
  _at=$(git -C "$1" rev-parse --short HEAD 2>/dev/null) || _at="its current commit"
  _when=$(git -C "$1" log -1 --format=%cd --date=short 2>/dev/null) || _when=""
  [ -z "$_when" ] || _when=" of $_when"
}

# A remote this run could not reach is not a clone that refuses to move. The
# clone on disk is untouched and still serves every link it served before, so
# this warns and carries on. #98 is that both failures arrived as one non-zero
# exit and got update_blocked()'s message, whose only advice was to run
# uninstall.sh and delete the clone -- a destructive answer to a network blip,
# for a condition nothing of the user's caused.
#
# Continuing rather than exiting non-zero is the decision here, and it is what
# keeps the unattended form safe: a blip on CI leaves the links exactly as a
# successful run with nothing incoming would have left them. What it costs is
# that the clone may be behind and this run cannot tell, so it says how old the
# text it is installing is and leaves the reader to judge.
update_unreachable() {
  _d=$1
  clone_at "$_d"
  {
    echo
    echo "Could not fetch from the remote of $_d; git's message above says why."
    echo
    echo "  installing from the clone as it stands, at $_at$_when -- nothing"
    echo "    was fetched, so it may be behind, and nothing in a session that"
    echo "    loads it can tell how old it is"
    echo "  re-run once the remote is reachable and it updates as usual"
    echo
  } >&2
}

# `pull --ff-only` refuses in order to protect an edit made here, which is
# right; the dead end it leaves the reader is not. This names what blocked and
# a way past it, and says which of the files you edited are *not* in the way --
# the one thing git's own message above cannot tell you.
#
# It also names what the refusal holds back, which is a different list and in
# #84 shared no entry with the first: a clone ten commits behind went on
# serving a skill nobody here had edited, and the session that loaded it got a
# well-formed document with no way to date it. Naming only the blockers
# answers the question the operator asked and not the one that costs. A
# refused run is the last moment anything in this project can say so, so it is
# said here rather than left to surface twelve days later in another
# repository.
#
# Nothing here writes to the clone: an installer that stashed or reset on the
# user's behalf is the bug this refusal exists to prevent, and losing an edit
# silently would be the worse failure.
update_blocked() {
  _d=$1
  _up=$(git -C "$_d" rev-parse --abbrev-ref '@{u}' 2>/dev/null) || _up=""
  _ahead=0
  _behind=0
  _incoming=""
  if [ -n "$_up" ]; then
    # The fetch half of the pull already ran, so the upstream ref names what
    # this run was trying to land -- the merge is what refused.
    _ahead=$(git -C "$_d" rev-list --count "$_up..HEAD") || _ahead=0
    _behind=$(git -C "$_d" rev-list --count "HEAD..$_up") || _behind=0
    # Diffed from the fork point rather than from HEAD, so the answer is what
    # upstream adds. Against HEAD a clone carrying commits of its own also
    # lists the files those commits changed, which the update never touches --
    # naming them as held back would be the same wrong answer this message
    # exists to stop giving.
    _base=$(git -C "$_d" merge-base HEAD "$_up") || _base=HEAD
    _incoming=$(git -C "$_d" diff --name-only "$_base" "$_up") || _incoming=""
  fi

  # Tracked files that differ from HEAD, then untracked ones -- which block
  # too, when the update would create a file at that same path. Tagged by kind
  # because only an untracked one needs `stash -u`, and `checkout --` cannot
  # bring one back, so a suggestion that fits one does not fit the other.
  _edited=$(
    git -C "$_d" diff --name-only HEAD | sed 's/^/t /'
    git -C "$_d" ls-files --others --exclude-standard | sed 's/^/u /'
  ) || _edited=""

  _stuck=""; _spare=""; _paths=""; _stash_u=""; _restorable=1
  while IFS= read -r _line; do
    [ -n "$_line" ] || continue
    _p=${_line#? }
    if printf '%s\n' "$_incoming" | grep -qxF -e "$_p"; then
      _note=""
      case "$_line" in "u "*) _note=" (untracked)"; _stash_u=" -u"; _restorable=0 ;; esac
      _stuck="$_stuck    $_p$_note
"
      _paths="$_paths $_p"
    else
      # Only tracked edits are worth listing as not-in-the-way. Every other
      # untracked file in the clone is noise the reader did not ask about.
      case "$_line" in "t "*) _spare="$_spare    $_p
" ;; esac
    fi
  done <<EOF
$_edited
EOF

  # Every path the update carries, and not only the ones something of yours
  # blocks: in #84 the two sets were disjoint for all ten commits, so a list of
  # blockers named nothing that was going stale. Tagged where sync_tool() links
  # the path out, because that is the copy a session reads -- the rest of the
  # clone ageing costs nothing until you next open it yourself.
  _held=""; _linked=0
  while IFS= read -r _p; do
    [ -n "$_p" ] || continue
    # Tagged only where the path exists here as well: an incoming file the
    # clone does not have yet is held back but is not being served, and a tag
    # promising a session reads it would be the wrong answer again.
    _tag=""
    case "$_p" in
      agents/*.md|skills/*)
        if [ -e "$_d/$_p" ]; then _tag=" (installed)"; _linked=1; fi ;;
    esac
    _held="$_held    $_p$_tag
"
  done <<EOF
$_incoming
EOF

  clone_at "$_d"

  {
    echo
    if [ "$_ahead" -gt 0 ]; then
      echo "$_d has $_ahead commit(s) of its own, so it cannot be fast-forwarded."
      echo
      echo "  put them somewhere they survive (a branch, a push), reset this clone"
      echo "    onto $_up yourself, and re-run"
    elif [ -n "$_stuck" ]; then
      echo "An incoming change lands on a file of yours in $_d."
      echo
      echo "  in the way (yours here, and changed by the update):"
      printf '%s' "$_stuck"
      if [ -n "$_spare" ]; then
        echo
        echo "  edited here, but not in the way:"
        printf '%s' "$_spare"
      fi
      echo
      echo "  set the blocking ones aside, update, put them back:"
      echo "    git -C $_d stash push$_stash_u --$_paths"
      echo "    (re-run this installer)"
      echo "    git -C $_d stash pop"
      echo "      can stop on a conflict, since the update touched these paths"
      echo "      too: nothing is lost -- the update is in, your edit is still"
      echo "      in the stash"
      if [ "$_restorable" -eq 1 ]; then
        echo "  or drop them and take the update:"
        echo "    git -C $_d checkout --$_paths, then re-run"
      fi
    else
      echo "$_d could not be fast-forwarded; git's message above says why."
      echo
      echo "  no commit and no file of yours is in the way, so that message names"
      echo "    a condition this script cannot: clear it in the clone and re-run"
    fi
    # Written once below the branches rather than inside each: it is the same
    # route out of all three, and three copies of it had drifted into three
    # lead-ins. Every branch prints a route first, so "or" always fits.
    echo "  or keep what you have here and stop updating this clone: sh $_d/install.sh"
    echo "    installs from where it sits and never pulls"
    # Last, so it is read whichever route was taken -- and the route above is
    # the one that makes this permanent. Below the branches for the same reason
    # as that route: what the refusal holds back does not depend on why it
    # refused.
    if [ -n "$_held" ]; then
      echo
      echo "  held back -- $_at$_when is $_behind commit(s) behind $_up, and the"
      echo "  update changes each of these while this clone does not:"
      printf '%s' "$_held"
      if [ "$_linked" -eq 1 ]; then
        echo "      an (installed) path is linked into your tool directories: what"
        echo "      is here now is what a session loads, and nothing in that"
        echo "      session can tell how old it is"
      fi
    fi
    echo
  } >&2

  die "left $_d unchanged at $_at, and removed nothing"
}

if [ -z "$SRC_DIR" ]; then
  command -v git >/dev/null 2>&1 || die "git is required to install from a URL"

  if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating $INSTALL_DIR"
    # Split out of `pull --ff-only` so the two failures it handed back as one
    # exit status can be told apart. They are different conditions with
    # different remedies: a remote that could not be read says nothing about
    # this clone, while a merge that refuses is about nothing else.
    if git -C "$INSTALL_DIR" fetch -q; then
      git -C "$INSTALL_DIR" merge --ff-only -q || update_blocked "$INSTALL_DIR"
    else
      update_unreachable "$INSTALL_DIR"
    fi
    # Said on the run that works, because the run that refuses is too late: an
    # edit here costs nothing until an incoming commit lands on that same file,
    # and every update after that one refuses. update_blocked() says what to do
    # once it has; this only says it is coming, so it names no path and no route.
    [ -z "$(git -C "$INSTALL_DIR" status --porcelain)" ] ||
      echo "  files of yours here -- an update stops once a commit lands on one" >&2
    # A second condition rather than a wider first one: --porcelain reports the
    # working tree, so a commit made here never appears in it, and the way out
    # differs too -- stash moves an edit and moves no commit. The fallback keeps
    # a clone with no upstream to count against from turning an update that
    # worked into a failure.
    _ahead=$(git -C "$INSTALL_DIR" rev-list --count '@{u}..HEAD' 2>/dev/null) || _ahead=0
    [ "$_ahead" -eq 0 ] ||
      echo "  commits of yours here -- an update stops once anything lands upstream" >&2
  else
    echo "Cloning into $INSTALL_DIR"
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone -q "$REPO_URL" "$INSTALL_DIR" || die "clone failed"
  fi
  SRC_DIR="$INSTALL_DIR"
fi

[ -d "$SRC_DIR/agents" ] || die "no agents/ directory in $SRC_DIR"

# ----------------------------------------------------------------- tools ----

# Only the tools found on this machine are listed: a checkbox for something
# that is not installed is a row you can only get wrong. Re-running the install
# command is the update path, so the checked set starts as the installed one
# and enter refreshes exactly that; unchecking limits what is refreshed and
# never removes, since uninstall.sh is the only thing that deletes. Without a
# terminal (CI, cron) the run takes that same set without asking, which is what
# keeps the one-liner safe for unattended updates.
INSTALLED=""
for t in $SUPPORTED; do tool_installed "$t" && INSTALLED="$INSTALLED $t"; done
DETECTED=""
for t in $SUPPORTED; do tool_present "$t" && DETECTED="$DETECTED $t"; done

if [ -n "$REQUESTED" ]; then
  # A named set outranks detection, since the caller may be provisioning a
  # machine where the tool arrives later. Saying which names were not found is
  # what keeps a typo visible instead of quietly linking into an empty corner.
  TOOLS="$REQUESTED"
  ABSENT=""
  for t in $TOOLS; do tool_present "$t" || ABSENT="$ABSENT $t"; done
  echo "ROLE_AGENT_TOOLS:$TOOLS"
  if [ -n "$ABSENT" ]; then
    echo "  not detected on this machine, installing anyway:$ABSENT"
  fi
else
  # Nothing found to install into leaves nothing to ask about, so this is
  # settled before the prompt rather than after it.
  [ -n "$DETECTED" ] || die "no supported tool found (looked for: $SUPPORTED)"

  if [ -n "$INSTALLED" ]; then
    PROMPT_TITLE="Update role definitions in:"
    DEFAULT="$INSTALLED"
    NOTICE="Refreshing:"
  else
    PROMPT_TITLE="Install role definitions into:"
    DEFAULT="$DETECTED"
    NOTICE="Detected:"
  fi

  # Being told not to ask lands on the same answer no terminal already gives
  # itself, so the two share the branch rather than each getting one.
  if [ -z "$NONINTERACTIVE" ] && have_tty; then
    TOOLS=$(choose_tools "$DEFAULT")
  else
    TOOLS="$DEFAULT"
    echo "$NOTICE$TOOLS"
  fi
fi

# --------------------------------------------------------------- install ----

# Only symlinks are ours to replace. A real file or directory at a target path
# belongs to the user and is left alone.
#
# Every branch ends by checking the disk rather than trusting the command it
# just ran: the reported outcome is what is at $dest now, not which branch got
# there. That is what kept `linked` from being printed over an untouched
# directory.
install_one() {
  src="$1"
  dest="$2"

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

# Link every role (and skill) into one tool's directories.
sync_tool() {
  t=$1
  tool_label "$t"

  target=$(tool_dir "$t")
  mkdir -p "$target"
  for src in "$SRC_DIR"/agents/*.md; do
    install_one "$src" "$target/$(basename "$src")"
  done

  [ -d "$SRC_DIR/skills" ] || return 0
  target=$(tool_skills_dir "$t")
  mkdir -p "$target"
  for src in "$SRC_DIR"/skills/*/; do
    src=${src%/}
    install_one "$src" "$target/$(basename "$src")"
  done
}

for t in $TOOLS; do
  sync_tool "$t"
done

echo
# Written as `if` rather than `test && echo` because a failed test hands its
# status to whatever ran last, and these sit at the end: drop or reorder the
# two echoes below and a clean install would start reporting failure to the
# `curl ... | sh` that called it. `if` keeps each message's status to itself.
if [ "$CHANGED" -eq 0 ]; then
  echo "Already up to date."
fi
if [ "$MODIFIED" -gt 0 ]; then
  echo "$MODIFIED path(s) left alone because something of yours sits there."
fi
echo "Source: $SRC_DIR"
echo "Start a session in a role with:  claude --agent pm  |  opencode --agent pm"
