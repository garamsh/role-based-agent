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
| Codex | `~/.codex/{pm,worker,qa}.config.toml` and `~/.agents/skills/` | `codex` on `PATH`, or `~/.codex/` exists |

The role documents in `agents/` are the source of truth. Claude Code and opencode roles, and every tool's skills, are symlinked to the clone. Codex roles are generated TOML profiles: each contains the role body as `developer_instructions`, without its YAML frontmatter. Re-run the installer after editing a role to refresh its Codex profile; source edits alone do not update a generated file.

A generated profile begins with a generated region — a marker, a checksum, its source path and the `developer_instructions` line — and install and uninstall only replace or remove profiles with the expected marker, filename and an unchanged region. Anything after that region is yours and Codex's: Codex writes its own settings there on first use, and a refresh replaces only the region and keeps everything after it byte for byte, so those settings stay in place. Existing user profiles, profile symlinks, and generated profiles whose region you have edited are reported as kept during installation — move them yourself and re-run if you want the generated role there. The checksum detects edits; it is not a security signature. Your base `config.toml` is never changed. At the symlink targets, real files and directories are left alone as before.

Codex 0.134.0 or later is required for separate `NAME.config.toml` profiles selected with `codex -p NAME`. The installer does not require the Codex binary, so it can also provision a machine before Codex is installed. See the [official profile format](https://learn.chatgpt.com/docs/config-file/config-advanced#profiles).

`~/.agents/skills/` is not Codex's alone. Other tools keep skills there too, as real directories, and both scripts leave those alone. opencode reads it as well, besides `~/.claude/skills/` and its own directory, so where the skill is installed for more than one tool opencode finds it more than once: it loads one and logs `duplicate skill name` for each of the others — all links to the same clone, so which one it loads makes no difference. Claude Code and Codex each read only their own of the three, and load it once.

Re-run the same command to update: the list starts with your installed set checked, and enter refreshes exactly that set. An older skills-only Codex installation is recognized and gains role profiles on the next run. Unchecking only limits what is refreshed; it never removes. Run without a terminal — CI, cron — it refreshes in place and never blocks on a prompt. Nothing re-runs it for you: links serve the clone's current text, while profiles serve the text captured when they were generated. Editing a generated profile's region protects it from subsequent updates and removal, so maintain the role in the source clone instead if you want it to keep updating; settings added below the region do neither.

Updating that clone is a fast-forward and nothing else, so an edit of your own can block it: a file you modified there stops the update once an incoming commit lands on that same file, and a commit of your own stops a fast-forward once the histories diverge. A blocked run installs nothing and leaves your working tree and HEAD unchanged. Where something of yours is in the way it names those files, separates them from the ones you edited that are not, and offers a `git stash` sequence for them — a clone carrying commits of its own gets that list too, as the step that follows dealing with the commits. A refusal git gave for some other reason names no file, because none of yours is in the way, and points at git's own message instead. Every blocked run exits non-zero. It also lists every file the refused update would have brought, marking paths with a tool link or an unedited generated profile sourced from this clone. Those installed versions stay in use; a profile can also predate local edits to its source. User-owned target files and edited profiles are not marked. Nothing is stashed, reset or discarded for you — which of your edits to move is yours to decide.

A remote the run cannot reach is a different thing, and is not reported as one: the clone's working tree and HEAD remain as they were. The run says it could not fetch, names the commit and date it is installing from, warns that the clone may be behind, and refreshes the links and unedited profiles from it rather than failing — so a network blip does not turn an unattended update into a red build, and nothing is deleted to recover from one. Re-run once the remote is reachable and it updates as usual.

`install.sh` takes no arguments; it installs, and that is all it does. Anything you would reach for a flag to say is said by environment variable instead, which is also what survives a pipe — `curl … | sh` cannot take a flag without `sh -s --` in front of it. The scripts decide which variables those are, not this table: they are the names either script expands and never assigns, and the table is read off them rather than kept in step with them by hand. The `ROLE_AGENT_` names exist only here; the rest are the ones your shell already uses to say where a tool keeps its files:

| Variable | Effect |
|---|---|
| `ROLE_AGENT_TOOLS` | Install into exactly these tools — space- or comma-separated, e.g. `claude` or `claude,opencode`. No prompt. An unknown name stops the run before anything is written. A name the host does not appear to have is still installed, and said to be undetected, so a typo shows itself. |
| `ROLE_AGENT_NONINTERACTIVE` | Any non-empty value: do not prompt, install the set the prompt would have started with. |
| `ROLE_AGENT_DIR` | Where the piped form keeps its clone. |
| `XDG_DATA_HOME` | Where the piped form keeps its clone when `ROLE_AGENT_DIR` is unset: `$XDG_DATA_HOME/role-based-agent` in place of `~/.local/share/role-based-agent`. |
| `CLAUDE_CONFIG_DIR` | Claude Code's config directory in place of `~/.claude`, so the target paths listed above move with it. `uninstall.sh` reads it too and needs the value install had: without it that run looks under `~/.claude`, removes nothing there, and reports the directories it did not find. |
| `XDG_CONFIG_HOME` | In place of `~/.config`, under which opencode's directory is found. Read by `uninstall.sh` on the same terms. |
| `CODEX_HOME` | Codex's config directory in place of `~/.codex`, used for detection and generated role profiles. `uninstall.sh` needs the same value to find those profiles. The skill remains at `~/.agents/skills/`. |
| `HOME` | The base every default above is built from. Read by both scripts. |

`ROLE_AGENT_TOOLS` wins where it and `ROLE_AGENT_NONINTERACTIVE` are both set, and either beats the prompt. They exist for the caller a missing terminal does not already cover — a provisioning script, a dotfiles bootstrap, a CI runner that allocates a pty and would otherwise block on the question.

Removal is the other script, and covers all tools: there is no tool-selection option. For selective removal, delete only that tool's installed links or generated profiles yourself.

To remove:

```bash
curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/uninstall.sh | sh
```

It removes unedited generated Codex profiles even if their source checkout is gone. It also removes symlinks that name a role-based-agent checkout — by the link's text, not by what it still resolves to. A relative link text is read against the link's own directory, so where you run it from cannot change what it removes. A profile whose region is unedited is removed whole, with any settings Codex or you added below it. Other real files and directories, profile symlinks, and profiles with an edited region are preserved. Edited profiles retaining their marker are reported as kept.

To keep the clone elsewhere or edit the roles yourself, run `install.sh` from your own clone and it is used in place. Installing from a URL requires `git`; profile generation uses standard shell utilities and needs no Python or Node runtime. That clone has to hold the roles it is being asked to install: an `agents/` directory with no role document in it stops the run before installing anything. Skills are not required — a clone carrying none installs the roles as usual and says that it linked no skill.

Which clone you edit decides what it costs you. A clone you run `install.sh` from supplies links and generated profiles and is never pulled, so your edits there survive every run. The clone the piped one-liner keeps at `~/.local/share/role-based-agent` is the one it fast-forwards, so an edit there is what the blocked update above is about — recoverable, and it costs nothing until an incoming commit lands on that same file, which is when the update starts refusing and the clone stops moving. Edit your own clone, and leave the managed one to the installer.

## Use

A session is bound to one role at launch and cannot switch mid-session:

```bash
claude --agent pm        opencode --agent pm        codex -p pm
claude --agent worker    opencode --agent worker    codex -p worker
claude --agent qa        opencode --agent qa        codex -p qa
```

In Claude Code and opencode the role document becomes the session's system prompt, so the session *is* that role rather than delegating to a subagent.

Codex selects the generated profile by name. Launch it from the project you want to work on; additional CLI options and a starting prompt work as usual:

```bash
codex -p pm "Review the open pull requests"
codex -p worker -C /path/to/task-worktree
```

The profile sets only `developer_instructions`. Codex keeps its built-in instructions and inherits your other settings, such as model and permissions. The role replaces any base `developer_instructions` value; project or CLI overrides can take precedence over the profile. YAML frontmatter, including any `permission:` block you add, is not imported. These profiles configure the main session, not subagents, and require no shell alias or function.
