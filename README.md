# role-based-agent

Roles and procedures for AI coding agents, installed once per machine and shared by every project.

Three roles divide the work: a **PM** on `main` that reviews, merges, and supervises; **workers** on task branches that implement and deliver PRs; and a **QA** agent that hunts for problems and files them as issues with evidence. One merge authority keeps concurrent work from landing in conflicting directions.

One skill ships alongside them. `sync-conventions` brings a conventions template repository into a project and keeps it current — first-time adoption, initial bootstrap, and later updates. It records the template as a git remote, so it works with whichever template you point it at.

These live on your machine rather than in a project repo because they describe how *you* operate agents, not what any one codebase is. Each project supplies its own conventions, architecture documents, and review rules; the roles read whatever the project declares and are bound by it.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/install.sh | sh
```

Clones to `~/.local/share/role-based-agent`, then asks which tools to install into — arrows move, space toggles, enter confirms. Tools found on the host are pre-selected:

| Tool | Targets | Detected by |
|---|---|---|
| Claude Code | `~/.claude/{agents,skills}/` | `claude` on `PATH`, or `~/.claude/` exists |
| opencode | `~/.config/opencode/{agents,skills}/` | `opencode` on `PATH`, or `~/.config/opencode/` exists |

Roles are symlinked, so there is no second copy to fall behind. A real file you put at a target path is left alone unless you pass `--force`.

```bash
./install.sh --update        # pull the source and refresh installed tools
./install.sh --tool claude   # target one tool, skipping the picker
./install.sh --yes           # accept detected tools without prompting
./install.sh --list          # show targets and exit
./install.sh --uninstall     # remove the symlinks
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
