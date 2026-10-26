# role-based-agent

Roles and procedures for AI coding agents, installed once per machine and shared by every project.

Three roles divide the work: a **PM** on the default branch that reviews, merges, supervises, and runs the workers; **workers** on task branches that implement and deliver PRs; and a **QA** agent that hunts for problems and files them as issues with evidence. One merge authority keeps concurrent work from landing in conflicting directions.

Four skills ship alongside them, and the PM runs all four.

`sync-conventions` brings a conventions template repository into a project and keeps it current — first-time adoption, initial bootstrap, and later updates. It records the template as a git remote and reads that template's own convention index to decide what the project keeps, so a template that adds or renames a tier of conventions needs no change here — but one that indexes its conventions some other way is not a template it can read. Unlike the roles it is not neutral: it names paths and assumes a file layout, so its reach ends where that layout does.

`manage-issues` keeps the backlog small enough to schedule from: it searches before filing, merges issues whose target paths overlap or that must land in one pull request, and closes rather than deletes, so the next batch of work can be chosen by reading the open issues rather than remembering them.

`assign-work` sends that work out. Two issues run at once exactly when their target paths are disjoint; overlapping issues go to one worker in one dispatch. It measures which files change together from the project's git history rather than guessing, checks each brief against its issue before sending it, and accounts for every worker until it is retired. Like the roles, these two name no platform and no host command — `assign-work`'s one command is git's.

`review-work` reviews what comes back and, on approve, merges it. It holds the order of a review, not its rules: which checks run and what may merge unverified stay the project's, found before the diff, and the PM role's own standard applies only where the project has none. It verifies the merge of head onto base rather than the head, starting that run first and reviewing while it goes, re-reviews only the delta after a request for changes, refuses to merge once the base or the head has moved since verification, and afterwards confirms that the tree which landed is the one verified and that every author of a squash survived it. It names no platform either: posting and merging are the host's, and every command it names is git's.

These live on your machine rather than in a project repo because they describe how *you* operate agents, not what any one codebase is. The roles name no paths and assume no file layout: each finds the rules through whatever entry point the project gives contributors, then treats them as binding.

Changing this repository has its own rules, in `CONVENTIONS.md`. They reach every file here, documentation included: what each kind of file may become, and what a change to one has to survive before it lands.

They do assume a project that keeps its conventions in writing — an index of rules, a template saying what a pull request must state, documentation describing the system's shape. On a repository with none of that, the roles still work but have little to enforce.

Nothing here names a platform. The PM's rule on hosts says only that a host may ship procedure guides of its own, and that you load the ones covering your next action rather than working from memory. It does not say which host, or which commands — a host that ships guides advertises them itself, and its own copy is the one that cannot drift from the binary you are about to run. A summary kept here could only go stale, so there is none. `assign-work` defers the same way: where it and a host's guide decide the same mechanism, the host's wins.

