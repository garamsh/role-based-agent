#!/usr/bin/env sh
# Run every check this project expects, from one entry point.
#
#   ./check.sh
#
# Three sections: shellcheck over the shell scripts, guards over the blocks the
# scripts carry twice on purpose, and a behavioural suite that drives install.sh
# and uninstall.sh through the cases #22, #23 and #24 were filed for.
#
# One line per check, PASS / FAIL / SKIP, and a summary. Exits non-zero if
# anything FAILED. A SKIP -- a check whose tool is missing -- is counted and
# named in the summary rather than folded into success: a check that did not run
# has not passed.
#
# Every behavioural case runs against a throwaway HOME inside a mktemp -d
# sandbox, removed on exit however the run ends. Nothing here may reach the real
# ~/.claude or ~/.config, and the last check says whether it did.
set -eu

# shellcheck disable=SC1007 # CDPATH= prefixes cd, it is not an assignment of its own
REPO=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REAL_HOME=$HOME

PASSED=0
FAILED=0
SKIPPED=0
SKIP_NOTES=""
STATUS=0

pass() { PASSED=$((PASSED + 1)); echo "PASS  $1"; }
fail() { FAILED=$((FAILED + 1)); echo "FAIL  $1"; }
skip() {
  SKIPPED=$((SKIPPED + 1))
  SKIP_NOTES="$SKIP_NOTES  $1
"
  echo "SKIP  $1"
}

# `check LABEL cmd...` takes its verdict from cmd's exit status, and `[` is a
# command, so a condition reads as one: check "..." [ -L "$p" ]. Nothing here
# aborts the run -- a failing check must not hide the checks after it.
check() {
  _label=$1
  shift
  if "$@"; then pass "$_label"; else fail "$_label"; fi
}

check_not() {
  _label=$1
  shift
  if "$@"; then fail "$_label"; else pass "$_label"; fi
}

# What the scripts report is part of their contract, so cases assert on what was
# printed as well as on what is on disk.
said() { grep -qF -- "$2" "$1"; }

# --------------------------------------------------------------- sandbox ----

SCRATCH=""
cleanup() {
  if [ -n "$SCRATCH" ] && [ -d "$SCRATCH" ]; then rm -rf "$SCRATCH"; fi
}
trap cleanup EXIT INT TERM HUP
SCRATCH=$(mktemp -d) || { echo "error: could not create a sandbox" >&2; exit 1; }

# ------------------------------------------------------------------ lint ----

# Lint with the tool this project already assumes: install.sh carries
# `# shellcheck disable=` directives, and nobody writes one without having run
# it. The rule those directives set is the rule here -- suppress only a false
# positive, inline at the line, with its reason; fix anything real. No -e
# exclusion list: it blinds every file at once, including code nobody has
# written yet, and such a list only ever grows.
LINT=""
if command -v shellcheck >/dev/null 2>&1; then
  LINT="shellcheck"
elif command -v npx >/dev/null 2>&1; then
  LINT="npx --yes shellcheck"                # not installed here; npx fetches it
fi

# shellcheck disable=SC2086 # word splitting turns the runner into args
if [ -z "$LINT" ]; then
  skip "shellcheck: neither shellcheck nor npx is on PATH, so nothing linted"
elif ! $LINT --version >/dev/null 2>&1; then
  skip "shellcheck: '$LINT' could not run (offline?), so nothing linted"
elif $LINT -s sh "$REPO/install.sh" "$REPO/uninstall.sh" "$REPO/check.sh" \
     > "$SCRATCH/lint.log" 2>&1; then
  pass "shellcheck: install.sh, uninstall.sh, check.sh"
else
  fail "shellcheck: install.sh, uninstall.sh, check.sh"
  sed 's/^/      /' "$SCRATCH/lint.log"
fi

# ----------------------------------------------------- deliberate copies ----

# Duplication on purpose is allowed here; drift is not. uninstall.sh is
# curl-piped standalone and cannot source install.sh, so the definition of what
# counts as ours exists twice by design, and install.sh's --help repeats its own
# header's last line number. Both are correct and both rot silently -- two
# removal paths disagreeing about what is ours is exactly the failure #23 was
# filed for. Every block copied on purpose gets one assertion below. Add a copy,
# add a line.

