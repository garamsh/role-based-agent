---
name: manage-issues
description: Keeps a project's issue backlog small enough to schedule from — searches before filing, merges issues whose target paths overlap or that must land in one pull request, and closes stale, duplicate or finished issues with a reason instead of deleting them. Use when the PM is about to file an issue, triage findings, groom, clean up or deduplicate the backlog, or choose the next wave of work and cannot tell from the open issues which ones can run at once.
---

# Manage issues

The PM operates this; every step is the PM's. Its product is a backlog from
which the next wave can be chosen **by reading it, not by remembering it** —
the input `assign-work` schedules on.

An issue's fields are the ones the role document lists; no issue template is
assumed. What this skill adds is what those fields are for: **target paths are
what a wave is scheduled on.** An issue without them cannot be placed in a wave
except by re-reading its body and guessing, so it is not ready to dispatch.

## Before filing

1. Search the open issues for the same target paths, then for the same subject.
   A duplicate costs a triage, and two issues on one file are a collision
   waiting to be dispatched.
2. Found one → add the new evidence to it. Do not file.
3. None → file it, with target paths. If the paths are unknown, find them
   before filing: read the code the issue is about.

## Merging

| Two open issues | Do | Because |
|---|---|---|
| Target paths overlap | Merge into one | They cannot run in the same wave. Left split, they go to two workers, collide, and one is rebased and re-reviewed. |
| One makes a claim false that the other fixes | Merge into one | A change that falsifies a claim fixes it in the same pull request, so the claim's file cannot be a separate issue. Here this deadlocked: a file-count sentence only the PM may edit, falsified by a pull request only a worker may write. |
| Same subject, disjoint paths | Keep both; link them | They can run in parallel. Merging them only makes one worker do serially what two could do at once. |

To merge: keep the issue other issues and pull requests already cite, copy the
other's acceptance criteria and target paths into it, and close the other as a
duplicate pointing at the survivor.

Escape hatch: when the merged issue would be too large for one pull request,
or would hold a ready issue behind one still in triage, keep both and record
that one is blocked by the other. They then never go out in the same wave,
which is what the merge was for.

## Closing

- **Close with a reason in a comment**: done (name the pull request),
  duplicate of (name the issue), superseded by (name it), or won't do (say
  why).
- **Do not delete.** Deletion is available and destroys the record — what was
  asked, decided and rejected — that filing existed to keep. Reserve it for
  what was never a real issue: spam, or a test filed by mistake.
- Before closing as done, check the default branch's tip actually holds the
  change. A squash merge leaves the branch unmerged in git's eyes, so ask the
  forge whether the pull request merged, not git.

## Backlog pass

Run before choosing a wave. Copy and check off:

```
Backlog pass:
- [ ] Every open issue names its target paths
- [ ] No two open issues share a target path, unless one is recorded as blocked by the other
- [ ] No open issue is done, duplicated or superseded
- [ ] No issue's change will falsify a claim another open issue owns
- [ ] Each issue still describes the default branch's tip, not the code it was written against
- [ ] A wave can be read off: a set of issues with pairwise-disjoint target paths
```

The pass fails if any line needs memory to answer — "I know that one is
nearly done", "those two don't really overlap". Write what memory knows into
the issue, then re-run the pass.
