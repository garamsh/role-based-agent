---
name: run-agents
description: Runs the PM's role agents on the model that fits the work — Opus for the PM and the final review, Sonnet for what only a reader can judge, the local model for what a check judges — each local agent a live opencode TUI in its own Orca worktree, reused across rounds and open to questions. Use when the PM, following plan-work, dispatches a round, chooses a role's model, starts, reuses, commands or retires a role's agent, hands a fresh session its role note, or needs the Orca commands for one.
compatibility: Needs orca-ide, opencode, gh, Claude Code, a local model server (127.0.0.1:8080).
license: Apache-2.0
metadata:
  version: "1.4.0"
---

# Run agents

`plan-work` governs the roles; this skill is the model each role runs on and
how its agent is started, commanded and retired. Record its worktree,
terminal handle and session id on the roster.

| Opus (Claude Code) | Sonnet (Claude Code) | Local model (opencode) |
|---|---|---|
| The PM; the final review | Implementation only a reader can judge (design, rule documents, a change with no test), any research ("find out why or how"), and any doubt; the next model after an escalation; the optional independent reviewer; QA | Implementation when all hold: checks the agent runs itself decide acceptance, with the same result in CI; no research; the PM expects to merge after one look. The review's first pass; research that needs no web |

Escalate to the next model on a wrong-direction fix (it addresses
something other than what was named, or treats the symptom), and after a
second round on a repeated finding; "same failure twice" stays only for flaky
or environmental failures. A local PR needing 2–3 review rounds costs the PM more than a Sonnet PR
merged after one look.

Review stays on Opus because only review would catch a weaker model's mistake
in a design decision or after a repeated failure; QA runs below it because it
files evidence the PM triages, so review still stands behind it. An agent
changes model only in a new round. No Claude subagent runs on Opus: name
Sonnet when starting one, since a subagent inherits the PM's model.

## Sessions and role notes

A local role's opencode session stays open and gets every round until its
footer passes about 80%; the next round gets a new session id. A Sonnet
session serves one issue: its PR and that PR's review round-trips. It ends at
merge or at about 150k, read by the PM from the subagent transcript's usage,
whichever comes first. One past 150k and under 200k still finishes a review
round of one or two findings itself: a fresh session re-reads its whole context
to fix a missing control. The next issue starts fresh from its role note. Compaction alone fires near 1M, too late. Each round's end, a Sonnet role leaves a
**role note** (1–2k tokens: structure learnt, pitfalls, state) as a roster
issue comment; a fresh session's brief says to read the latest first. Subagent
`memory` is rejected.

## The local agent is a terminal that stays open

A worker is an agent the PM and the user can still talk to; a command that
takes a prompt and exits is not one: a mid-round question goes unanswered.

## One local agent per role

A local role's agent is one Orca worktree and one opencode session, both
named after the role (`<area>`).

```sh
orca-ide worktree create --repo path:<repo> --name local-<area> \
  --branch local/<area> --base-branch origin/<default> --no-parent --setup skip --json
```

The result's `worktree.path` is `<worktree>`.

## Start it

Write the brief to a file outside the worktree — `/tmp/opencode/brief-<area>.md`
— so the tree stays clean and the text can be sent again. It tells a local
agent to use `gh api` or `--json` forms (`gh pr create/edit` failures cost
rounds), to commit and push after each passing step so a dead round leaves its
state there, and to read a long output by its tail plus exit code.

Start the role's agent in a terminal:

```sh
orca-ide terminal create --worktree path:<worktree> --title local-<area> --json --command \
  'opencode mini --agent worker --model local/<model> --session ses_<repo><area>1 --prompt "$(cat /tmp/opencode/brief-<area>.md)"'
```

`--agent` takes the role document, `--session` the context a later round
continues; `terminal.handle` is the agent's terminal.

The host's launcher is the alternative, and the only one reporting the agent
to `orca-ide worktree ps --json`:

```sh
orca-ide agent launch --agent opencode --worktree path:<worktree> \
  --prompt "$(cat /tmp/opencode/brief-<area>.md)" --surface terminal --json
```

`result.outcome.handle` is the terminal. It binds neither `worker` nor the model:
write `{ "default_agent": "worker" }` into an opencode config the worktree's
parent directory holds, outside the repository, and change the model in
opencode's own configuration. Retire a session created with the wrong agent.

## Wait, ask, read

```sh
orca-ide terminal wait --terminal <handle> --for tui-idle --timeout-ms 180000 --json
orca-ide terminal read --terminal <handle> --screen --json
orca-ide terminal send --terminal <handle> --text "<question>" --enter --json
```

- `tui-idle` holds before a turn starts as after one: it alone marked a
  finished round that had produced nothing.
- Read before sending. A send receipt stopping at `input_accepted` is
  expected (the provider cannot report delivery): confirm on screen, do not resend.
- The next round is another send on the same session; after a restart,
  start it with `--session <id>`.

## Judge by output

A round is done when the artifact its brief names exists — a PR, or a done
file outside the tree — polled for, not judged by screen reads.
`orca-ide worktree ps --json` reports the conversation name and last message
of an agent the host launched. A live tab is not evidence.

## Retiring

When `plan-work` says to retire a role's agent, start its next round on a new
session id (`…2`); for a local one run `opencode session delete <id>` on the
old, then check that no process keeps its cwd in the worktree: closed terminals' sessions
kept running under `opencode serve` and opened a duplicate PR. A role's worktree stays until the role is removed; then run
`orca-ide worktree rm --worktree path:<worktree>`, after its branches are
merged or closed.

## Limits

If the local server is down (`curl -s 127.0.0.1:8080/health`), dispatch to a
Sonnet worker.

Nothing here enforces the worker's `git push … main` deny: opencode's
permission rules do. Confirm it is in force before a round that pushes.

If a command here fails, read `orca-ide skills get orca-cli`, not guess.

## Observed, not documented: re-check after an upgrade

- A subagent's prompt cache lasts five minutes, or an hour with
  `subagentPromptCacheTtl: "1h"` in user settings.
- Subagent `memory`, rejected: `local` is lost with the worktree; `user` is
  shared by every project.
- `agent launch` starts opencode's `build` agent, not `worker`, and refuses
  `--model` for opencode (`capability_unsupported`); a session already created
  keeps the agent it was created with.
- The local server runs two rounds at once.
