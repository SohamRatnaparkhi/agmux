# agmux

A thin manager layer over tmux for terminal coding agents (Claude Code, opencode, grok, codex, pi). It never wraps or replaces the agents' own UIs — it only finds, spawns, and jumps between them, from a laptop keyboard or a phone tap.

- **Picker**: every running agent across all sessions, blocked-first, live pane preview
- **Spawn**: repo → agent → task, with automatic git-worktree isolation when a repo already hosts an agent
- **Status**: `✋2 ▶5` (blocked / working) in the tmux status bar, fed by `claude agents --json` (cached, async, never blocks rendering); codex blocked-state read from its own terminal title
- **Mobile**: tap the status bar in any SSH client or the browser terminal — no keyboard chords
- **Web**: one command exposes tmux at your Tailscale address for any browser

## Install

```sh
git clone https://github.com/SohamRatnaparkhi/agmux ~/projects/agmux
~/projects/agmux/install.sh
```

Idempotent; symlinks configs to the repo so `git pull` updates everything. Requires tmux ≥ 3.4, fzf, fd, jq (auto-installed via brew if missing). Tmux plugins (TPM, Dracula, resurrect, continuum, yank) auto-install on first tmux start.

## Shortcuts

Your leader key is chosen during install (default `C-a`); change it any time with `agmux prefix <key>`.

### Agents (agmux layer)

| Key | Action |
|---|---|
| `<leader> a` | Agent picker — fuzzy, blocked-first, preview, Enter jumps |
| `<leader> A` | Spawn agent **in the current repo** (skips repo picker) |
| `<leader> n` | Spawn agent — pick repo → agent → task name |
| `<leader> m` | Compact agent menu |
| tap status-bar **left** | Agent menu (mobile) |
| tap status-bar **right** | Full picker (mobile) |

### Shell

| Command | Action |
|---|---|
| `p` | Fuzzy-cd into any repo under `~/projects` |
| `an` | Spawn an agent (same as `<leader> n`) |
| `agmux web on\|off` | Browser terminal over Tailscale |
| `agmux repos` | Rescan roots now (also auto-rescans hourly) |
| `agmux root add <path>` | Register a new folder to scan — its repos appear everywhere immediately |
| `agmux root list` / `rm` | Show or remove scan roots |
| `agmux prefix <key>` | Change the tmux leader key |
| `agmux clean` | Remove finished worktrees — keeps any with an agent inside, uncommitted changes, or unmerged commits (prints the merge command for those) |

### Base tmux

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

## Projects

`agmux` scans every folder listed in `~/.agmux/roots` (default: `~/projects`) for git repos, up to 6 levels deep.

- **New repo inside an existing root** — picked up automatically on the next rescan (hourly), or run `agmux repos` to see it now.
- **New folder somewhere else** — `agmux root add ~/work` and it's registered permanently; repos under it show up in the picker, `p`, and spawn flows immediately.

## Layout convention

- **Session = repo**, named `workspace/repo` (e.g. `cortex/hydradb`)
- **Window = agent**, named `agent·task` (e.g. `claude·auth-refactor`)
- Second agent on a busy repo gets an isolated worktree under `~/.agmux/worktrees/` on branch `ax/<task>` (shared checkout one keystroke away)
- Claude Code's process names itself after its version (`2.1.233`); `automatic-rename-format` maps that back to `claude` in window names

## Files

| Repo file | Installs to |
|---|---|
| `bin/agmux` | `~/.local/bin/agmux` (symlink) |
| `tmux/tmux.conf` | `~/.tmux.conf` (symlink) |
| `tmux/agents.conf` | `~/.tmux/agents.conf` (symlink) |
| `dracula/agmux_status.sh` | `~/.tmux/plugins/tmux/scripts/` (copy — plugin updates wipe it; re-run install.sh) |
| `zsh/agmux.zsh` | sourced from `~/.zshrc` |