# The copied pair runs from the comment the two scripts share to the close of
# ours_link(), the second line that is a lone `}` after it. Anchoring on the text
# rather than on line numbers is what lets either file move without false
# alarms, and is why the extraction is itself checked before it is trusted.
copied_pair() {
  awk '
    /^# A symlink is ours when its target names/ { in_block = 1 }
    in_block { print }
    in_block && /^}$/ { closed = closed + 1; if (closed == 2) exit }
  ' "$1"
}

# A silent extraction failure would compare two empty files and call it a match,
# so each copy has to look like the whole block before the two are compared.
whole_block() {
  grep -q '^ours() {$' "$1" &&
    grep -q '^ours_link() {$' "$1" &&
    [ "$(tail -n 1 "$1")" = "}" ]
}

copied_pair "$REPO/install.sh" > "$SCRATCH/pair.install"
copied_pair "$REPO/uninstall.sh" > "$SCRATCH/pair.uninstall"

check "copies: ours()/ours_link() found whole in install.sh" \
  whole_block "$SCRATCH/pair.install"
check "copies: ours()/ours_link() found whole in uninstall.sh" \
  whole_block "$SCRATCH/pair.uninstall"

if cmp -s "$SCRATCH/pair.install" "$SCRATCH/pair.uninstall"; then
  pass "copies: ours()/ours_link() byte-identical in install.sh and uninstall.sh"
else
  fail "copies: ours()/ours_link() differ -- change one, change the other"
  diff "$SCRATCH/pair.install" "$SCRATCH/pair.uninstall" | sed 's/^/      /' || true
fi

# install.sh's --help prints its own header block by line range, so the range is
# a line number that has to follow a file that grows. Read the end of it out of
# the sed command rather than repeating it here, then assert it still lands on
# the header's last line: line N is a comment and line N+1 is not.
help_range_end() {
  awk '/--help/ && /sed -n/ {
         if (match($0, /[0-9]+,[0-9]+p/)) {
           spec = substr($0, RSTART, RLENGTH)
           sub(/.*,/, "", spec)
           sub(/p$/, "", spec)
           print spec
           exit
         }
       }' "$1"
}

HELP_END=$(help_range_end "$REPO/install.sh")
if [ -z "$HELP_END" ]; then
  fail "copies: could not read the --help line range out of install.sh"
else
  _last=$(sed -n "${HELP_END}p" "$REPO/install.sh")
  _after=$(sed -n "$((HELP_END + 1))p" "$REPO/install.sh")
  case "$_last" in
    '#'*) pass "copies: --help range ends on header line $HELP_END" ;;
    *) fail "copies: --help range ends at line $HELP_END, which is not a comment: $_last" ;;
  esac
  case "$_after" in
    '#'*) fail "copies: the header runs past the --help range, at line $((HELP_END + 1)): $_after" ;;
    *) pass "copies: the header ends where the --help range does" ;;
  esac
fi

# ------------------------------------------------------------- behaviour ----

# Every case below runs the two scripts against a HOME of its own inside the
# sandbox, with every variable they read for a path overridden. That is what
# makes it safe to let them create and delete symlinks: no path they can compute
# reaches the real ~/.claude or ~/.config. A case that cannot be isolated that
# far does not belong here.

# What the real target directories hold now, recorded so the run can prove it
# left them alone. Only symlinks, and only in the four directories the scripts
# write to: that is the whole of what they create and delete, so that is where a
# hole in the isolation would show.
real_links() {
  find "$REAL_HOME/.claude/agents" "$REAL_HOME/.claude/skills" \
    "$REAL_HOME/.config/opencode/agents" "$REAL_HOME/.config/opencode/skills" \
    -type l 2>/dev/null |
    sort |
    while IFS= read -r l; do printf '%s -> %s\n' "$l" "$(readlink "$l")"; done
}
real_links > "$SCRATCH/real.before"

