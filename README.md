# role-based-agent

Roles and procedures for AI coding agents, installed once per machine and shared by every project.

Three roles divide the work: a **PM** on the default branch that reviews, merges, supervises, and runs the workers; **workers** on task branches that implement and deliver PRs; and a **QA** agent that hunts for problems and files them as issues with evidence. One merge authority keeps concurrent work from landing in conflicting directions.


Eight skills ship alongside them: QA runs `review-architecture` and `review-craft`, the PM the other six. Each skill's own description says what it does and when; in short:

- `sync-conventions`: brings a conventions template repository into a project and keeps it current. It names paths and assumes a file layout, so its reach ends where that layout does.
- `plan-work`: keeps the issue backlog small and sends work to standing roles, each issue to a fresh session.
- `review-pr`: holds the order of a PR review and, on approve, merges it.
- `run-agents`: which model each role runs on (Opus for the PM and the final review, Sonnet for every role agent) and how long a session lives.
- `review-architecture`: QA's read-only scan for shallow modules that could be deep ones.
- `review-craft`: QA's read-only scan for workmanship, with web-sourced candidates.
- `delegate-goal`: settles a goal with the user, records it as an issue and hands over a `/goal` line; in deadline mode it hands off to `meet-deadline`, which cuts waiting, never quality.

`review-architecture` and `delegate-goal` are adapted from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT).

These live on your machine rather than in a project repo because they describe how *you* operate agents, not what any one codebase is. The roles name no paths and assume no file layout: each finds the rules through whatever entry point the project gives contributors, then treats them as binding. They do assume a project that keeps its conventions in writing: an index of rules, a pull request template, documentation of the system's shape. Without that the roles still work but have little to enforce. Changing this repository has its own rules, in `CONVENTIONS.md`, which reach every file here, documentation included.

Apart from `run-agents` and `delegate-goal`, nothing here names a platform. Where a host ships procedure guides of its own, the PM loads the ones covering its next action instead of working from memory, and `plan-work` defers to them on the same mechanism.

It is installed by a script rather than published as a plugin, because a plugin cannot carry the roles: a plugin's agents are "subagent definitions Claude can delegate to", never the role the session runs as, and a Codex profile is configuration no plugin writes. Packaging and versioned releases are what the installer and the release tags already do.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/install.sh | sh
```

Clones to `~/.local/share/role-based-agent`, then lists the tools it finds on the host as checkboxes, starting checked (on an update, your installed set), each with what checking it would do (paths to link, profiles to generate or regenerate, paths kept because they are yours or another checkout's), read off the disk before anything is written. Toggle rows by number (`2`, `1 3` or `1,3`), `a` checks all, `n` none, and an empty entry installs what is checked. An entry holding anything else is refused whole; three refused in a row stop the run.

| Tool | Targets | Detected by |
|---|---|---|
| Claude Code | `~/.claude/{agents,skills}/` | `claude` on `PATH`, or `~/.claude/` exists |
| opencode | `~/.config/opencode/{agents,skills}/` | `opencode` on `PATH`, or `~/.config/opencode/` exists |
| Codex | `~/.codex/{pm,worker,qa}.config.toml` and `~/.agents/skills/` | `codex` on `PATH`, or `~/.codex/` exists |

The role documents in `agents/` are the source of truth. Claude Code and opencode roles, and every tool's skills, are symlinks to the clone, so they always read current. Codex roles are generated TOML profiles holding the role body as `developer_instructions`: a snapshot, refreshed by re-running the installer after a role changes. Real files, directories, other links and Codex profiles that are not unedited generated ones of this clone are left alone and reported as kept; move them yourself and re-run. Your base `config.toml` is never changed.

A generated profile starts with a region of marker, checksum, source path, `# Commit:` and the `developer_instructions` line. Only an unedited region is replaced or removed; everything after it (Codex writes its own settings there) is kept byte for byte on refresh. The checksum detects edits and is not a security signature. A profile is current while its `# Commit:` matches `git -C <clone> log -1 --format=%H -- agents/<role>.md`; it ends in `+ uncommitted edits` when generated from an uncommitted edit. Releases are tagged `vN.N.N`, and each skill carries `metadata.version` in its frontmatter. A running session loaded its role document at start, so an update reaches new sessions and the workers they dispatch, not one already running.

