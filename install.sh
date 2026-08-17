#!/usr/bin/env bash
# agmux installer — idempotent, safe to re-run.
#
#   curl -fsSL https://raw.githubusercontent.com/SohamRatnaparkhi/agmux/main/install.sh | bash
#
# or, from a clone:   ./install.sh
#
# By default this touches FOUR things and nothing else:
#   ~/.local/bin/agmux        symlink to this repo
#   ~/.tmux/agents.conf       symlink to this repo (the key bindings)
#   ~/.tmux.conf              ONE `source-file` line appended, your config kept
#   ~/.zshrc                  ONE `source` line appended (the `p` / `an` helpers)
#
# It does NOT replace your tmux.conf. An earlier version did, and that is the
# wrong trade for a tool that is supposed to sit on top of the terminal you
# already have: a manager layer that overwrites your config is not a layer.
# If you DO want the author's full tmux setup (dracula, plugins, sane defaults),
# ask for it explicitly:  ./install.sh --full-config
set -euo pipefail

FULL_CONFIG=0
for arg in "$@"; do
  case "$arg" in
    --full-config) FULL_CONFIG=1 ;;
    -h|--help) sed -n '2,${/^#/!q;s/^# \{0,1\}//;p;}' "$0"; exit 0 ;;
    *) echo "unknown option: $arg (try --help)" >&2; exit 1 ;;
  esac
done

# ── bootstrap ───────────────────────────────────────────────────────────────
# Piped from curl there is no repo around us, so fetch one and re-exec from it.
# ${BASH_SOURCE:-} is empty under `curl | bash`, which is the tell.
# Resolve our own location, but ONLY from a real file on disk. Under
# `curl | bash` there is no script file: BASH_SOURCE[0] is the string "bash",
# and `dirname bash` is ".", so a naive resolve silently yields the user's
# CURRENT WORKING DIRECTORY. If that directory happened to contain bin/agmux
# the installer would install from it and never clone — which is exactly what
# happened while testing this, from inside the repo, making the bootstrap look
# like it worked when it had not run at all.
SRC_FILE="${BASH_SOURCE[0]:-}"
if [ -n "$SRC_FILE" ] && [ -f "$SRC_FILE" ]; then
  REPO="$(cd "$(dirname "$SRC_FILE")" && pwd)"
else
  REPO=""
fi
if [ -z "$REPO" ] || [ ! -f "$REPO/bin/agmux" ]; then
  command -v git >/dev/null || { echo "git is required to bootstrap" >&2; exit 1; }
  DEST="${AGMUX_SRC:-$HOME/.local/share/agmux}"
  if [ -d "$DEST/.git" ]; then
    echo "updating  $DEST"
    git -C "$DEST" pull --ff-only --quiet || echo "  (pull skipped: local changes)"
  else
    echo "cloning   $DEST"
    mkdir -p "$(dirname "$DEST")"
    git clone --depth 1 --quiet https://github.com/SohamRatnaparkhi/agmux.git "$DEST"
  fi
  exec bash "$DEST/install.sh" "$@"
fi

say() { printf '%s\n' "$*"; }

link() { # $1 = path inside repo, $2 = destination
  local src="$REPO/$1" dst="$2"
  [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ] && { say "ok       $dst"; return; }
  [ -e "$dst" ] && [ ! -L "$dst" ] && { mv "$dst" "$dst.bak"; say "backup   $dst -> $dst.bak"; }
  mkdir -p "$(dirname "$dst")"
  ln -sf "$src" "$dst"; say "linked   $dst"
}

# Append a line to a file exactly once, wrapped in markers so it can be found
# and removed later (uninstall.sh reads the same markers).
append_once() { # $1 = file, $2 = line, $3 = label
  local file="$1" line="$2" label="$3"
  [ -f "$file" ] || { mkdir -p "$(dirname "$file")"; : > "$file"; }
  if grep -qF "$line" "$file" 2>/dev/null; then say "ok       $file (already sources agmux)"; return; fi
  printf '\n# >>> agmux %s >>>\n%s\n# <<< agmux %s <<<\n' "$label" "$line" "$label" >> "$file"
  say "appended $file"
}

# ── dependencies ────────────────────────────────────────────────────────────
# tmux/fzf are required; fd and jq are used by the repo scan and the Claude
# roster read. Report what is missing instead of failing: agmux degrades to a
# smaller feature set rather than refusing to install.
MISSING=""
for dep in tmux fzf fd jq; do
  command -v "$dep" >/dev/null && continue
  if command -v brew >/dev/null; then
    say "installing $dep via brew…"
    brew install "$dep" >/dev/null 2>&1 || MISSING="$MISSING $dep"
  else
    MISSING="$MISSING $dep"
  fi
