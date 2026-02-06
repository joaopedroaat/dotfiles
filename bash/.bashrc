# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# Prompt
export PS1="[\u@\h \w]\$ "

# Path function
add_to_path() {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    export PATH="$1:$PATH"
  fi
}

# Local bin
add_to_path "$HOME/.local/bin"

# Fast Node Manager
FNM_PATH="/home/joaopedroaat/.local/share/fnm"
add_to_path "$FNM_PATH"
eval "$(fnm env --use-on-cd --shell bash)"

# Go
GOPATH="$HOME/go"
add_to_path "$GOPATH/bin"

# Tmux sessionizer
if command -v tmux-sessionizer >/dev/null 2>&1; then
  bind '"\C-f": "\C-utmux-sessionizer\n"'
fi

# Fzf Integration
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --bash)"
fi

# Bash completion
[[ $PS1 &&
  ! ${BASH_COMPLETION_VERSINFO:-} &&
  -f /usr/share/bash-completion/bash_completion ]] &&
  . /usr/share/bash-completion/bash_completion
