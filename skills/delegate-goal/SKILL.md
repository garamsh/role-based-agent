---
name: delegate-goal
description: Runs a delegation cycle for the PM. Settle every decision up front with the user in rounds of questions, record it as a goal issue, hand the user a ready goal line, run unattended, then close with one report. Use when the user starts a goal or hands off work, says "grill", asks for the goal line, or a goal ends and the next is to be decided.
license: Apache-2.0
metadata:
  version: "2.0.1"
---

# Delegate a goal

The PM operates this; every step is the PM's. The user decides once, at the
start, and checks once, at the end; a question put off to mid-run interrupts
the run.

## 1. Decide

Map the work as a **design tree**: each decision branches into those that hang
off it. Also settle:

- **Urgency**: normal or deadline. For a deadline, show the run estimate with
  and without workers' local checks; the user chooses and agrees the deadline
  before any work, and cuts scope, never quality, where the estimate exceeds it.
- **Done**: acceptance criteria that output in this conversation can show,
  such as merged PRs, a test exit code or a file count.
- **Grant**: what you may decide alone on the way, naming which of
  `decide-or-escalate`'s escalate-to-user items you may take. Anything not named
  stops the run.
- **Bounds**: what must not change.
- **Final check**: what the user will check to accept the result.

Work the tree in rounds. The **frontier** is every decision whose prerequisites
are settled, askable without guessing at unheard answers. Ask the whole frontier
in one round, however many calls it takes, then wait.

- With the host's question tool, put at most 4 questions per call, the
  recommended option first. Without one, number the questions in text, each
  with your recommendation.
- Stop asking when the frontier is empty and nothing is silently assumed; act
  only once the user confirms.

## 2. Record

Then file one goal issue through the project's issue procedure, holding the
decisions (a deadline goal's deadline and checks choice included), grant,
acceptance criteria, bounds and final check. An unwritten decision is not
granted: a session is compacted; the issue outlives it.

## 3. Hand over the goal line

Where the host has a goal command, only the user can type it. End your turn
with the line to paste, in a code block, within its length limit, pointing at
the issue without restating it. Example, Claude Code's `/goal`:

    /goal Every acceptance criterion in issue #N holds, each shown by output in this session, and a final report comment is posted on #N. Or an escalation comment on #N awaits the user's decision.

Add "Or stop after T turns" only if the user asked for a cap. The evaluator
reads only this conversation, so show evidence for each claim: a `gh` result,
a test tail or a comment URL.

## 4. Run

Work to the end; a deadline goal follows `meet-deadline`. At a decision the
grant does not cover, post an escalation comment with options and a
recommendation and show its URL. Stop.

## 5. Report

Post one comment on the goal issue covering what merged, each decision you
took alone, each check you did not verify, and every departure from what was
decided. Show its URL, summarize it for the user in their language, and offer the next cycle.