Codex 0.134.0 or later is required for `NAME.config.toml` profiles selected with `codex -p NAME`; the installer itself does not need the Codex binary. See the [official profile format](https://learn.chatgpt.com/docs/config-file/config-advanced#profiles).

`~/.agents/skills/` is shared: other tools keep real skill directories there, which both scripts leave alone, and opencode reads it besides its own directory and `~/.claude/skills/`. A skill installed for several tools is found more than once by opencode, which loads one and logs `duplicate skill name` for the rest; they are links to the same clone, so it makes no difference.

### Update

Re-run the same command. The list starts with your installed set checked and enter refreshes exactly that set; unchecking limits what is refreshed and never removes anything. Run without a terminal (CI, cron), it refreshes in place and never prompts. Nothing re-runs it for you: a role or skill new to the clone has no link or profile until you do, and is linked to the clone that run came from, so keep to one clone. A skill removed from the clone has the link the installer wrote removed by the next run, in the tools that run covers.

The piped form updates its clone by fast-forward only. If a file you edited there, or a commit of your own, is in the way, the run installs nothing, changes no file or HEAD, exits non-zero, names the files and offers a `git stash` sequence (or, for commits, what to do with them), and lists the files the update would have brought, marking those with an installed link or unedited profile, which stay in use. Nothing is stashed, reset or discarded for you. If the remote cannot be reached, the run says so, names the commit it installs from and refreshes from the clone as it stands, so a network failure does not break an unattended run; re-run once it is reachable.

### Environment

`install.sh` takes no arguments; configure it by environment variable, which survives a pipe (`curl … | sh` cannot take a flag without `sh -s --`).

| Variable | Effect |
|---|---|
| `ROLE_AGENT_TOOLS` | Install into exactly these tools, space- or comma-separated, e.g. `claude,opencode`. No prompt. An unknown name stops the run before anything is written; a name the host does not appear to have is still installed and said to be undetected. |
| `ROLE_AGENT_NONINTERACTIVE` | Any non-empty value: no prompt, install the set the prompt would have started with. |
| `ROLE_AGENT_DIR` | Where the piped form keeps its clone. |
| `XDG_DATA_HOME` | The clone lives at `$XDG_DATA_HOME/role-based-agent` when `ROLE_AGENT_DIR` is unset. |
| `CLAUDE_CONFIG_DIR` | Claude Code's config directory in place of `~/.claude`. |
| `XDG_CONFIG_HOME` | In place of `~/.config`, under which opencode's directory is found. |
| `CODEX_HOME` | Codex's config directory in place of `~/.codex`. Skills stay at `~/.agents/skills/`. |
| `HOME` | The base every default is built from. |

`ROLE_AGENT_TOOLS` wins over `ROLE_AGENT_NONINTERACTIVE`, and either beats the prompt. `uninstall.sh` reads the last four too, and needs the values install had: without them it looks in the defaults and warns that directories were not there.

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/garamsh/role-based-agent/main/uninstall.sh | sh
```

It takes no arguments and covers every tool at once; for one tool, delete its links or generated profiles yourself. It removes symlinks that name a role-based-agent checkout, by the link's text rather than where it resolves, so a link left dangling by deleting the checkout still goes. It removes unedited generated Codex profiles whole, even if their source checkout is gone and with any settings added below the region. Other real files and directories, profile symlinks and edited profiles are preserved; edited profiles that keep their marker are reported as kept.

### Your own clone

Run `install.sh` from your own clone to use it in place: it is never pulled, so your edits survive every run. A link or unedited profile an earlier run made from another clone is kept and reported, not repointed, so every tool goes on serving that one clone until you move or delete them and re-run. The clone must hold an `agents/` directory with a role document; skills are optional. Installing from a URL requires `git`; profile generation needs only standard shell utilities.

## Use

A session is bound to one role at launch and cannot switch mid-session:

```bash
claude --agent pm        opencode --agent pm        codex -p pm
claude --agent worker    opencode --agent worker    codex -p worker
claude --agent qa        opencode --agent qa        codex -p qa
```

In Claude Code and opencode the role document becomes the session's system prompt, so the session *is* that role rather than delegating to a subagent.

To keep a role running as a long-lived coordinator in Claude Code without a terminal, launch it in the background: `claude --bg --name <name> --agent <role>`. The workers it delegates to run inside that session's process, so `claude stop` stops them mid-task. A background session has no terminal to answer a permission prompt, so it blocks at the first one: allow what the role needs before launching it.

Codex selects the generated profile by name. Launch it from the project you want to work on; additional CLI options and a starting prompt work as usual:

```bash
codex -p pm "Review the open pull requests"
codex -p worker -C /path/to/task-worktree
```

The profile sets only `developer_instructions`. Codex keeps its built-in instructions and inherits your other settings, such as model and permissions. The role replaces any base `developer_instructions` value; project or CLI overrides can take precedence over the profile. YAML frontmatter, including any `permission:` block you add, is not imported. These profiles configure the main session, not subagents, and require no shell alias or function.
