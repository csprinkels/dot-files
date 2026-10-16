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

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Welcome message
echo "🖥️  Headless Mac Setup 🖥️"
echo "==================================================="
echo "Terminal, shell, and dev tools for a Mac you mostly reach from the terminal."
[ "$DRY_RUN" = "1" ] && echo -e "${YELLOW}DRY RUN: no changes will be made.${NC}"
echo ""

# Create necessary directories
section "Creating Directories"
if [ "$DRY_RUN" != "1" ]; then
    mkdir -p "$HOME/.config/ohmyposh"
    mkdir -p "$HOME/.config/ghostty"
    mkdir -p "$HOME/dotfiles"
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

# Terminal look (font, colors, padding). cmux runs on Ghostty's engine and reads this path.
TERMINAL_CONFIG_SRC="./config-files/terminal.conf"
TERMINAL_CONFIG_DEST="$HOME/.config/ghostty/config"
if [ -f "$TERMINAL_CONFIG_SRC" ]; then
    if [ -f "$TERMINAL_CONFIG_DEST" ]; then
        backup_if_exists "$TERMINAL_CONFIG_DEST"
    fi
    if [ "$DRY_RUN" != "1" ]; then
        cp "$TERMINAL_CONFIG_SRC" "$TERMINAL_CONFIG_DEST"
    fi
    info "Terminal config copied to $TERMINAL_CONFIG_DEST (cmux reads it)."
else
    warn "Terminal config not found at $TERMINAL_CONFIG_SRC."
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
if [ "$DRY_RUN" = "1" ]; then
    log_action "Would run brew update and brew upgrade"
elif brew update 2>/dev/null; then
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

# Everything else Homebrew installs is listed in the Brewfile.
section "Installing from Brewfile"
if [ "$DRY_RUN" = "1" ]; then
    brew bundle list --all --file="$DOTFILES_DIR/Brewfile" | while read -r entry; do log_action "Would install $entry"; done
elif brew bundle --file="$DOTFILES_DIR/Brewfile"; then
    info "Brewfile installed successfully!"
else
    warn "Some Brewfile entries failed. Run: brew bundle --file=$DOTFILES_DIR/Brewfile"
fi

# Rust: rustup comes from the Brewfile; this installs the stable toolchain into ~/.rustup.
section "Setting up Rust"
RUSTUP="$(brew --prefix)/opt/rustup/bin/rustup"
if [ "$DRY_RUN" = "1" ]; then
    log_action "Would install the stable Rust toolchain with rustup"
elif [ -x "$RUSTUP" ]; then
    "$RUSTUP" default stable && info "Rust stable installed!" || warn "rustup couldn't install stable. Run: rustup default stable"
else
    warn "rustup not found (did the Brewfile step fail?). Skipping Rust."
fi

# Configure Git if not configured and .gitconfig wasn't copied
section "Setting up Git"
if [ "$DRY_RUN" = "1" ]; then
    log_action "Would ask for your Git name and email if there's no .gitconfig"
elif [ ! -f "$HOME/.gitconfig" ] && [ -z "$(git config --global user.name)" ]; then
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

# Install NVM (Node Version Manager) – primary Node for dev; global npm packages installed after
section "Installing NVM"
# Resolve latest NVM version from GitHub (falls back to known good)
NVM_LATEST=$(curl -fsS -o /dev/null -w '%{redirect_url}' https://github.com/nvm-sh/nvm/releases/latest 2>/dev/null \
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
    log_action "Would install global npm packages: typescript next eslint prettier nodemon ts-node @anthropic-ai/claude-code"
elif command -v npm &>/dev/null; then
    echo "Installing global npm packages..."
    npm install -g typescript next eslint prettier nodemon ts-node @anthropic-ai/claude-code
    info "Node.js global packages installed successfully!"
else
    warn "npm not found (NVM not loaded?). Skipping global npm packages."
fi

# Setup shell environment (Oh My Zsh may clobber .zshrc, so install it BEFORE any appends)
section "Setting up Shell Environment"
if [ "$DRY_RUN" = "1" ]; then
    log_action "Would install Oh My Zsh if missing"
elif [ ! -d "$HOME/.oh-my-zsh" ]; then
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

section "Setup Complete!"
echo "🎉 Your headless Mac is set up! 🎉"
echo ""
echo "Dotfiles: copied to ~/dotfiles for backup"
echo "Prompt:   ~/.config/ohmyposh/sprinks.omp.json"
echo "Terminal: ~/.config/ghostty/config (font and colors, read by cmux)"
echo "Apps and tools: Brewfile (brew bundle --file=$DOTFILES_DIR/Brewfile)"
echo "Extended drive: tool caches (DevCache), when it's plugged in"
echo ""
echo "DRY_RUN=1 to preview changes without applying."
echo ""
echo "Run 'source ~/.zshrc' (or restart terminal) to apply aliases and the prompt."
echo "Happy coding! 💻"
