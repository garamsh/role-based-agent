# Conventions

Rules for changing this repository. They bind every pull request here.

The project has these kinds of file: two POSIX shell installers, a role
document per role, a skill per procedure and the POSIX shell script a skill
may bundle, a README, the pull request template, the licence, and this. A file
of another kind is the user's decision; the PM lists it here in the change that
admits it, since this file is not a worker's to edit (#58 found the list
already wrong). There is no build step and no test harness (a check runner was tried and
removed as disproportionate). Verification is
manual: paste the real output, and report a check you did not run as not run.

## Shell — `install.sh`, `uninstall.sh`, `skills/*/scripts/*.sh`

- POSIX `sh` only, `set -eu` at the top.
- Comments say **why** a non-obvious construct exists, naming the bug it
  guards against, never what the line does.
- `npx shellcheck -s sh <script>` is clean at default severity with **no
  exclusion list**. Suppress a false positive inline with a reason; fix a real
  finding.
- A skill's script is tested in a `mktemp -d` repository, each refusal run
  beside the pass it guards; §Verifying a change to either script binds the
  installers alone.

## Invariants — do not regress these without saying so

Each was a filed bug. Changing one is a decision, not a detail.

- The role documents are the source of truth, in each tool's native format:
  symlinks for Claude Code and opencode roles and for all skills, generated
  profiles for Codex roles. Refresh profiles on install, not at session launch.
- `ours()` lives in `uninstall.sh` alone. Both scripts check profile format;
  their update and removal decisions must agree.
- Every link's removal verdict is taken before the first removal, so the order
  of `SUPPORTED` cannot change one. A profile's verdict reads only its own
  bytes, so it is taken in place.
- `uninstall.sh` is the only path that removes installed files. The installer
  may clean up its own temporary files while staging a profile.
- `install.sh` takes no flags; configuration is by environment variable,
  because a flag through `curl … | sh` needs `sh -s --` plumbing.
- No `rm -rf`. Preserve whatever the user put at a target path: files,
  directories, and any link other than the one a run writes. A Codex profile is
  replaced or removed only when its marker, filename and generated-region
  checksum match; an unedited one is removed whole, with anything below it.
  Preserve edited profiles and profile symlinks. Never rewrite the user's base
  Codex configuration.

## Verifying a change to either script

Run every test in a `mktemp -d` sandbox, overriding every environment variable
either script reads, taken from the scripts rather than from a list:
a list once missed `ROLE_AGENT_DIR`, which `install.sh` reads ahead of
`XDG_DATA_HOME`, and a test fast-forwarded the real clone. Never touch the
real `~/.claude`, `~/.config/opencode`, `~/.agents`, Codex config directory or
that clone; run the scripts as a subprocess, never `source` them.

Bracket the run with a listing of every entry's type, path and target, two
levels deep, in all four tool trees (with configured overrides):

    L() { find ~/.claude ~/.config/opencode ~/.agents "${CODEX_HOME:-$HOME/.codex}" -maxdepth 2 -exec sh -c '
            for p do
              if [ -L "$p" ]; then echo "l $p -> $(readlink "$p")"
              elif [ -d "$p" ]; then echo "d $p"
              else echo "f $p"; fi
            done' sh {} + | sort; }
    L > before          # then the sandboxed run
    L > after; diff before after

List everything at that depth, not only the paths the scripts write: a hash of
just those missed a stray write to `settings.local.json`. Also hash every
`*.config.toml` and the base `config.toml` in the real Codex directory, since
a listing cannot see a profile rewritten in place, and require `rev-parse HEAD`
and `status --porcelain` unchanged in the source clone. A new write target
extends these checks in the same change.

Read a non-empty diff by attribution, not size: `~/.claude` rotates backups,
retires session files and adds `session-env/<uuid>` on its own. Name what
wrote each line; anything under `agents/` or `skills/` is the failure.

**Pick an instrument that can only answer the question asked.** A `grep` for a
substring is not a test of behaviour: it matched `output` for `tput` and
counted its own command line among processes. Read `/proc` rather than grep
`ps`, normalise output before comparing, and run the code rather than search
it.

## Role documents — `agents/*.md`

System prompts for Claude Code and opencode, developer instructions for Codex.
Every word is paid for on every run.

- Second person, imperative. Each rule stated once.
- Name the concrete failure after the rule that prevents it; a rule flattened
  into a bare instruction loses its compliance.
- The YAML frontmatter is load-bearing: Claude Code and opencode select by
  `name`; Codex profiles use the filename. Do not touch it.
- They name no platform and no paths.
- Do not grow them. Pay for an added rule by consolidating a duplication, and
  list every rule before and after. Where no consolidation avoids losing a
  named failure, list every candidate pair and why each fails, and let the
  growth be decided: without the survey, "nothing pays" reads the same as "I
  did not look".

## Skills — `skills/*/SKILL.md`

A skill loads only when its description matches the task, so its length is
paid when it runs, not every session.

- A skill is for an occasional procedure. One needed constantly sits unloaded
  when it applies; that belongs in a role document.
- Name the role that operates it, and keep every step inside that role's
  authority: `sync-conventions` once told its operator to do the PM's work.
- Write it to the skill-authoring guide the tools publish, read rather than
  remembered; keep no copy of it here.
- Name it as the skills here are named.
- Validate with `uvx --from skills-ref agentskills validate <dir>`, not a
  check written for the occasion that nobody else can re-run. Where a
  tool ships its own validator that accepts a skill directory, run it beside,
  never instead; where none does, say so.
- A change to a skill bumps its `metadata.version` in the same pull request:
  third number for wording, second for a step or a rule's scope, first where
  following the old version would now be wrong.

## Documentation

A wrong claim in any document here is a defect, fixed in the same pull request
that makes it false. Every change owes three checks over the files it changed,
each answered by the files, not the author:

- **A cited section still exists under that heading**, read from the cited
  file.
- **Every `file:N` citation resolves**: print the lines and read them. A
  commit is cited by its full object name, in files and commit messages alike;
  a short prefix stops resolving once another object shares it.
- **A claim is true of the current code**, read off the script it is about.

All three pass by finding nothing, and so does a wrong pattern: pair each with
a control that must come back non-empty.
