# === Oh My Zsh ===
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # Disabled — Oh My Posh handles the prompt (see bottom)
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh" 2>/dev/null || true  # graceful if not yet installed

# === Shell options ===
setopt correct
setopt nocaseglob

# === History ===
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# === PATH ===
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# === Terminal ===
export TERM="xterm-256color"

# Custom aliases
alias ll="ls -la"
alias cat="bat"
alias find="fd"
alias grep="rg"
alias top="htop"

# Git aliases
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gco="git checkout"
alias gb="git branch"

# Docker aliases
alias dc="docker-compose"
alias dps="docker ps"
alias dex="docker exec -it"

# NVM setup
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Oh My Posh setup
if command -v oh-my-posh &> /dev/null; then
    unset POSH_THEME
    eval "$(oh-my-posh init zsh --config "$HOME/.config/ohmyposh/sprinks.omp.json")"
fi

# Utility
reload_zsh() {
    source ~/.zshrc
    echo "Zsh configuration reloaded!"
}
