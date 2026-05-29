# If not running interactively, bail out to prevent breaking rsync/scp
case $- in
  *i*) ;;
    *) return;;
esac

# =============================================================================
# CORE SYSTEM & HELPERS
# =============================================================================
# Load system-wide bashrc
[ -f /etc/bashrc ] && . /etc/bashrc

# Safely add directories to PATH without duplication
add_to_path() {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    export PATH="$1:$PATH"
  fi
}

# Ensure local bin exists and is in PATH
[ ! -d "$HOME/.local/bin" ] && mkdir -p "$HOME/.local/bin"
add_to_path "$HOME/.local/bin"

# Add Mason (Neovim package manager) binaries to PATH
add_to_path "$HOME/.local/share/nvim/mason/bin"

# =============================================================================
# SHELL BEHAVIOR & HISTORY
# =============================================================================
# Smart history management
shopt -s histappend
HISTCONTROL=ignoreboth
HISTSIZE=5000
HISTFILESIZE=10000

# Fix text wrapping when resizing terminal panes
shopt -s checkwinsize

# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================
# Prompt
C_GREEN="\[\e[1;32m\]"
C_BLUE="\[\e[1;34m\]"
C_RESET="\[\e[0m\]"

export PS1="${C_GREEN}\u@\h ${C_BLUE}\w ${C_RESET}\$ "

# Default Terminal
for term_cmd in kitty foot ghostty xterm; do
  if command -v "$term_cmd" >/dev/null 2>&1; then
    export TERMINAL="$term_cmd"
    break
  fi
done

# Default Editor
for editor_cmd in nvim vim vi nano; do
  if command -v "$editor_cmd" >/dev/null 2>&1; then
    export EDITOR="$editor_cmd"
    export VISUAL="$editor_cmd"
    break
  fi
done

# =============================================================================
# LANGUAGE RUNTIMES & ENV MANAGERS
# =============================================================================
# mise (Tool & Environment Manager)
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
elif [ -x "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate bash)"
fi

# Rust (Cargo global binaries)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# =============================================================================
# INTERACTIVE TOOLS & BEHAVIOR
# =============================================================================
# fzf (Fuzzy Finder)
if command -v fzf >/dev/null 2>&1; then
  # Try the modern method first (silently fail if unsupported)
  if fzf --bash >/dev/null 2>&1; then
    eval "$(fzf --bash)"
  # Fallback for legacy fzf (Standard Linux Mint/Debian apt package)
  else
    [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
    [ -f /usr/share/doc/fzf/examples/completion.bash ] && . /usr/share/doc/fzf/examples/completion.bash
  fi
fi

# zoxide (Smarter cd)
[ -x "$(command -v zoxide)" ] && eval "$(zoxide init bash --cmd cd)"

# tmux-sessionizer keybinding (Ctrl-f)
_ts_bind() {
  if [[ -n "$TMUX" ]]; then
    tmux sessionizer
  else
    tmux-sessionizer
  fi
  
  local err=$?
  if [ $err -eq 126 ]; then
    echo -e "\n[!] Permission denied: Make tmux-sessionizer executable."
  elif [ $err -eq 127 ]; then
    echo -e "\n[!] Not found: tmux-sessionizer is not installed."
  fi
}

bind '"\C-f": "\C-u_ts_bind\n"'

# Autocompletion
[[ $PS1 && ! ${BASH_COMPLETION_VERSINFO:-} && -f /usr/share/bash-completion/bash_completion ]] && \
  . /usr/share/bash-completion/bash_completion

# =============================================================================
# BACKGROUND SERVICES (SSH AGENT)
# =============================================================================
# Ensure a single SSH agent instance persists across shell sessions
[ -f "$HOME/.ssh/agent.env" ] && . "$HOME/.ssh/agent.env" >/dev/null
if ! ps -p "${SSH_AGENT_PID:-0}" >/dev/null 2>&1; then
  ssh-agent -s >"$HOME/.ssh/agent.env"
  . "$HOME/.ssh/agent.env" >/dev/null
fi

# =============================================================================
# ALIASES & COLORS
# =============================================================================
# Load separate alias file if it exists
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# Editor aliases (if nvim was selected above)
[ "$EDITOR" = "nvim" ] && alias vim="nvim" && alias vi="nvim"

# Command colors
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi
