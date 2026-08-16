---
name: orca-dispatch
description: Find and load Orca's own procedure guides before dispatching a worker or coordinating agents on an Orca-managed host. Use when about to dispatch, orchestrate, hand off, or wait on another agent and the host is Orca — an Orca-managed terminal or worktree, or an `orca` CLI on the machine.
---

# Dispatch and coordinate on an Orca-managed host

Where the host is Orca-managed, Orca's guides are the procedure — not a role definition, and not memory. Discover what the installed CLI ships rather than recalling it: its interface moves faster than any summary, this one included.

If the host is not Orca-managed, none of this applies. Nothing here substitutes for the CLI; it only says how to reach what the CLI ships.

## Load the guides before acting

```bash
orca skills list
```

Enumerates the bundled guides with their descriptions. Some are already installed on this machine as skills, so they need no fetching; load the rest on demand:

```bash
orca skills get <topic>
```

Read every guide covering your next action before you take it, and take commands from the guide rather than from memory. Dispatching is covered by the coordination guide — read that one before starting a worker, not after the first command fails.

## `orca` and `orca-ide` name the same build

Two names, one binary. Which name reaches the CLI depends on the host:

- On Linux, bare `orca` may instead be the screen reader, an unrelated program that will answer as if it were the CLI.
- Where an Orca instance is already running for the profile, bare `orca` can exit 3 with empty stdout, having handed the request to the existing window. `orca-ide` of the same build answers the same command normally. This is field-verified, and it fails silently, so it reads like a broken guide rather than a wrong name.

If the name you tried cannot run the CLI, try the other before concluding the guide is wrong.