# The picker only appears with a controlling terminal, so cases that exercise
# the no-terminal path need one taken away. setsid is the way; where check.sh
# was started without a terminal its children inherit that and need nothing.
#
# The probe runs in a subshell on purpose. A redirection that cannot be opened
# is fatal to the shell that attempted it, so asking this question in-process
# would end the run rather than answer it.
NO_TTY=""
if ! (true < /dev/tty) 2>/dev/null; then
  NO_TTY="inherited"
elif command -v setsid >/dev/null 2>&1 && setsid -w true >/dev/null 2>&1; then
  NO_TTY="setsid"
fi

CASE=0
CASE_ROLE_DIR=""

# A fresh throwaway HOME, a disposable copy of this checkout to link from, and a
# copy of uninstall.sh outside it. Cases delete their checkout, so copying is
# not optional: the real one is never a link target and never removable. Both
# tools' config directories exist so detection never depends on what happens to
# be on this host's PATH.
new_case() {
  CASE=$((CASE + 1))
  HOME_DIR="$SCRATCH/case$CASE"
  CHECKOUT="$HOME_DIR/checkout"
  AGENTS="$HOME_DIR/.claude/agents"
  SKILLS="$HOME_DIR/.claude/skills"
  OC_AGENTS="$HOME_DIR/.config/opencode/agents"
  OC_SKILLS="$HOME_DIR/.config/opencode/skills"
  OUT="$HOME_DIR/out"
  CASE_ROLE_DIR=""
  mkdir -p "$CHECKOUT" "$HOME_DIR/.claude" "$HOME_DIR/.config/opencode"
  cp -R "$REPO/agents" "$REPO/skills" "$REPO/install.sh" "$REPO/uninstall.sh" \
    "$CHECKOUT/"
  cp "$REPO/uninstall.sh" "$HOME_DIR/uninstall.sh"
}

# env rather than export, so check.sh's own environment is never the only thing
# standing between a case and the user's home directory. env is also a program,
# which is what lets setsid below take it; a shell function it could not.
in_case() {
  env HOME="$HOME_DIR" \
    CLAUDE_CONFIG_DIR="$HOME_DIR/.claude" \
    XDG_CONFIG_HOME="$HOME_DIR/.config" \
    XDG_DATA_HOME="$HOME_DIR/.local/share" \
    ROLE_AGENT_DIR="${CASE_ROLE_DIR:-$HOME_DIR/.local/share/role-based-agent}" \
    "$@"
}

detached_in_case() {
  if [ "$NO_TTY" = "setsid" ]; then in_case setsid -w "$@"; else in_case "$@"; fi
}

# Several cases expect a non-zero exit, so the status is captured rather than
# left to abort the suite.
install_run() {
  if in_case sh "$CHECKOUT/install.sh" "$@" > "$OUT" 2>&1; then
    STATUS=0
  else
    STATUS=$?
  fi
}

uninstall_run() {
  if in_case sh "$HOME_DIR/uninstall.sh" > "$OUT" 2>&1; then STATUS=0; else STATUS=$?; fi
}

# How many symlinks stand in this case's tool directories, of ours or otherwise.
link_count() {
  find "$HOME_DIR/.claude" "$HOME_DIR/.config" -type l 2>/dev/null | wc -l
}

# #22 -- a real directory at a skill target path, with --force.
new_case
mkdir -p "$SKILLS/sync-conventions"
echo "mine" > "$SKILLS/sync-conventions/notes.md"
install_run --tool claude --force
check "#22 skill path: --force replaces a real directory" [ -L "$SKILLS/sync-conventions" ]
check "#22 skill path: the link points into the checkout" \
  [ "$(readlink "$SKILLS/sync-conventions")" = "$CHECKOUT/skills/sync-conventions" ]
check_not "#22 skill path: no link is left nested inside" \
  [ -L "$SKILLS/sync-conventions/sync-conventions" ]
check "#22 skill path: the run reports the replacement" \
  said "$OUT" "replaced  $SKILLS/sync-conventions (was a directory)"

# #22 -- a real directory at an agent target path, with --force.
new_case
mkdir -p "$AGENTS/pm.md"
echo "mine" > "$AGENTS/pm.md/notes.md"
install_run --tool claude --force
check "#22 agent path: --force replaces a real directory" [ -L "$AGENTS/pm.md" ]
check "#22 agent path: the link points into the checkout" \
  [ "$(readlink "$AGENTS/pm.md")" = "$CHECKOUT/agents/pm.md" ]
