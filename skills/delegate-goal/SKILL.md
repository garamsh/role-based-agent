---
name: delegate-goal
description: Runs a delegation cycle for the PM. Settle every decision up front with the user in rounds of questions, record it as a goal issue, hand the user a ready /goal line, run unattended, then close with one report. Use when the user or a coordinator starts a goal or a piece of work to hand off, says "grill", asks what to put in /goal, or when a goal ends and the next is to be decided.
license: Apache-2.0
metadata:
  version: "1.3.0"
---

# Delegate a goal

The PM operates this; every step is the PM's. The user decides once, at the
start, and checks once, at the end; a question put off to mid-run interrupts
the run.

## 1. Decide

Map the work as a **design tree**: each decision branches into those that hang
off it. Also settle these branches:

- **Urgency**: normal or deadline. For a deadline, show the run estimate with
  and without workers' local checks; the user chooses and agrees the deadline
  before any work, and cuts scope, never quality, where the estimate exceeds it.
- **Done**: acceptance criteria that output in this conversation can show,
  such as merged PRs, a test exit code or a file count.
- **Grant**: what you may decide alone on the way, naming which of your
  role's §Deciding escalate-to-user items you may take. Anything not named
  stops the run.
- **Bounds**: what must not change.
- **Final check**: what the user will check to accept the result.

Work the tree in rounds. The **frontier** is every decision whose
prerequisites are settled. Ask the whole frontier in one round, however many
calls it takes, then wait.

- With a question tool from the host, put at most 4 questions per call, the
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

Where a coordinator starts goals, its message linking the goal issue and the
user's recorded approval starts this one: hand over no line; work until every
criterion holds or an escalation is posted.

Otherwise only the user can type `/goal` on Claude Code; other hosts use their
own goal mechanism. End your turn with the line to paste, in a code block,
under 4,000 characters, pointing at the issue without restating it:

    /goal Every acceptance criterion in issue #N holds, each shown by output in this session, and a final report comment is posted on #N. Or an escalation comment on #N awaits the user's decision.

Add "Or stop after T turns" only if the user asked for a cap. The evaluator
reads only this conversation, so show evidence for each claim: a `gh` result,
a test tail or a comment URL.

## 4. Run

Work to the end; a deadline goal follows `meet-deadline`. At
a decision the grant does not cover, post an escalation comment with options
and a recommendation, show its URL and stop.

## 5. Report

Post one comment on the goal issue covering what merged, each decision you
took alone, each check you did not verify, and every departure from what was
decided. Show its URL, summarize it for the coordinator, or else the user in
their language, and offer the next cycle.
