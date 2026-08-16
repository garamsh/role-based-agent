# role-based-agent

Roles and procedures for AI coding agents, installed once per machine and shared by every project.

Three roles divide the work: a **PM** on the default branch that reviews, merges, supervises, and runs the workers; **workers** on task branches that implement and deliver PRs; and a **QA** agent that hunts for problems and files them as issues with evidence. One merge authority keeps concurrent work from landing in conflicting directions.

One skill ships alongside them. `sync-conventions` brings a conventions template repository into a project and keeps it current — first-time adoption, initial bootstrap, and later updates. It records the template as a git remote, so it works with whichever template you point it at. Unlike the roles it is not neutral: it names paths — `AGENTS.md`, `stack-*.md`, `CODEOWNERS`, `Makefile` — and takes its shared templates and `.gitignore` from GitHub.

These live on your machine rather than in a project repo because they describe how *you* operate agents, not what any one codebase is. The roles name no paths and assume no file layout: each finds the rules through whatever entry point the project gives contributors, then treats them as binding.

They do assume a project that keeps its conventions in writing — an index of rules, a template saying what a pull request must state, documentation describing the system's shape. On a repository with none of that, the roles still work but have little to enforce.

Among the roles, one platform appears by name, in one place. The PM has an `Orca` section saying that on an Orca-managed host it loads Orca's own orchestration guides before dispatching; everything outside that section is platform-neutral, and the section carries no procedure of its own — only what is needed to discover and load those guides — so the procedure stays with whoever ships it. On a host without Orca, delete the section.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/install.sh | sh
```

Clones to `~/.local/share/role-based-agent`, then asks which tools to install into with a checkbox list. Only tools it finds on the host are listed, and they start checked; a number toggles that row and reprints the list, enter installs whatever is checked:

| Tool | Targets | Detected by |
|---|---|---|
| Claude Code | `~/.claude/{agents,skills}/` | `claude` on `PATH`, or `~/.claude/` exists |
| opencode | `~/.config/opencode/{agents,skills}/` | `opencode` on `PATH`, or `~/.config/opencode/` exists |

Roles and skills are symlinked, so there is no second copy to fall behind. A real file or directory you put at a target path is left alone and reported as kept — move it yourself and re-run to link there.

Re-run the same command to update: the list starts with your installed set checked, and enter refreshes exactly that set. Unchecking only limits what is refreshed; it never removes. Run without a terminal — CI, cron — it refreshes in place and never blocks on a prompt, so the same one-liner stays safe for unattended updates.

`install.sh` takes no arguments; it installs, and that is all it does. Removal is the other script, and it is all-or-nothing: there is no way to remove one tool's symlinks while keeping the other's, and no way to target a single tool non-interactively. If you need either, delete the symlinks yourself — they are only symlinks.

To remove:

```bash
curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/uninstall.sh | sh
```

It removes only symlinks that name a role-based-agent checkout — by the link's text, not by what it still resolves to, so deleting the checkout first leaves nothing behind — and never touches real files or directories.

To keep the clone elsewhere or edit the roles yourself, run `install.sh` from your own clone and it is used in place. `ROLE_AGENT_DIR` overrides the clone location for the piped form. Requires `git`.

## Use

A session is bound to one role at launch and cannot switch mid-session:

```bash
claude --agent pm        opencode --agent pm
claude --agent worker    opencode --agent worker
claude --agent qa        opencode --agent qa
```

The role file becomes the session's system prompt, so the session *is* that role rather than delegating to a subagent.
