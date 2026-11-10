---
name: run-agents
description: Runs the PM's role agents on the model that fits the work — Opus for the PM and the final review, Sonnet for every role agent. Use when the PM, following plan-work, dispatches a round, chooses a role's model, starts, commands or retires a role's agent, or hands a fresh session its role note.
compatibility: Needs Claude Code.
license: Apache-2.0
metadata:
  version: "2.0.1"
---

# Run agents

`plan-work` governs the roles; this skill is the model each role runs on and
how its agent is started, commanded and retired. Record its worktree and
agent id on the roster.

Opus runs the PM and the final review. Sonnet runs every role agent:
implementation, research ("find out why or how"), QA and the optional
independent reviewer.

On a wrong-direction fix (it addresses something other than what was named,
or treats the symptom), and after a second round on a repeated finding,
re-scope the brief, split the issue or report to the PM. A failure twice counts
only when flaky or environmental.

Review stays on Opus because only review would catch a mistake
in a design decision or after a repeated failure; QA runs below it because it
files evidence the PM triages, so review still stands behind it. No Claude subagent runs on Opus: name
Sonnet when starting one, since a subagent inherits the PM's model.

## Sessions and role notes

A Sonnet session serves one issue: its PR and that PR's review round-trips. It ends at
merge or at about 150k, read by the PM from the subagent transcript's usage,
whichever comes first. One past 150k and under 200k still finishes a review
round of one or two findings itself: a fresh session re-reads its whole context
to fix a missing control. The next issue starts fresh from its role note. Compaction alone fires near 1M, too late. Each round's end, a Sonnet role leaves a
**role note** (1–2k tokens: structure learnt, pitfalls, state) as a roster
issue comment; a fresh session's brief says to read the latest first.

## Observed, not documented: re-check after an upgrade

- A subagent's prompt cache lasts five minutes, or an hour with
  `subagentPromptCacheTtl: "1h"` in user settings.
- Subagent `memory`, rejected: `local` is lost with the worktree; `user` is
  shared by every project.
