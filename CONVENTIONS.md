# Conventions

Rules for changing this repository. They bind every pull request here.

This project is two POSIX shell scripts that install role documents and skills
where agent tools read them, and the documents themselves: a role document per
role, a skill per procedure and the POSIX shell script a skill may bundle,
a README, the pull request template that binds
every change here, the licence they are published under, and this. Those are
the kinds it has. A file of another kind is the user's decision, and the PM
lists it here in the same change that admits it, because the pull request
adding it is a worker's and this file is not theirs to edit. Leaving the list
behind is how it was already wrong once: #58 met "seven" against a repository
of nine, and naming kinds in place of a count did not end it — a licence is a
kind, and the list had to be opened for it. It has no build step, no toolchain,
and no test harness — a check runner was tried and removed as disproportionate.
Verification is manual and the burden is on the author to show it ran: paste
the real output, and report a check you did not run as not run rather than as
passed.

## Shell — `install.sh`, `uninstall.sh`, `skills/*/scripts/*.sh`

- POSIX `sh` only. No bashisms.
- `set -eu` at the top.
- Comments explain **why** a non-obvious construct is needed, never what the
  line does. A construct with no comment should be obvious; one with a comment
  should say which bug the comment is protecting against.
- `npx shellcheck -s sh <script>` is clean at default severity
  with **no exclusion list**. Suppress a false positive inline with
  `# shellcheck disable=` and a reason on the same line; fix a real finding
  instead of suppressing it.
- A skill's script is tested in a `mktemp -d` repository, each refusal run
  beside the pass it guards; §Verifying a change to either script binds the
  installers alone.

## Invariants — do not regress these without saying so

Each of these was a filed bug. Changing one is a decision, not a detail.

- The role documents are the source of truth. Use each tool's native format:
  Claude Code and opencode roles and all skills use symlinks; Codex roles use
  generated profiles. Refresh profiles on install, not at session launch.
- `ours()` is defined in `uninstall.sh` alone. Profile format checks occur in
  both standalone scripts; verify their update and removal decisions agree.
- Every link's removal verdict is taken before the first removal, so the order
  of `SUPPORTED` cannot change one. Deciding and removing in one pass made a
  foreign link's fate depend on which tool directory was walked first. A
  profile's verdict reads only that file's own bytes, so it is taken in place.
- `uninstall.sh` is the only installed-file removal path. The installer may
  clean up its own temporary files when staging a profile replacement.
- `install.sh` takes no command-line flags. Configuration is by environment
  variable, because a flag through `curl … | sh` needs `sh -s --` plumbing.
- No `rm -rf` anywhere. Preserve at target paths whatever the user put there:
  files, directories, and any link other than the one a run would write.
  A generated Codex profile is replaceable or removable only when its marker,
  filename and the checksum of its generated region match; a profile whose
  region is unedited is removed whole, with anything written below it.
  Preserve edited profiles and profile symlinks.
  Never rewrite the user's base Codex configuration.

## Verifying a change to either script

Every test runs in a `mktemp -d` sandbox with every environment variable either
script reads overridden — the names they expand and never assign, taken from
the scripts and not from a list here. A list is what hid `ROLE_AGENT_DIR`,
which `install.sh:20` reads *ahead of* `XDG_DATA_HOME`: a shell that exports it
gets a real fast-forward of its own clone past a sandbox that overrides the
others, and nothing here says so. Never touch the real `~/.claude`,
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
- Write it to the skill-authoring guide the tools that read skills publish,
  found and read rather than remembered: their limits on the name and the
  description, and the structure they ask for in place of prose. Keeping a copy
  of that guide here is the mistake `orca-dispatch` was reverted for one layer
  down — a static summary of someone else's interface.
- Name it the way the skills already here are named, so one collection does not
  mix forms.
- Verify it with the specification's own validator rather than a check written
  for the occasion — `uvx --from skills-ref agentskills validate <dir>`. #169
  hand-wrote a frontmatter check because this host has no PyYAML, and a control
  nobody else can re-run is worth less than one they can.
- A tool's own validator runs **beside** that one and never instead. One passed
  a skill whose frontmatter keys were misspelled and whose `name` did not match
  its directory — both forbidden by the specification, both caught by its
  validator — so a licence field that did nothing would have shipped. And that
  validator is itself looser than the specification in one place, accepting an
  unquoted `metadata` value where the map holds strings, so passing it is not
  being correct either.
- A change to a skill's instructions bumps its `metadata.version` in the same
  pull request: the third number where only the wording moved, the second where
  a step or a rule's scope did, the first where someone following the old
  version would now be wrong. These skills ship together, so the version earns
  its place only by moving when the skill does; one that stops moving is the
  wrong claim §Documentation already treats as a defect.

## Documentation

A wrong claim in any document here is a defect, not a typo, and a change that
makes a sentence false fixes it in the same pull request.

A change touching no script is most of them and owes Checks all the same.
Three, over every file it changed, each answered by the files and not by the
author, so each can come back failed:

- **The cited section still exists under that heading**, matched against the
  headings read out of the cited file rather than the one you remember.
- **Every `file:N` citation resolves** — print those lines and read them.
  `#111` cites this section by a range that had moved before it was picked up.
  A commit is cited by its full object name, in a file and in a commit message
  alike. A prefix resolves only while nothing collides with it, and six
  seven-character citations of another repository's commits already sit in this
  history, where no rewrite reaches them; they resolve because that repository
  is small. In `github/docs` seven characters return 422 for a commit whose
  eighth resolves. Issues, pull requests and comments can be edited, so this
  binds the record that cannot be.
- **The claim is true of the current code**, read off the script it is about.
  `README.md` and this file are the two that make such claims.

All three pass by finding nothing, and a wrong pattern finds nothing too, so
each is paired with a control that must come back non-empty.
