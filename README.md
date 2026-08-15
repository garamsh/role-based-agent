# role-based-agent

Role definitions for AI coding agents, installed once per machine and shared by every project you work on.

Three roles divide the work: a **PM** on `main` that reviews, merges, and supervises; **workers** on task branches that implement and deliver PRs; and a **QA** agent that hunts for problems and files them as issues with evidence. One merge authority keeps concurrent work from landing in conflicting directions.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/install.sh | sh
```

This clones the repo to `~/.local/share/role-based-agent` and symlinks each role file into both tools:

- `~/.claude/agents/` — Claude Code
- `~/.config/opencode/agents/` — opencode

Because these are symlinks, no copies exist, so no copy can drift. **Re-running the same command is the update** — it fast-forwards the clone and refreshes the links.

To keep the clone somewhere else, or to edit the roles yourself, install from a clone instead. The installer then uses that clone in place:

```bash
git clone git@github.com:garamsh/role-based-agent.git ~/Workspace/role-based-agent
~/Workspace/role-based-agent/install.sh
```

`ROLE_AGENT_DIR` overrides the clone location for the piped form. `./install.sh --uninstall`, run from a clone, removes the links it created. Existing regular files at a target path are never overwritten; the installer skips them and says so.

Requires `git`. The script is POSIX `sh`, so `| sh` and `| bash` both work.

## Use

A session is bound to one role at launch and cannot switch mid-session:

```bash
claude --agent pm        opencode --agent pm
claude --agent worker    opencode --agent worker
claude --agent qa        opencode --agent qa
```

The role file becomes the session's system prompt, so the session *is* that role rather than delegating to a subagent.

## Why this is not in the project repo

Rules live with what they describe.

- **This repo** describes how you operate agents. It is the same in every project, and it depends on your machine and tooling — so it belongs to your user environment.
- **A project repo** describes its own codebase: conventions, architecture, PR and issue templates. Those must be reviewable in PRs and versioned alongside the code they govern.

The split follows from that: a project declares the *contract* (its `AGENTS.md` role matrix, its `docs/convention/`), and this repo supplies the *procedure* for carrying it out. Precedence runs `docs/convention/` > the project's `AGENTS.md` > these role definitions, so a project can always overrule them — and a project-level `.claude/agents/` file wins over the user-level one when a project genuinely needs its own variant.

For the project side of this arrangement, see the [convention-driven-project](https://github.com/garamsh/convention-driven-project) template.

## Adding a role

Drop a markdown file in `agents/` and re-run `./install.sh`. The filename becomes the role name. Frontmatter carries both tools' keys in one file:

```yaml
---
name: reviewer          # Claude Code
description: ...        # both
mode: primary           # opencode
---
```

Each tool ignores the other's keys. Keep the body self-sufficient: it replaces the default system prompt rather than adding to it.