check_not "#22 agent path: no link is left nested inside" [ -L "$AGENTS/pm.md/pm.md" ]
check "#22 agent path: the run reports the replacement" \
  said "$OUT" "replaced  $AGENTS/pm.md (was a directory)"

# Without --force, both a real file and a real directory stay the user's.
new_case
mkdir -p "$AGENTS" "$SKILLS/sync-conventions"
echo "my own notes" > "$AGENTS/pm.md"
echo "my own skill" > "$SKILLS/sync-conventions/SKILL.md"
install_run --tool claude
check "no --force: exits clean" [ "$STATUS" -eq 0 ]
check_not "no --force: a real file is not turned into a link" [ -L "$AGENTS/pm.md" ]
check "no --force: the file's contents survive" \
  [ "$(cat "$AGENTS/pm.md")" = "my own notes" ]
check_not "no --force: a real directory is not turned into a link" \
  [ -L "$SKILLS/sync-conventions" ]
check "no --force: the directory's contents survive" \
  [ "$(cat "$SKILLS/sync-conventions/SKILL.md")" = "my own skill" ]
check_not "no --force: no link is left nested inside the directory" \
  [ -L "$SKILLS/sync-conventions/sync-conventions" ]
check "no --force: the kept file is named" \
  said "$OUT" "kept      $AGENTS/pm.md (your own file; --force to replace)"
check "no --force: the kept directory is named" \
  said "$OUT" "kept      $SKILLS/sync-conventions (your own directory; --force to replace)"
check "no --force: the summary counts both" \
  said "$OUT" "2 path(s) left alone because something of yours sits there."
check "no --force: the paths that were free are still linked" [ -L "$AGENTS/qa.md" ]

# #23a -- a foreign link, pointing outside any checkout, survives --uninstall.
new_case
mkdir -p "$HOME_DIR/notes"
echo "mine" > "$HOME_DIR/notes/foreign.md"
install_run --tool claude
ln -s "$HOME_DIR/notes/foreign.md" "$AGENTS/foreign.md"
install_run --uninstall --tool claude
check "#23a: a link outside any checkout survives --uninstall" [ -L "$AGENTS/foreign.md" ]
check "#23a: its target is untouched" [ -f "$HOME_DIR/notes/foreign.md" ]
check_not "#23a: our own agent links are gone" [ -e "$AGENTS/pm.md" ]
check_not "#23a: our own skill link is gone" [ -e "$SKILLS/sync-conventions" ]

# #23b -- delete the checkout first; uninstall.sh still sweeps every dangling
# link of ours. Run from outside the checkout, as the curl-piped form is.
new_case
install_run --tool claude,opencode
check "#23b: install placed eight links" [ "$(link_count)" -eq 8 ]
rm -rf "$CHECKOUT"
uninstall_run
check "#23b: uninstall.sh exits clean with the checkout gone" [ "$STATUS" -eq 0 ]
check "#23b: every dangling link of ours is removed" [ "$(link_count)" -eq 0 ]
check "#23b: it reports all eight removals" [ "$(grep -c 'removed   ' "$OUT")" -eq 8 ]

# #24 -- ROLE_AGENT_DIR is what a piped --uninstall has to go on, since the
# piped form has no clone beside it to find the role names in.
new_case
CASE_ROLE_DIR="$CHECKOUT"
install_run --tool claude
check "#24: install placed four links" [ "$(link_count)" -eq 4 ]
# shellcheck disable=SC2002 # the cat is the delivery model under test, not a useless use
if cat "$CHECKOUT/install.sh" |
  in_case sh -s -- --uninstall --tool claude > "$OUT" 2>&1; then
  STATUS=0
else
  STATUS=$?
fi
check "#24: a piped --uninstall exits clean" [ "$STATUS" -eq 0 ]
check "#24: a piped --uninstall honours ROLE_AGENT_DIR" [ "$(link_count)" -eq 0 ]

