---
name: assign-work
description: Sends issues out to workers in waves without collisions — splits an issue one fresh context cannot finish, measures which files change together, partitions issues by disjoint target paths, batches overlapping issues to one worker, writes and validates each brief before dispatch, matches each agent's model capability to its task, and accounts for every worker until it is retired. Use when the PM is about to dispatch, assign, delegate or parallelise issues across workers, plan a wave or round, write a worker's brief, choose the model an agent runs on, handle a worker that needs files outside its issue, or decide whether to keep or retire a standing worker.
license: Apache-2.0
metadata:
  version: "0.9.0"
---

# Assign work

The PM operates every step of this, deciding what goes to which worker. **The
host owns how an agent is started, waited on, reused and ended**: load the
host's guide for those. Where this skill and a host guide decide the same
mechanism, the host wins.

## The rule

**The conflict surface is files, not topics.** Two issues may run at once
exactly when their target paths are disjoint.

- Disjoint paths → different workers, same wave.
- Overlapping paths → one worker, one dispatch, all of those issues in one
  brief, up to the bound in step 1: one owner removes the rebase churn rather
  than causing it.

## Measure coupling; do not guess it

Files that change together are one unit: an issue touching one touches the
group. Count co-changes over recent history:

```sh
git log -60 --name-only --format='format:@' | awk '
  /^@$/ { for (a in f) for (b in f) if (a < b) n[a " + " b]++; delete f; next }
  NF    { f[$0] = 1; c[$0]++ }
  END   { for (a in f) for (b in f) if (a < b) n[a " + " b]++
          for (p in n) { split(p, x, " [+] ")
            printf "%d %.2f %s\n", n[p], n[p] / (c[x[1]] + c[x[2]] - n[p]), p } }' |
  sort -rn | head -20
```

Each line: commits changing both, Jaccard (both ÷ either), the pair. The
coupled groups stand apart at the top. A file changing with everything, such
as a README, is a shared index, not a coupling.

## Running a wave

Copy and check off:

```
Wave:
- [ ] 1. Backlog passes (manage-issues); pick the issues; split any too large
- [ ] 2. Expand each issue's target paths by its coupled groups
- [ ] 3. Partition: overlap → one worker; disjoint → separate workers
- [ ] 4. Assign contested names and numbers
- [ ] 5. Write each brief
- [ ] 6. Validate each brief against its issue; fix and re-validate
- [ ] 7. Dispatch through the host's tracked protocol
- [ ] 8. Confirm each worker is working under its role
- [ ] 9. Judge each by what it produced; review each pull request as it lands
- [ ] 10. Account for every worker; retire on a trigger
```

**1. Split.** An issue a worker cannot finish in one fresh context, or that
bundles independently deliverable problems, is split first: one ran through a
chain of replacement workers.

**3. Partition.** No file belongs to two workers in one wave: two owners of one
file produce conflicting pull requests only the PM can sequence. Each worker
works in its own workspace, never the PM's base checkout. Paths the PM alone
may edit belong to no worker. Reuse the area's standing owner: its context
amortises, so its second round costs less. A batch stops at the bound in step
1; the rest waits, recorded as blocked (manage-issues). Start review and QA
fresh every time: one that has seen the area checks it against memory.
Review, not generation, bounds how many workers run: a pull request the PM
cannot yet review waits while the default branch moves under it.

**4. Contested names.** Assign at dispatch anything two workers could both
claim: branch name, issue or record number, port, migration index. Four agents
choosing their own took the same number. Give whatever the worker starts
outside its workspace — a container, an image, a scratch service, a long job —
a name carrying the issue number: a stopped worker reports none of it.

**5. The brief carries what the issue does not:**

- what changed since the issue was written, and the default branch's tip to
  start from;
- what the worker must not touch: adjacent paths another worker or the PM
  owns;
- the names and numbers assigned in step 4;
- that a check not run is reported as not run, never as passed;
- that the worker waits on its own long job for one completion signal rather
  than waking to check, since a wake after a long wait rewrites the whole
  context, and reads a long output by its tail or a filtered search, since a
  whole output is re-read every later turn;
- what ends a round that is not converging, such as the same failure
  repeating, at which the worker stops and reports: otherwise a stuck worker
  loops. The next round runs one tier up; at the top tier, re-scope the brief,
  split the issue or report to the PM instead. A round repeated unchanged meets
  the same failure;
- the model tier: one below the most capable model the host offers, lower
  where a mechanical check catches the mistakes. Only the independent reviewer,
  a design decision the pull request records, and a round after the same
  failure repeated run on the top tier: there only review would catch a weaker
  model's mistake. A standing owner changes tier only in a new round.

**6. Validate before dispatch.** Read the brief against the issue's acceptance
criteria for a contradiction, such as a criterion the "do not touch" list makes
impossible: one stopped its worker until the PM answered. Fix the brief or the
issue, then read again.

**7. Dispatch** through the host's protocol for tracked work: an untracked agent
dies invisibly. Where the host offers none, run one worker directly.

**8. Confirm the start** by something only a started, unblocked worker could
produce, such as a first commit or a message naming what it read, never by the
host reporting success: one reported start sat idle at a permission prompt.

**9. Judge by output** — commits, a pull request, a comment on the issue —
never by a heartbeat, a live terminal or silence. Wait on a worker as step 5
says, but look for output each time you return, for any reason: a pull request
sat unreviewed while the wait kept failing. Repair a stuck worker in place; a
second workspace for its area orphans the first.

## When a wave goes wrong

- **A worker needs a path outside its issue** → it stops and reports; the PM
  re-partitions, or a file is in two workers' hands.
- **Two pull requests in one wave conflict** → the partition was wrong. Fix it
  and the coupled groups it came from, not just the merge, or the next wave
  repeats the conflict.

## Retirement and accounting

Retire a standing worker on an observable trigger:

| Trigger | Because |
|---|---|
| Its context was compacted | What it remembers is a summary, possibly of stale rules. |
| A round produced nothing | The next round would command an idle agent. |
| The partition changed | It no longer owns the area it was briefed on. |

Retiring ends what the worker started: its workspace, its branch once merged or
stale, what its report names. Before releasing it, and once it stops without
reporting, find what it started by the name step 4 gave it and confirm each
removal landed: a cleanup reporting success proves no more than a start does.

Ending the PM's session can end its workers mid-task. After any restart, read
each worker's state from its workspace and pull request, never from memory: a
restarted PM reported a worker finished whose workspace showed it halfway.

A standing worker is still the PM's between waves. Close each wave with one
line per worker — issue, pull request, tier, verified or not, kept or retired
and why — where the next reader finds it, not only in a terminal.