done
[ -n "$MISSING" ] && say "MISSING:$MISSING  (install these, then re-run)"

command -v tmux >/dev/null || { echo "tmux is required and was not found" >&2; exit 1; }

# ── the four things ─────────────────────────────────────────────────────────
link bin/agmux "$HOME/.local/bin/agmux"
chmod +x "$REPO/bin/agmux"
link tmux/agents.conf "$HOME/.tmux/agents.conf"

if [ "$FULL_CONFIG" = 1 ]; then
  # Explicitly requested: adopt the author's whole tmux config. The previous
  # file is backed up as ~/.tmux.conf.bak by link().
  link tmux/tmux.conf "$HOME/.tmux.conf"
else
  # The default, and the point of the tool: keep YOUR tmux.conf, add one line.
  append_once "$HOME/.tmux.conf" 'source-file ~/.tmux/agents.conf' "agent manager"
fi

append_once "$HOME/.zshrc" "source \"$REPO/zsh/agmux.zsh\"" "shell helpers"

# PATH check — a linked binary nobody can run is not installed. Worth saying
# out loud because the failure ("command not found: agmux") looks like the
# install failed when it actually succeeded.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) say ""
     say "NOTE: ~/.local/bin is not on your PATH. Add this to ~/.zshrc:"
     say '      export PATH="$HOME/.local/bin:$PATH"' ;;
esac

# ── dracula widget (optional) ───────────────────────────────────────────────
# Copied, not linked: the plugin dir is wiped on plugin update, so a symlink
# would be replaced by a stale file. Re-run install.sh after a TPM update.
DR="$HOME/.tmux/plugins/tmux/scripts"
if [ -d "$DR" ]; then
  cp "$REPO/dracula/agmux_status.sh" "$DR/agmux_status.sh"
  chmod +x "$DR/agmux_status.sh"
  say "copied   $DR/agmux_status.sh"
  say "         add  custom:agmux_status.sh  to @dracula-plugins to show it"
fi

# ── onboarding: the leader key ──────────────────────────────────────────────
# Only written if absent, and only asked interactively — under `curl | bash`
# stdin is the script itself, so reading from it would consume the script.
if [ ! -f "$HOME/.agmux/prefix.conf" ]; then
  mkdir -p "$HOME/.agmux"
  KEY="C-a"
  if [ -t 0 ]; then
    say ""
    say "tmux leader key — the prefix you press before every shortcut."
    say "  C-a       home-row, replaces the default C-b (recommended)"
    say "  C-b       tmux default, leave my binding alone"
    say "  C-Space   thumb-friendly"
    printf 'leader key [C-a]: '
    read -r ANS || true
    [ -n "${ANS:-}" ] && KEY="$ANS"
  fi
  if [ "$KEY" = "C-b" ]; then
    # Don't rebind anything if they kept the default; writing the unbind/set
    # pair for C-b is a no-op that only creates a file to be confused by later.
    : > "$HOME/.agmux/prefix.conf"
  else
    printf 'unbind C-b\nset -g prefix %s\nbind %s send-prefix\n' "$KEY" "$KEY" > "$HOME/.agmux/prefix.conf"
  fi
  say "leader   $KEY   (change later: agmux prefix <key>)"
fi

# ── first scan, so the picker is useful immediately ─────────────────────────
# An empty picker on first launch reads as "broken", not "no roots configured".
if [ ! -s "$HOME/.agmux/roots" ] && [ -d "$HOME/projects" ]; then
  mkdir -p "$HOME/.agmux"
  printf '%s\n' "$HOME/projects" > "$HOME/.agmux/roots"
  say "root     $HOME/projects  (add more: agmux root add <path>)"
fi
if [ -s "$HOME/.agmux/roots" ]; then
  "$HOME/.local/bin/agmux" repos >/dev/null 2>&1 || true
  [ -f "$HOME/.agmux/repos" ] && say "scanned  $(wc -l < "$HOME/.agmux/repos" | tr -d ' ') projects"
fi

tmux source-file "$HOME/.tmux.conf" 2>/dev/null && say "tmux     reloaded" || true

LEADER="$(sed -n 's/^set -g prefix //p' "$HOME/.agmux/prefix.conf" 2>/dev/null)"
LEADER="${LEADER:-C-b}"
say ""
say "done. open a new shell (or: source ~/.zshrc)"
say ""
say "  $LEADER a      jump to any running agent"
say "  $LEADER A      spawn an agent right here"
say "  $LEADER n      pick a repo, spawn an agent there"
say "  $LEADER m      menu: new / resume / sweep / jump (phone)"
say "  $LEADER e      resume a past session in the same CLI"
say "  $LEADER w      search the web (default browser)"
say "  $LEADER x      sweep inactive agents (chats stay)"
say ""
say "  agmux help   everything else"
