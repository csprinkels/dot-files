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

# Configure Oh My Posh
if command -v oh-my-posh &> /dev/null; then
    # Set the path to your desired theme
    export POSH_THEME="$HOME/.config/ohmyposh/zen.toml"  # Replace with your theme file path
    eval "$(oh-my-posh init zsh)"  # Initialize Oh My Posh for Zsh
fi

# Customize the terminal prompt (if needed)
# Example of a simple custom prompt
PROMPT='%n@%m %~ %# '  # Default Zsh prompt

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
