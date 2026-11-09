---
name: run-agents
description: Runs the PM's role agents on the model that fits the work — Opus for the PM and the final review, Sonnet for what only a reader can judge, the local model for what a check judges — each local agent a live opencode TUI in its own Orca worktree, reused across rounds and open to questions. Use when the PM, following plan-work, dispatches a round, chooses a role's model, starts, reuses, commands or retires a role's agent, hands a fresh session its role note, or needs the Orca commands for one.
compatibility: Needs orca-ide, opencode, gh, Claude Code, a local model server (127.0.0.1:8080).
license: Apache-2.0
metadata:
  version: "1.1.1"
---

# Run agents

`plan-work` governs the roles; this skill is the model each role runs on and
how its agent is started, commanded and retired. Record its worktree,
terminal handle and session id on the roster.

| Opus (Claude Code) | Sonnet (Claude Code) | Local model (opencode) |
|---|---|---|
| The PM; the final review | Implementation only a reader can judge (design, rule documents, a change with no test); a round after the same failure repeated twice locally; the optional independent reviewer; QA | Implementation a test or check the agent itself can run judges (the default for such work); the review's first pass; research that needs no web |

Root-only tests only CI can run (mvmd: supervision, nftables) do not qualify
for local; mvmd's PM under-used local until the user asked.

Review stays on Opus because only review would catch a weaker model's mistake
in a design decision or after a repeated failure; QA runs below it because it
files evidence the PM triages, so review still stands behind it. An agent
changes model only in a new round. No Claude subagent runs on Opus: name
Sonnet when starting one, since a subagent inherits the PM's model.

## Sessions and role notes

A local role's opencode session stays open and gets every round until its
footer passes about 80%; the next round gets a new session id. A Sonnet
session is reused only while work continues (about an hour), and starts fresh, from its role note, at the end of the round
in which its context passed about 150k, read by the PM from the subagent
transcript's usage. Compaction alone fires near 1M, too late: knowno reached
965k after 34 resumes, mvmd 690k. Each round's end, a Sonnet role leaves a
**role note** (1–2k tokens: structure learnt, pitfalls, state) as a roster
issue comment; a fresh session's brief says to read the latest first. Subagent
`memory` is rejected.

## The local agent is a terminal that stays open

A worker is an agent the PM and the user can still talk to; a command that
takes a prompt and exits is not one: a mid-round question goes unanswered and
a dead round leaves nobody to answer. In mvmd two of three local rounds ended
so (one died in compaction, one was cut off resolving a conflict) and
neither was recoverable: its terminal was gone.

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
agent to use `gh api` or `--json` forms: `gh` warnings and `gh pr create/edit`
failures cost rounds in mvmd and here.

Start the role's agent in a terminal:

```sh
orca-ide terminal create --worktree path:<worktree> --title local-<area> --json --command \
  'opencode mini --agent worker --model local/<model> --session ses_<repo><area>1 --prompt "$(cat /tmp/opencode/brief-<area>.md)"'
```

`opencode mini` is opencode's interactive interface: `--agent` takes the role
document, `--session` the context a later round continues.
`terminal.handle` is the agent's terminal.

The host's launcher is the alternative, and the only one reporting the agent
to `orca-ide worktree ps --json`:

```sh
orca-ide agent launch --agent opencode --worktree path:<worktree> \
  --prompt "$(cat /tmp/opencode/brief-<area>.md)" --surface terminal --json
```

`result.outcome.handle` is the terminal. It binds neither `worker` nor the model:
write `{ "default_agent": "worker" }` into an opencode config
the worktree's parent directory holds — outside the repository, so the tree
stays clean — and change the model in opencode's own configuration. Retire a
session created with the wrong agent.

## Wait, ask, read

```sh
orca-ide terminal wait --terminal <handle> --for tui-idle --timeout-ms 180000 --json
orca-ide terminal read --terminal <handle> --screen --json
orca-ide terminal send --terminal <handle> --text "<question>" --enter --json
```

- `tui-idle` is satisfied before a turn starts as readily as after one: the
  idle signal alone marked a finished round that had produced nothing.
- Read before sending. A send receipt stopping at `input_accepted` is
  expected — the opencode provider cannot report delivery — so confirm on
  screen instead of resending.
- The next round is another send, on the same session; after a restart,
  start it again with `--session <id>`.

## Judge by output

A round is done when the artifact its brief names exists — a PR, or
a done file outside the tree — polled for, not judged by screen reads, which
were clumsy in mvmd. `orca-ide worktree ps --json` reports the conversation
name and last message of an agent the host launched. A live tab is not
evidence: one sat at a permission prompt while the host reported success.

## Retiring

When `plan-work` says to retire a role's agent, start its next round on a new
session id (`…2`); for a local one run `opencode session delete <id>` on the
old, then check that no process keeps its cwd in the worktree: in knowno the
closed terminals' sessions kept running under `opencode serve` and opened a
duplicate PR. A role's worktree stays until the role is removed (in
mvmd a resume failed after its removal); then run
`orca-ide worktree rm --worktree path:<worktree>`, after its branches are
merged or closed.

## Limits

If the local server is down (`curl -s 127.0.0.1:8080/health`), dispatch to a
Sonnet worker.

Nothing here enforces the worker's `git push … main` deny: opencode's
permission rules do. Confirm it is in force before a round that pushes.

If a command here fails, read `orca-ide skills get orca-cli` rather than
guessing.

## Observed, not documented: re-check after an upgrade

- A provider's cache expires after about an hour.
- Subagent `memory`, rejected: `local` lives inside the worktree, so it shows as
  untracked and is lost when the worktree is removed; `user` is one file shared
  by every project.
- `agent launch` starts opencode's `build` agent, not `worker`, and refuses
  `--model` for opencode (`capability_unsupported`); a session already created
  keeps the agent it was created with.
- The local server runs two rounds at once.
