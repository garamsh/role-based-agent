# role-based-agent

Roles and procedures for AI coding agents, installed once per machine and shared by every project.

Three roles divide the work: a **PM** on the default branch that reviews, merges, supervises, and runs the workers; **workers** on task branches that implement and deliver PRs; and a **QA** agent that hunts for problems and files them as issues with evidence. One merge authority keeps concurrent work from landing in conflicting directions.

One skill ships alongside them. `sync-conventions` brings a conventions template repository into a project and keeps it current — first-time adoption, initial bootstrap, and later updates. It records the template as a git remote and reads that template's own convention index to decide what the project keeps, so a template that adds or renames a tier of conventions needs no change here — but one that indexes its conventions some other way is not a template it can read. Unlike the roles it is not neutral: it names paths and assumes a file layout, so its reach ends where that layout does.

These live on your machine rather than in a project repo because they describe how *you* operate agents, not what any one codebase is. The roles name no paths and assume no file layout: each finds the rules through whatever entry point the project gives contributors, then treats them as binding.

Changing this repository has its own rules, in `CONVENTIONS.md`. They reach every file here, documentation included: what each kind of file may become, and what a change to one has to survive before it lands.

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

Roles and skills are symlinked, so there is no second copy to fall behind the clone: a session loads exactly what the clone holds, however old that is. A real file or directory you put at a target path is left alone and reported as kept — move it yourself and re-run to link there.

Re-run the same command to update: the list starts with your installed set checked, and enter refreshes exactly that set. Unchecking only limits what is refreshed; it never removes. Run without a terminal — CI, cron — it refreshes in place and never blocks on a prompt, so the same one-liner stays safe for unattended updates of a clone you have not edited yourself. Nothing re-runs it for you, and until it is run again the linked paths keep serving the clone's text: what a session loads is as old as the last run, and nothing at the point of reading dates it.

Updating that clone is a fast-forward and nothing else, so an edit of your own can block it: a file you modified there stops the update once an incoming commit lands on that same file, and a commit of your own there stops it outright. A blocked run installs nothing and leaves the clone and your edits exactly as they were. Where something of yours is in the way it names those files, separates them from the ones you edited that are not, and offers a `git stash` sequence for them — a clone carrying commits of its own gets that list too, as the step that follows dealing with the commits. A refusal git gave for some other reason names no file, because none of yours is in the way, and points at git's own message instead. Every blocked run exits non-zero. It also lists every file the refused update would have brought, marking the ones a tool directory links to this clone: those are what a session keeps loading, at the clone's older text, for as long as the update is refused — and they need not be the files you edited, or overlap with them at all. A path no tool directory links is not marked: where your own file sits at the target instead, what a session loads there is that file and not this clone's. Nothing is stashed, reset or discarded for you — which of your edits to move is yours to decide.

A remote the run cannot reach is a different thing, and is not reported as one: nothing was fetched, so the clone on disk is exactly as it was and every link it serves still resolves. The run says it could not fetch, names the commit and date it is installing from, warns that the clone may be behind with nothing in a session able to tell, and refreshes the links from it rather than failing — so a network blip does not turn an unattended update into a red build, and nothing is deleted to recover from one. Re-run once the remote is reachable and it updates as usual.

`install.sh` takes no arguments; it installs, and that is all it does. Anything you would reach for a flag to say is said by environment variable instead, which is also what survives a pipe — `curl … | sh` cannot take a flag without `sh -s --` in front of it. The scripts decide which variables those are, not this table: they are the names either script expands and never assigns, and the table is read off them rather than kept in step with them by hand. The `ROLE_AGENT_` names exist only here; the rest are the ones your shell already uses to say where a tool keeps its files:

| Variable | Effect |
|---|---|
| `ROLE_AGENT_TOOLS` | Install into exactly these tools — space- or comma-separated, e.g. `claude` or `claude,opencode`. No prompt. An unknown name stops the run before anything is written. A name the host does not appear to have is still installed, and said to be undetected, so a typo shows itself. |
| `ROLE_AGENT_NONINTERACTIVE` | Any non-empty value: do not prompt, install the set the prompt would have started with. |
| `ROLE_AGENT_DIR` | Where the piped form keeps its clone. |
| `XDG_DATA_HOME` | Where the piped form keeps its clone when `ROLE_AGENT_DIR` is unset: `$XDG_DATA_HOME/role-based-agent` in place of `~/.local/share/role-based-agent`. |
| `CLAUDE_CONFIG_DIR` | Claude Code's config directory in place of `~/.claude`, so the target paths listed above move with it. `uninstall.sh` reads it too and needs the value install had: without it that run looks under `~/.claude`, removes nothing there, and reports the directories it did not find. |
| `XDG_CONFIG_HOME` | In place of `~/.config`, under which opencode's directory is found. Read by `uninstall.sh` on the same terms. |
| `HOME` | The base every default above is built from. Read by both scripts. |

`ROLE_AGENT_TOOLS` wins where it and `ROLE_AGENT_NONINTERACTIVE` are both set, and either beats the prompt. They exist for the caller a missing terminal does not already cover — a provisioning script, a dotfiles bootstrap, a CI runner that allocates a pty and would otherwise block on the question.

Removal is the other script, and it is all-or-nothing: there is no way to remove one tool's symlinks while keeping the other's. If you need that, delete the symlinks yourself — they are only symlinks.

To remove:

```bash
curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/uninstall.sh | sh
```

It removes only symlinks that name a role-based-agent checkout — by the link's text, not by what it still resolves to, so deleting the checkout first leaves nothing behind — and never touches real files or directories. A relative link text is read against the link's own directory, so where you run it from cannot change what it removes.

To keep the clone elsewhere or edit the roles yourself, run `install.sh` from your own clone and it is used in place. Requires `git`. That clone has to hold the roles it is being asked to install: an `agents/` directory with no role definition in it stops the run before anything is written, exactly as a missing one does. Skills are not required of it — a clone carrying none links the roles as usual and says that it linked no skill.

Which clone you edit decides what it costs you. A clone you run `install.sh` from is only linked out of, never pulled, so your edits there survive every run. The clone the piped one-liner keeps at `~/.local/share/role-based-agent` is the one it fast-forwards, so an edit there is what the blocked update above is about — recoverable, and it costs nothing until an incoming commit lands on that same file, which is when the update starts refusing and the clone stops moving. Edit your own clone, and leave the managed one to the installer.

## Use

A session is bound to one role at launch and cannot switch mid-session:

```bash
claude --agent pm        opencode --agent pm
claude --agent worker    opencode --agent worker
claude --agent qa        opencode --agent qa
```

The role file becomes the session's system prompt, so the session *is* that role rather than delegating to a subagent.
