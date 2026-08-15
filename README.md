# role-based-agent

Role definitions for AI coding agents, installed once per machine and shared by every project.

Three roles divide the work: a **PM** on `main` that reviews, merges, and supervises; **workers** on task branches that implement and deliver PRs; and a **QA** agent that hunts for problems and files them as issues with evidence. One merge authority keeps concurrent work from landing in conflicting directions.

These live on your machine rather than in a project repo because they describe how *you* operate agents, not what any one codebase is. The project side — conventions, architecture docs, PR and issue templates — belongs in [convention-driven-project](https://github.com/garamsh/convention-driven-project).

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/install.sh | sh
```

Clones to `~/.local/share/role-based-agent` and symlinks each role into every supported tool found on the host:

| Tool | Target | Detected by |
|---|---|---|
| Claude Code | `~/.claude/agents/` | `claude` on `PATH`, or `~/.claude/` exists |
| opencode | `~/.config/opencode/agents/` | `opencode` on `PATH`, or `~/.config/opencode/` exists |

A tool you do not have is skipped. Re-running the same command is the update.

```bash
./install.sh --tool claude   # target one tool explicitly
./install.sh --list          # show targets and exit
./install.sh --uninstall     # remove the links
```

To keep the clone elsewhere or edit the roles yourself, run `install.sh` from your own clone and it is used in place. `ROLE_AGENT_DIR` overrides the clone location for the piped form. Requires `git`.

## Use

A session is bound to one role at launch and cannot switch mid-session:

```bash
claude --agent pm        opencode --agent pm
claude --agent worker    opencode --agent worker
claude --agent qa        opencode --agent qa
```

The role file becomes the session's system prompt, so the session *is* that role rather than delegating to a subagent.
