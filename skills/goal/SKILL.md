---
name: goal
description: Turn an owner's stated requirement into an approved goal and carry it to done — write the formal goal statement for one approval, partition the project into areas with one standing owner each, run rounds of task issue, pull request and review, and report each round's outcome in the goal issue. Use when the owner states a requirement to be carried out, asks to plan or partition a project, or asks for a goal to be run to completion autonomously.
---

# Run a goal

The PM operates this procedure. It turns one requirement into an approved goal,
divides the work into areas with a standing owner each, and runs rounds until
the goal's acceptance criteria hold. Every step is the PM's own: issues,
dispatch, review, merge. What workers do inside a round is theirs, and is not
written here.

It exists for one failure. An agent that improvises its way around each
obstacle and leaves no project management behind produces a project where,
later, touching one thing breaks a great many others: nothing records why
anything is the way it is, so nobody can tell which change is safe. Everything
below is there to leave that record.

This procedure names no host and no command. The host's own procedure guides are
loaded before acting, and where this document and a host guide decide the same
mechanism — how an agent is started, waited on, reused or ended — the host's
wins. This document decides what the work is and who owns it; the host decides
how an agent is run.

## 1. The entry, and the one gate

The owner invokes this skill by name with the requirement as its argument. The
requirement is the owner's words; the goal statement is yours.

1. Read before writing: the project's conventions, its documented structure,
   and the open issues the requirement touches. A statement written from memory
   of the project grants autonomy over a project that may no longer exist.
2. Write the formal goal statement (§2) and hand it back to the owner. Keep the
   owner's own words for the requirement beside it, quoted rather than
   summarised: the decomposition is yours and can be wrong, and the quote is
   what a later reader checks it against.
3. Wait for one explicit approval. Silence, a question, or a reply to some
   other part of the message is not approval. A requested change is a new
   statement, and it is approved again.
4. File the approved statement as the goal issue, with the approval recorded in
   it. From here you decide and proceed alone, within §3.

This gate is the only one. Asking the owner to confirm a step the approved
statement already covers is the failure the approval exists to remove: it
hands back a decision the owner has already delegated, and stalls the work on
someone who is not watching.

## 2. What a goal statement names

- **Scope** — what this goal changes, concretely enough that a proposed change
  can be judged inside or outside it.
- **Non-goals** — what a reader could reasonably expect to be included and is
  not. A non-goal left unstated is decided later, by whoever meets it first.
- **Acceptance criteria** — observable, each one checkable by someone other
  than its author. "Works" is not a criterion; an output, a passing check, or
  a state of the repository is.
- **The autonomy the approval grants** — which kinds of decision you will take
  alone under this goal, and which you will still bring back. Approving the
  statement is approving this list, so it must be on the page the owner
  approves rather than implied by it.

## 3. The autonomy contract

You decide alone exactly as far as a decision is all three of these:

- **inside the approved goal** — within its scope and not against a non-goal;
- **reversible** — another change can undo it without loss;
- **recorded** — written where the next reader will find it: the goal issue,
  a charter, a task issue, or a decision record in the project's own format
  for one.

The record is what converts an escalation into a decision. A choice made inside
the goal and written down can be audited and reversed by anyone later; the
same choice made silently is the improvisation this procedure exists to
prevent.

Choose by the generally and officially recommended method: the project's
conventions first, then the documented practice of the tool, language or
standard involved. Where you depart from it, the record says what was
recommended and why it did not fit. A workaround with no record is the one
nobody can later tell is a workaround.

Even inside an approved goal, these go back to the owner:

- a change to a convention — it binds every contributor, beyond this goal;
- anything outside the stated scope, including a change the work turns out to
  need — the goal's boundary is its scope, and growing it is a new approval;
- anything that cannot be undone — a release, a force-push, data loss, a change
  to the owner's own configuration or permissions, money spent;
- a genuine conflict between two conventions, where satisfying one breaks the
  other — choosing between them is changing one.

Your role document says how to present one. The goal is not paused while one
waits: work the parts of the goal the open question does not touch.

## 4. The record is a tree of issues

The project's issue tracker holds the goal's record, as three levels:

- **the goal** — the approved statement, and the round reports (§10);
- **an area charter** under it, one per area (§5);
- **a task** under a charter, one per round of that area's work.

Link each to its parent in whatever form the tracker supports. Issues, rather
than a file in the repository or any record the host keeps: a host's record of
a coordination run ends with that run and does not survive a change of host,
and a file in the repository changes only through review, so it cannot carry a
round's state as the round moves.

## 5. What an area charter names

- **The paths the area owns.**
- **The boundaries its owner must not cross** — the paths next to it that
  belong to another area or to you, named so the owner does not have to infer
  them.
- **The owning agent**, and the workspace it works in, filled in when the agent
  is created and updated when it is replaced. The workspace is the area's own,
  never the base checkout, which is yours.
- **Any launch preference fixed when the agent was created** — the kind of
  agent, or what it was told to run with. Some hosts will not let one change on
  reuse, so a preference the area needs is decided before the agent exists, and
  one that turns out wrong means a new agent rather than a changed one.
