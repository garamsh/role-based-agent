---
name: sync-conventions
description: Bring a conventions template repository into this project and keep it current — first-time adoption, initial bootstrap, and later updates. Use when asked to adopt, apply, bootstrap, or update project conventions, architecture document structure, or shared GitHub templates from a template repository.
---

# Sync conventions from a template repository

One procedure covering three moments in a project's life: adopting a conventions template for the first time, bootstrapping the project on top of it, and pulling later template updates. Which one runs is decided by what the repository already has.

The PM operates it: the conventions it rewrites are the PM's to maintain, and a user invoking the skill is the explicit instruction the PM needs to write the `Makefile`, hooks, and CI workflow Bootstrap 5 calls for.

Everything lands via pull request. Never push to `main`.

## Principles

- **The template is a read-only source.** The project keeps its own origin and history; the template remote is only a file supplier. No merges, no shared history.
- **Verbatim first.** Take file contents as-is. Modify only where the project genuinely requires it — paths, stack, ownership — and record every adaptation in the PR body.
- **Selective, not wholesale.** Take only what the project will actually enforce.
- **The project owns its file tree.** Never delete or reorganize existing project files to fit the template.

## Step 0 — Find the template

```bash
git remote -v | grep '^template'
```

- **Remote exists** — that is the template. Use it.
- **No remote** — ask the user for the template repository URL. Then record it once:
  ```bash
  git remote add template <template-repo-url>
  ```
  The remote is the only record needed; do not write a config file for it.

Then fetch, which touches `refs/remotes/template/*` only:

```bash
git fetch template
```

Read a file without touching the worktree with `git show template/main:<path>`.
Copy one verbatim with `git checkout template/main -- <path>`.

## Step 1 — Decide which mode applies

| Repository state | Mode |
|---|---|
| No convention documents yet | **Adopt**, then **Bootstrap** |
| Convention documents present, some for what the project does not use, template README still in place | **Bootstrap** only |
| Conventions present and already tailored to this project | **Update** |

Confirm the mode with the user in one sentence before making changes. That one confirmation is deliberate — the rules this skill writes or adapts are agreed at the PR, not one at a time as it works.

Pre-flight for every mode: `git status` is clean, and you are on a task branch, not `main`.

## Selection — which convention files the project keeps

Adopt, Bootstrap, and Update all answer this the same way, and none of them
answers it from a filename. Read the template's convention index — the
`README.md` sitting beside its convention files — and do what that index says.

1. **Take each section that lists convention files.** The prose around its
   table states whether the project keeps all of them, the one that fits, or
   the ones that apply. That sentence is the rule. Apply it section by
   section, sections this skill has never heard of included: a tier added
   upstream arrives carrying its own rule, so it costs no change here. Reading
   the index is the whole point — a glob over filenames sees only the tiers
   that existed when it was written.

2. **Keep what a kept file depends on.** Where a table has a column naming a
   base for a file, keeping that file keeps its base too. Never delete a file
   while something the project keeps still names it.

3. **Keeping none of a section is an answer.** Where the rule is that the ones
   that apply are kept and none applies, the project keeps none and runs on
   the sections every project keeps. Do not write a new convention file to
   fill an empty section — that manufactures a rule nobody agreed to.

Selection is not settled at bootstrap. A change that alters what the index
selects on — the project's stack, the shape it is partitioned into — carries
the selection with it, in the same pull request. It is the PM's to make: a
worker whose change triggers a selection does not make it.

## Adopt — bring the template in

1. **Choose the set.**

   - the agent contract file (`AGENTS.md` and, for Claude Code, a `CLAUDE.md` that imports it).
   - the convention index, and the convention files **Selection** keeps.
   - the skeleton for the project's *own* architecture documents: the
     directory the template reserves for responsibility documents and ADRs,
     with everything the template puts there and no content of its own.
   - the shared GitHub templates.

   Skip the template's own `README.md` — the project keeps its own.

2. **Copy verbatim.**
   If a target directory already exists, copy only the missing subpaths; never overwrite an existing project file.

