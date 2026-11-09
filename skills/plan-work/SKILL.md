---
name: plan-work
description: Plans the PM's work. Keeps the issue backlog small enough to schedule from (searches before filing, merges issues whose target paths overlap, closes with a reason). Keeps a standing agent per role on a pinned roster issue, each implementation role owning a disjoint scope of paths. Assigns issues to roles with a brief instead of starting an agent per issue. Use when the PM is about to file, triage, groom or close issues, choose the next round, assign or parallelise work, plan a round, write a brief, create or redraw a role, handle an agent needing paths outside its scope, or recover after a restart.
license: Apache-2.0
metadata:
  version: "1.1.0"
---

# Plan work

The PM operates every step. The product is a backlog and a roster from which
the next round can be chosen **by reading them, not by remembering them**.
**The host owns how an agent is started, waited on, reused and ended**: load
the host's guide for those. Where this skill and a host guide decide the same
mechanism, the host wins. Which model a role runs on, and how, is `run-agents`.

An issue's fields are the ones the role document lists; no issue template is
assumed. **Target paths are what a round is scheduled on.** An issue without
them cannot be placed except by re-reading its body and guessing, so it is not
ready to dispatch.

## Before filing

1. Search the open issues for the same target paths, then the same subject. A
   duplicate costs a triage; two issues on one file are a collision waiting to
   be dispatched.
2. Found one → add the new evidence to it. Do not file.
3. None → file it, with target paths. If they are unknown, read the code the
   issue is about first.

## Merging

| Two open issues | Do | Because |
|---|---|---|
| Target paths overlap | Merge into one | They cannot run in the same round. Left split, they go to two workers, collide, and one is rebased and re-reviewed. |
| One makes a claim false that the other fixes | Merge into one | A change that falsifies a claim fixes it in the same PR. Here this deadlocked: a file-count sentence only the PM may edit, falsified by a PR only a worker may write. |
| Same subject, disjoint paths | Keep both; link them | They can run in parallel; merging makes one worker do serially what two could do at once. |

To merge: keep the issue others already cite, copy the other's acceptance
criteria and target paths into it, close the other as a duplicate pointing at
the survivor. When the merged issue would be too large for one PR, or
would hold a ready issue behind one still in triage, keep both and record that
one is blocked by the other: they then never go out in the same round.

## Closing

- **Close with a reason in a comment**: done (name the PR),
  duplicate of, superseded by (name the issue), or won't do (say why).
- **Do not delete**: it destroys the record of what was asked, decided and
  rejected. Reserve it for spam or a test filed by mistake.
- Before closing as done, check the default branch's tip actually holds the
  change, and ask the host whether the PR merged: a squash merge
  leaves the branch unmerged in git's eyes.

## Backlog pass

Run before choosing a round:

```
- [ ] Every open issue names its target paths
- [ ] No two open issues share a target path, unless one is recorded as blocked by the other
- [ ] No open issue is done, duplicated or superseded
- [ ] No issue's change will falsify a claim another open issue owns
- [ ] Each issue still describes the default branch's tip, not the code it was written against
- [ ] A round can be read off: issues with pairwise-disjoint target paths
```

