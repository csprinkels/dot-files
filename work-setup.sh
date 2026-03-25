#!/bin/bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Optional: set DRY_RUN=1 to print actions without making changes
DRY_RUN="${DRY_RUN:-0}"

# Print with colors and emojis
function info() {
    echo -e "${GREEN}✅ $1${NC}"
}

function warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

function error() {
    echo -e "${RED}❌ $1${NC}"
}

function section() {
    echo ""
    echo -e "${BLUE}🚀 $1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' $(seq 1 ${#1}))${NC}"
}

function log_action() {
    if [ "$DRY_RUN" = "1" ]; then
        echo -e "${BLUE}[DRY RUN] $1${NC}"
    else
        echo -e "${BLUE}  → $1${NC}"
    fi
}

# Welcome message
echo "🖥️  Work IT Computer Setup 🖥️"
echo "==================================================="
echo "This script will set up your work Mac for development."
[ "$DRY_RUN" = "1" ] && echo -e "${YELLOW}DRY RUN: no changes will be made.${NC}"
echo ""

# Create necessary directories (internal)
section "Creating Directories"
if [ "$DRY_RUN" != "1" ]; then
    mkdir -p "$HOME/.config/ohmyposh"
    mkdir -p "$HOME/dotfiles"
    mkdir -p "$HOME/Developer"
fi
info "Directories created successfully!"

# Copy configuration files to appropriate locations (backup existing with timestamp)
section "Setting Up Configuration Files"
echo "Copying configuration files..."

backup_if_exists() {
    local path="$1"
    if [ -e "$path" ] && [ "$DRY_RUN" != "1" ]; then
        local stamp=$(date +%Y%m%d-%H%M%S)
        mv "$path" "${path}.backup.$stamp"
        log_action "Backed up $path → ${path}.backup.$stamp"
    fi
}

# Copy .gitconfig
if [ -f "./config-files/.gitconfig" ]; then
    if [ -f "$HOME/.gitconfig" ]; then
        backup_if_exists "$HOME/.gitconfig"
    fi
    if [ "$DRY_RUN" != "1" ]; then
        cp ./config-files/.gitconfig "$HOME/dotfiles/.gitconfig"
        cp ./config-files/.gitconfig "$HOME/.gitconfig"
    fi
    log_action "Placed .gitconfig at $HOME/.gitconfig and $HOME/dotfiles/.gitconfig"
    info ".gitconfig copied successfully!"
else
    warn ".gitconfig not found in config-files directory."
fi

# .zshrc is copied AFTER Oh My Zsh install (see below) so OMZ can't clobber it.
if [ -f "./config-files/.zshrc" ] && [ "$DRY_RUN" != "1" ]; then
    cp ./config-files/.zshrc "$HOME/dotfiles/.zshrc"
    log_action "Saved .zshrc to $HOME/dotfiles/.zshrc (will deploy after Oh My Zsh)"
fi

# Copy sprinks.omp.json (Oh My Posh theme)
if [ -f "./config-files/sprinks.omp.json" ]; then
    if [ -f "$HOME/.config/ohmyposh/sprinks.omp.json" ]; then
        backup_if_exists "$HOME/.config/ohmyposh/sprinks.omp.json"
    fi
    if [ "$DRY_RUN" != "1" ]; then
        cp ./config-files/sprinks.omp.json "$HOME/.config/ohmyposh/sprinks.omp.json"
    fi
    info "Oh My Posh theme copied successfully!"
else
    warn "sprinks.omp.json not found in config-files directory."
fi

# Copy Ghostty config
GHOSTTY_CONFIG_SRC="./config-files/ghostty/config"
GHOSTTY_CONFIG_DEST="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
if [ -f "$GHOSTTY_CONFIG_SRC" ]; then
    if [ "$DRY_RUN" != "1" ]; then
        mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
        if [ -f "$GHOSTTY_CONFIG_DEST" ]; then
            backup_if_exists "$GHOSTTY_CONFIG_DEST"
        fi
        cp "$GHOSTTY_CONFIG_SRC" "$GHOSTTY_CONFIG_DEST"
    fi
    info "Ghostty config copied successfully!"
else
    warn "Ghostty config not found in config-files directory."
fi

