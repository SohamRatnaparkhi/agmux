# ax

A thin manager layer over tmux for terminal coding agents (Claude Code, opencode, grok, codex, pi). It never wraps or replaces the agents' own UIs — it only finds, spawns, and jumps between them, from a laptop keyboard or a phone tap.

- **Picker**: every running agent across all sessions, blocked-first, live pane preview
- **Spawn**: repo → agent → task, with automatic git-worktree isolation when a repo already hosts an agent
- **Status**: `✋2 ▶5` (blocked / working) in the tmux status bar, fed by `claude agents --json` (cached, async, never blocks rendering); codex blocked-state read from its own terminal title
- **Mobile**: tap the status bar in any SSH client or the browser terminal — no keyboard chords
- **Web**: one command exposes tmux at your Tailscale address for any browser

## Install

```sh
git clone https://github.com/SohamRatnaparkhi/ax ~/projects/ax
~/projects/ax/install.sh
```

Idempotent; symlinks configs to the repo so `git pull` updates everything. Requires tmux ≥ 3.4, fzf, fd, jq (auto-installed via brew if missing). Tmux plugins (TPM, Dracula, resurrect, continuum, yank) auto-install on first tmux start.

## Shortcuts

Prefix is `C-a`.

### Agents (ax layer)

| Key | Action |
|---|---|
| `C-a a` | Agent picker — fuzzy, blocked-first, preview, Enter jumps |
| `C-a A` | Spawn agent **in the current repo** (skips repo picker) |
| `C-a n` | Spawn agent — pick repo → agent → task name |
| `C-a m` | Compact agent menu |
| tap status-bar **left** | Agent menu (mobile) |
| tap status-bar **right** | Full picker (mobile) |

### Shell

| Command | Action |
|---|---|
| `p` | Fuzzy-cd into any repo under `~/projects` |
| `an` | Spawn an agent (same as `C-a n`) |
| `ax web on\|off` | Browser terminal over Tailscale |
| `ax repos` | Refresh the repo cache (auto-refreshes every 6h) |
| `ax clean` | Remove finished worktrees — keeps any with an agent inside, uncommitted changes, or unmerged commits (prints the merge command for those) |

### Base tmux

| Key | Action |
|---|---|
| `C-a c` | New window (in current path) |
| `C-a \|` / `C-a -` | Split horizontal / vertical (in current path) |
| `C-a h j k l` | Move between panes |
| `C-a H J K L` | Resize pane (repeatable) |
| `S-←` / `S-→` | Previous / next window (no prefix) |
| `C-a r` | Rename session |
| `C-a y` | Toggle synchronized panes |
| `C-a p` | Paste from macOS clipboard |
| `C-a R` | Reload tmux config |
| `C-a C-d` / `C-a C-g` | Dark / light theme |
| `v` `y` (copy mode) | Vi-style select / yank → clipboard |

## Layout convention

- **Session = repo**, named `workspace/repo` (e.g. `cortex/hydradb`)
- **Window = agent**, named `agent·task` (e.g. `claude·auth-refactor`)
- Second agent on a busy repo gets an isolated worktree under `~/.ax/worktrees/` on branch `ax/<task>` (shared checkout one keystroke away)
- Claude Code's process names itself after its version (`2.1.233`); `automatic-rename-format` maps that back to `claude` in window names

## Files

| Repo file | Installs to |
|---|---|
| `bin/ax` | `~/.local/bin/ax` (symlink) |
| `tmux/tmux.conf` | `~/.tmux.conf` (symlink) |
| `tmux/agents.conf` | `~/.tmux/agents.conf` (symlink) |
| `dracula/ax_status.sh` | `~/.tmux/plugins/tmux/scripts/` (copy — plugin updates wipe it; re-run install.sh) |
| `zsh/ax.zsh` | sourced from `~/.zshrc` |
