#!/usr/bin/env sh
# Remove installed symlinks and unedited generated Codex profiles.
#
#   curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/uninstall.sh | sh
#
# Only symlinks of ours are removed: a link is ours when its target names
# <checkout>/agents/<name>.md or <checkout>/skills/<name> and the link carries
# that same <name>. A relative target is read against the link's own directory,
# so where this script is run from cannot change what it removes. The target
# need not still exist, so a link left dangling by deleting the checkout is
# still removed; while the checkout is on disk it has to still hold install.sh
# and agents/{pm,qa,worker}.md, so a link into a tool directory or any other
# tree that only shares the agents/ shape is left alone. Other files and
# directories are never touched; generated Codex profiles are recognized by
# their marker and content checksum.
# This is the only script that removes installed files.
set -eu

SUPPORTED="claude opencode codex"

die() { printf '%s\n' "error: $*" >&2; exit 1; }

# No arguments, as install.sh takes none: there is no selective removal, and an
# argument ignored here removed everything for `uninstall.sh claude` and said
# nothing about it (#136). Refused before the verdict pass below clears "$@".
[ $# -eq 0 ] || die "uninstall.sh takes no arguments (got: $1); it removes from every tool at once -- to remove one tool's files only, delete its links or generated profiles yourself"

# printf and not echo: dash's echo expands backslash sequences, and a `\c` in a
# config path cut the directory short (#138).
tool_dirs() {
  case "$1" in
    claude)   printf '%s\n' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/agents"
              printf '%s\n' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills" ;;
    opencode) printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/agents"
              printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills" ;;
    codex)    printf '%s\n' "${CODEX_HOME:-$HOME/.codex}"
              printf '%s\n' "$HOME/.agents/skills" ;;
  esac
}

# Both walks below read these directories one line per path, so a newline in
# one splits it into two that are not there: the install succeeded, this run
# reported success, and every link stayed (#138). Refused before the first
# verdict, so nothing is removed.
NL='
'
refuse_newline() {
  case "$2" in
    *"$NL"*) die "$1 contains a newline, which this script cannot walk; set it as it was at install time, or remove what install.sh wrote there yourself (nothing was removed)" ;;
  esac
}
refuse_newline CLAUDE_CONFIG_DIR "${CLAUDE_CONFIG_DIR:-}"
refuse_newline XDG_CONFIG_HOME "${XDG_CONFIG_HOME:-}"
refuse_newline CODEX_HOME "${CODEX_HOME:-}"
refuse_newline HOME "$HOME"

