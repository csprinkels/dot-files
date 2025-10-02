# Enable the desired Zsh theme
ZSH_THEME="agnoster"  # You can change this to another theme (e.g., robbyrussell, or a custom theme)

# Enable useful plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Enable command auto-correction
setopt correct

# Enable case-insensitive globbing (e.g., file matching)
setopt nocaseglob

# Set the history size
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Set up Nerd Fonts or other custom fonts (you must have Nerd Fonts installed)
# If using iTerm, make sure the font is set correctly in preferences (Hack Nerd Font, Fira Code, etc.)



# Optional: Add custom aliases here
alias ll='ls -lA'
alias gs='git status'
alias gco='git checkout'

# Optional: Add any custom functions here
# e.g., a function to reload the zsh config
reload_zsh() {
    source ~/.zshrc
    echo "Zsh configuration reloaded!"
}

# Initialize completion system
autoload -U compinit
compinit

# Ensure the terminal supports 256 colors
export TERM="xterm-256color"

# Enable auto-completion
autoload -U compinit
compinit

# Set the PATH if you have custom locations
export PATH="$HOME/bin:$PATH"

# Optional: Customize the prompt style with colors or add more settings here

# Added by Windsurf
export PATH="/Users/sprinkel/.codeium/windsurf/bin:$PATH"

# Added by Windsurf
export PATH="/Users/sprinkel/.codeium/windsurf/bin:$PATH"

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

# NVM setup
export NVM_DIR="/Users/christiansprinkel/.nvm"
[ -s "/Users/christiansprinkel/.nvm/nvm.sh" ] && \. "/Users/christiansprinkel/.nvm/nvm.sh"
[ -s "/Users/christiansprinkel/.nvm/bash_completion" ] && \. "/Users/christiansprinkel/.nvm/bash_completion"

# Docker aliases
alias dc="docker-compose"
alias dps="docker ps"
alias dex="docker exec -it"

# Oh My Posh setup
if command -v oh-my-posh &> /dev/null; then
    eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/catppuccin_frappe.omp.json)"
fi
export PATH="$HOME/.local/bin:$PATH"
