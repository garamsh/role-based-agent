---
name: run-agents
description: Runs the PM's role agents on the model that fits the work — Opus for the PM and the final review, Sonnet for what only a reader can judge, the local model for what a check judges — and, for the local model, each role's agent a live opencode TUI in its own Orca worktree, reused round after round and open to the PM's and the user's questions. Use when the PM, following plan-work, dispatches a round, chooses a role's model, starts, reuses, commands or retires a role's agent, hands a fresh session its role note, or needs the Orca commands for one.
license: Apache-2.0
metadata:
  version: "1.0.0"
---

# Run agents

`plan-work` governs the roles (scopes, roster, assignment, briefs,
accounting); this skill is the model each role runs on and how its agent is
started, commanded and retired. Record its worktree, terminal handle and
session id on the roster.

| Opus (Claude Code) | Sonnet (Claude Code) | Local model (opencode) |
|---|---|---|
| The PM; the final review | Implementation only a reader can judge (design, rule documents, a change with no test); a round after the same failure repeated twice locally; the optional independent reviewer; QA | Implementation a test or check judges; the review's first pass; research that needs no web |

No Claude subagent runs on Opus: name Sonnet when starting one, since a
subagent inherits the PM's model.

## Sessions and role notes

A local role's opencode session stays open and gets every round. A Sonnet
role's session is reused only while work continues (within about an hour,
before its cache expires); otherwise the next round starts a fresh session.
At the end of each round a Sonnet role leaves a **role note** (1–2k tokens:
structure learnt, pitfalls, state) as a comment on the roster issue, and the
brief of a fresh session tells it to read that role's latest note first.
Subagent `memory` was measured and rejected: `local` lives inside the worktree,
so it shows as untracked and is lost when the worktree is removed; `user` is
one file shared by every project.

## The local agent is a terminal that stays open

A worker is an agent the PM and the user can still talk to. A command that
takes a prompt and exits is not one: a question asked mid-round goes
unanswered, and a round that dies leaves nobody to answer it. In mvmd two of
three local rounds ended that way — one died in compaction, one was cut off
resolving a conflict — and neither was recoverable afterwards, because the
terminal that held the agent was gone.

## One local agent per role

Each local role's agent is one Orca worktree and one opencode
session, both named after the role (`<area>` below).

```sh
orca-ide worktree create --repo path:<repo> --name local-<area> \
  --branch local/<area> --base-branch origin/<default> --no-parent --setup skip --json
```

The result's `worktree.path` is the worker's workspace.

## Start it

Write the brief to a file outside the worktree — `/tmp/opencode/brief-<area>.md`
— so the tree stays clean and the same text can be sent again.

Start the role's own agent in a terminal that stays open:

```sh
orca-ide terminal create --worktree path:<worktree> --title local-<area> --json --command \
  'opencode mini --agent worker --model local/<model> --session ses_<repo><area>1 --prompt "$(cat /tmp/opencode/brief-<area>.md)"'
```

`opencode mini` is opencode's interactive interface with the flags this needs:
`--agent` for the role document, `--model` for the local model, `--session`
for the context a later round continues, `--prompt` for the brief. The result's
`terminal.handle` is the agent's terminal.

The host's own launcher is the alternative, and the only one that reports the
agent to `orca-ide worktree ps --json`:

```sh
orca-ide agent launch --agent opencode --worktree path:<worktree> \
  --prompt "$(cat /tmp/opencode/brief-<area>.md)" --surface terminal --json
```

`result.outcome.handle` is the terminal. It starts opencode's `build` agent,
not this project's `worker`, and refuses `--model` for opencode
(`capability_unsupported`): to bind the role document to it, write
`{ "default_agent": "worker" }` into an opencode config the worktree's parent
directory holds — outside the repository, so the tree stays clean — and change
the model in opencode's own configuration. A session already created keeps the
agent it was created with, so a stale one is retired, not reused.

## Wait, ask, read

```sh
orca-ide terminal wait --terminal <handle> --for tui-idle --timeout-ms 180000 --json
orca-ide terminal read --terminal <handle> --screen --json
orca-ide terminal send --terminal <handle> --text "<question>" --enter --json
```

- `tui-idle` is satisfied before a turn starts as readily as after one. Read
  the screen before calling a round done: the idle signal alone marked a
  finished round that had produced nothing.
- Read before sending. A send receipt stopping at `input_accepted` is
  expected — the opencode provider cannot report delivery — so confirm on
  screen instead of resending.
- Keep the terminal open between rounds. The next round is another send, on
  the same session. After a restart, start it again with `--session <id>`.

## Judge by output

A round is judged by what it produced: a commit, a pull request, a message
naming what it read. `orca-ide worktree ps --json` reports the conversation
name and last message of an agent the host launched. A live tab is not
evidence: one sat at a permission prompt while the host reported success.

## Retiring

When `plan-work` says to retire a role's agent, start its next round on a
new session id (`…2`). When the role itself is removed, run
`orca-ide worktree rm --worktree path:<worktree>`, after its branches are
merged or closed.

## Limits

The local server runs two rounds at once. If it is down
(`curl -s 127.0.0.1:8080/health`), dispatch the round to a Sonnet worker.

Nothing here enforces the worker's `git push … main` deny: opencode's
permission rules do that, not the command line. Confirm the rule is in force
before a round that pushes.

If a command here fails, read `orca-ide skills get orca-cli` rather than
guessing.
