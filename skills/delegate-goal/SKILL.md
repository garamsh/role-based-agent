---
name: delegate-goal
description: Runs a delegation cycle for the PM. Settle every decision up front with the user in rounds of questions, record it as a goal issue, hand the user a ready /goal line, run unattended, then close with one report. Use when the user starts a goal or a piece of work to hand off, says "grill", asks what to put in /goal, or when a goal ends and the next is to be decided.
license: Apache-2.0
metadata:
  version: "1.0.0"
---

# Delegate a goal

The PM operates this; every step is the PM's. The user decides once, at the
start, and checks once, at the end; a question put off to mid-run interrupts
the run.

## 1. Decide

Map the work as a **design tree**: each decision branches into the decisions
that hang off it. Work it in rounds. The **frontier** is every decision whose
prerequisites are settled, askable without guessing at answers not yet
heard. Ask the whole frontier in one round, then wait.

- With a question tool from the host, put at most 4 questions per call, the
  recommended option first. Without one, number the questions in text, each
  with your recommendation.
- A question that depends on one still open in this round waits for a later
  round.
- Look up facts yourself, never asking the user for one; only questions
  downstream of a running lookup wait.
- You are done when the frontier is empty and nothing is silently assumed.
  Act only after the user confirms.

Besides the work, settle these branches:

- **Done**: acceptance criteria that output in this conversation can show,
  such as merged PRs, a test exit code or a file count.
- **Grant**: what you may decide alone on the way, naming each row of your
  role's §Deciding you may take inside the goal. Anything not named stops the
  run.
- **Bounds**: what must not change. Set no turn cap unless the user asks for
  one.
- **Final check**: what the user will look at to accept the result.

## 2. Record

After confirmation, file one goal issue through the project's own issue
procedure, holding the decisions, grant, acceptance criteria, bounds and
final check. A decision not written there is not granted: the session can be
compacted, and the issue outlives it.

## 3. Hand over the goal line

On Claude Code only the user can type `/goal`; other hosts put the condition
in their own goal mechanism. End your turn with the line to paste, in a code
block, under 4,000 characters, pointing at the issue without restating it:

    /goal Every acceptance criterion in issue #N holds, each shown by output in this session, and a final report comment is posted on #N. Or an escalation comment on #N awaits the user's decision.

Add "Or stop after T turns" only if the user asked for a cap. The evaluator
reads only this conversation, so show evidence for each claim: a `gh`
result, a test tail or a comment URL.

## 4. Run

Work to the end without asking. At a decision the grant does not cover, post
an escalation comment with options and a recommendation, show its URL and
stop; that ends the goal cleanly.

## 5. Report

Post one comment on the goal issue covering what merged, each decision you
took alone under the grant, each check you did not verify, and every departure
from what was decided. Show its URL, summarize it briefly for the user in their language, and
offer the next cycle.
