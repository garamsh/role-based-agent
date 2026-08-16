# Conventions

Rules for changing this repository. They bind every pull request here.

This project is seven files: two POSIX shell scripts that symlink role
definitions into agent config directories, three role documents, one skill,
and this. It has no build step, no toolchain, and no test harness — a check
runner was tried and removed as disproportionate. Verification is manual and
the burden is on the author to show it ran.

## Shell — `install.sh`, `uninstall.sh`

- POSIX `sh` only. No bashisms.
- `set -eu` at the top.
- Comments explain **why** a non-obvious construct is needed, never what the
  line does. A construct with no comment should be obvious; one with a comment
  should say which bug the comment is protecting against.
- `npx shellcheck -s sh install.sh uninstall.sh` is clean at default severity
  with **no exclusion list**. Suppress a false positive inline with
  `# shellcheck disable=` and a reason on the same line; fix a real finding
  instead of suppressing it.

## Invariants — do not regress these without saying so

Each of these was a filed bug. Changing one is a decision, not a detail.

- Symlinks, never copies. A single clone is the source of truth.
- `ours()` is defined in `uninstall.sh` alone. `install.sh` does not remove.
- `uninstall.sh` is the only removal path.
- `install.sh` takes no command-line flags. Configuration is by environment
  variable, because a flag through `curl … | sh` needs `sh -s --` plumbing.
- No `rm -rf` anywhere. A real file or directory at a target path is reported
  as kept, never replaced.

## Verifying a change to either script

Every test runs in a `mktemp -d` sandbox with `HOME`, `CLAUDE_CONFIG_DIR`,
`XDG_CONFIG_HOME` and `XDG_DATA_HOME` all overridden. Never touch the real
`~/.claude` or `~/.config/opencode`; checksum both before and after and show
they are unchanged. Run the scripts as a subprocess — never `source` them,
which executes a real install against your own machine.

Paste the real output into the pull request. A check you did not run is
reported as not run, never as passed.

**Pick an instrument that can only answer the question asked.** A cheap
command usually answers something adjacent, and a wrong answer looks exactly
like a right one. Six times in one session a `grep` here answered "does this
substring appear" where the question was "does this behaviour hold" — matching
`output` when searching for `tput`, counting its own command line among the
processes, and diffing two clones' output without normalising their paths.
Read `/proc` rather than grepping `ps`; compare normalised program output
rather than raw strings; run the code rather than search for it.

## Role documents — `agents/*.md`

These are system prompts. A session launches with one as its entire
instruction set, so every word is paid for on every run.

- Second person, imperative. Each rule stated once.
- Name the concrete failure after the rule that prevents it. That habit is why
  these documents produce compliance; a rule flattened into a bare instruction
  loses it.
- The YAML frontmatter is load-bearing: `install.sh` links by filename and the
  CLIs select by `name`. Do not touch it.
- They name no platform and no paths. Host-specific procedure belongs to
  whoever ships the host.
- Do not grow them. Pay for an added rule by consolidating an existing
  duplication, and list every rule before and after to show none was lost.

## Documentation

Five of the seven files are documentation, so a wrong claim is a defect here,
not a typo. Every statement in `README.md` about what the scripts do must be
true of the current code. If a change makes a sentence false, the same pull
request fixes the sentence.
