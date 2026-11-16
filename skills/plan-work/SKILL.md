---
name: plan-work
description: Plans the PM's work. Keeps the issue backlog small enough to schedule from (searches before filing, merges issues whose target paths overlap, closes with a reason). Keeps a standing role per code area on a pinned roster issue, each implementation role owning a disjoint scope of paths. Assigns issues to roles with a brief, each issue to a fresh session briefed with the role's latest note. Use when the PM is about to file, triage, groom or close issues, choose the next round, assign or parallelise work, plan a round, write a brief, create or redraw a role, handle an agent needing paths outside its scope, recover after a restart, or retire an agent.
license: Apache-2.0
metadata:
  version: "1.8.0"
---

# Plan work

The PM operates every step. The product is a backlog and a roster from which
the next round can be chosen by reading them, not by remembering them. The host
owns how an agent is started, waited on, reused and ended: load its guide;
where it and this skill decide the same mechanism, the host wins. Model,
session and repeated-failure rules are `run-agents`.

An issue's fields are the ones the role document lists; no issue template is
assumed. Target paths are what a round is scheduled on; an issue without them
cannot be placed except by guessing, so it is not ready to dispatch.

## Roles

A role is a code area plus a kind of work.

- Implementation roles are split by code area. Each owns a scope of paths, and
  no path is in two scopes: two owners of one file produce conflicting PRs only
  the PM can sequence. Paths only the PM edits are in no scope.
- Review and QA are fixed roles, each task on a fresh agent: one that has seen
  the area checks it against memory.

Draw scopes from coupling, not guesses. Files that change together belong
to one scope. Count co-changes over recent history:

```sh
git log -60 --name-only --format='format:@' | awk '
  /^@$/ { for (a in f) for (b in f) if (a < b) n[a " + " b]++; delete f; next }
  NF    { f[$0] = 1; c[$0]++ }
  END   { for (a in f) for (b in f) if (a < b) n[a " + " b]++
          for (p in n) { split(p, x, " [+] ")
            printf "%d %.2f %s\n", n[p], n[p] / (c[x[1]] + c[x[2]] - n[p]), p } }' |
  sort -rn | head -20
```

Each line: commits changing both, Jaccard (both ÷ either), the pair; coupled
groups top the list. A file changing with everything, like a README, is an
index, not a coupling.

## The roster

One pinned issue per project, titled `Agent roster`, records every role. If no
open issue has that title, file it with this table as its body and pin it.

```
| Role | Kind | Scope | Model | Agent (worktree, agent id) |
|---|---|---|---|---|
| parser | implementation | src/parser/, tests/parser/ | Sonnet | <worktree>, <id> |
```

Update it in the same step as any role added or removed, scope redrawn, or
agent started, handed over or retired: a roster one change behind sends the
next issue to the wrong agent. Per-issue status goes in the round-close
comment, not a Status cell. After a restart, read the roster, then each
agent's worktree and PR, never memory.

## Before filing

1. Search the open issues for the same target paths, then the same subject. A
   duplicate costs a triage; two issues on one file are a collision.
2. Found one → add the new evidence to it. Do not file.
3. None → file it, with target paths. If they are unknown, read the code the
   issue is about first.

## Merging

| Two open issues | Do | Because |
|---|---|---|
| Target paths overlap | Merge into one | They cannot share a round: split, they collide and one is rebased and re-reviewed. |
| One makes a claim false that the other fixes | Merge into one | A change that falsifies a claim fixes it in the same PR; split, a PM-only edit and a worker-only PR deadlock. |
| Same subject, disjoint paths | Keep both; link them | They can run in parallel. |

To merge: keep the issue others already cite, copy the other's acceptance
criteria and target paths into it, close the other as its duplicate. When
the merged issue would be too large for one PR, or would hold a ready issue
behind one still in triage, keep both and record one as blocked by the other:
they then never go out in the same round.

## Closing

- Close with a reason in a comment: done (name the PR), duplicate of,
  superseded by (name the issue), or won't do (say why).
- Do not delete: it destroys the record of what was asked, decided and
  rejected. Delete only spam or a test filed by mistake.
