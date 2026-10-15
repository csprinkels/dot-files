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
    eval "$(oh-my-posh init zsh --config "$HOME/.config/ohmyposh/sprinks.omp.json")"
fi

# Utility
reload_zsh() {
    source ~/.zshrc
    echo "Zsh configuration reloaded!"
}

# === Caches on the Extended drive (only when it's plugged in) ===
# Keeps tool caches off the internal disk. Without the drive, tools use their defaults.
# pnpm needs nothing: it keeps its store on the same drive as the project.
EXTENDED="/Volumes/MacOS Extended"
if [ -d "$EXTENDED" ]; then
    export npm_config_cache="$EXTENDED/DevCache/npm"
    export YARN_CACHE_FOLDER="$EXTENDED/DevCache/yarn"
    export PIP_CACHE_DIR="$EXTENDED/DevCache/python"
    export GOMODCACHE="$EXTENDED/DevCache/go/mod"
    export GOCACHE="$EXTENDED/DevCache/go/cache"
    export XDG_CACHE_HOME="$EXTENDED/DevCache/xdg"
fi
