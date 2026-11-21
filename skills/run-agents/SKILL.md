---
name: run-agents
description: Runs the PM's role agents on the model that fits the work — the strongest available for the PM and the final review, a cheaper one for every role agent. Use when the PM, following plan-work, dispatches a round, chooses a role's model, starts, commands or retires a role's agent, or hands a fresh session its role note.
license: Apache-2.0
metadata:
  version: "3.1.0"
---

# Run agents

`plan-work` governs the roles; this skill sets their models and runs and
retires their agents.

The user names the models. The strongest runs the PM and the final review; a
cheaper one runs every role agent: implementation, research, QA and the
independent reviewer. Review stays on the strongest, the only
check left on a design mistake or a repeated failure; QA runs below it, filing
evidence the PM triages. Subagent inheritance: a host may start subagents on
the parent's model (Claude Code does); name the cheaper one.

On a wrong-direction fix (it fixes something other than what was named, or the
symptom), and after a second round on a repeated finding, re-scope the brief,
split the issue or report to the PM. A failure repeated twice triggers this
only when flaky or environmental.

## Sessions and role notes

A session serves one issue, its PR and reviews. It ends at
merge or at the user's context budget, read from the agent's usage. A nearly spent one still finishes a review round of up to two
findings: a fresh session re-reads its whole context to fix a missing control. The next
issue starts fresh from a **role note**: the brief has each session end its
completion report with one (1-2k tokens: structure learnt, pitfalls, state),
the PM posts it as a roster issue comment, and the next brief says to read the
latest first. QA writes none. Subagent `memory` is unused: `local` dies with
the worktree, `user` spans every project.
