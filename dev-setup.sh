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
echo "🖥️  Full Stack Web Development Environment Setup 🖥️"
echo "==================================================="
echo "This script will set up your Mac for full stack web development (external-first: WorkFlow drive)."
[ "$DRY_RUN" = "1" ] && echo -e "${YELLOW}DRY RUN: no changes will be made.${NC}"
echo ""

# --- External WorkFlow drive (external-first workflow) ---
EXTERNAL_VOL_NAME="${EXTERNAL_VOL_NAME:-WorkFlow}"
EXTERNAL_ROOT="/Volumes/$EXTERNAL_VOL_NAME"

# Check external volume exists and is writable
if [ ! -d "$EXTERNAL_ROOT" ]; then
    error "External volume not found: $EXTERNAL_ROOT"
    error "Plug in the drive named '$EXTERNAL_VOL_NAME' (or set EXTERNAL_VOL_NAME) and re-run."
    exit 1
fi
if [ ! -w "$EXTERNAL_ROOT" ]; then
    error "External volume not writable: $EXTERNAL_ROOT"
    exit 1
fi

# Load workflow.env from external drive (safe: whitelist keys only, trim/strip quotes)
WORKFLOW_ENV="$EXTERNAL_ROOT/workflow.env"
WORKFLOW_ALLOWED_KEYS="CODE_DIR_NAME MOVE_DOWNLOADS EXTERNAL_VOL_NAME"
if [ -f "$WORKFLOW_ENV" ]; then
    info "Loading config from $WORKFLOW_ENV"
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            # Whitelist: only accept known keys
            [[ " $WORKFLOW_ALLOWED_KEYS " != *" $key "* ]] && continue
            # Trim leading/trailing whitespace
            value="${value#"${value%%[![:space:]]*}"}"
            value="${value%"${value##*[![:space:]]}"}"
            # Strip one layer of surrounding double or single quotes
            [[ "$value" =~ ^\"(.*)\"$ ]] && value="${BASH_REMATCH[1]}"
            [[ "$value" =~ ^\'(.*)\'$ ]] && value="${BASH_REMATCH[1]}"
            export "$key=$value"
        fi
    done < "$WORKFLOW_ENV"
else
    info "Creating default config at $WORKFLOW_ENV"
    if [ "$DRY_RUN" != "1" ]; then
        cat > "$WORKFLOW_ENV" << 'WORKFLOW_ENV_EOF'
# WorkFlow external-drive config for dev-setup.sh
# You can edit these and re-run the script.

CODE_DIR_NAME=Developer
MOVE_DOWNLOADS=0
WORKFLOW_ENV_EOF
    fi
fi

CODE_DIR_NAME="${CODE_DIR_NAME:-Developer}"
MOVE_DOWNLOADS="${MOVE_DOWNLOADS:-0}"
EXTERNAL_DEVELOPER="$EXTERNAL_ROOT/$CODE_DIR_NAME"
EXTERNAL_DOWNLOADS="$EXTERNAL_ROOT/Downloads"
EXTERNAL_DEVCACHE="$EXTERNAL_ROOT/DevCache"
EXTERNAL_APPS="$EXTERNAL_ROOT/Apps"

# Create directory layout on external drive (full WorkFlow structure)
section "External drive: $EXTERNAL_VOL_NAME"
if [ "$DRY_RUN" != "1" ]; then
    mkdir -p "$EXTERNAL_ROOT/Assets"
    mkdir -p "$EXTERNAL_ROOT/Creative"
    mkdir -p "$EXTERNAL_DEVELOPER"
    mkdir -p "$EXTERNAL_ROOT/Documents"
    mkdir -p "$EXTERNAL_DOWNLOADS"
    mkdir -p "$EXTERNAL_ROOT/Hardware"
    mkdir -p "$EXTERNAL_DEVCACHE"/{npm,pnpm,yarn,python,cargo,go/mod,go/cache,gradle,swiftpm,xdg}
    mkdir -p "$EXTERNAL_APPS"
fi
echo "Internal (macOS + Homebrew + Docker):"
echo "  Homebrew: /opt/homebrew (unchanged)"
echo "  Docker:   internal disk images (unchanged)"
echo "External ($EXTERNAL_ROOT):"
echo "  Developer"
echo "  Assets"
echo "  Creative"
echo "  Documents"
echo "  Downloads"
echo "  Hardware"
echo "  DevCache"
echo "  Apps"
info "External directory layout ready."

# Safe merge: rsync src to dest (faithful mirror), then rename src to timestamp backup
# Usage: safe_merge_move <source_dir> <dest_dir> <backup_base_name>
safe_merge_move() {
    local src="$1" dest="$2" backup_name="$3"
    [ "$DRY_RUN" = "1" ] && { log_action "Would merge $src → $dest and replace $src with symlink"; return 0; }
    [ ! -d "$src" ] && return 0
    [ -L "$src" ] && return 0
    log_action "Merging $src → $dest (rsync)..."
    mkdir -p "$dest"
    rsync -a "$src"/ "$dest"/
    local stamp=$(date +%Y%m%d-%H%M%S)
    local backup="$src.backup.$stamp"
    if [ -d "$src" ] && [ ! -L "$src" ]; then
        mv "$src" "$backup"
        log_action "Renamed $src → $backup"
    fi
}

# Ensure ~/Developer is a symlink to external Developer (migrate ~/Projects, ~/Code, or real ~/Developer first)
section "Developer folder (external-first)"
if [ -d "$HOME/Projects" ] && [ ! -L "$HOME/Projects" ]; then
    log_action "Migrating ~/Projects → $EXTERNAL_DEVELOPER"
    safe_merge_move "$HOME/Projects" "$EXTERNAL_DEVELOPER" "Projects"
fi
if [ -d "$HOME/Code" ] && [ ! -L "$HOME/Code" ]; then
    log_action "Migrating ~/Code → $EXTERNAL_DEVELOPER"
    safe_merge_move "$HOME/Code" "$EXTERNAL_DEVELOPER" "Code"
fi
if [ -d "$HOME/Developer" ] && [ ! -L "$HOME/Developer" ]; then
    log_action "Moving ~/Developer contents to $EXTERNAL_DEVELOPER"
    safe_merge_move "$HOME/Developer" "$EXTERNAL_DEVELOPER" "Developer"
fi
if [ -L "$HOME/Developer" ] && [ "$(readlink "$HOME/Developer")" = "$EXTERNAL_DEVELOPER" ]; then
    info "~/Developer already points to $EXTERNAL_DEVELOPER"
elif [ "$DRY_RUN" != "1" ]; then
    ln -sfn "$EXTERNAL_DEVELOPER" "$HOME/Developer"
    info "Created ~/Developer → $EXTERNAL_DEVELOPER"
else
    log_action "Would create ~/Developer → $EXTERNAL_DEVELOPER"
fi

# Optional: move Downloads to external
if [ "$MOVE_DOWNLOADS" = "1" ]; then
    if [ -d "$HOME/Downloads" ] && [ ! -L "$HOME/Downloads" ]; then
        log_action "Moving ~/Downloads to $EXTERNAL_DOWNLOADS"
        safe_merge_move "$HOME/Downloads" "$EXTERNAL_DOWNLOADS" "Downloads"
        if [ "$DRY_RUN" != "1" ] && [ ! -L "$HOME/Downloads" ]; then
            ln -sfn "$EXTERNAL_DOWNLOADS" "$HOME/Downloads"
            info "~/Downloads → $EXTERNAL_DOWNLOADS"
        fi
    elif [ -L "$HOME/Downloads" ]; then
        info "~/Downloads already a symlink"
    else
        if [ "$DRY_RUN" != "1" ]; then
            ln -sfn "$EXTERNAL_DOWNLOADS" "$HOME/Downloads"
            info "Created ~/Downloads → $EXTERNAL_DOWNLOADS"
        fi
    fi
else
    info "Downloads left on internal (set MOVE_DOWNLOADS=1 in workflow.env to move)"
fi

# Create necessary directories (internal)
section "Creating Directories"
if [ "$DRY_RUN" != "1" ]; then
    mkdir -p "$HOME/.config/ohmyposh"
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
    "cursor"               # Cursor IDE
    "docker"               # Containerization
    "github"               # GitHub Desktop
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

# Optional: Terminal with AI (Warp). macOS Terminal has no built-in AI; Warp offers agents, suggestions, blocks.
# Alternative: Lacy Shell (lacy.sh) adds AI to zsh/bash via natural-language input.
if [ "${INSTALL_WARP:-}" = "1" ]; then
    echo "Installing Warp (AI terminal)..."
    if brew list --cask "warp" &>/dev/null; then
        info "Warp is already installed."
    elif [ "$DRY_RUN" = "1" ]; then
        log_action "Would install --cask warp"
    elif brew install --cask "warp"; then
        info "Warp installed successfully! Use it when you want AI in the terminal."
    else
        warn "Failed to install Warp."
    fi
fi

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

# Install applications
# These apps MUST stay on the internal macOS drive.
# Do not relocate to WorkFlow/Apps.
# They integrate deeply with macOS (menu bar, login items, permissions, etc.)
section "Installing Applications"
apps=(
    "appcleaner"           # App Uninstaller
    "thebrowsercompany-dia" # Dia Browser
    "cleanmymac"          # Clean My Mac X
    "parsec"              # Remote desktop
    "bartender"            # Menu Bar Manager
    "alt-tab"              # Windows-like alt-tab
    "synergy"              # Network KVM
    "google-chrome"        # Chrome Browser
    "cleanshot"            # ScreenShot App
    "keka"                 # Zip File Manager
    "nordpass"             # Password Manager
    "raycast"              # Spotlight Replacement
    "spotify"              # Music
)

echo "Installing applications..."
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
info "System-integrated apps were installed to /Applications (internal drive)."
info "Large creative apps can optionally be installed manually to /Volumes/WorkFlow/Apps."

# Deskin (remote desktop) has no Homebrew cask. Install manually from App Store or https://deskin.io
info "Deskin: install from App Store or deskin.io if needed (no Homebrew cask)."

# Install Cursor CLI (needed before profile import)
section "Installing Cursor CLI"
if ! command -v cursor &> /dev/null; then
    echo "Installing Cursor CLI..."
    curl https://cursor.com/install -fsS | bash
    info "Cursor CLI installed successfully!"
else
    info "Cursor CLI already installed."
fi

# Set up Cursor from exported profile (config-files/cursor profile.code-profile)
section "Setting Up Cursor from Exported Profile"
CURSOR_USER="$HOME/Library/Application Support/Cursor/User"
PROFILE_FILE="./config-files/cursor profile.code-profile"
if [ "$DRY_RUN" != "1" ]; then
    mkdir -p "$CURSOR_USER"
fi

if [ -f "$PROFILE_FILE" ] && [ "$DRY_RUN" != "1" ]; then
    # Parse .code-profile: unwrap settings/keybindings and write to Cursor User; list extension IDs
    EXT_IDS_FILE=$(mktemp)
    python3 - "$PROFILE_FILE" "$CURSOR_USER" "$EXT_IDS_FILE" << 'PYTHON_SCRIPT'
import json
import sys
import os

profile_path = sys.argv[1]
cursor_user = os.path.expanduser(sys.argv[2])
ext_ids_file = sys.argv[3]

with open(profile_path) as f:
    d = json.load(f)

def unwrap(obj, key="settings"):
    for _ in range(5):
        if isinstance(obj, str):
            obj = json.loads(obj)
        elif isinstance(obj, dict) and key in obj and len(obj) == 1:
            obj = obj[key]
        else:
            break
    return obj

# Settings
raw_settings = d.get("settings")
if raw_settings is not None:
    settings = unwrap(raw_settings)
    if isinstance(settings, dict):
        with open(os.path.join(cursor_user, "settings.json"), "w") as out:
            json.dump(settings, out, indent=4)

# Keybindings (optional)
raw_keybindings = d.get("keybindings")
if raw_keybindings is not None:
    keybindings = unwrap(raw_keybindings, "keybindings")
    if isinstance(keybindings, list):
        with open(os.path.join(cursor_user, "keybindings.json"), "w") as out:
            json.dump(keybindings, out, indent=4)

# Extension IDs for cursor --install-extension (extensions may be JSON string in profile)
raw_ext = d.get("extensions")
if isinstance(raw_ext, str):
    try:
        raw_ext = json.loads(raw_ext)
    except json.JSONDecodeError:
        raw_ext = []
ext_ids = []
for ext in (raw_ext or []):
    if isinstance(ext, dict):
        ident = ext.get("identifier") or ext.get("id")
        if isinstance(ident, dict) and "id" in ident:
            ext_ids.append(ident["id"])
        elif isinstance(ident, str):
            ext_ids.append(ident)
with open(ext_ids_file, "w") as out:
    for eid in ext_ids:
        out.write(eid + "\n")
PYTHON_SCRIPT
    if [ $? -eq 0 ]; then
        info "Cursor settings and keybindings applied from profile."
    else
        warn "Failed to parse Cursor profile."
    fi

    # Install extensions from profile if Cursor CLI is available
    if command -v cursor &>/dev/null && [ -s "$EXT_IDS_FILE" ]; then
        while IFS= read -r ext_id; do
            [ -z "$ext_id" ] && continue
            if cursor --install-extension "$ext_id" --force 2>/dev/null; then
                info "Installed extension: $ext_id"
            else
                warn "Failed to install $ext_id"
            fi
        done < "$EXT_IDS_FILE"
    fi
    rm -f "$EXT_IDS_FILE"

    # Copy raw profile for fallback UI import (Preferences → Profiles → Import)
    cp "$PROFILE_FILE" "$CURSOR_USER/cursor-profile.code-profile"
    info "Cursor profile imported. Fallback: Cursor → Preferences → Profiles → Import → cursor-profile.code-profile"
elif [ -f "$PROFILE_FILE" ] && [ "$DRY_RUN" = "1" ]; then
    log_action "Would apply Cursor profile from $PROFILE_FILE"
else
    warn "Cursor profile not found at $PROFILE_FILE"
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
    npm install -g typescript @angular/cli next eslint prettier nodemon ts-node
    info "Node.js global packages installed successfully!"
else
    warn "npm not found (NVM not loaded?). Skipping global npm packages."
fi

# Redirect dev caches to external drive (reduces internal disk use)
section "Redirecting dev caches to external"
if [ "$DRY_RUN" = "1" ]; then
    log_action "Would set npm/pnpm/yarn/pip/cargo/go cache dirs to $EXTERNAL_DEVCACHE"
else
    if command -v npm &>/dev/null; then
        npm config set cache "$EXTERNAL_DEVCACHE/npm"
        log_action "npm cache → $EXTERNAL_DEVCACHE/npm"
    fi
    if command -v pnpm &>/dev/null; then
        pnpm config set store-dir "$EXTERNAL_DEVCACHE/pnpm"
        log_action "pnpm store → $EXTERNAL_DEVCACHE/pnpm"
    fi
    if command -v yarn &>/dev/null; then
        yarn config set cache-folder "$EXTERNAL_DEVCACHE/yarn" 2>/dev/null && log_action "yarn cache → $EXTERNAL_DEVCACHE/yarn" || true
    fi
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
    eval "$(oh-my-posh init zsh --config "$HOME/.config/ohmyposh/sprinks.omp.json")"
fi
CUSTOM_EOF
    fi
    info "Custom configurations added to .zshrc!"
else
    info "Custom configurations already exist in .zshrc."
fi

# WorkFlow env vars block (idempotent: check marker)
WORKFLOW_BLOCK_MARKER="# === WorkFlow external-drive paths ==="
if ! grep -q "$WORKFLOW_BLOCK_MARKER" "$HOME/.zshrc" 2>/dev/null; then
    if [ "$DRY_RUN" != "1" ]; then
        cat >> "$HOME/.zshrc" << WORKFLOW_ZSHRC_EOF

$WORKFLOW_BLOCK_MARKER
export PIP_CACHE_DIR="$EXTERNAL_DEVCACHE/python"
export CARGO_HOME="$EXTERNAL_DEVCACHE/cargo"
export GOMODCACHE="$EXTERNAL_DEVCACHE/go/mod"
export GOCACHE="$EXTERNAL_DEVCACHE/go/cache"
export XDG_CACHE_HOME="$EXTERNAL_DEVCACHE/xdg"
WORKFLOW_ZSHRC_EOF
        log_action "Appended WorkFlow cache paths to $HOME/.zshrc"
    else
        log_action "Would append WorkFlow cache block to $HOME/.zshrc"
    fi
else
    info "WorkFlow cache block already in .zshrc"
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
    info "Dock: edit dev-setup.sh (defaults write com.apple.dock ...) and re-run with SET_MACOS_DEFAULTS=1 to apply, then killall Dock."
fi

section "Setup Complete!"
echo "🎉 Your Full Stack Web Development environment has been set up! 🎉"
echo ""
echo "Internal: Homebrew + Docker unchanged. Developer, caches, and (optionally) Downloads live on $EXTERNAL_ROOT"
echo "Config:   $WORKFLOW_ENV (edit and re-run to change CODE_DIR_NAME, MOVE_DOWNLOADS)"
echo "Dotfiles: copied to ~/dotfiles for backup"
echo "Oh My Posh: ~/.config/ohmyposh/sprinks.omp.json"
echo "Cursor: profile from config-files/cursor profile.code-profile (or Preferences → Profiles → Import)"
echo ""
echo "Optional: INSTALL_WARP=1 (Warp terminal); SET_MACOS_DEFAULTS=1 (default browser/dock); set in workflow.env: MOVE_DOWNLOADS=1"
echo "DRY_RUN=1 to preview changes without applying."
echo ""
echo "Run 'source ~/.zshrc' (or restart terminal) to apply cache paths and aliases."
echo "Happy coding! 💻"