# role-based-agent

Roles and procedures for AI coding agents, installed once per machine and shared by every project.

Three roles divide the work: a **PM** on the default branch that reviews, merges, supervises, and runs the workers; **workers** on task branches that implement and deliver PRs; and a **QA** agent that hunts for problems and files them as issues with evidence. One merge authority keeps concurrent work from landing in conflicting directions.

One skill ships alongside them. `sync-conventions` brings a conventions template repository into a project and keeps it current — first-time adoption, initial bootstrap, and later updates. It records the template as a git remote and reads that template's own convention index to decide what the project keeps, so a template that adds or renames a tier of conventions needs no change here — but one that indexes its conventions some other way is not a template it can read. Unlike the roles it is not neutral: it names paths — `AGENTS.md`, `CODEOWNERS`, `Makefile`, an index beside the convention files — and takes its shared templates and `.gitignore` from GitHub.

These live on your machine rather than in a project repo because they describe how *you* operate agents, not what any one codebase is. The roles name no paths and assume no file layout: each finds the rules through whatever entry point the project gives contributors, then treats them as binding.

Changing this repository has its own rules, in `CONVENTIONS.md`: what the two
shell scripts may and may not do, how a change to either is verified, and what
a role document is allowed to become.

They do assume a project that keeps its conventions in writing — an index of rules, a template saying what a pull request must state, documentation describing the system's shape. On a repository with none of that, the roles still work but have little to enforce.

Nothing here names a platform. The PM's dispatch rule says only that a host may ship procedure guides of its own, and that you load the ones covering your next action rather than working from memory. It does not say which host, or which commands — a host that ships guides advertises them itself, and its own copy is the one that cannot drift from the binary you are about to run. A summary kept here could only go stale, so there is none.

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

Re-run the same command to update: the list starts with your installed set checked, and enter refreshes exactly that set. Unchecking only limits what is refreshed; it never removes. Run without a terminal — CI, cron — it refreshes in place and never blocks on a prompt, so the same one-liner stays safe for unattended updates of a clone you have not edited yourself.

Updating that clone is a fast-forward and nothing else, so an edit of your own can block it: a file you modified there stops the update once an incoming commit lands on that same file, and a commit of your own there stops it outright. A blocked run installs nothing and leaves the clone and your edits exactly as they were. It names the files in the way, separates them from the ones you edited that are not, offers a `git stash` sequence to get past it, and exits non-zero. Nothing is stashed, reset or discarded for you — which of your edits to move is yours to decide.

`install.sh` takes no arguments; it installs, and that is all it does. Anything you would reach for a flag to say is said by environment variable instead, which is also what survives a pipe — `curl … | sh` cannot take a flag without `sh -s --` in front of it:

| Variable | Effect |
|---|---|
| `ROLE_AGENT_TOOLS` | Install into exactly these tools — space- or comma-separated, e.g. `claude` or `claude,opencode`. No prompt. An unknown name stops the run before anything is written. A name the host does not appear to have is still installed, and said to be undetected, so a typo shows itself. |
| `ROLE_AGENT_NONINTERACTIVE` | Any non-empty value: do not prompt, install the set the prompt would have started with. |
| `ROLE_AGENT_DIR` | Where the piped form keeps its clone. |

`ROLE_AGENT_TOOLS` wins where both of the first two are set, and either beats the prompt. They exist for the caller a missing terminal does not already cover — a provisioning script, a dotfiles bootstrap, a CI runner that allocates a pty and would otherwise block on the question.

Removal is the other script, and it is all-or-nothing: there is no way to remove one tool's symlinks while keeping the other's. If you need that, delete the symlinks yourself — they are only symlinks.

To remove:

```bash
curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/uninstall.sh | sh
```

It removes only symlinks that name a role-based-agent checkout — by the link's text, not by what it still resolves to, so deleting the checkout first leaves nothing behind — and never touches real files or directories.

To keep the clone elsewhere or edit the roles yourself, run `install.sh` from your own clone and it is used in place. Requires `git`.

Which clone you edit decides what it costs you. A clone you run `install.sh` from is only linked out of, never pulled, so your edits there survive every run. The clone the piped one-liner keeps at `~/.local/share/role-based-agent` is the one it fast-forwards, so an edit there is what the blocked update above is about — recoverable, but it stops updating until you move it. Edit your own clone, and leave the managed one to the installer.

## Use

A session is bound to one role at launch and cannot switch mid-session:

```bash
claude --agent pm        opencode --agent pm
claude --agent worker    opencode --agent worker
claude --agent qa        opencode --agent qa
```

The role file becomes the session's system prompt, so the session *is* that role rather than delegating to a subagent.
