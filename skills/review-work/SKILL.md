---
name: review-work
description: Reviews one pull request and, on approve, merges it and confirms what landed — reads whatever governs the changed paths before the diff, verifies the merge of head onto base while the review runs, judges every section the pull request body fills, re-reviews only the delta after a request for changes, refuses to merge when the base or head moved since verification, and keeps every author of a squash. Use when the PM is about to review, re-review, approve, request changes on or merge a pull request, delegate an independent reviewer, or confirm what a merge landed.
license: Apache-2.0
metadata:
  version: "0.1.0"
---

# Review work

The PM operates this; every step is the PM's. It holds the **order** of a
review, not its rules. Which checks run, and what may merge unverified, are the
project's: `agents/pm.md` §Reviewing says so, and supplies the standard where
the project gives none. Nothing here restates either.

**The host owns posting a review and merging**: load the host's own guide for
those and take its commands. The only commands named here are git's. Where the
project ships its own review procedure, it decides every mechanic it covers,
and this skill fills only what it leaves open — as `assign-work` defers to a
host's guide.

## The rule

**Verify the tree that will land, and land only the tree verified.** A pull
request lands as the merge of its head onto the base as it stands at merge
time, not as its head. A green run on the head alone, or on a merge with an
older base, says nothing about what lands. The landed tree is checked against
the verified one afterwards, because a merge guard that is skipped once is not
noticed until then: one project's change landed as a tree nobody had verified,
because another pull request merged between its verification and its merge.

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
- [ ] 8. On approve: merge guard, then merge keeping every author
- [ ] 9. Confirm the landed tree and authors
```

**1. Find what governs, and read it**, before the diff. Start from the
project's entry point for contributors and read, from the files at the base
rather than from memory, whatever governs the changed paths —
`git diff --name-only <base>...<head>` lists them without the diff — and the
pull request template, if there is one. From what you read, take what it says
about which checks run, the base branch, how to verify, and how to merge and
word the message.

Whatever you looked for and did not find is written into the review as
`unverified`, never guessed: a guessed merge method or verification command
reads exactly like a written one, and the review then certifies a rule nobody
wrote.

**2. Verify early.** Fetch the base and the head, then record three full
object names before reading anything else:

```sh
base=$(git rev-parse <remote>/<base branch>)
head=$(git rev-parse <the pull request's head>)
tree=$(git merge-tree --write-tree "$base" "$head")
```

`git merge-tree --write-tree` builds the merge without touching any checkout
and prints its tree. It exits 1 on a conflict, which is a request for changes
with nothing to verify; any other non-zero status is an error, not a verdict
on the pull request. To run verification on that tree, wrap it in a
commit and check it out in a throwaway worktree:

```sh
c=$(git commit-tree "$tree" -p "$base" -p "$head" -m "verify $head onto $base")
git worktree add --detach <scratch dir> "$c"
```

Start the project's verification entry point there, in the background, and
review while it runs. Verification that takes most of an hour, run after the
review, queues every review behind it. Remove the worktree once its outcome is
read. A run that ended without the outcome line its entry point prints died
part-way; it verified nothing.

**3. Conventions, then the diff.** Read in full the conventions step 1 found
for each changed path, then read `git diff "$base...$head"`. Three dots compare the head with its
merge base; two dots compare the two tips and show every change the base
gained since the branch was cut as if the pull request reverted it.

**4. Independent reviewer.** A reviewer delegated with a clean context finds
what the PM's own reading misses: in one project it was the step that found
the blockers on three pull requests in a row. Its brief carries:

- the pull request, `$base`, `$head` and what step 1 found governs it —
  not the PM's conclusion, which it would confirm;
- that it changes no checkout. It reads with `git show "$head:<path>"` and
  `git diff "$base...$head"`, or works in a throwaway worktree it adds for
  itself and removes. One reviewer told "read-only" checked out a branch in
  the base checkout, which is the PM's and holds no task branch.

Re-verify every claim it makes, from the files, before posting it. Its
findings arrive in the same confident register as its mistakes, and a claim
the PM posts is the PM's.

**5. Pull request body.** Judge every section the body fills, as part of the
review: is its claim true of the diff and the files, and is a "none" or "not
applicable" justified? Build nothing to do it with; read the body against
what you read in steps 1 and 3.

- A section whose claim you could not check is marked `unverified`. Left to
  memory, sections such as what the author declined to restructure were read
  only when the reviewer happened to remember them.
- An author's claim that a test was seen to fail without the change is re-run
  — revert the behaviour in the throwaway worktree and run the test — or
  marked `unverified`. Marked pass on the body's say-so, it is the author's
  check, not the review's.

**6. Per-check result.** Report one result per check of the standard, as
`agents/pm.md` §Reviewing requires, citations included. A check folded into
a general pass is how one nobody ran merges as passed. Write the recorded
`$head` and `$tree` beside the verification result: without them the merge
guard and the re-review have nothing to compare against.

**7. Post** through the host, in whatever form step 1's reading asks for,
before merging. A merge with no review posted leaves no record of what
was checked, and the next reader cannot tell a reviewed change from one waved
through.

**8. Merge guard.** Immediately before merging, fetch again and confirm both
are the ones verified — each line prints the name recorded in step 2:

```sh
git rev-parse <remote>/<base branch>       # equals $base
git rev-parse <the pull request's head>    # equals $head
```

Either moved → go back to step 2 on the new pair. Do not merge: the base moving
is exactly how an unverified tree landed in the rule above. Where the host's
merge can be pinned to an expected head, pin it to `$head`.

The squash message keeps every author of the squashed commits, in the form
step 1's reading gives for a message. Collect them before merging:

```sh
git log --no-merges --format='%an <%ae>%n%(trailers:key=Co-authored-by,valueonly)' "$base..$head"
```

Each distinct name it prints is an author. The trailer key matches without
regard to case. `--no-merges` leaves out a
merge the host made to bring the branch up to date, which carries no change of
anyone's. A squash given an empty body dropped a second author, and nobody saw
it until after landing.

**9. After merge.** Fetch, take the commit the base now points at, and confirm:

```sh
git rev-parse "<landed commit>^{tree}"     # equals $tree
git log -1 --format='%an <%ae>%n%(trailers:key=Co-authored-by,valueonly)' "<landed commit>"
```

The landed tree equals the verified tree, and the landed authors cover every
author step 8 collected. Either fails → report it where the next reader finds
it: the merge has already happened, and only a recorded failure gets repaired.

## Re-review after a request for changes

Read only what changed since the review, against its findings:

```sh
git merge-base --is-ancestor <old head> <new head> && git diff <old head>..<new head>
```

Where the old head is not an ancestor, the branch was rebased and
`<old head>..<new head>` mixes in the base's changes; read
`git range-diff "$base..<old head>" "<new base>..<new head>"` instead. Check
each earlier finding is resolved or rebutted, then run step 2 again on the new
pair: the old verification covered a tree that will no longer land. Re-reading
the whole diff spends the review on what already passed.