- Before closing as done, check the default branch's tip holds the change and
  ask the host whether the PR merged: a squash merge leaves the branch
  unmerged in git's eyes.

## Backlog pass

Before choosing a round, answer from the issues, not memory: every open issue
names target paths and still describes the default branch's tip; none is done,
duplicated or superseded; no two share a target path unless one is recorded as
blocked by the other; no issue's change falsifies a claim another open issue
owns. An answer that needs memory ("nearly done") goes into the issue, then
re-run. A round is the issues with pairwise-disjoint target paths.

## Assigning

An issue goes to the role whose scope covers its target paths, expanded by
their coupled groups.

- Paths span two roles → split the issue along the scopes, or redraw the
  scopes and update the roster, before dispatch.
- Paths in no scope → add a role, or grow the closest role's scope; record
  either on the roster.
- Several issues for one role → one brief; the rest waits, recorded as
  blocked.

## Running a round

```
- [ ] 1. Pick issues; split any too large
- [ ] 2. Assign each to its role
- [ ] 3. Assign contested names
- [ ] 4. Write each brief
- [ ] 5. Validate it against its issue
- [ ] 6. Dispatch, tracked
- [ ] 7. Confirm each start
- [ ] 8. Judge by output; review each PR
- [ ] 9. Account in the round-close comment; retire on a trigger
```

1. **Split** an issue an agent cannot finish in one fresh context, or that
   bundles independently deliverable problems.
3. **Contested names.** Assign at dispatch anything two agents could both
   claim: a branch, a number, a port. Give whatever an agent starts outside its
   worktree, such as a container or a long job, a name carrying the issue
   number: a stopped agent reports none of it.
4. **The brief carries what the issue does not:**
   - what changed since the issue was written, and the default branch's tip to
     start from;
   - the convention files that govern the target paths, which the agent reads
     in full, and the target paths, which it reads by range; no architecture
     document or decision record the task does not name;
   - what not to touch: other roles' scopes and the PM's paths;
   - the names and numbers assigned in step 3;
   - that a check not run is reported as not run;
   - that the agent waits on a long job for one completion signal and reads a
     long output by its tail plus exit code;
   - what ends a round that is not converging, such as the same failure
     repeating: the agent stops and reports;
   - the role's latest note, to read first, and the request for a new one
     (`run-agents`);
   - its model, from `run-agents`.
5. **Validate before dispatch.** Read the brief against the issue's acceptance
   criteria for a contradiction, such as a criterion the "not to touch" list
   makes impossible. Fix it and re-read.
6. **Dispatch** through the host's protocol for tracked work: an untracked
   agent dies invisibly. Where the host offers none, run one agent directly.
7. **Confirm the start** by something only a started, unblocked agent could
   produce, such as a first commit or a message naming what it read, not by the
   host reporting success.
8. **Judge by output** (commits, a PR, a comment on the issue), not by a
   heartbeat, a live terminal or silence. Repair a stuck agent in place; a second worktree for its area
   orphans the first.
9. **Account.** Close the round with one comment on the roster issue, a line
   per agent: role, issue, PR, model, verified or not, kept or retired and why.

## When a round goes wrong

- An agent needs a path outside its scope → it stops and reports; the PM
  redraws the scopes and updates the roster, or a file is in two roles' hands.
- Two PRs in one round conflict → the scopes were wrong. Fix them and the
  coupled groups behind them, not just the merge, or the next round repeats
  the conflict.
- A wrong-direction fix, a repeated finding or a repeated failure → `run-agents`.

## Retiring an agent

Retire an agent when its issue merges or closes unmerged, at `run-agents`'
session limit, or when its scope changed, so it no longer owns what it was
briefed on. A new agent takes the role, and the roster records the handover:
old id, new id, trigger. A role is removed only when its scope is gone.

Retiring ends what the agent started: its worktree, its branch once merged or
stale, what its report names. Before releasing it, or once it stops without
reporting, find each by its step 3 name and confirm the removal landed: a
cleanup reporting success proves no more than a start does.
