---
name: assign-work
description: Sends issues out to workers in waves without collisions — measures which files change together, partitions issues by disjoint target paths, batches overlapping issues to one worker, writes and validates each brief before dispatch, matches each agent's model capability to its task, and accounts for every worker until it is retired. Use when the PM is about to dispatch, assign, delegate or parallelise issues across workers, plan a wave or round, write a worker's brief, choose the model an agent runs on, handle a worker that needs files outside its issue, or decide whether to keep or retire a standing worker.
license: Apache-2.0
metadata:
  version: "0.3.0"
---

# Assign work

The PM operates this; every step is the PM's. It decides what goes to which
worker. **The host owns how an agent is started, waited on, reused and
ended**: load the host's own guide for those and take its commands. Where this
skill and a host guide decide the same mechanism, the host wins.

## The rule

**The conflict surface is files, not topics.** Two issues may run at once
exactly when their target paths are disjoint.

- Disjoint paths → different workers, same wave.
- Overlapping paths → one worker, one dispatch, all of those issues in one
  brief.

The second branch is where several issues at once belongs. Overlapping issues
cannot be parallelised, so batching them to one owner removes the rebase churn
rather than causing it.

Parallelism is real and bounded. Measured on the 60 commits of the repository
this skill ships from: a third of commit pairs conflict on a file, and 25
changes needed 10 waves, the widest 6.

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
coupled groups stand apart at the top. In the repository above they were the
two installer scripts (0.43), the PM and worker role documents (0.45), and the
README with the installer (0.39); everything below fell under 0.35.

A file that changes with everything (the README: 24 of 60 commits) is a shared
index, not a coupling. Treating such files as PM-owned moved 10 waves to 9;
coupled groups set the rest. Build nothing special for the index case.

## Running a wave

Copy and check off:

```
Wave:
- [ ] 1. Backlog passes (manage-issues); pick the issues
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

**3. Partition.** No file belongs to two workers in one wave: two owners of one
file produce conflicting pull requests only the PM can sequence. Each worker
works in its own workspace, never the base checkout — that is the PM's.
Paths the PM alone may edit belong to no worker. Reuse the area's standing
owner: its context amortises, so its second round costs less than its first.
Start review and QA fresh every time: freshness is their product, and one that
has seen the area checks it against memory.
Disjoint partitions bound how many workers can run at once; how many pull
requests the PM can actually review bounds how many should. Review, not
generation, limits throughput: a worker past that bound produces a pull
request that waits unreviewed while the default branch moves under it.

**4. Contested names.** Assign at dispatch anything two workers could both
claim: branch name, issue or record number, port, migration index. A worker
choosing its own sees only what has landed — four agents dispatched minutes
apart all took the same number.

**5. The brief carries what the issue does not:**

- what changed since the issue was written, and the default branch's tip to
  start from;
- what the worker must not touch — the adjacent paths owned by another worker
  or by the PM, named so they need not be inferred;
- the names and numbers assigned in step 4;
- that a check not run is reported as not run, never as passed;
- what ends the round when the work is not converging — a condition the PM
  sets, such as the same failure repeating — at which the worker stops and
  reports. Without one, a stuck worker loops on its failure instead of
  reporting it. The next round of that work runs one capability tier up,
  never again on the same model: a repeat meets the same failure;
- the model tier, chosen by who catches the agent's mistake, not by the task's
  size. A smaller model fits work a mechanical check catches: a search that
  returns a conclusion, a test or build run that reports output, a fully
  specified mechanical edit. The independent reviewer, design-bearing
  implementation, debugging and wording whose sentences change behaviour stay
  on the most capable model the host offers: there a weaker model's mistake
  lands in review, the bottleneck step 3 names. A standing owner changes tier
  only in a new round, so reusing it never conflicts with escalating.
  Recorded, the tier lets the accounting say which tier did what; left
  unchosen, every agent runs on the costliest model whatever its task.

**6. Validate before dispatch.** Read the brief against the issue's own
acceptance criteria and look for a contradiction: a subject one rule requires
and another forbids, a criterion the "do not touch" list makes impossible. A
brief whose required subjects were forbidden by another of its own rules
stopped its worker until the PM answered. Found one → fix the brief or the
issue, then read again.

**7. Dispatch.** Use the host's protocol for tracked work: an agent nothing
tracks reports no status and dies invisibly. Where the host offers none, run
one worker directly and follow it.

**8. Confirm the start** by something only a started, unblocked worker could
produce — a first commit or file in its workspace, or a message from it naming
what it read — never by the host reporting success: a start reported as a
success left an agent idle at a permission prompt.

**9. Judge by output** — commits, a pull request, a comment on the issue —
never by a heartbeat, a live terminal or silence. Look each time you return,
not only when the host signals: a pull request sat unreviewed while the wait
kept failing, its worker alive, heartbeating and done. A stuck worker is
repaired in place; a second workspace for the same area orphans the first.

## When a wave goes wrong

- **A worker needs a path outside its issue** → it stops and reports; the PM
  re-partitions. A worker that edits the path anyway has just put a file in
  two workers' hands.
- **Two pull requests in one wave conflict** → the decomposition was wrong. Fix
  the partition and the coupled groups it came from, not just the merge; the
  next wave repeats the conflict otherwise.

## Retirement and accounting

Retire a standing worker on an observable trigger:

| Trigger | Because |
|---|---|
| Its context was compacted | What it remembers is a summary: the reason to keep it is gone, the hazard of stale rules remains. |
| A round produced nothing | The next round would command an agent that is not working. |
| The partition changed | It no longer owns the area it was briefed on. |

Retiring ends what the worker started: its workspace, its branch once merged
or confirmed stale, what its report names. Before it is released, confirm
nothing it started still runs — four monitors a released worker left running
were traceable afterwards only by the deleted workspace they ran in. Confirm
each removal landed; a cleanup reporting success is no more evidence than a
start reporting success.

Ending the PM's own session can end the workers it delegated, mid-task, and a
restart may resume them or never reach them. After any restart, read each
worker's state from its workspace and its pull request, never from what the PM
or the worker remembers: a restarted PM reported its worker ran every step
without a stop, while the worker's workspace showed one halfway.

The accounting outlives the round: a standing worker is still the PM's between
waves, while nothing is dispatched to it. Close each wave with one line per
worker — issue, pull request, tier, verified or not, kept or retired and why —
written where the next reader finds it, not only in a terminal.