3. **Adapt the touch points.**
   Append missing `.gitignore` lines while keeping existing ones.
   Replace the CODEOWNERS placeholder with the real owner.
   Everything else stays verbatim.

4. **Verify.**
   `git status` shows only the intended paths, and no project file changed unexpectedly.

5. Continue into **Bootstrap**.

## Bootstrap — make the template this project's

1. **Identify the project.**
   Ask the user, or infer from existing code: purpose, primary stack, and tooling (package manager, linter, formatter, test runner).

2. **Select the convention files.**
   Apply **Selection** above, and delete the files it does not keep.

3. **Adapt the kept conventions.**
   Review every convention file the project kept and adjust whatever conflicts with its stack or its tooling.
   Do not pad them with restated content.

4. **Extend `.gitignore`** with the stack's template from the `github/gitignore` collection.
   Fetch the current content; do not write it from memory.

5. **Set up CI plumbing.**
   Create the `Makefile` and git hook configuration the CI convention describes, using the project's real commands.
   Add a CI workflow if the project will run automated checks.

6. **Write the project's own architecture documents.**
   These are the project's: responsibility documents and ADRs, in the directory the template reserves for them.
   The architecture *convention* — the template's file naming the structure a project is partitioned into — is a convention file, selected in step 2 and not written here.
   Write one responsibility document per major domain, following the skeleton in that directory's README, record any initial decisions as ADRs, and fill in the index.

7. **Write the project `README.md`** — what it is, who it is for, how to run it.
   Structure and modules belong in the project's architecture documents, not here.

8. **Refresh the convention index** so its tables name only the files the project kept.

9. **Open one PR** titled `chore: bootstrap project conventions`.
   Merging it is the user's call: it settles the project's whole convention set at once.

Do not invent conventions beyond the chosen stack's needs; the template defaults are the baseline.

## Update — pull a newer template version

1. `git fetch template`. For every shared path that differs, read the upstream
   commits, not the file's diff: inside a region the project has adapted, an
   upstream change is indistinguishable from the adaptation, so one half of a
   coupled change is taken and the other kept as local. Walk
   `git rev-list template/main -- <path>` for the newest commit whose
   `git show <commit>:<path>` matches the project's copy — that is where the
   project last took the file — then read
   `git log -p <commit>..template/main -- <path>`. Where nothing matches, the
   project has adapted the file and only its own diff is left: read every hunk
   asking whether upstream moved, not only whether the project did. Derive this
   each sync; a recorded baseline is what puts a project on a wrong one.

2. **Re-select against the fetched index.**
   Apply **Selection** again: the template may have added a section, a file, or a base since adoption.
   Take what the project now qualifies for — a file added upstream after adoption included — and drop what it no longer qualifies for.

3. Classify before adopting:

| Category | Paths | Action |
|---|---|---|
| Take verbatim | shared GitHub templates | `git checkout template/main -- <path>` |
| Compare hunks | the agent contract file, the index's rules, the architecture skeleton the template supplies, every convention file the project keeps — the selected ones included | adopt improvements, keep deliberate local changes; read a change to a base against the files extending it |
| Never touch | the responsibility documents and ADRs the project wrote, its `README.md`, its source | the template supplies none of these |

The selected files sit under *compare*, not *never touch*, because the tier
that changes most upstream is the one an adopted project could otherwise never
follow. What that row protected is protected by the row it moved into: a
deliberate local change is kept, not overwritten.

Both indexes are split down the middle, and the row reaches only half of each.
The convention index's tables and the architecture README's index name what
this project keeps and what it has written, so an entry missing from either is
a selection, not a missed improvement. The rules around them are the
template's and compare with the rest of the row.

4. Open one PR titled `chore: sync template updates`.
   The body lists what was adopted, adapted, and deliberately skipped — skipped items are not re-proposed on later syncs.

## Rules

- Never adopt or update during active feature work; wait for a quiet `main`.
- A file the project deleted stays deleted. The template does not resurrect it; only a fresh **Selection** takes it back.
- If the project has drifted far from the template, re-run the relevant Bootstrap steps instead of merging hunk by hunk.
- Report what you changed and what you deliberately skipped. Silence about a skipped file reads as coverage it did not get.
