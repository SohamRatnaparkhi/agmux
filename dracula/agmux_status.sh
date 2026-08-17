#!/usr/bin/env bash
# dracula custom widget: agent fleet summary from `agmux status` (cached)
"$HOME/.local/bin/agmux" status 2>/dev/null || printf '·'
