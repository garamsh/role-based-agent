---
name: sync-conventions
description: Brings a conventions template repository into this project and keeps it current — first-time adoption, initial bootstrap, and later updates. Use when asked to adopt, apply, bootstrap, or update project conventions, architecture document structure, or shared GitHub templates from a template repository.
license: Apache-2.0
metadata:
  version: "0.2.1"
---

# Sync conventions from a template repository

One procedure for three moments: adopting a conventions template, bootstrapping the project on top of it, and pulling later updates. A step is cited as mode and number: Bootstrap 6.

The PM operates it. A user invoking the skill is the explicit instruction the PM needs to write what Bootstrap writes on top of the conventions: the `Makefile`, hooks and CI workflow (5), architecture documents and ADRs (6), the project `README.md` (7). That cover reaches no further: Step 1 confirms the mode first, and Bootstrap 9 leaves the merge to the user.

## Rules

- Everything lands via PR, never a push to `main`, and not during active feature work.
- The template is a read-only source: no merges, no shared history. The project keeps its own origin.
- Take file contents verbatim. Adapt only where the project requires it (paths, stack, ownership) and record each adaptation in the PR body.
- Take only what the project will enforce, and invent no conventions beyond the chosen stack's needs.
- The project owns its file tree. A file it deleted stays deleted until a fresh Selection takes it back; never delete or reorganize existing project files to fit the template.
- If the project has drifted far from the template, re-run the Bootstrap steps instead of merging hunk by hunk.
- Report what changed and what was deliberately skipped: silence about a skipped file reads as coverage it did not get.

## Step 0 — Find the template

```bash
git remote -v | grep '^template'
```

With no remote, ask the user for the template repository URL and record it with `git remote add template <url>`. The remote is the only record; write no config file.

Then `git fetch template`. Read a file with `git show template/main:<path>`; copy one verbatim with `git checkout template/main -- <path>`.

## Step 1 — Decide the mode

| Repository state | Mode |
|---|---|
| No convention documents yet | **Adopt**, then **Bootstrap** |
| Convention documents present, some for what the project does not use, template README still in place | **Bootstrap** only |
| Conventions present and already tailored to this project | **Update** |

Confirm the mode with the user in one sentence before changing anything; the rules the skill writes are agreed at the PR, not one at a time.

Pre-flight for every mode: `git status` is clean and you are on a task branch. Check off Bootstrap or Update:

```
Bootstrap: ☐ 1 identify ☐ 2 select ☐ 3 adapt ☐ 4 .gitignore ☐ 5 CI ☐ 6 architecture ☐ 7 README ☐ 8 index ☐ 9 verify, PR
Update:    ☐ 1 walk ☐ 2 re-select ☐ 3 classify ☐ 4 verify, PR
```

## Selection — which convention files the project keeps

Read the template's convention index, the `README.md` beside its convention files, and do what it says; never decide from a filename glob, which sees only the tiers that existed when it was written.

1. **Take each section that lists convention files** as its prose states: all of them, the one that fits, or the ones that apply. Sections this skill has never heard of included.
2. **Keep what a kept file depends on.** Where a table names a base for a file, keeping the file keeps its base.
3. **Keeping none of a section is an answer.** Write no new convention file to fill it.

A change that alters what the index selects on (the stack, the partitioning) carries the selection in the same PR. The PM makes it, not the worker whose change triggered it.

## Adopt — bring the template in

1. **Choose the set.** Everything the template ships, less the convention files Selection drops and the file describing the template itself. Nothing else is dropped or added.
2. **Copy verbatim.** Where a target directory exists, copy only the missing subpaths; never overwrite an existing project file.
3. **Adapt the touch points.** Append missing `.gitignore` lines, keeping existing ones; replace the CODEOWNERS placeholder with the real owner.
4. **Verify.** `git status` shows only the intended paths and no project file changed unexpectedly.
5. Continue into **Bootstrap**.

## Bootstrap — make the template this project's

1. **Identify the project:** purpose, primary stack and tooling, from the user or existing code.
2. **Select the convention files** by Selection, and delete the rest.
3. **Adapt the kept conventions** to the stack and tooling, without padding them with restated content.
4. **Extend `.gitignore`** with the stack's template from `github/gitignore`, fetched current, not written from memory.
5. **Set up CI plumbing:** the `Makefile` and git hook configuration the CI convention describes, with the project's real commands, and a CI workflow if it will run automated checks.
6. **Write the architecture documents:** one responsibility document per major domain following the skeleton in the template's architecture directory README, initial decisions as ADRs, and the index filled in. The architecture *convention* is a convention file, selected in step 2. Where the template supplies a set of alternatives a project can run only one of, make and record the choice as that README directs, then delete the set. No index lists it, so Selection and Update 3 never reach it: this step decides it, on whichever sync first brings it.
7. **Write the project `README.md`:** what it is, who it is for, how to run it. Structure belongs in the architecture documents.
8. **Refresh the convention index** so its tables name only the kept files.
9. **Verify** as Adopt 4 does, fix and check again, then open one PR titled `chore: bootstrap project conventions`. Merging it is the user's call: it settles the project's whole convention set at once.

## Update — pull a newer template version

1. **Walk.** `git fetch template`. For each shared path that differs, read the upstream commits, not the file's diff: inside an adapted region an upstream change looks like the adaptation. Find the project's baseline as the newest commit in `git rev-list template/main -- <path>` whose `git show <commit>:<path>` matches the project's copy, then read `git log -p <commit>..template/main -- <path>`. With no match the file is adapted: read every hunk asking whether upstream moved. Derive the baseline each sync; a recorded one goes stale.
2. **Re-select** by Selection against the fetched index: take what the project now qualifies for, drop what it no longer does. A set of alternatives is Bootstrap 6's to decide, not Selection's.
3. **Classify** by whose content the file holds, as Update 1 showed (matching an upstream commit means unadapted). Read a base's change against every file extending it.

   | Category | The file holds | Action |
   |---|---|---|
   | Take verbatim | the template's content, unadapted | `git checkout template/main -- <path>` |
   | Compare hunks | the template's content, adapted | adopt improvements and removals, keep deliberate local changes |
   | Never touch | the project's own content, whether or not the template ships that path | none |

   A file can hold both: entries in the convention index and the architecture README index are the project's selection, and the rules around them are the template's. An entry missing from either index is a selection, not a missed improvement.

   Hunt removals from upstream, since deleted text in an adapted region looks like a local addition: take the `-` lines of `git log -p --since=<D> template/main -- <path>` that `template/main` no longer holds, `<D>` being the date of the project's first commit of the file (or earlier). Delete from the project's file any such content it still carries, and adopt the removing commit whole, so the replacement arrives with the retraction.
4. **Verify** as Bootstrap 9 does, then open one PR titled `chore: sync template updates`. The body lists what was adopted, adapted, and skipped (an upstream removal kept here included); skipped items are not re-proposed.