# The other half of #24: pointed at something that is not a checkout, the piped
# form has to say so rather than quietly remove nothing.
new_case
CASE_ROLE_DIR="$HOME_DIR/empty"
mkdir -p "$CASE_ROLE_DIR"
# shellcheck disable=SC2002 # the cat is the delivery model under test, not a useless use
if cat "$CHECKOUT/install.sh" |
  in_case sh -s -- --uninstall --tool claude > "$OUT" 2>&1; then
  STATUS=0
else
  STATUS=$?
fi
check "#24: a piped --uninstall with no checkout to name exits non-zero" [ "$STATUS" -ne 0 ]
check "#24: and says how to give it one" said "$OUT" "point ROLE_AGENT_DIR at one"

# Adversarial -- the link's root is on disk but is not a checkout.
new_case
mkdir -p "$HOME_DIR/lookalike/agents" "$AGENTS"
echo "not ours" > "$HOME_DIR/lookalike/agents/pm.md"
ln -s "$HOME_DIR/lookalike/agents/pm.md" "$AGENTS/pm.md"
uninstall_run
check "adversarial: a link into a tree that is not a checkout is not claimed" \
  [ -L "$AGENTS/pm.md" ]
check "adversarial: its target survives" [ -f "$HOME_DIR/lookalike/agents/pm.md" ]

# Adversarial -- the link's basename does not match its target's. The links that
# do match go, which is what makes the survivor above survival and not inaction.
new_case
install_run --tool claude
ln -s "$CHECKOUT/agents/pm.md" "$AGENTS/notes.md"
uninstall_run
check "adversarial: a link named unlike its target is not claimed" [ -L "$AGENTS/notes.md" ]
check_not "adversarial: the links that do match were removed" [ -e "$AGENTS/pm.md" ]

# Regression sweep -- the surface that must keep working while the above is fixed.
new_case
install_run --list --tool claude,opencode
check "--list: exits clean" [ "$STATUS" -eq 0 ]
check "--list: names the Claude Code target" said "$OUT" "claude  ->  $AGENTS"
check "--list: names the opencode target" said "$OUT" "opencode  ->  $OC_AGENTS"
check_not "--list: links nothing" [ -e "$AGENTS/pm.md" ]

install_run --help
check "--help: exits clean" [ "$STATUS" -eq 0 ]
check "--help: prints the header's first line" \
  said "$OUT" "Install, update, or remove role definitions"
check_not "--help: stops before the code" said "$OUT" "set -eu"
if [ -n "$HELP_END" ]; then
  # Tied to the range guard above, so --help and the header cannot drift apart.
  _expected=$(sed -n "${HELP_END}p" "$REPO/install.sh" | sed 's/^# \{0,1\}//')
  check "--help: prints through the header's last line" said "$OUT" "$_expected"
fi

install_run --tool bogus
check "--tool bogus: exits non-zero" [ "$STATUS" -ne 0 ]
check "--tool bogus: names it and lists what is supported" \
  said "$OUT" "unknown tool: bogus (supported: claude opencode)"

install_run --nope
check "unknown option: exits non-zero" [ "$STATUS" -ne 0 ]
check "unknown option: names it" said "$OUT" "unknown option: --nope"

new_case
install_run --tool claude
check "--tool claude: exits clean" [ "$STATUS" -eq 0 ]
check "--tool claude: links Claude Code" [ -L "$AGENTS/pm.md" ]
check_not "--tool claude: leaves opencode alone" [ -e "$OC_AGENTS/pm.md" ]

new_case
install_run --tool opencode
check "--tool opencode: exits clean" [ "$STATUS" -eq 0 ]
check "--tool opencode: links opencode" [ -L "$OC_AGENTS/pm.md" ]
check "--tool opencode: links its skills too" [ -L "$OC_SKILLS/sync-conventions" ]
check_not "--tool opencode: leaves Claude Code alone" [ -e "$AGENTS/pm.md" ]

new_case
install_run --tool claude,opencode
check "--tool claude,opencode: exits clean" [ "$STATUS" -eq 0 ]
check "--tool claude,opencode: links both" [ "$(link_count)" -eq 8 ]