It is installed by a script rather than published as a plugin, because a plugin cannot carry the roles: a plugin's agents are, in Claude Code's own words, "subagent definitions Claude can delegate to" — a subagent a session hands work to, never the role the session runs as — and a Codex profile is configuration no plugin writes. The other two things a plugin is for, packaging the pieces as one unit and publishing versioned releases, are what the installer and the release tags already do, and a skill linked into a skills directory works without one.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/install.sh | sh
```

Clones to `~/.local/share/role-based-agent`, then asks which tools to install into with a checkbox list. Only tools it finds on the host are listed, and they start checked. Under each row is what checking it would do — how many paths it would link or generate, how many profiles it would regenerate, and how many it would keep because something of yours or another checkout's is there — read off the disk before anything is written; the run's own report afterwards is what it did. An entry toggles any number of rows at once, as `2`, `1 3` or `1,3`; `a` checks every row and `n` none; each entry reprints the list, and an empty one installs whatever is checked. An entry holding anything other than a listed number, `a` or `n` is refused whole, and three refused in a row stop the run:

| Tool | Targets | Detected by |
|---|---|---|
| Claude Code | `~/.claude/{agents,skills}/` | `claude` on `PATH`, or `~/.claude/` exists |
| opencode | `~/.config/opencode/{agents,skills}/` | `opencode` on `PATH`, or `~/.config/opencode/` exists |
| Codex | `~/.codex/{pm,worker,qa}.config.toml` and `~/.agents/skills/` | `codex` on `PATH`, or `~/.codex/` exists |

The role documents in `agents/` are the source of truth. Claude Code and opencode roles, and every tool's skills, are symlinked to the clone. Codex roles are generated TOML profiles: each contains the role body as `developer_instructions`, without its YAML frontmatter. Re-run the installer after editing a role to refresh its Codex profile; source edits alone do not update a generated file.

A generated profile begins with a generated region — a marker, a checksum, its source path, the commit its body came from and the `developer_instructions` line — and install and uninstall only replace or remove profiles with the expected marker, filename and an unchanged region. Anything after that region is yours and Codex's: Codex writes its own settings there on first use, and a refresh replaces only the region and keeps everything after it byte for byte, so those settings stay in place. Existing user profiles, profile symlinks, generated profiles whose region you have edited, and unedited ones whose recorded source is another clone's are reported as kept during installation — move them yourself and re-run if you want the generated role there. The checksum detects edits; it is not a security signature. Your base `config.toml` is never changed. At the symlink targets, real files, directories and any link other than the one the run would write are left alone and reported as kept.

A link serves the clone's current text; a profile is a snapshot, and one that is behind reads exactly like one that is current. Its `# Commit:` line says which it is: the commit that last changed its source role, so the profile is current while that line matches `git -C <clone> log -1 --format=%H -- agents/<role>.md`. It ends in `+ uncommitted edits` when the body was generated from an edit not yet committed, and reads `none` when the clone has no git history. The marker's `v1` says how to parse the file, not what it was made from, so it does not change with the commit; a profile written before the commit line existed has none, is still recognised as generated, and gains one on its next refresh. Releases are tagged `vN.N.N` from `v0.1.0`, so `git -C <clone> describe --tags --contains <commit>` names the first release carrying a recorded commit, and fails for one no release carries yet — the clone still follows the default branch, not a tag. Each skill carries a version too, as `metadata.version` in its frontmatter, the place the [Agent Skills specification](https://agentskills.io/specification) gives one. A running session is a snapshot too, taken when it started: it loads its role document once, so an update reaches new sessions and the workers they dispatch — a freshly delegated subagent read the changed file at spawn — but not a session already running, while the link beside it reads current. A plain resume does not pick the change up, because Claude Code reuses the prompt it recorded for that conversation; resuming with `--system-prompt-snapshot off` did, keeping the conversation. That was measured on a role definition kept at project level, and Claude Code documents the flag as rebuilding the prompt on every request, not for an `--agent` body in particular; a user-level definition, and whether the rebuild costs prompt caching, were not measured.

