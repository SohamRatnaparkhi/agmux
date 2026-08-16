#!/usr/bin/env bash
# agmux uninstaller — removes everything install.sh added, and nothing else.
#
#   ./uninstall.sh            remove the install, keep ~/.agmux (roots, prefix)
#   ./uninstall.sh --purge    also remove ~/.agmux
#
# Worktrees under ~/.agmux/worktrees are NEVER removed here, even with --purge:
# they are git checkouts that may hold unmerged work. Use `agmux clean` first,
# which knows which ones are safe to drop.
set -euo pipefail

PURGE=0
for arg in "$@"; do
  case "$arg" in
    --purge) PURGE=1 ;;
    -h|--help) sed -n '2,${/^#/!q;s/^# \{0,1\}//;p;}' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

say() { printf '%s\n' "$*"; }

# Remove a symlink only if it points into an agmux checkout. A user's own file
# at the same path is left alone: uninstall must not delete something install
# never created.
unlink_if_ours() {
  local dst="$1"
  if [ -L "$dst" ] && readlink "$dst" | grep -q '/agmux/'; then
    rm -f "$dst"; say "removed  $dst"
    # `[ ... ] && { ... }` as the LAST statement in a function returns non-zero
    # when the test fails, and under `set -e` that non-zero return kills the
    # whole script. It did: uninstall removed the binary and silently stopped
    # before touching anything else. Use `if` so the function ends cleanly.
    if [ -e "$dst.bak" ]; then
      mv "$dst.bak" "$dst"; say "restored $dst (from .bak)"
    fi
  elif [ -e "$dst" ]; then
    say "kept     $dst (not an agmux symlink)"
  fi
}

# Strip the marker-delimited block install.sh appended. Matching on the markers
# rather than the line means a user who moved the line inside their own config
# still gets it removed, and a user who never had it is untouched.
strip_block() {
  local file="$1" label="$2"
  [ -f "$file" ] || return 0
  grep -q "^# >>> agmux $label >>>" "$file" || { say "ok       $file (no agmux block)"; return 0; }
  cp "$file" "$file.agmux-bak"
  awk -v s="# >>> agmux $label >>>" -v e="# <<< agmux $label <<<" '
    $0 == s { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip
  ' "$file.agmux-bak" > "$file"
  say "cleaned  $file (backup: $file.agmux-bak)"
}

unlink_if_ours "$HOME/.local/bin/agmux"
unlink_if_ours "$HOME/.tmux/agents.conf"
unlink_if_ours "$HOME/.tmux.conf"        # only if --full-config was used
strip_block "$HOME/.tmux.conf" "agent manager"
strip_block "$HOME/.zshrc" "shell helpers"

DR="$HOME/.tmux/plugins/tmux/scripts/agmux_status.sh"
if [ -f "$DR" ]; then rm -f "$DR"; say "removed  $DR"; fi

if [ "$PURGE" = 1 ]; then
  if [ -d "$HOME/.agmux/worktrees" ] && [ -n "$(ls -A "$HOME/.agmux/worktrees" 2>/dev/null)" ]; then
    say ""
    say "NOT removing ~/.agmux — worktrees still exist there:"
    ls -1 "$HOME/.agmux/worktrees" | sed 's/^/    /'
    say "Run \`agmux clean\` first, then re-run with --purge."
  else
    rm -rf "$HOME/.agmux"; say "removed  $HOME/.agmux"
  fi
else
  if [ -d "$HOME/.agmux" ]; then say "kept     $HOME/.agmux (roots, prefix, worktrees); remove with --purge"; fi
fi

say ""
say "done. Your tmux config is intact; reload it with: tmux source-file ~/.tmux.conf"