new_case
install_run --yes
check "--yes: exits clean without a picker" [ "$STATUS" -eq 0 ]
check "--yes: says what it detected" said "$OUT" "Detected: claude opencode"
check "--yes: installs to both detected tools" [ "$(link_count)" -eq 8 ]

new_case
install_run --tool claude
check "cycle: install links four paths" [ "$(link_count)" -eq 4 ]
install_run --uninstall --tool claude
check "cycle: uninstall removes all four" [ "$(link_count)" -eq 0 ]
install_run --tool claude
check "cycle: install puts all four back" [ "$(link_count)" -eq 4 ]
install_run --tool claude
check "cycle: a repeat run reports no change" said "$OUT" "Already up to date."

if [ -z "$NO_TTY" ]; then
  skip "no tty: check.sh has a terminal and setsid is unavailable to take it away"
else
  new_case
  install_run --tool claude
  detached_install() {
    if detached_in_case sh "$CHECKOUT/install.sh" > "$OUT" 2>&1; then
      STATUS=0
    else
      STATUS=$?
    fi
  }
  detached_install
  check "no tty: a second run exits clean instead of prompting" [ "$STATUS" -eq 0 ]
  check "no tty: it refreshes the installed set in place" said "$OUT" "Refreshing: claude"
  check "no tty: it reports no change" said "$OUT" "Already up to date."
  check "no tty: the links are still there" [ "$(link_count)" -eq 4 ]
fi

# The documented delivery model, end to end: nothing on stderr. Piped, install.sh
# has no clone beside it and works from ROLE_AGENT_DIR, expecting git there -- so
# the case builds a local origin from this checkout and clones it. That keeps the
# run offline and tests the working tree rather than what happens to be committed.
if [ -z "$NO_TTY" ]; then
  skip "piped install: needs a run with no terminal, and one cannot be arranged"
elif ! command -v git >/dev/null 2>&1; then
  skip "piped install: git is not on PATH, and the piped form needs it"
else
  new_case
  CASE_ROLE_DIR="$HOME_DIR/.local/share/role-based-agent"
  if (
    mkdir -p "$HOME_DIR/origin" "$HOME_DIR/.local/share"
    cp -R "$REPO/agents" "$REPO/skills" "$REPO/install.sh" "$REPO/uninstall.sh" \
      "$HOME_DIR/origin/"
    cd "$HOME_DIR/origin"
    git init -q .
    git add -A
    git -c user.name=check -c user.email=check@localhost commit -qm checkout
    git clone -q "$HOME_DIR/origin" "$CASE_ROLE_DIR"
  ) > "$HOME_DIR/git.log" 2>&1; then
    # shellcheck disable=SC2002 # the cat is the delivery model under test
    if cat "$REPO/install.sh" | detached_in_case sh \
      > "$HOME_DIR/piped.out" 2> "$HOME_DIR/piped.err"; then
      STATUS=0
    else
      STATUS=$?
    fi
    check "piped install: exits clean" [ "$STATUS" -eq 0 ]
    check "piped install: writes nothing to stderr" \
      [ "$(wc -c < "$HOME_DIR/piped.err")" -eq 0 ]
    check "piped install: links both tools" [ "$(link_count)" -eq 8 ]
  else
    fail "piped install: could not build a local origin to clone from"
    sed 's/^/      /' "$HOME_DIR/git.log"
  fi
fi

# The isolation itself, asserted rather than asserted about.
real_links > "$SCRATCH/real.after"
if cmp -s "$SCRATCH/real.before" "$SCRATCH/real.after"; then
  pass "isolation: the real ~/.claude and ~/.config/opencode are unchanged"
else
  fail "isolation: a case reached outside the sandbox"
  diff "$SCRATCH/real.before" "$SCRATCH/real.after" | sed 's/^/      /' || true
fi

# --------------------------------------------------------------- summary ----

echo
echo "$PASSED passed, $FAILED failed, $SKIPPED skipped."
if [ "$SKIPPED" -gt 0 ]; then
  echo "Skipped checks did not run, so they did not pass:"
  printf '%s' "$SKIP_NOTES"
fi
[ "$FAILED" -eq 0 ] || exit 1
