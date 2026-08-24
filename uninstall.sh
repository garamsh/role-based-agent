#!/usr/bin/env sh
# Remove the role-definition symlinks for Claude Code and opencode.
#
#   curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/uninstall.sh | sh
#
# Only symlinks of ours are removed: a link is ours when its target names
# <checkout>/agents/<name>.md or <checkout>/skills/<name> and the link carries
# that same <name>. The target need not still exist, so a link left dangling by
# deleting the checkout is still removed; while the checkout is on disk it has
# to still hold agents/{pm,qa,worker}.md, so a link into an unrelated tree of
# the same shape is left alone. Real files and directories are never touched.
# This is the only script that removes anything; install.sh only installs.
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

# A symlink is ours when its target names <root>/agents/<name>.md or
# <root>/skills/<name> and the link carries that same <name> -- which is how
# install.sh writes them, and nothing else does. The check is on the link text,
# not on what it resolves to, because deleting the checkout before uninstalling
# is the normal order and leaves every link of ours dangling but still named.
# While <root> is on disk it still has to look like a checkout, so a link into
# an unrelated tree that happens to share the shape is not claimed.
#
# This is the only copy: removing is this script's whole job, so nothing else
# needs the definition and no second copy can drift from it.
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

# What was covered is tracked alongside what was acted on, because a count of
# removals cannot tell "there was nothing there" from "the directories were
# never opened" -- and the second is what a CLAUDE_CONFIG_DIR or XDG_CONFIG_HOME
# set at install time and absent at uninstall time produces. Both printed
# "Nothing to remove." and exited 0, so a user could delete the checkout on the
# strength of it and strand every link this script exists to collect.
REMOVED=0
LOOKED=""
MISSING=0
for t in $SUPPORTED; do
  for d in $(tool_dirs "$t"); do
    if [ -d "$d" ]; then
      _seen=0
      for f in "$d"/*; do
        # An empty directory leaves the glob unexpanded, and that literal names
        # no entry. -e alone would also drop a dangling link of ours, which is
        # the normal state after deleting the checkout and the one thing here
        # that must always be counted.
        [ -e "$f" ] || [ -L "$f" ] || continue
        _seen=$((_seen + 1))
        ours "$f" || continue
        rm "$f"
        REMOVED=$((REMOVED + 1))
        echo "  removed   $f"
      done
      # "none ours" is safe to assert because this string is only ever printed
      # when the whole run removed nothing, so every entry counted here is one
      # ours() rejected -- someone else's link, or ours() itself being wrong.
      if [ "$_seen" -eq 0 ]; then _how="empty"; else _how="$_seen entries, none ours"; fi
    else
      _how="not there"; MISSING=$((MISSING + 1))
    fi
    LOOKED="$LOOKED    $d -- $_how
"
  done
done

# `if` rather than `test && echo`, because this sits at the end of the script
# and a failed test would hand its status to the caller: removing nothing from
# a clean machine is success and stays 0. Same reason install.sh's summary was
# rewritten in #50.
if [ "$REMOVED" -eq 0 ]; then
  echo "Nothing to remove. Looked in:"
  printf '%s' "$LOOKED"
# Not the block above widened to this run: its "none ours" holds only where the
# run removed nothing, and would be false of a directory this run just emptied.
elif [ "$MISSING" -gt 0 ]; then
  echo "$MISSING of the directories looked in were not there, so links may remain --"
  echo "  set CLAUDE_CONFIG_DIR or XDG_CONFIG_HOME as at install time and re-run."
fi
