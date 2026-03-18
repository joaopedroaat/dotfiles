# .bashrc

# --- System & Prompt ---
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

export PS1="[\u@\h \w]\$ "

# --- Path Helpers ---
add_to_path() {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    export PATH="$1:$PATH"
  fi
}

add_to_path "$HOME/.local/bin"
add_to_path "$HOME/.local/share/fnm"
add_to_path "$HOME/go/bin"

# --- Tools Integration ---
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell bash)"
fi

if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --bash)"
fi

if command -v tmux-sessionizer >/dev/null 2>&1; then
  bind '"\C-f": "\C-utmux-sessionizer\n"'
fi

# --- Language Runtimes ---
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
fi

# --- SSH Agent ---
if [ -f "$HOME/.ssh/agent.env" ]; then
  . "$HOME/.ssh/agent.env" > /dev/null
fi

if ! ps -p "$SSH_AGENT_PID" > /dev/null 2>&1; then
  ssh-agent -s > "$HOME/.ssh/agent.env"
  . "$HOME/.ssh/agent.env" > /dev/null
fi

# --- Autocompletion ---
[[ $PS1 && ! ${BASH_COMPLETION_VERSINFO:-} && -f /usr/share/bash-completion/bash_completion ]] && \
  . /usr/share/bash-completion/bash_completion
