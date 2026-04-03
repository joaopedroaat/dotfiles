# .bashrc

# --- System & Prompt ---
# Load system-wide bashrc if it exists
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

export PS1="[\u@\h \w]\$ "

# --- Path Helpers ---
# Function to safely add directories to PATH without duplication
add_to_path() {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    export PATH="$1:$PATH"
  fi
}

# Add local binaries to PATH
add_to_path "$HOME/.local/bin"

# --- Homebrew Setup ---
# Homebrew must be loaded early so other tools (fnm, fzf) can be detected
if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
fi

# --- Language Runtimes ---
# Only add Go binaries to PATH if the Go compiler is installed
if command -v go >/dev/null 2>&1; then
  add_to_path "$HOME/go/bin"
fi

# Load Cargo (Rust) environment if present
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# --- Tools Integration ---

# Initialize fnm (Fast Node Manager)
FNM_PATH="$HOME/.local/share/fnm"

# Add fnm to PATH
if [ -d "$FNM_PATH" ]; then
  add_to_path "$FNM_PATH"
fi

# Initialize fnm environment once with desired flags
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --shell bash)"
fi

# Initialize fzf (Command-line fuzzy finder)
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --bash)"
fi

# Keybinding for tmux-sessionizer (Ctrl-f)
if command -v tmux-sessionizer >/dev/null 2>&1; then
  if [[ -n "$TMUX" ]]; then
    # Inside tmux: call the custom command we defined in tmux.conf
    bind '"\C-f": "\C-utmux sessionizer\n"'
  else
    # Outside tmux: clear line and run normally
    bind '"\C-f": "\C-utmux-sessionizer\n"'
  fi
fi

# --- Aliases ---
# Enable color support for common commands
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# --- SSH Agent ---
# Ensure a single SSH agent instance persists across shell sessions
if [ -f "$HOME/.ssh/agent.env" ]; then
  . "$HOME/.ssh/agent.env" > /dev/null
fi

if ! ps -p "$SSH_AGENT_PID" > /dev/null 2>&1; then
  ssh-agent -s > "$HOME/.ssh/agent.env"
  . "$HOME/.ssh/agent.env" > /dev/null
fi

# --- Autocompletion ---
# Enable programmable completion features
[[ $PS1 && ! ${BASH_COMPLETION_VERSINFO:-} && -f /usr/share/bash-completion/bash_completion ]] && \
  . /usr/share/bash-completion/bash_completion

