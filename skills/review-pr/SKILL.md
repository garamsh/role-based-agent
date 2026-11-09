---
name: review-pr
description: Reviews one PR and, on approve, merges it and confirms what landed — verifies the merge of head onto base while the review runs, judges every section of the body, re-reviews only the delta, refuses to merge when base or head moved since verification, and keeps every author of a squash. Use when the PM is about to review, re-review, approve, request changes on or merge a PR, delegate an independent reviewer, or confirm what landed.
license: Apache-2.0
metadata:
  version: "0.4.1"
---

# Review PR

The PM operates this; every step is the PM's. It holds the order of a review,
not its rules: which checks run and what may merge unverified come from what
governs the changed paths, and from `agents/pm.md` §Reviewing where nothing
does. Posting and merging are the host's; take its guide's commands. A review
procedure the project ships decides every mechanic it covers.

A **short path** applies when `git diff --shortstat` shows at most 50 changed
lines, all in documentation files (`.md`, `.txt`, `.rst`, `.adoc`): skip only
step 2's worktree and verification, and step 4. A cheaper model the host
offers may first run the mechanical checks the rules list and rank the hunks
by risk; that orders the review, excluding nothing: every changed line is
still read for scope, and the top-tier reviewer re-verifies each finding.

**Verify the tree that will land, and land only the tree verified.** One
change landed as a tree nobody had verified, because another PR
merged between verification and merge.

The git steps are `scripts/review.sh` in this skill's directory: run it with
`sh` inside the repository under review, never retyping its commands. It
exits 0 pass, 1 refused, 2 usage or git error, 3 merge conflict, and says why
on stderr.

## Running a review

Check off:

```
Review of #<n>:
[ ] 1. What governs
[ ] 2. Record; verify
[ ] 3. Conventions, diff
[ ] 4. (Optional) Independent reviewer
[ ] 5. Body
[ ] 6. Read verification's outcome; per-check result
[ ] 7. Post
[ ] 8. On approve: guard; merge, every author kept
[ ] 9. Landed
```

**1. Find what governs, and read it**, before the diff: from the project's
entry point for contributors, read at the base whatever governs the paths `git
diff --name-only <base>...<head>` lists, and the PR template if
there is one. Take from them which checks run, how to verify, and how to merge
and word the message. What you looked for and did not find goes in the review
as `unverified`: a guessed command reads like a written one.

**2. Verify early.** Fetch, then:

```sh
sh scripts/review.sh record <remote>/<base branch> <head ref>
sh scripts/review.sh worktree <base> <head> <scratch dir>
```

Exit 3 is a conflict: request changes. Start the project's verification in the
worktree in the background and review while it runs; run after, an hour-long
verification queues every review behind it. A run that ended without
its outcome line died part-way. Remove the worktree once the outcome is read.

**3. Conventions, then the diff.** Read in full what step 1 found, then
`git diff <base>...<head>`.

**4. Independent reviewer.** A reviewer delegated with a clean context finds
what the PM's reading misses: in one project, the blockers on three PRs in a row. Its brief carries the PR, base, head
and what step 1 found, not the PM's conclusion, which it would confirm, and
says it changes no checkout: it reads with `git show <head>:<path>` and
`git diff`, or in a throwaway worktree it adds and removes. One told
"read-only" checked out a branch in the base checkout. Re-verify every claim
it makes, from the files, before posting: its mistakes arrive in the same
confident register as its findings.

**5. PR body.** Judge every section the body fills: is its claim
true of the diff and the files, and is a "none" or "not applicable" justified?
Build nothing to do it with. A section whose claim you could not check is
`unverified`. Left to memory, sections such as what the author declined to
restructure were read only when remembered. A claim that a test was seen to
fail without the change is re-run in the worktree with the behaviour reverted,
or marked `unverified`; passed on the body's say-so, it is the author's check,
not the review's.

**6. Per-check result**, as `agents/pm.md` §Reviewing requires, with the
recorded head and tree beside verification. A check folded into a general
pass is how one nobody ran merges as passed.

**7. Post** through the host before merging: a merge with no posted review
leaves no record of the checks.

**8. Guard.** Where the host requires the branch to be up to date, update it
first, then run step 2 again on the new pair (in knowno every merge needed
update-branch, a tree comparison and a second CI wait). Immediately before
merging, fetch, then:

```sh
sh scripts/review.sh guard <base> <head> <remote>/<base branch> <head ref>
sh scripts/review.sh authors <base> <head> [<excluded>...]
```

Exit 1 means the base or head moved: go back to step 2, and do not merge. Pin
the host's merge to the head where it can be. The project's commit convention
decides which identities are authors: pass each it excludes, by exact email,
as `<excluded>`; with no such rule pass none, and every identity is an author.
Put every author `authors` prints into the squash message, in the form step 1
found: a squash with an empty body dropped a second author.

**9. Check what landed.** Fetch, then on the commit the base branch now
points at:

```sh
sh scripts/review.sh landed <landed commit> <tree> <base> <head> [<excluded>...]
```

Pass step 8's `<excluded>`: the commit convention decides here too which
identities must have landed. Exit 1 names the wrong tree or the missing
authors. The merge has happened; record the failure where the next reader
finds it, to be repaired. Delete the head branch only after `landed`
passes: in knowno a branch delete chained after a refused merge closed the
PR.

## Re-review after a request for changes

Read only `<old head>..<new head>` against the earlier findings — or
`git range-diff` where the branch was rebased — and check each is resolved or
rebutted. Then run step 2 again on the new pair: the old verification covered
a tree that will no longer land. Re-reading the whole diff spends the review
on what already passed.