# Check if Homebrew is installed
section "Setting up Homebrew"
if ! command -v brew &> /dev/null; then
    warn "Homebrew is not installed. Installing now..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for the current session if it was just installed
    if [[ -d "/opt/homebrew/bin" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        # Add to shell profile for future sessions (idempotent)
        if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        fi
    elif [[ -d "/usr/local/bin" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
        fi
    fi

    info "Homebrew installed successfully!"
else
    info "Homebrew is already installed."
fi

# Set Homebrew environment variables for macOS version compatibility
# These prevent auto-update issues with unsupported/beta macOS versions
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_SYSTEM_ENV_TAKES_PRIORITY=1
info "Homebrew environment configured for your macOS version."

# Update Homebrew (optional - skipped if version compatibility issues exist)
echo "Checking for Homebrew updates..."
# Try to update brew, but don't fail if it doesn't work due to version issues
if brew update 2>/dev/null; then
    echo "Upgrading Homebrew packages..."
    brew upgrade 2>/dev/null || warn "Some brew upgrades failed, continuing..."
    info "Homebrew updated successfully!"
else
    warn "Homebrew update skipped (macOS version compatibility), continuing with installations..."
fi

# Install XCode Command Line Tools if not installed
section "Installing XCode Command Line Tools"
if ! xcode-select -p &> /dev/null; then
    warn "XCode Command Line Tools not found. Installing..."
    xcode-select --install
    info "XCode Command Line Tools installation started. Please complete the installation prompt."
    read -p "Press enter once XCode Command Line Tools installation is complete..."
else
    info "XCode Command Line Tools already installed."
fi

# Install Git if not already installed
section "Setting up Git"
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    brew install git
    info "Git installed successfully!"
else
    info "Git already installed."
fi

# Configure Git if not configured and .gitconfig wasn't copied
if [ ! -f "$HOME/.gitconfig" ] && [ -z "$(git config --global user.name)" ]; then
    echo "Configuring Git..."
    read -p "Enter your Git username: " git_username
    read -p "Enter your Git email: " git_email
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    info "Git configured successfully!"
else
    info "Git already configured."
fi

# Install development tools
section "Installing Development Tools"
dev_tools=(
    "visual-studio-code"   # VS Code
    "docker"               # Containerization
    "github"               # GitHub Desktop
    "ghostty"              # Terminal emulator
)

echo "Installing development tools..."
for tool in "${dev_tools[@]}"; do
    echo "Installing $tool..."
    if brew list --cask "$tool" &>/dev/null; then
        info "$tool is already installed."
    elif [ "$DRY_RUN" = "1" ]; then
        log_action "Would install --cask $tool"
    elif brew install --cask "$tool"; then
        info "$tool installed successfully!"
    else
        warn "Failed to install $tool."
    fi
done

# Install apps
section "Installing Apps"
apps=(
    "appcleaner"                # App Uninstaller
    "thebrowsercompany-dia"     # Dia Browser
    "parsec"                    # Remote desktop
    "alt-tab"                   # Windows-like alt-tab
    "synergy"                   # Network KVM
    "google-chrome"             # Chrome Browser
    "keka"                      # Zip File Manager
    "apple-configurator"        # Apple Configurator
    "blip"                      # Blip
    "anydesk"                   # Remote desktop
    "raycast"                   # Spotlight Replacement
    "logmein"                   # LogMeIn remote access
    "rectangle"                 # Window management
)

echo "Installing apps..."
for app in "${apps[@]}"; do
    echo "Installing $app..."
    if brew list --cask "$app" &>/dev/null; then
        info "$app is already installed."
    elif [ "$DRY_RUN" = "1" ]; then
        log_action "Would install --cask $app"
    elif brew install --cask "$app"; then
        info "$app installed successfully!"
    else
        warn "Failed to install $app."
    fi
done

# Note: Node + TypeScript come from NVM + npm (below). No separate brew install needed.

# Install package managers and build tools
section "Installing Package Managers & Build Tools"
tools=(
    "yarn"                 # JavaScript package manager
    "pnpm"                 # Fast, disk space efficient package manager
)

echo "Installing package managers and build tools..."
for tool in "${tools[@]}"; do
    echo "Installing $tool..."
    if brew list "$tool" &>/dev/null; then
        info "$tool is already installed."
    elif [ "$DRY_RUN" = "1" ]; then
        log_action "Would install $tool"
    elif brew install "$tool"; then
        info "$tool installed successfully!"
    else
        warn "Failed to install $tool."
    fi
done

# Install Nerd Fonts for Oh My Posh themes
section "Installing Nerd Fonts"
nerd_fonts=(
    "font-meslo-lg-nerd-font"      # Meslo Nerd Font (recommended)
    "font-jetbrains-mono-nerd-font" # JetBrains Mono Nerd Font
    "font-fira-code-nerd-font"     # Fira Code Nerd Font
)

echo "Installing Nerd Fonts for Oh My Posh themes..."
for font in "${nerd_fonts[@]}"; do
    echo "Installing $font..."
    if brew list --cask "$font" &>/dev/null; then
        info "$font is already installed."
    elif [ "$DRY_RUN" = "1" ]; then
        log_action "Would install --cask $font"
    elif brew install --cask "$font"; then
        info "$font installed successfully!"
    else
        warn "Failed to install $font."
    fi
done

# Install shell tools
section "Installing Shell Tools"
shell_tools=(
    "fzf"                  # Fuzzy finder
    "ripgrep"              # Better grep
    "fd"                   # Better find
    "bat"                  # Better cat
    "jq"                   # JSON processor
    "htop"                 # Process viewer
    "gh"                   # GitHub CLI
    "oh-my-posh"           # Prompt theme engine
    "gitui"                # Git terminal UI
    "lazygit"              # Git terminal UI (alternative)
)

echo "Installing shell tools..."
for tool in "${shell_tools[@]}"; do
    echo "Installing $tool..."
    if brew list "$tool" &>/dev/null; then
        info "$tool is already installed."
    elif [ "$DRY_RUN" = "1" ]; then
        log_action "Would install $tool"
    elif brew install "$tool"; then
        info "$tool installed successfully!"
    else
        warn "Failed to install $tool."
    fi
done

# Install databases
section "Installing Databases"
databases=(
    "mysql"                # MySQL
    "postgresql@15"        # PostgreSQL
)

echo "Installing databases..."
for db in "${databases[@]}"; do
    echo "Installing $db..."
    if brew list "$db" &>/dev/null; then
        info "$db is already installed."
    elif [ "$DRY_RUN" = "1" ]; then
        log_action "Would install $db"
    elif brew install "$db"; then
        info "$db installed successfully!"
    else
        warn "Failed to install $db."
    fi
done

# Set up VS Code settings and extensions
section "Setting Up VS Code"
VSCODE_USER="$HOME/Library/Application Support/Code/User"
VSCODE_SETTINGS="./config-files/vscode/settings.json"
VSCODE_EXTENSIONS="./config-files/vscode/extensions.json"

if [ "$DRY_RUN" != "1" ]; then
    mkdir -p "$VSCODE_USER"
fi

# Copy settings.json
if [ -f "$VSCODE_SETTINGS" ]; then
    if [ -f "$VSCODE_USER/settings.json" ]; then
        backup_if_exists "$VSCODE_USER/settings.json"
    fi
    if [ "$DRY_RUN" != "1" ]; then
        cp "$VSCODE_SETTINGS" "$VSCODE_USER/settings.json"
    fi
    info "VS Code settings applied from $VSCODE_SETTINGS"
else
    warn "VS Code settings not found at $VSCODE_SETTINGS"
fi

# Install custom theme (symlink to ~/.vscode/extensions)
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
THEME_SRC="$DOTFILES_DIR/config-files/vscode/themes/onedark-catppuccin"
THEME_DEST="$HOME/.vscode/extensions/onedark-catppuccin"
if [ -d "$THEME_SRC" ]; then
    if [ "$DRY_RUN" != "1" ]; then
        mkdir -p "$HOME/.vscode/extensions"
        ln -sfn "$THEME_SRC" "$THEME_DEST"
    fi
    info "Custom theme linked: $THEME_DEST → $THEME_SRC"
else
    warn "Custom theme not found at $THEME_SRC"
fi

# Install extensions from extensions.json
if [ -f "$VSCODE_EXTENSIONS" ] && command -v code &>/dev/null; then
    echo "Installing VS Code extensions..."
    for ext_id in $(python3 -c "import json; [print(e) for e in json.load(open('$VSCODE_EXTENSIONS'))['recommendations']]" 2>/dev/null); do
        if [ "$DRY_RUN" = "1" ]; then
            log_action "Would install extension: $ext_id"
        elif code --install-extension "$ext_id" --force 2>/dev/null; then
            info "Installed extension: $ext_id"
        else
            warn "Failed to install $ext_id"
        fi
    done
elif [ -f "$VSCODE_EXTENSIONS" ]; then
    warn "VS Code CLI (code) not found. Install extensions manually or run: code --install-extension <id>"
else
    warn "Extensions list not found at $VSCODE_EXTENSIONS"
fi

# Install NVM (Node Version Manager) – primary Node for dev; global npm packages installed after
section "Installing NVM"
# Resolve latest NVM version from GitHub (falls back to known good)
NVM_LATEST=$(curl -fsSL -o /dev/null -w '%{redirect_url}' https://github.com/nvm-sh/nvm/releases/latest 2>/dev/null \
    | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "v0.40.1")
if [ "$DRY_RUN" = "1" ]; then
    log_action "Would install NVM ($NVM_LATEST) + Node LTS + global npm packages"
elif [ ! -d "$HOME/.nvm" ]; then
    echo "Installing NVM ($NVM_LATEST)..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_LATEST}/install.sh" | bash

    # Load NVM for this session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install LTS version of Node.js
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'

    info "NVM installed and configured with latest LTS Node.js version!"
else
    info "NVM already installed."

    # Load NVM for this session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Make sure LTS version is installed
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'

    info "NVM configured with latest LTS Node.js version!"
fi

# Global npm packages (after NVM so they land on NVM Node)
section "Setting up Node.js environment (global packages)"
if [ "$DRY_RUN" = "1" ]; then
    log_action "Would install global npm packages: typescript @angular/cli next eslint prettier nodemon ts-node"
elif command -v npm &>/dev/null; then
    echo "Installing global npm packages..."
    # Dropped deprecated: create-react-app, @vue/cli, gatsby-cli (use npx create-vite / npx create-vue)
    npm install -g typescript @angular/cli next eslint prettier nodemon ts-node @anthropic-ai/claude-code
    info "Node.js global packages installed successfully!"
else
    warn "npm not found (NVM not loaded?). Skipping global npm packages."
fi

# Setup shell environment (Oh My Zsh may clobber .zshrc, so install it BEFORE any appends)
section "Setting up Shell Environment"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    info "Oh My Zsh installed successfully!"
else
    info "Oh My Zsh already installed."
fi

# Install Oh My Zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    if [ "$DRY_RUN" = "1" ]; then
        log_action "Would clone zsh-autosuggestions"
    else
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        info "zsh-autosuggestions installed!"
    fi
else
    info "zsh-autosuggestions already installed."
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    if [ "$DRY_RUN" = "1" ]; then
        log_action "Would clone zsh-syntax-highlighting"
    else
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        info "zsh-syntax-highlighting installed!"
    fi
else
    info "zsh-syntax-highlighting already installed."
fi

# Deploy .zshrc NOW (after Oh My Zsh, so its template doesn't clobber ours)
if [ -f "./config-files/.zshrc" ]; then
    if [ -f "$HOME/.zshrc" ]; then
        backup_if_exists "$HOME/.zshrc"
    fi
    if [ "$DRY_RUN" != "1" ]; then
        cp ./config-files/.zshrc "$HOME/.zshrc"
    fi
    log_action "Placed .zshrc at $HOME/.zshrc"
    info ".zshrc deployed successfully!"
else
    warn ".zshrc not found in config-files directory."
fi

# --- All .zshrc appends below (after deploy, so markers can be detected) ---

# Custom aliases / NVM / Docker / Oh My Posh block (idempotent: check marker)
# Skipped if config-files/.zshrc was copied earlier (it already contains these).
if ! grep -q "# Custom aliases" "$HOME/.zshrc" 2>/dev/null; then
    echo "Adding custom configurations to .zshrc..."
    if [ "$DRY_RUN" != "1" ]; then
        cat << 'CUSTOM_EOF' >> "$HOME/.zshrc"

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
    eval "$(oh-my-posh init zsh)"
    _omp_config="$HOME/.config/ohmyposh/sprinks.omp.json"
    _omp_real_bin="$_omp_executable"
    function _omp_bin() { "$_omp_real_bin" --config "$_omp_config" "$@"; }
    _omp_executable=_omp_bin
fi
CUSTOM_EOF
    fi
    info "Custom configurations added to .zshrc!"
else
    info "Custom configurations already exist in .zshrc."
fi

# Optional: macOS system defaults (default browser, dock). Set SET_MACOS_DEFAULTS=1 to run.
if [ "${SET_MACOS_DEFAULTS:-0}" = "1" ]; then
    section "Optional: Setting macOS Defaults"
    # Default browser (Dia). Requires: brew install defaultbrowser; then e.g. defaultbrowser dia
    if command -v defaultbrowser &>/dev/null; then
        if defaultbrowser dia 2>/dev/null; then
            info "Default browser set to Dia."
        else
            warn "Could not set Dia as default browser. Run 'defaultbrowser' to see available browsers and set manually."
        fi
    else
        brew install defaultbrowser 2>/dev/null && defaultbrowser dia 2>/dev/null || warn "Install defaultbrowser (brew install defaultbrowser) and set default browser in System Settings if desired."
    fi
    # Dock: uncomment and adjust to taste (then killall Dock)
    # defaults write com.apple.dock autohide -bool true
    # defaults write com.apple.dock orientation -string "left"
    # defaults write com.apple.dock show-recents -bool false
    # killall Dock
    info "Dock: edit work-setup.sh (defaults write com.apple.dock ...) and re-run with SET_MACOS_DEFAULTS=1 to apply, then killall Dock."
fi

section "Setup Complete!"
echo "🎉 Your work IT environment has been set up! 🎉"
echo ""
echo "Dotfiles: copied to ~/dotfiles for backup"
echo "Oh My Posh: ~/.config/ohmyposh/sprinks.omp.json"
echo "VS Code: settings from config-files/vscode/settings.json, extensions from config-files/vscode/extensions.json"
echo ""
echo "Optional: SET_MACOS_DEFAULTS=1 (default browser/dock)"
echo "DRY_RUN=1 to preview changes without applying."
echo ""
echo "Run 'source ~/.zshrc' (or restart terminal) to apply aliases."
echo "Happy coding! 💻"
