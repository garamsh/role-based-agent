---
name: review-work
description: Reviews one pull request and, on approve, merges it and confirms what landed — reads whatever governs the changed paths before the diff, verifies the merge of head onto base while the review runs, judges every section the pull request body fills, re-reviews only the delta after a request for changes, refuses to merge when the base or head moved since verification, and keeps every author of a squash. Use when the PM is about to review, re-review, approve, request changes on or merge a pull request, delegate an independent reviewer, or confirm what a merge landed.
license: Apache-2.0
metadata:
  version: "0.3.0"
---

# Review work

The PM operates this; every step is the PM's. It holds the review order, not
its rules: which checks run, and what may merge unverified, come from whatever
governs the changed paths, and from `agents/pm.md` §Reviewing where nothing
does. The project's review procedure decides every mechanic it covers.

A **short path** skips the verification worktree and independent reviewer for safe changes: when `git diff --shortstat` shows ≤50 lines across files that are all documentation (`.md`, `.txt`, `.rst`, `.adoc`). The `review.sh` guard, authors, landed, and a result per check remain. A cheaper model the host offers may make a first pass — run the mechanical checks the rules list, rank the hunks by risk, then the review — and the top-tier reviewer re-verifies each finding it reports.

**Verify the tree that will land, and land only the tree verified.** One change landed as a tree nobody had verified, when another pull request merged between verification and merge.

The git steps are `scripts/review.sh`. Run it with `sh` from inside the repository, and do not retype its commands. It exits 0 pass, 1 refused, 2 usage or git error, 3 merge conflict, and says why on stderr.

## Running a review

Copy and check off:

```
Review of #<n>:
- [ ] 1. Find what governs, and read it
- [ ] 2. Record base, head and merge tree; start verification on that tree
- [ ] 3. Read the governing conventions, then the diff
- [ ] 4. (Optional) Delegate an independent reviewer; re-verify each claim
- [ ] 5. Judge every section the pull request body fills
- [ ] 6. Read verification's outcome; report a result per check
- [ ] 7. Post the review through the host
- [ ] 8. On approve: guard, then merge keeping every author
- [ ] 9. Check what landed
```

**1. Find what governs, and read it**, before the diff: from the project's entry point for contributors, read at the base whatever governs the paths `git diff --name-only <base>...<head>` lists, and the pull request template. Take from them which checks run, how to verify, and how to merge and word the message. What you did not find goes in the review as `unverified`: a guessed command reads like a written one.

**2. Verify early.** Fetch, then:

```sh
sh scripts/review.sh record <remote>/<base branch> <head ref>
```

The **full path** also runs a verification worktree and starts its verification in the background; review while it runs. A run that ends without its outcome line died part-way. Exit 3 is a conflict: request changes. Remove the worktree once the outcome is read. The short path skips the worktree and the verification run.

**3. Conventions, then the diff.** Read in full what step 1 found, then
`git diff <base>...<head>`.

**4. Independent reviewer.** An independent reviewer finds what the PM misses. Its brief carries the PR, base, head, and what step 1 found — not the PM's conclusion, which it would confirm — and the rule to stay read-only: use `git show <head>:<path>` and `git diff`, never a checkout in the base repo. One told "read-only" checked out a branch in the base checkout. Re-verify every claim from the files before posting it: its mistakes arrive in the same confident register as its findings. The short path skips this step.

**5. Pull request body.** Judge every section the body fills, as part of the review: is its claim true of the diff and the files, and is a "none" or "not applicable" justified? A section whose claim you could not check is `unverified`. Left to memory, what the author declined to restructure was read only when the reviewer happened to remember it. A claim that a test was seen to fail without the change is re-run in the worktree with the behaviour reverted, or marked `unverified`; passed on its say-so, it is the author's check, not the review's.

**6. Per-check result**, as `agents/pm.md` §Reviewing requires, with the recorded head and tree. A check folded into a general pass is how unverified merges pass.

**7. Post** through the host before merging: a merge with no posted review leaves no record of what was checked.

**8. Guard.** Immediately before merging, fetch, then:

```sh
sh scripts/review.sh guard <base> <head> <remote>/<base branch> <head ref>
sh scripts/review.sh authors <base> <head> [<excluded>...]
```

Exit 1 means the base or head moved: go back to step 2, and do not merge. Pin the host's merge to the head. The commit convention decides which identities are authors: pass each one it excludes by its exact email as `<excluded>`; with no such rule pass none, and every identity is an author. Put every author `authors` prints into the squash message, in the form step 1 found: a squash with an empty body dropped a second author.

**9. Check what landed.** Fetch, then on the commit the base branch now
points at:

```sh
sh scripts/review.sh landed <landed commit> <tree> <base> <head> [<excluded>...]
```

Pass the same `<excluded>` as step 8, so the commit convention decides here
too which identities must have landed. Exit 1 names the wrong tree or the
missing authors. The merge happened; record the failure where the next reader
finds it, so it gets repaired.

## Re-review after a request for changes

Read only `<old head>..<new head>` against the earlier findings — or
`git range-diff` where the branch was rebased — and check each finding is
resolved or rebutted. Then run step 2 again on the new pair: the old
verification covered a tree that will no longer land. Re-reading the whole
diff spends the review on what already passed.
