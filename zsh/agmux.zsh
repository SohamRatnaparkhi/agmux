# agmux agent manager — shell shortcuts
# p        fuzzy-cd into any repo under ~/projects
# an       spawn an agent (repo → agent → worktree)
p() { local d; d="$(ax path)" && [ -n "$d" ] && cd "$d"; }
alias an='ax new'
