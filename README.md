# agmux

A thin manager layer over tmux for terminal coding agents (Claude Code, opencode, grok, codex, pi). It never wraps or replaces the agents' own UIs. It only finds, spawns, jumps, resumes, and sweeps them, from a laptop keyboard or a phone tap.

- **Picker**: `+ new agent` and `> spawn here` stay pinned at the top, so a swept-empty list is still a spawn menu, never a dead `0/0`. Under that: every running agent across all sessions, blocked-first, with a live pane preview. Leftover windows whose process already exited still show up as `○`.
- **Spawn**: repo → agent → new conversation / continue last / pick a past session. Isolated git-worktree only for a brand-new conversation on a busy repo.
- **Resume**: tap a leftover `○` row, or pick a saved chat with `agmux resume` / `<leader> e`. That same CLI restarts (`claude --resume <id>`, `grok --resume <id>`, and the equivalents). A Claude session stays Claude.
- **Sweep**: `agmux sweep` closes inactive agents (dead `○`, plus idle ones in other sessions) and then drops leftover agent-only tmux sessions. It never kills the session you are in, and never touches real work sessions (k8s, hydradb, …). `--all` also closes live agents. Chats stay on disk.
- **Status**: `✋2 ▶5` (blocked / working) in the tmux status bar, fed by `claude agents --json` (cached, async, never blocks rendering). Codex blocked-state is read from its own terminal title.
- **Search**: type a query (`agmux search`, `<leader> w`, or `/` in the menu). It opens in your default browser as a new tab.
- **Mobile**: tap anywhere on the status bar. The menu is a full-screen list with fat rows: new, here, resume, search, sweep, live jump, then `○` restart. Single tap accepts.
- **Web**: one command exposes tmux at your Tailscale address for any browser

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/SohamRatnaparkhi/agmux/main/install.sh | bash
```

That is the whole thing. It clones to `~/.local/share/agmux`, asks once for your tmux leader key, and prints your shortcuts.

**It does not touch your tmux config.** It appends exactly one `source-file` line to `~/.tmux.conf` and leaves everything else alone, because a manager layer that overwrites your config is not a layer. Four paths are touched in total:

| Path | What |
|---|---|
| `~/.local/bin/agmux` | symlink to the checkout |
| `~/.tmux/agents.conf` | symlink to the checkout (the key bindings) |
| `~/.tmux.conf` | one `source-file` line appended |
| `~/.zshrc` | one `source` line appended (the `p` / `an` helpers) |

Prefer to clone yourself, or want the author's complete tmux setup (Dracula, plugins, the base bindings listed below)?

```sh
git clone https://github.com/SohamRatnaparkhi/agmux ~/projects/agmux
~/projects/agmux/install.sh                 # just agmux
~/projects/agmux/install.sh --full-config   # + the full tmux.conf (yours is backed up to .bak)
```

Idempotent, so re-run it any time; `git pull` updates everything through the symlinks. Requires tmux ≥ 3.4, plus fzf, fd and jq (auto-installed via brew when available).

### Uninstall

```sh
~/.local/share/agmux/uninstall.sh            # keeps ~/.agmux (roots, prefix, worktrees)
~/.local/share/agmux/uninstall.sh --purge    # removes it too
```

Removes only what the installer added, restores any `.bak` it made, and refuses to purge while worktrees still exist (run `agmux clean` first).

## Shortcuts

Your leader key is chosen during install (default `C-a`); change it any time with `agmux prefix <key>`.

### Agents (agmux layer)

| Key | Action |
|---|---|
| `<leader> a` | Agent picker: `+ new` / `> here` always, then fuzzy jump (blocked-first) |
| `<leader> A` | Spawn agent in the current repo (pick Claude / Grok / …) |
| `<leader> n` | Spawn: pick repo, then agent |
| `<leader> m` | Menu: **+ new agent** picks the CLI next (current repo). `n` if you need a different repo. |
| `<leader> e` | Resume a past session in the same CLI |
| `<leader> w` | Search the web (opens your default browser) |
| `<leader> x` | Sweep inactive agents and leftover agent-only sessions (never the one you are in) |
| tap the status bar | Same menu (the whole bar is the tap target) |

### Shell

| Command | Action |
|---|---|
| `p` | Fuzzy-cd into any repo under the configured roots |
| `an` | Spawn an agent (same as `<leader> n`) |
| `asweep` | Same as `agmux sweep` |
| `agmux resume` | Pick a past chat and restart it in the same CLI |
| `agmux search` | Type a query, open it in the default browser |
| `agmux sweep` | Close inactive agents (dead `○`, plus idle ones in *other* sessions) and drop leftover agent-only sessions. Never kills the session you are in. `--all` also closes live agents. `--dry-run` prints the plan. |
| `agmux web on\|off` | Browser terminal over Tailscale |
| `agmux repos` | Rescan roots now (also auto-rescans hourly) |
| `agmux root add <path>` | Register a new folder to scan. Its repos appear everywhere immediately. |
| `agmux root list` / `rm` | Show or remove scan roots |
| `agmux prefix <key>` | Change the tmux leader key |
| `agmux clean` | Remove finished worktrees. Keeps any with an agent inside, uncommitted changes, or unmerged commits (prints the merge command for those). |

### Base tmux

These ship in `tmux/tmux.conf`, so they apply only if you installed with `--full-config`.

| Key | Action |
|---|---|
| `<leader> c` | New window (in current path) |
| `<leader> \|` / `<leader> -` | Split horizontal / vertical (in current path) |
| `<leader> h j k l` | Move between panes |
| `<leader> H J K L` | Resize pane (repeatable) |
| `S-←` / `S-→` | Previous / next window (no prefix) |
| `<leader> r` | Rename session |
| `<leader> y` | Toggle synchronized panes |
| `<leader> p` | Paste from macOS clipboard |
| `<leader> R` | Reload tmux config |
| `<leader> C-d` / `<leader> C-g` | Dark / light theme |
| `v` `y` (copy mode) | Vi-style select / yank → clipboard |

## Resume

Saved chats live in each CLI's own store. agmux does not copy them. It lists them and restarts that same binary:

| Agent | Restart command |
|---|---|
| Claude | `claude --dangerously-skip-permissions --resume <id>` |
| Grok | `grok --always-approve --resume <id>` |
| OpenCode | `opencode --auto --session <id>` |
| pi | `pi --session <id>` |
| Codex | `codex --dangerously-bypass-approvals-and-sandbox resume <id>` |

From the menu, a leftover `○` window restarts in that pane. From `agmux resume`, a saved chat opens a new window in the original repo.

## Sweep

Default `agmux sweep` (also `<leader> x` / menu `x`) is the safe cleanup:

1. Close leftover `○` windows everywhere (the process is already gone).
2. Close idle `·` agents only in sessions nobody is attached to. Blocked `✋` and working `▶` stay. Idle agents in the session you are looking at stay.
3. Drop other tmux sessions that now only have the placeholder `shell` window spawn created. The attached session is never killed. Sessions with real work windows (`k8s`, `go-api`, hydradb, …) stay.
4. Chats remain on disk. Bring one back with the menu or `agmux resume`.

`agmux sweep --all` also closes live agent windows. `agmux sweep --dry-run` prints the plan and changes nothing.

## Projects

`agmux` scans every folder listed in `~/.agmux/roots` (default: `~/projects`) for git repos, up to 6 levels deep.

- **New repo inside an existing root**: picked up automatically on the next rescan (hourly), or run `agmux repos` to see it now.
- **New folder somewhere else**: `agmux root add ~/work` and it's registered permanently. Repos under it show up in the picker, `p`, and spawn flows immediately.

## Layout convention

- **Session = repo**, named `workspace/repo` (e.g. `cortex/hydradb`)
- **Window = agent**, named `agent·task` (e.g. `claude·auth-refactor`). Automatic-rename is turned off on those windows so a finished agent stays visible as `○` until you sweep it.
- Second agent on a busy repo gets an isolated worktree under `~/.agmux/worktrees/` on branch `ax/<task>` (shared checkout one keystroke away)
- Claude Code's native binary names its process after its version (`2.1.233`); `automatic-rename-format` maps that back to `claude` for windows that still auto-rename

## Files

| Repo file | Installs to |
|---|---|
| `bin/agmux` | `~/.local/bin/agmux` (symlink) |
| `tmux/tmux.conf` | `~/.tmux.conf` (symlink), only with `--full-config` |
| `tmux/agents.conf` | `~/.tmux/agents.conf` (symlink) |
| `dracula/agmux_status.sh` | `~/.tmux/plugins/tmux/scripts/` (copy. Plugin updates wipe it; re-run install.sh) |
| `zsh/agmux.zsh` | sourced from `~/.zshrc` |
