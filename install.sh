#!/usr/bin/env bash
# agmux installer — idempotent. Symlinks configs to this repo so `git pull` updates everything.
# Safe to re-run. Existing non-symlink files are backed up as *.bak once.
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"

link() { # $1 = repo file, $2 = target path
  local src="$REPO/$1" dst="$2"
  [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ] && { echo "ok      $dst"; return; }
  [ -e "$dst" ] && [ ! -L "$dst" ] && { mv "$dst" "$dst.bak"; echo "backup  $dst -> $dst.bak"; }
  mkdir -p "$(dirname "$dst")"
  ln -sf "$src" "$dst"; echo "linked  $dst"
}

# deps check (install what's missing via brew if available)
for dep in tmux fzf fd jq; do
  command -v "$dep" >/dev/null || { command -v brew >/dev/null && brew install "$dep" || echo "MISSING: $dep"; }
done

link bin/agmux         "$HOME/.local/bin/agmux"
chmod +x "$REPO/bin/agmux"
link tmux/tmux.conf   "$HOME/.tmux.conf"
link tmux/agents.conf "$HOME/.tmux/agents.conf"

# dracula custom widget lives inside the plugin dir (re-copied since plugin updates wipe it)
DR="$HOME/.tmux/plugins/tmux/scripts"
if [ -d "$DR" ]; then cp "$REPO/dracula/agmux_status.sh" "$DR/agmux_status.sh" && chmod +x "$DR/agmux_status.sh" && echo "copied  $DR/agmux_status.sh"
else echo "note: dracula not installed yet — TPM will fetch it on first tmux start; re-run install.sh after"; fi

# onboarding: leader (prefix) key. Skip silently if already chosen or non-interactive.
if [ ! -f "$HOME/.agmux/prefix.conf" ]; then
  mkdir -p "$HOME/.agmux"
  KEY="C-a"
  if [ -t 0 ]; then
    echo
    echo "tmux leader key — the prefix you press before every shortcut."
    echo "  C-a       (recommended: home-row, replaces the default C-b)"
    echo "  C-b       tmux default"
    echo "  C-Space   thumb-friendly"
    printf 'leader key [C-a]: '
    read -r ANS || true
    [ -n "${ANS:-}" ] && KEY="$ANS"
  fi
  printf 'unbind C-b\nset -g prefix %s\nbind %s send-prefix\n' "$KEY" "$KEY" > "$HOME/.agmux/prefix.conf"
  echo "leader   $KEY  (change later: agmux prefix <key>)"
fi

# zsh shortcuts: source the repo file from .zshrc (append once)
ZLINE="source \"$REPO/zsh/agmux.zsh\""
grep -qF "$ZLINE" "$HOME/.zshrc" 2>/dev/null || { printf '\n# >>> agmux agent manager >>>\n%s\n# <<< agmux agent manager <<<\n' "$ZLINE" >> "$HOME/.zshrc"; echo "zshrc   appended source line"; }

# reload live tmux server if one is running
tmux source-file "$HOME/.tmux.conf" 2>/dev/null && echo "tmux    reloaded" || true
echo "done. open a new shell (or: source ~/.zshrc)"
