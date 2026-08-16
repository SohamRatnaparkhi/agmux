#!/usr/bin/env bash
# dracula custom widget: agent fleet summary from `ax status` (cached)
"$HOME/.local/bin/ax" status 2>/dev/null || printf '·'
