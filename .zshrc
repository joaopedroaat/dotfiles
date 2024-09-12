# Neovim aliases
alias vi=nvim
alias vim=nvim

# Makes Neovim the default text editor
export EDITOR=nvim
export VISUAL=nvim

# Yazi with yy
function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Set default bat theme
export BAT_THEME="base16-256"

# Set up oh-my-posh
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/amro.omp.json)"

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Set up zoxide
eval "$(zoxide init zsh)"
alias cd=z

# Add autosuggestions
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh

# kitten icat img alias
alias icat="kitten icat"