Codex 0.134.0 or later is required for separate `NAME.config.toml` profiles selected with `codex -p NAME`. The installer does not require the Codex binary, so it can also provision a machine before Codex is installed. See the [official profile format](https://learn.chatgpt.com/docs/config-file/config-advanced#profiles).

`~/.agents/skills/` is not Codex's alone. Other tools keep skills there too, as real directories, and both scripts leave those alone. opencode reads it as well, besides `~/.claude/skills/` and its own directory, so where a skill is installed for more than one tool opencode finds it more than once: it loads one and logs `duplicate skill name` for each of the others — all links to the same clone, so which one it loads makes no difference. Claude Code and Codex each read only their own of the three, and load each skill once.

Re-run the same command to update: the list starts with your installed set checked, and enter refreshes exactly that set. An older skills-only Codex installation is recognized and gains role profiles on the next run. Unchecking only limits what is refreshed; it never removes. Run without a terminal — CI, cron — it refreshes in place and never blocks on a prompt. Nothing re-runs it for you: links serve the clone's current text, while profiles serve the text captured when they were generated. A role or skill new to the clone has no link or profile until the installer runs, so one that has just merged reaches no tool before that run. It is linked to whichever clone that run came from, because a new skill has no earlier link to keep: on a machine with two clones, new skills then serve from one and everything else from the other, and the cure is installing from one clone only, not another run. The reverse is not cleaned up either. The installer links what the clone holds and removes nothing, so a skill removed from the clone leaves each tool's link to it behind, dangling; `uninstall.sh` removes links by their text, so running it and then the installer leaves only what the clone still holds. Editing a generated profile's region protects it from subsequent updates and removal, so maintain the role in the source clone instead if you want it to keep updating; settings added below the region do neither.

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
| `CODEX_HOME` | Codex's config directory in place of `~/.codex`, used for detection and generated role profiles. `uninstall.sh` needs the same value to find those profiles. Skills remain at `~/.agents/skills/`. |
| `HOME` | The base every default above is built from. Read by both scripts. |

`ROLE_AGENT_TOOLS` wins where it and `ROLE_AGENT_NONINTERACTIVE` are both set, and either beats the prompt. They exist for the caller a missing terminal does not already cover — a provisioning script, a dotfiles bootstrap, a CI runner that allocates a pty and would otherwise block on the question.

Removal is the other script, and covers all tools: there is no tool-selection option. For selective removal, delete only that tool's installed links or generated profiles yourself.

To remove:

```bash
curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/uninstall.sh | sh
```

It removes unedited generated Codex profiles even if their source checkout is gone. It also removes symlinks that name a role-based-agent checkout — by the link's text, not by what it still resolves to. A relative link text is read against the link's own directory, so where you run it from cannot change what it removes. A profile whose region is unedited is removed whole, with any settings Codex or you added below it. Other real files and directories, profile symlinks, and profiles with an edited region are preserved. Edited profiles retaining their marker are reported as kept.

To keep the clone elsewhere or edit the roles yourself, run `install.sh` from your own clone and it is used in place; a link or unedited generated profile an earlier run made from another clone is kept and reported rather than repointed or regenerated, so every tool goes on serving that one clone until you move or delete them and re-run. Installing from a URL requires `git`; profile generation uses standard shell utilities and needs no Python or Node runtime. That clone has to hold the roles it is being asked to install: an `agents/` directory with no role document in it stops the run before installing anything. Skills are not required — a clone carrying none installs the roles as usual and says that it linked no skill.

Which clone you edit decides what it costs you. A clone you run `install.sh` from supplies links and generated profiles and is never pulled, so your edits there survive every run. The clone the piped one-liner keeps at `~/.local/share/role-based-agent` is the one it fast-forwards, so an edit there is what the blocked update above is about — recoverable, and it costs nothing until an incoming commit lands on that same file, which is when the update starts refusing and the clone stops moving. Edit your own clone, and leave the managed one to the installer.

## Use

A session is bound to one role at launch and cannot switch mid-session:

```bash
claude --agent pm        opencode --agent pm        codex -p pm
claude --agent worker    opencode --agent worker    codex -p worker
claude --agent qa        opencode --agent qa        codex -p qa
```

In Claude Code and opencode the role document becomes the session's system prompt, so the session *is* that role rather than delegating to a subagent.

To keep a role running as a long-lived coordinator in Claude Code without a terminal, launch it in the background: `claude --bg --name <name> --agent <role>`. Measured on Claude Code 2.1.310: the workers it delegates to run inside that session's process, so `claude stop` on it stops them mid-task. `claude respawn <id>` restarted the same session, and its delegated worker carried on in the same worktree without repeating a step; `claude --bg --resume <id>`, run right after `claude stop`, started a new session instead, from which the old one's worker could not be reached — contrary to `claude --help`, which says it continues the same ID unless the session is still running. Whether `respawn` rebuilds the role document, the snapshot above, was not measured. A background session has no terminal to answer a permission prompt, so it blocks at the first one: allow what the role needs before launching it.

Codex selects the generated profile by name. Launch it from the project you want to work on; additional CLI options and a starting prompt work as usual:

```bash
codex -p pm "Review the open pull requests"
codex -p worker -C /path/to/task-worktree
```

The profile sets only `developer_instructions`. Codex keeps its built-in instructions and inherits your other settings, such as model and permissions. The role replaces any base `developer_instructions` value; project or CLI overrides can take precedence over the profile. YAML frontmatter, including any `permission:` block you add, is not imported. These profiles configure the main session, not subagents, and require no shell alias or function.
