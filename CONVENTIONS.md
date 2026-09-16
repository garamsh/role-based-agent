# Conventions

Rules for changing this repository. They bind every pull request here.

This project is nine files: two POSIX shell scripts that install role
definitions and skills where agent tools read them, and seven documents — three
role documents, one skill, a README, the pull request template that binds every
change here, and this. It has no build step, no toolchain, and no test harness
— a check runner was tried and removed as disproportionate. Verification is
manual and the burden is on the author to show it ran: paste the real output,
and report a check you did not run as not run rather than as passed.

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

- The role documents are the source of truth. Use each tool's native format:
  Claude Code and opencode roles and all skills use symlinks; Codex roles use
  generated profiles. Refresh profiles on install, not at session launch.
- `ours()` is defined in `uninstall.sh` alone. Profile format checks occur in
  both standalone scripts; verify their update and removal decisions agree.
- `uninstall.sh` is the only installed-file removal path. The installer may
  clean up its own temporary files when staging a profile replacement.
- `install.sh` takes no command-line flags. Configuration is by environment
  variable, because a flag through `curl … | sh` needs `sh -s --` plumbing.
- No `rm -rf` anywhere. Preserve user files and directories at target paths.
  A generated Codex profile is replaceable or removable only when its marker,
  filename and checksum match. Preserve edited profiles and profile symlinks.
  Never rewrite the user's base Codex configuration.

## Verifying a change to either script

Every test runs in a `mktemp -d` sandbox with every environment variable either
script reads overridden — the names they expand and never assign, taken from
the scripts and not from a list here. A list is what hid `ROLE_AGENT_DIR`,
which `install.sh:20` reads *ahead of* `XDG_DATA_HOME`: a shell that exports it
gets a real fast-forward of its own clone past a sandbox that overrides the
other four, and nothing here says so. Never touch the real `~/.claude`,
`~/.config/opencode`, `~/.agents`, Codex config directory or that clone in a test;
run the scripts as a subprocess, never `source` them, which runs a real install
on your machine.

Bracket the run with a listing of every entry, its type and target in all
four tool trees, including configured overrides when different from defaults:

    L() { find ~/.claude ~/.config/opencode ~/.agents "${CODEX_HOME:-$HOME/.codex}" -maxdepth 2 -exec sh -c '
            for p do
              if [ -L "$p" ]; then echo "l $p -> $(readlink "$p")"
              elif [ -d "$p" ]; then echo "d $p"
              else echo "f $p"; fi
            done' sh {} + | sort; }
    L > before          # then the sandboxed run
    L > after; diff before after

Type, path and target detect created directories, changed symlinks and files
replaced with another type. A path listing alone misses a retarget, while
`ls -l` adds size and mtime that move for one appended prompt. Codex profiles
also carry content: hash every `*.config.toml` and the base `config.toml` in
the real Codex config directory before and after the test and require those
hashes unchanged. A listing alone cannot detect a profile rewritten in place.

Two levels reaches `agents/<role>.md`, `skills/<name>` and Codex profiles —
every installed path either script writes — and stops above the transcript
the verifying session writes under `~/.claude` as the
check runs. List everything at that depth, never only the paths the scripts
write: a hash of just those came back identical across a stray write to
`settings.local.json` this listing caught at once, so it is not the check.

Bracket the run tightly, and read a non-empty diff by attribution and never by
size: `~/.claude` rotates its own backups at that depth, retires a session file
when a session exits, and adds an empty `session-env/<uuid>`, each named by its
own timestamp. Name what wrote every line; anything under `agents/` or
`skills/` is the failure this check is for. Budget it in lines instead and a
reader meeting four lines of that churn fails a run that passed.

The source clone needs its own check: bracket the run with `rev-parse HEAD`
and `status --porcelain` there too, and require both unchanged. When adding
another write target, extend these checks in the same change.

**Pick an instrument that can only answer the question asked.** A cheap
command usually answers something adjacent, and a wrong answer looks exactly
like a right one. Six times in one session a `grep` here answered "does this
substring appear" where the question was "does this behaviour hold" — matching
`output` when searching for `tput`, counting its own command line among the
processes, and diffing two clones' output without normalising their paths.
Read `/proc` rather than grepping `ps`; compare normalised program output
rather than raw strings; run the code rather than search for it.

## Role documents — `agents/*.md`

These are session role instructions: system prompts for Claude Code and
opencode, developer instructions for Codex. Every word is paid for on every run.

- Second person, imperative. Each rule stated once.
- Name the concrete failure after the rule that prevents it. That habit is why
  these documents produce compliance; a rule flattened into a bare instruction
  loses it.
- The YAML frontmatter is load-bearing: Claude Code and opencode select by
  `name`. Codex profiles use the filename and omit frontmatter. Do not touch it.
- They name no platform and no paths. Host-specific procedure belongs to
  whoever ships the host.
- Do not grow them. Pay for an added rule by consolidating an existing
  duplication, and list every rule before and after to show none was lost.
  Where no consolidation exists that does not cost a named concrete
  failure, list in the pull request every candidate pair in the file and
  why each fails, and let the growth be decided rather than smuggled.
  Without the survey, "nothing pays" is indistinguishable from "I did not
  look"; without the branch, an author manufactures a consolidation out of
  a deliberate extension and deletes a named failure to buy the arithmetic.

## Skills — `skills/*/SKILL.md`

`install.sh` links these into every tool it supports, so a skill reaches every
machine a role does. It is not read like one: a role loads at session launch,
while a skill loads only when its description matches what the session is
doing. Its length is paid for when the
procedure runs, not on every session, so the budget that binds a role document
does not bind it.

- A skill is for a procedure that is occasional and that no role can afford to
  carry. One needed constantly sits unloaded at exactly the moments it applies,
  because nobody stops to ask for it by name; that belongs in a role document.
- Name the role that operates it, and keep every step inside that role's
  authority. `sync-conventions` shipped without that and no role could run it
  end to end: every step that rewrote conventions was the PM's alone, while the
  skill told its operator that merging was the PM's call.

## Documentation

A wrong claim in any of the seven documents is a defect here, not a typo, and
a change that makes a sentence false fixes it in the same pull request.

A change touching no script is most of them and owes Checks all the same.
Three, over every file it changed, each answered by the files and not by the
author, so each can come back failed:

- **The cited section still exists under that heading**, matched against the
  headings read out of the cited file rather than the one you remember.
- **Every `file:N` citation resolves** — print those lines and read them.
  `#111` cites this section by a range that had moved before it was picked up.
- **The claim is true of the current code**, read off the script it is about.
  `README.md` and this file are the two that make such claims.

All three pass by finding nothing, and a wrong pattern finds nothing too, so
each is paired with a control that must come back non-empty.