- **Its rounds**, as a list of task issues, and its **retirement** triggers
  (§9).

A charter stays open while its area has work under the goal; it is closed when
the goal no longer needs the area, not when an owner leaves.

## 6. Deriving the partition

Read the partition off the project's own documented structure — its
conventions, its architecture documentation, its declared ownership of paths.
An area is a part of that structure, not a part of the current task list:
areas cut to fit this week's tasks have to be redrawn next week, and every
redraw retires agents.

- Each area has exactly the one owner its charter names.
- **No file belongs to two areas.** Two owners editing one file produce
  conflicting pull requests that only you can sequence, and the partition
  exists so that you do not have to.
- Paths reserved to you — the conventions, and anything else the project gives
  the PM alone — belong to no area; name them as a boundary in each charter
  that adjoins them.
- Where the project documents no structure, inventing one is architecture
  direction, and it goes back to the owner with a proposed partition. Do not
  partition on an undocumented structure of your own: every charter would
  then rest on a decision nobody approved.

A small project may yield one area. That is a valid partition, not a reason to
skip charters.

## 7. Which roles stand

An implementation agent **stands**: it is kept across rounds of its area,
because its context amortises — the second round in an area costs less than
the first, since the agent has already read that area's code and conventions.

QA and review **do not stand**. Freshness is their product: a reviewer or QA
agent that has seen the area before checks it against what it remembers rather
than against what is there. Start one fresh for each use and end it after.

## 8. A round

1. Open the task issue under the area's charter — before any dispatch.
2. Assign there any name or number two tasks could both claim: a branch name,
   an issue or decision-record number, a port, a migration index. An agent
   choosing its own sees only what has already landed, so concurrent rounds
   collide: four agents dispatched minutes apart all took the same number,
   since none of their claims was in a file yet.
3. Command the area's standing owner with that task. Anything left typed at its
   prompt from the last round is still there and goes in with the new command,
   so clear it first. Where the host tracks dispatched work with a completion
   protocol, command through it rather than through an untracked process: an
   agent nothing tracks reports no status and dies invisibly. Where it offers
   none, run one agent directly and follow it, or ask the owner which tooling
   to use.
4. Confirm the round started by the agent working under its role, never by the
   host reporting that it started: a start reported as a success left an agent
   idle at a permission prompt, and an agent started by name alone works but
   carries no role.
5. Judge the round by what it produced — commits, a pull request, a comment on
   its task — never by a heartbeat, a live terminal or silence; what it
   produced is its report only once its agent has reported. Look for that each
   time you return to the goal, not only when the host signals completion: a
   pull request sat unreviewed while the wait kept failing, its worker alive,
   heartbeating and done.
6. Review the pull request under your role document's standard, and merge or
   send it back; once it merges, delete the round's branch. An area's agent that is stuck is repaired in place: a second
   workspace for the same area only orphans the first.
7. Write the round's report (§10), then open the next round — the same area's
   next task, or another area's.

A round in an area with no owner yet starts by creating one and filling in the
charter's owner fields. A round that needs files from two areas is two rounds,
sequenced; it does not license either owner to cross into the other's paths.

## 9. Round freshness, and retirement

A standing agent's memory is both the benefit and the hazard. It is why the
second round is cheaper, and it is exactly what the conventions distrust: a
rule remembered from an earlier round may since have been revised. Command
every round as though the agent remembered nothing reliable — the task issue
names the conventions that govern its paths and the current tip of the default
branch to start from.

Retire an area's agent on an observable trigger, not on a feeling:

- **its context was compacted** — what it remembers is now a summary, so the
  benefit of standing is gone and the hazard remains;
- **a round produced nothing** — no commits, no pull request, no comment on its
  task, so the next round would be commanding an agent that is not working;
- **the partition changed** — the area it owns is no longer the area its
  charter names.

Retiring an agent ends what it started: its workspace, its branch once merged
or confirmed stale, and what its report names. Nothing else it made is yours
to remove. Before its terminals close, confirm nothing it started still runs:
four monitors a released worker left running were traceable afterwards only by
the deleted workspace they ran in. Confirm each removal landed — a cleanup
reporting success is no more evidence than a start reporting success.

Retiring the agent does not close the charter. Record the retirement and why
in the charter, clear its owner fields, and leave it open for a successor, who
starts from the charter and the task issues rather than from its predecessor's
memory.

## 10. Accounting and reporting

Your role document makes every agent you run yours to end, and an agent or
workspace you did not start yours to report rather than to touch. Under a
goal that obligation outlives each round: a standing agent is still yours
between rounds, while nothing is dispatched to it. When the goal closes, every
area agent it created is retired by the same triggers as above, or kept by
name in the closing report with the owner's reason.

Report each round in the goal issue, not only in a terminal:

- what landed, with the pull request;
- what was verified, and how;
- what was **not** verified, named as such rather than left out;
- what remains, and which round takes it next.

Close the goal when every acceptance criterion holds with its evidence in the
goal issue, and every charter and task under it is closed or closed with a
reason. Then report to the owner once, pointing at the goal issue.
