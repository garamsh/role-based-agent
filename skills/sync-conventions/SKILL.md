---
name: sync-conventions
description: Bring a conventions template repository into this project and keep it current — first-time adoption, initial bootstrap, and later updates. Use when asked to adopt, apply, bootstrap, or update project conventions, architecture document structure, or shared GitHub templates from a template repository.
---

# Sync conventions from a template repository

One procedure covering three moments in a project's life: adopting a conventions template for the first time, bootstrapping the project on top of it, and pulling later template updates. Which one runs is decided by what the repository already has.

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
- **No remote** — ask the user for the template repository URL, then record it once:
  ```bash
  git remote add template <template-repo-url>
  ```
  The remote is the only record needed; do not write a config file for it.

Then fetch, which touches `refs/remotes/template/*` only:

```bash
git fetch template
```

Read a file without touching the worktree with `git show template/main:<path>`, and copy one verbatim with `git checkout template/main -- <path>`.

## Step 1 — Decide which mode applies

| Repository state | Mode |
|---|---|
| No convention documents yet | **Adopt**, then **Bootstrap** |
| Convention documents present, several unrelated stack files, template README still in place | **Bootstrap** only |
| Conventions present and already tailored to this project | **Update** |

Confirm the mode with the user in one sentence before making changes.

Pre-flight for every mode: `git status` is clean, and you are on a task branch, not `main`.

## Adopt — bring the template in

1. **Choose the set.** The agent contract file (`AGENTS.md` and, for Claude Code, a `CLAUDE.md` that imports it), the convention documents the project will actually enforce plus only the matching `stack-*.md`, the architecture document skeleton, and the shared GitHub templates. Skip the template's own `README.md` — the project keeps its own.
2. **Copy verbatim.** If a target directory already exists, copy only the missing subpaths; never overwrite an existing project file.
3. **Adapt the touch points.** Append missing `.gitignore` lines while keeping existing ones. Replace the CODEOWNERS placeholder with the real owner. Everything else stays verbatim.
4. **Verify.** `git status` shows only the intended paths, and no project file changed unexpectedly.
5. Continue into **Bootstrap**.

## Bootstrap — make the template this project's

1. **Identify the project.** Ask the user, or infer from existing code: purpose, primary stack, and tooling (package manager, linter, formatter, test runner).
2. **Select stack conventions.** Keep only the `stack-*.md` files matching the stack and delete the rest. If none matches, write one in the same style as the existing stack files — concise rules, no fluff.
3. **Adapt the neutral conventions.** Review every convention file that is not stack-specific and adjust whatever conflicts with the chosen stack. Do not pad them with restated content.
4. **Extend `.gitignore`** with the stack's template from the `github/gitignore` collection. Fetch the current content; do not write it from memory.
5. **Set up CI plumbing.** Create the `Makefile` and git hook configuration the CI convention describes, using the project's real commands. Add a CI workflow if the project will run automated checks.
6. **Initialize architecture documents.** Write one responsibility document per major domain, following the skeleton in the architecture README, record any initial decisions as ADRs, and fill in the index.
7. **Write the project `README.md`** — what it is, who it is for, how to run it. Structure and modules belong in the architecture documents, not here.
8. **Refresh the convention index** so its file list matches reality.
9. **Open one PR** titled `chore: bootstrap project conventions`. Merging it is the PM's call, not the operator's.

Do not invent conventions beyond the chosen stack's needs; the template defaults are the baseline.

## Update — pull a newer template version

1. `git fetch template`, then compare per file with `git diff main template/main -- <path>`.
2. Classify before adopting:

| Category | Paths | Action |
|---|---|---|
| Take verbatim | shared GitHub templates | `git checkout template/main -- <path>` |
| Compare hunks | stack-neutral convention files, `AGENTS.md` | adopt improvements, keep deliberate local changes |
| Never touch | architecture documents, `README.md`, `stack-*.md`, source | project-owned |

3. Open one PR titled `chore: sync template updates`. The body lists what was adopted, adapted, and deliberately skipped — skipped items are not re-proposed on later syncs.

## Rules

- Never adopt or update during active feature work; wait for a quiet `main`.
- A file the project deleted stays deleted. The template does not resurrect it.
- If the project has drifted far from the template, re-run the relevant Bootstrap steps instead of merging hunk by hunk.
- Report what you changed and what you deliberately skipped. Silence about a skipped file reads as coverage it did not get.
