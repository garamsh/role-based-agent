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
# install.sh --uninstall removes by that same definition, from a clone.
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
# uninstall.sh is curl-piped standalone (README:42) and cannot source install.sh,
# so the two scripts carry byte-identical copies of ours() and ours_link().
# Change one, change the other; each script's header states this definition.
ours() {
  _target=$(readlink "$1") || return 1
  case "$_target" in
    */agents/*.md|*/skills/*) ;;
    *) return 1 ;;
  esac
  [ "$(basename "$_target")" = "$(basename "$1")" ] || return 1
  _root=$(dirname "$(dirname "$_target")")
  [ -d "$_root" ] || return 0         # checkout gone: the link text is all there is
  [ -f "$_root/agents/pm.md" ] && [ -f "$_root/agents/qa.md" ] &&
    [ -f "$_root/agents/worker.md" ]
}

# Prints the one link of ours sitting at $1, or fails and prints nothing.
ours_link() {
  if [ -L "$1" ]; then
    ours "$1" || return 1
    echo "$1"
    return 0
  fi
  # A real directory at a target path swallows a link aimed at it rather than
  # being replaced by it, so a run from before install.sh learned to clear the
  # path under --force can have left one nested inside, under the directory's
  # own name. Nothing else looks there.
  _nested="$1/$(basename "$1")"
  if [ ! -d "$1" ] || [ ! -L "$_nested" ]; then
    return 1
  fi
  ours "$_nested" || return 1
  echo "$_nested"
}

REMOVED=0
for t in $SUPPORTED; do
  for d in $(tool_dirs "$t"); do
    [ -d "$d" ] || continue
    for f in "$d"/*; do
      link=$(ours_link "$f") || continue
      rm "$link"
      REMOVED=$((REMOVED + 1))
      echo "  removed   $link"
    done
  done
done

if [ "$REMOVED" -eq 0 ]; then
  echo "Nothing to remove."
fi
