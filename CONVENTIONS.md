# Conventions

Rules for changing this repository. They bind every pull request here.

This project is nine files: two POSIX shell scripts that symlink role
definitions into agent config directories, and seven documents — three role
documents, one skill, a README, the pull request template that binds every
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

- Symlinks, never copies. A single clone is the source of truth.
- `ours()` is defined in `uninstall.sh` alone. `install.sh` does not remove.
- `uninstall.sh` is the only removal path.
- `install.sh` takes no command-line flags. Configuration is by environment
  variable, because a flag through `curl … | sh` needs `sh -s --` plumbing.
- No `rm -rf` anywhere. A real file or directory at a target path is reported
  as kept, never replaced.

## Verifying a change to either script

Every test runs in a `mktemp -d` sandbox with every environment variable either
script reads overridden — the names they expand and never assign, taken from
the scripts and not from a list here. A list is what hid `ROLE_AGENT_DIR`,
which `install.sh:20` reads *ahead of* `XDG_DATA_HOME`: a shell that exports it
gets a real fast-forward of its own clone past a sandbox that overrides the
other four, and nothing here says so. Never touch the real `~/.claude`,
`~/.config/opencode` or that clone; run the scripts as a subprocess, never
`source` them, which runs a real install on your machine.

Show all three untouched. The two config trees hold only directories and
symlinks, so bracket the run with a listing of every entry, its type and target:

    L() { find ~/.claude ~/.config/opencode -maxdepth 2 -exec sh -c '
            for p do
              if [ -L "$p" ]; then echo "l $p -> $(readlink "$p")"
              elif [ -d "$p" ]; then echo "d $p"
              else echo "f $p"; fi
            done' sh {} + | sort; }
    L > before          # then the sandboxed run
    L > after; diff before after

Type, path and target are what these scripts move there and all they move: each
creates a directory, or creates, retargets or removes a symlink, and every one
of those moves a line — a link written over a real file turns its `f` into an
`l`. The line carries those three and nothing else: a path listing alone misses
the retarget `ln -sfn` does on every re-run, `ls -l` adds size and mtime that
move for one appended prompt, and `find -printf` is GNU-only.

Two levels is derived, not picked: it reaches `agents/<role>.md` and
`skills/<name>` under both roots — every path either script links — and stops
above the transcript the verifying session writes under `~/.claude` as the
check runs. List everything at that depth, never only the paths the scripts
write: a hash of just those came back identical across a stray write to
`settings.local.json` this listing caught at once, so it is not the check.

Bracket the run tightly, and read a non-empty diff by attribution and never by
size: `~/.claude` rotates its own backups at that depth, retires a session file
when a session exits, and adds an empty `session-env/<uuid>`, each named by its
own timestamp. Name what wrote every line; anything under `agents/` or
`skills/` is the failure this check is for. Budget it in lines instead and a
reader meeting four lines of that churn fails a run that passed.

It is a listing and not a content hash, so it cannot see a file rewritten in
place — and `git clone` and `git pull` rewrite a whole tree, the clone. Git
hashes that one itself: bracket the run with `rev-parse HEAD` and
`status --porcelain` there too, and require both unchanged. Give either script
a write outside git's reach, and this check must be replaced in the same change.

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
  Where no consolidation exists that does not cost a named concrete
  failure, list in the pull request every candidate pair in the file and
  why each fails, and let the growth be decided rather than smuggled.
  Without the survey, "nothing pays" is indistinguishable from "I did not
  look"; without the branch, an author manufactures a consolidation out of
  a deliberate extension and deletes a named failure to buy the arithmetic.

## Skills — `skills/*/SKILL.md`

`install.sh` links these into the same tools as the roles, so a skill reaches
every machine a role does. It is not read like one: a role is the whole system
prompt, while a skill loads only when its description matches what the session
is doing. Its length is paid for when the procedure runs, not on every session,
so the budget that binds a role document does not bind it.

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
