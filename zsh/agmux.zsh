# agmux agent manager — shell shortcuts
# p        fuzzy-cd into any repo under the configured roots
# an       spawn an agent (repo → agent → new/resume)
p() { local d; d="$(agmux path)" && [ -n "$d" ] && cd "$d"; }
alias an='agmux new'
alias asweep='agmux sweep'