# A symlink is ours when its target names <root>/agents/<name>.md or
# <root>/skills/<name> and the link carries that same <name> -- which is how
# install.sh writes them, and nothing else does. The check is on the link text,
# not on what it resolves to, because deleting the checkout before uninstalling
# is the normal order and leaves every link of ours dangling but still named.
# While <root> is on disk it still has to be a checkout, so a link into an
# unrelated tree that happens to share the shape is not claimed.
#
# agents/{pm,qa,worker}.md alone is not a checkout: a tool directory has that
# shape too, from the user's own files with those names or from our role
# document links,
# which -f follows, and a foreign ~/.agents/skills/foo -> ../../.claude/skills/foo
# was claimed and deleted (#122). install.sh is what every checkout install.sh
# has linked from holds at its root -- it links from its own directory, or from
# a clone of this repository, which has carried it since the first commit --
# and nothing this project writes into a tool directory is named that. Only a
# regular file counts, so no link -- ours or anyone's -- can stand in for it.
#
# A relative target is text about the link's own directory, so it is joined to
# that directory before any line below reads it. Taken as written it was read
# against the caller's working directory instead, and the "checkout gone" line
# then claimed whatever that could not find: run from $HOME, a foreign
# ~/.claude/skills/computer-use -> ../../.agents/skills/computer-use looked for
# /home/.agents, missed, and was deleted (#97). Joining first is also what puts
# a relative link and its absolute equivalent on the same verdict, which is why
# the shape and basename tests below read the joined path and not the raw text.
#
# This is the only copy: removing is this script's whole job, so nothing else
# needs the definition and no second copy can drift from it.
ours() {
  [ -L "$1" ] || return 1
  _target=$(readlink "$1")
  case "$_target" in
    /*) ;;
    *)  _target="$(dirname "$1")/$_target" ;;
  esac
  case "$_target" in */agents/*.md|*/skills/*) ;; *) return 1 ;; esac
  [ "$(basename "$_target")" = "$(basename "$1")" ] || return 1
  _root=$(dirname "$(dirname "$_target")")
  [ -d "$_root" ] || return 0         # checkout gone: the link text is all there is
  [ -f "$_root/install.sh" ] && [ ! -L "$_root/install.sh" ] &&
    [ -f "$_root/agents/pm.md" ] && [ -f "$_root/agents/qa.md" ] &&
    [ -f "$_root/agents/worker.md" ]
}

# Keep this format check in step with install.sh. A matching marker alone
# would delete profiles the user customized after installation. Checking the
# embedded checksum needs neither the source checkout nor a separate registry.
# The checksum covers the generated region alone -- the source annotation
# through the developer_instructions line -- because Codex appends its own
# keys after it on first use (#124), and install.sh refreshes such a profile.
profile_region_end() {
  awk 'NR >= 3 && /^developer_instructions = / { print NR; exit }' "$1"
}
profile_pristine() {
  [ ! -L "$1" ] && [ -f "$1" ] || return 1
  [ "$(sed -n '1p' "$1")" = "# role-based-agent profile v1: $(basename "$1")" ] || return 1
  _profile_end=$(profile_region_end "$1")
  [ -n "$_profile_end" ] || return 1
  _profile_sum=$(sed -n "3,${_profile_end}p" "$1" | cksum)
  [ "$(sed -n '2p' "$1")" = "# cksum: $_profile_sum" ]
}

# Every verdict is taken before the first removal. ours() resolves the link's
# target, and that path can run through another link this run removes:
# ~/.claude/skills/x -> ~/.agents/skills/sync-conventions/skills/x resolves into
# the checkout and is kept while our sync-conventions link stands, and falls to
# "checkout gone" once it does not. Deciding and removing in one pass made the
# verdict turn on the order of SUPPORTED, which nothing chose (#122). "$@" is
# the one list POSIX sh has, and it holds any path whole.
set --
for t in $SUPPORTED; do
  while IFS= read -r d; do
    [ -n "$d" ] && [ -d "$d" ] || continue
    for f in "$d"/*; do
      if ours "$f"; then set -- "$@" "$f"; fi
    done
  done <<EOF
$(tool_dirs "$t")
EOF
done
claimed() {
  _claim=$1
  shift
  for _c do
    if [ "$_c" = "$_claim" ]; then return 0; fi
  done
  return 1
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
  # `for d in $(tool_dirs "$t")` split the list on every space, so one space in
  # a config path became two directories that were each "not there": the run
  # printed "Nothing to remove." over links it had never opened the directory
  # for, and exited 0 -- the exact failure the paragraph above says the count
  # exists to prevent. POSIX sh has no arrays; `read -r` off a here-document
  # keeps a line whole, where a pipeline would put REMOVED, LOOKED and MISSING
  # in a subshell and lose every count, and IFS=newline splitting would still
  # glob a path holding a `*`. A whole line is a whole path because the top of
  # this script refuses a newline in every variable tool_dirs reads; one split
  # in two stranded every link under it and still reported success (#138).
  while IFS= read -r d; do
    # tool_dirs prints nothing for a tool it does not know, and the substitution
    # below still feeds one empty line.
    [ -n "$d" ] || continue
    if [ -d "$d" ]; then
      _seen=0
      for f in "$d"/*; do
        # An empty directory leaves the glob unexpanded, and that literal names
        # no entry. -e alone would also drop a dangling link of ours, which is
        # the normal state after deleting the checkout and the one thing here
        # that must always be counted.
        [ -e "$f" ] || [ -L "$f" ] || continue
        _seen=$((_seen + 1))
        _note=""
        if [ "$t" = codex ] && [ "$d" = "${CODEX_HOME:-$HOME/.codex}" ]; then
          case "$f" in *.config.toml) ;; *) continue ;; esac
          if ! profile_pristine "$f"; then
            if [ ! -L "$f" ] && [ -f "$f" ] &&
               [ "$(sed -n '1p' "$f")" = "# role-based-agent profile v1: $(basename "$f")" ]; then
              printf '%s\n' "  kept      $f (edited profile; remove it yourself if no longer needed)"
            fi
            continue
          fi
          # A pristine region still goes whole: stripping it would leave a
          # NAME.config.toml that `codex -p NAME` loads with no role. What sits
          # below the region goes with it, and that is not always Codex's
          # bookkeeping -- a model and reasoning effort a person chose were lost
          # under a bare "removed" (#127). awk counts an unterminated last line
          # too, and reads the tail without parsing it.
          _below=$(tail -n +"$(($(profile_region_end "$f") + 1))" "$f" | awk 'END { print NR }')
          if [ "$_below" -gt 0 ]; then
            _note=" (with $_below line(s) below its generated region: settings Codex or you added)"
          fi
        else
          claimed "$f" "$@" || continue
        fi
        rm "$f"
        REMOVED=$((REMOVED + 1))
        printf '%s\n' "  removed   $f$_note"
      done
      # "none ours" is safe to assert because this string is only ever printed
      # when the whole run removed nothing, so every entry counted here is one
      # ours() rejected -- someone else's link, or ours() itself being wrong.
      if [ "$_seen" -eq 0 ]; then _how="empty"; else _how="$_seen entries, none ours"; fi
    else
      _how="not there"
      # Only the shared skill directory cannot move with a config override.
      if [ "$d" != "$HOME/.agents/skills" ]; then MISSING=$((MISSING + 1)); fi
    fi
    LOOKED="$LOOKED    $d -- $_how
"
  done <<EOF
$(tool_dirs "$t")
EOF
done

# `if` rather than `test && echo`, because these sit at the end of the script
# and a failed test would hand its status to the caller: removing nothing from
# a clean machine is success and stays 0. Same reason install.sh's summary was
# rewritten in #50.
if [ "$REMOVED" -eq 0 ]; then
  echo "Nothing to remove. Looked in:"
  printf '%s' "$LOOKED"
fi
# Its own `if` and not an `elif` on the block above: a directory that was never
# opened is itself a reason nothing was removed, so REMOVED -eq 0 is the case
# this advice exists for and an `elif` under it could never reach that case. In
# #100 it did not: the run printed "Nothing to remove." over eight live links
# and never said why (#107).
#
# Still a message of its own rather than the block above widened to every run:
# that block's "none ours" holds only where the run removed nothing, and would
# be false of a directory this run just emptied.
if [ "$MISSING" -gt 0 ]; then
  echo "$MISSING of the directories looked in were not there, so installed files may remain --"
  echo "  set CLAUDE_CONFIG_DIR, XDG_CONFIG_HOME and CODEX_HOME as at install time and re-run."
fi
