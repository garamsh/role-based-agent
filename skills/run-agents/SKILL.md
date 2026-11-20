---
name: run-agents
description: Runs the PM's role agents on the model that fits the work — Opus for the PM and the final review, Sonnet for every role agent. Use when the PM, following plan-work, dispatches a round, chooses a role's model, starts, commands or retires a role's agent, or hands a fresh session its role note.
compatibility: Needs Claude Code.
license: Apache-2.0
metadata:
  version: "2.3.0"
---
# Run agents

`plan-work` governs the roles; this skill sets each role's model and starts,
commands and retires its agent.

Opus runs the PM and the final review. Sonnet runs every role agent:
implementation, research, QA and the optional independent reviewer. Review
stays on Opus, the only check left on a design mistake or a repeated failure;
QA runs below it, filing evidence the PM triages. No Claude subagent runs on
Opus: name Sonnet when starting one, since a subagent inherits the PM's model.

On a wrong-direction fix (it fixes something other than what was named, or the
symptom), and after a second round on a repeated finding, re-scope the brief,
split the issue or report to the PM. A failure repeated twice triggers this
only when flaky or environmental.

A host-wide limit the user or coordinator sets, such as concurrent workers or a
load threshold for heavy jobs, bounds every dispatch: ask the coordinator, else
the user, for more, since other projects share the host.

## Sessions and role notes

A Sonnet session serves one issue: its PR and that PR's reviews. It ends at
merge or about 150k (subagent transcript usage). One between 150k and 200k
still finishes a review round of up to two findings: a fresh session re-reads
its whole context to fix a missing control. The next issue starts fresh from a
**role note**: the brief has each session end its completion report with one
(1-2k tokens: structure learnt, pitfalls, state), the PM posts it as a roster
issue comment, and the next brief says to read the latest. QA writes none.
Subagent `memory` is unused: `local` dies with the worktree, `user` spans every
project.