The pass fails if any line needs memory to answer ("I know that one is nearly
done"). Write what memory knows into the issue, then re-run it.

## Roles

A role is a code area plus a kind of work. An implementation role's agent is
reused round after round, so its context amortises.

- **Implementation roles** are split by code area. Each has a scope, the paths
  it owns, and no path is in two scopes: two owners of one file produce
  conflicting PRs only the PM can sequence. Paths only the PM edits
  are in no scope.
- **Review and QA** are fixed roles. Each task runs on a fresh agent: one that
  has seen the area checks it against memory.

Draw scopes from coupling; do not guess it. Files that change together belong
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
groups top the list. A file changing with everything, such as a README, is a
shared index, not a coupling.

## The roster

One pinned issue per project, titled `Agent roster`, records every role. Create
it once: search the open issues for that title; if none exists, file it with
this table as its body and pin it.

```
| Role | Kind | Scope | Model | Agent (worktree, terminal handle, session id) | Status |
|---|---|---|---|---|---|
| parser | implementation | src/parser/, tests/parser/ | local | <worktree>, <handle>, <id> | working #12 |
```

Update it at **every** change — a role added or removed, a scope redrawn, an
agent started, handed over or retired — in the same step: a roster one change
behind sends the next issue to the wrong agent. After any restart, read the
roster, then each agent's worktree and PR, never memory: a
restarted PM reported a worker finished whose worktree showed it halfway.

## Assigning

An issue goes to the role whose scope covers its target paths, expanded by
their coupled groups.

- **Paths span two roles** → split the issue along the scopes, or redraw the
  scopes and update the roster, before dispatch.
- **Paths in no scope** → add a role, or grow the closest role's scope; record
  either on the roster.
- **Several issues for one role** → one brief; the rest waits, recorded as
  blocked.

## Running a round

```
- [ ] 1. Pick issues; split any too large
- [ ] 2. Assign each to its role; update the roster
- [ ] 3. Assign contested names
- [ ] 4. Write each brief
- [ ] 5. Validate it against its issue
- [ ] 6. Dispatch, tracked
- [ ] 7. Confirm each start
- [ ] 8. Judge by output; review each PR
- [ ] 9. Account on the roster; retire on a trigger
```

**1. Split.** An issue an agent cannot finish in one fresh context, or that
bundles independently deliverable problems, is split first: one ran through a
chain of replacement workers.

**3. Contested names.** Assign at dispatch anything two agents could both
claim: a branch, a number, a port. Four agents choosing their own took the
same number. Give whatever an agent starts outside its worktree — a
container, a scratch service, a long job — a name carrying the issue number: a
stopped agent reports none of it.

**4. The brief carries what the issue does not:**

- what changed since the issue was written, and the default branch's tip to
  start from;
- what not to touch: other roles' scopes and the PM's paths;
- the names and numbers assigned in step 3;
- that a check not run is reported as not run, never as passed;
- that the agent waits on a long job for one completion signal and reads a
  long output by its tail: a wake rewrites the whole context, and a whole
  output is re-read every turn;
- what ends a round that is not converging, such as the same failure
  repeating: the agent stops and reports, or a stuck agent loops;
- its model, from the role (`run-agents`).

**5. Validate before dispatch.** Read the brief against the issue's acceptance
criteria for a contradiction, such as a criterion the "not to touch" list makes
impossible: one stopped its worker until the PM answered. Fix the brief or the
issue, then read again.

**6. Dispatch** through the host's protocol for tracked work: an untracked
agent dies invisibly. Where the host offers none, run one agent directly.

**7. Confirm the start** by something only a started, unblocked agent could
produce, such as a first commit or a message naming what it read, never by the
host reporting success: one reported start sat idle at a permission prompt.

**8. Judge by output** — commits, a PR, a comment on the issue —
never by a heartbeat, a live terminal or silence. Look for output each time you
return, for any reason: a PR sat unreviewed while the wait kept
failing. Repair a stuck agent in place; a second worktree for its area
orphans the first.

## When a round goes wrong

- **An agent needs a path outside its scope** → it stops and reports; the PM
  redraws the scopes and updates the roster, or a file is in two roles' hands.
- **Two PRs in one round conflict** → the scopes were wrong. Fix them
  and the coupled groups behind them, not just the merge, or the next round
  repeats the conflict.
- **The same failure repeats twice** → the next round runs on the next model
  up (`run-agents`); on Sonnet, re-scope the brief, split the issue or report
  to the PM.

## Retiring an agent

Retiring a role's agent is not removing the role. Retire on an observable
trigger: its context was compacted, so it remembers a summary, possibly of
stale rules; a round produced nothing, so the next would command an idle
agent; its scope changed, so it no longer owns what it was briefed on. A new
agent takes the role, and the roster records the handover: old handle, new
handle, trigger. A role is removed only when its scope is gone.

Retiring ends what the agent started: its worktree, its branch once merged or
stale, what its report names. Before releasing it, and once it stops without
reporting, find what it started by the name step 3 gave it and confirm each
removal landed: a cleanup reporting success proves no more than a start does.

## Accounting

Close each round with one comment on the roster issue, a line per agent —
role, issue, PR, model, verified or not, kept or retired and why —
where the next reader finds it.
