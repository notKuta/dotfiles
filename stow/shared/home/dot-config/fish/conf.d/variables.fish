# Set editor
set -gx EDITOR /usr/bin/nvim

# Format man pages
set -x MANROFFOPT "-c"
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
