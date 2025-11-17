#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Welcome message
echo "🖥️  Work Laptop Setup 🖥️"
echo "========================"
echo ""

# Create necessary directories
section "Creating Directories"
mkdir -p ~/.config/ohmyposh
mkdir -p ~/dotfiles
info "Directories created successfully!"

# Copy configuration files to appropriate locations
section "Setting Up Configuration Files"
echo "Copying configuration files..."

# Copy .gitconfig
if [ -f "./config-files/.gitconfig" ]; then
    if [ -f "$HOME/.gitconfig" ]; then
        warn "Existing .gitconfig found. Will be overwritten."
    fi
    cp ./config-files/.gitconfig ~/dotfiles/.gitconfig
    cp ./config-files/.gitconfig ~/.gitconfig
    info ".gitconfig copied successfully!"
else
    warn ".gitconfig not found in config-files directory."
fi

# Copy .zshrc
if [ -f "./config-files/.zshrc" ]; then
    if [ -f "$HOME/.zshrc" ]; then
        warn "Existing .zshrc found. Will be overwritten."
    fi
    cp ./config-files/.zshrc ~/dotfiles/.zshrc
    cp ./config-files/.zshrc ~/.zshrc
    info ".zshrc copied successfully!"
else
    warn ".zshrc not found in config-files directory."
fi

# Copy sprinks.omp.json (Oh My Posh theme)
if [ -f "./config-files/sprinks.omp.json" ]; then
    if [ -f "$HOME/.config/ohmyposh/sprinks.omp.json" ]; then
        warn "Existing sprinks.omp.json found. Will be overwritten."
    fi
    cp ./config-files/sprinks.omp.json ~/.config/ohmyposh/sprinks.omp.json
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
        # Add to shell profile for future sessions
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    elif [[ -d "/usr/local/bin" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        # Add to shell profile for future sessions
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
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
if [ ! -f "~/.gitconfig" ] && [ -z "$(git config --global user.name)" ]; then
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
    "docker"               # Containerization
    "github"               # GitHub Desktop
    "cursor"               # Cursor IDE
)

echo "Installing development tools..."
for tool in "${dev_tools[@]}"; do
    echo "Installing $tool..."
    # Check if already installed
    if brew list --cask "$tool" &>/dev/null; then
        info "$tool is already installed."
    elif brew install --cask "$tool"; then
        info "$tool installed successfully!"
    else
        warn "Failed to install $tool."
    fi
done

# Install programming languages and tools
section "Installing Programming Languages & Tools"
languages=(
    "node"                 # Node.js
    "typescript"           # TypeScript
)

echo "Installing programming languages..."
for lang in "${languages[@]}"; do
    echo "Installing $lang..."
    # Check if already installed
    if brew list "$lang" &>/dev/null; then
        info "$lang is already installed."
    elif brew install "$lang"; then
        info "$lang installed successfully!"
    else
        warn "Failed to install $lang."
    fi
done

# Install package managers and build tools
section "Installing Package Managers & Build Tools"
tools=(
    "yarn"                 # JavaScript package manager
)

echo "Installing package managers and build tools..."
for tool in "${tools[@]}"; do
    echo "Installing $tool..."
    # Check if already installed
    if brew list "$tool" &>/dev/null; then
        info "$tool is already installed."
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
    "tree-sitter"          # Tree-sitter CLI for LazyVim
    "neovim"               # Neovim text editor
)

echo "Installing shell tools..."
for tool in "${shell_tools[@]}"; do
    echo "Installing $tool..."
    # Check if already installed
    if brew list "$tool" &>/dev/null; then
        info "$tool is already installed."
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
    # Check if already installed
    if brew list "$db" &>/dev/null; then
        info "$db is already installed."
    elif brew install "$db"; then
        info "$db installed successfully!"
    else
        warn "Failed to install $db."
    fi
done

# Install applications
section "Installing Applications"
apps=(
    "appcleaner"           # App Uninstaller
    "arc"                  # Arc Browser
    "hiddenbar"            # Menu Bar Manager (replaces bartender)
    "alt-tab"              # Windows-like alt-tab
    "synergy"              # Network KVM
    "resilio-sync"         # File synchronization
    "lanscan"              # Network scanner
    "anydesk"              # Remote desktop
    "google-chrome"         # Chrome Browser
    "keka"                 # Zip File Manager
    "raycast"              # Spotlight Replacement
    "spotify"              # Music
)

echo "Installing applications..."
for app in "${apps[@]}"; do
    echo "Installing $app..."
    # Check if already installed as cask
    if brew list --cask "$app" &>/dev/null; then
        info "$app is already installed."
    elif brew install --cask "$app"; then
        info "$app installed successfully!"
    else
        warn "Failed to install $app."
    fi
done

# Install VS Code extensions
section "Installing VS Code Extensions"
if ! command -v code &>/dev/null; then
    warn "VS Code CLI 'code' not found, skipping extension installation."
else
    info "Installing VS Code extensions..."
    extensions=(
        # Code Formatting & Linting
        aaron-bond.better-comments        # Better Comments
        dbaeumer.vscode-eslint            # ESLint
        esbenp.prettier-vscode            # Prettier
        
        # IntelliSense & Productivity
        VisualStudioExptTeam.vscodeintellicode            # IntelliCode
        VisualStudioExptTeam.intellicode-api-usage-examples # IntelliCode API Examples
        christian-kohler.npm-intellisense # npm intellisense
        christian-kohler.path-intellisense # path intellisense
        usernamehw.errorlens              # Error Lens
        
        # JavaScript/TypeScript
        ms-vscode.vscode-typescript-next  # TypeScript
        dsznajder.es7-react-js-snippets   # React snippets
        bradlc.vscode-tailwindcss         # Tailwind CSS
        
        # HTML/CSS
        anteprimorac.html-end-tag-labels  # HTML End Tag Labels
        formulahendry.auto-close-tag      # Auto Close Tag
        formulahendry.auto-rename-tag     # Auto Rename Tag
        oderwat.indent-rainbow            # Indent Rainbow
        ritwickdey.liveserver             # Live Server
        solnurkarim.html-to-css-autocompletion # HTML to CSS Autocompletion
        
        # Docker/DevOps
        ms-azuretools.vscode-docker       # Docker
        redhat.vscode-yaml                # YAML
        twxs.cmake                        # CMake
        
        # Database
        cweijan.vscode-mysql-client2      # MySQL
        cweijan.dbclient-jdbc             # DB Client JDBC
        
        # Git
        eamodio.gitlens                   # GitLens
        github.vscode-pull-request-github # GitHub PRs
        
        # Terminal/Shell
        wmaurer.change-case               # Change case
        mikestead.dotenv                  # .env files
        
        # Themes & UI
        zhuangtongfa.material-theme       # One Dark Pro Theme
        miguelsolorio.symbols             # Symbols Icon Theme
    )
    for ext in "${extensions[@]}"; do
        if code --install-extension "$ext" --force; then
            info "Installed $ext"
        else
            warn "Failed to install $ext"
        fi
    done
fi

# Copy VS Code settings to Cursor
section "Setting Up Cursor with VS Code Settings"
if [ -f "./config-files/vscode/settings.json" ]; then
    mkdir -p ~/Library/Application\ Support/Cursor/User/
    cp ./config-files/vscode/settings.json ~/Library/Application\ Support/Cursor/User/settings.json
    info "VS Code settings copied to Cursor successfully!"
else
    warn "VS Code settings.json not found in config-files/vscode directory."
fi

# Also copy current VS Code settings if they exist
if [ -f ~/Library/Application\ Support/Code/User/settings.json ]; then
    mkdir -p ~/Library/Application\ Support/Cursor/User/
    cp ~/Library/Application\ Support/Code/User/settings.json ~/Library/Application\ Support/Cursor/User/settings.json
    info "Current VS Code settings copied to Cursor successfully!"
fi

# Install Cursor CLI
section "Installing Cursor CLI"
if ! command -v cursor &> /dev/null; then
    echo "Installing Cursor CLI..."
    curl https://cursor.com/install -fsS | bash
    info "Cursor CLI installed successfully!"
else
    info "Cursor CLI already installed."
fi

# Install and setup LazyVim
section "Installing LazyVim"
if command -v nvim &> /dev/null; then
    # Check if LazyVim is already installed
    if [ -d "$HOME/.config/nvim" ] && [ -f "$HOME/.config/nvim/lua/lazyvim/config/keymaps.lua" ]; then
        info "LazyVim is already installed."
    else
        info "Installing LazyVim..."
        
        # Make backup of existing Neovim config if it exists
        if [ -d "$HOME/.config/nvim" ]; then
            warn "Existing Neovim config found. Creating backup..."
            mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
            info "Backup created at ~/.config/nvim.bak"
        fi
        
        # Create backup of other Neovim directories
        if [ -d "$HOME/.local/share/nvim" ]; then
            mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.bak"
        fi
        if [ -d "$HOME/.local/state/nvim" ]; then
            mv "$HOME/.local/state/nvim" "$HOME/.local/state/nvim.bak"
        fi
        if [ -d "$HOME/.cache/nvim" ]; then
            mv "$HOME/.cache/nvim" "$HOME/.cache/nvim.bak"
        fi
        
        # Clone LazyVim starter
        echo "Cloning LazyVim starter..."
        if git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"; then
            # Remove .git folder so it can be added to user's repo later
            rm -rf "$HOME/.config/nvim/.git"
            info "LazyVim installed successfully!"
            info "You can now run 'nvim' to start LazyVim"
        else
            error "Failed to install LazyVim. Please install manually."
        fi
    fi
else
    warn "Neovim not found. Please install Neovim first before setting up LazyVim."
fi

# Install Cursor extensions (same as VS Code)
section "Installing Cursor Extensions"
if command -v cursor &>/dev/null; then
    info "Installing Cursor extensions..."
    # Check if Cursor supports the same CLI commands as VS Code
    if cursor --help 2>&1 | grep -q "\-\-install-extension"; then
        # Cursor uses same CLI format as VS Code
        for ext in "${extensions[@]}"; do
            if cursor --install-extension "$ext" --force; then
                info "Installed $ext in Cursor"
            else
                warn "Failed to install $ext in Cursor"
            fi
        done
    else
        # Alternative method: Copy VS Code extensions to Cursor extensions directory
        VSCODE_EXTS_DIR="$HOME/.vscode/extensions"
        CURSOR_EXTS_DIR="$HOME/Library/Application Support/Cursor/extensions"
        
        if [ -d "$VSCODE_EXTS_DIR" ]; then
            mkdir -p "$CURSOR_EXTS_DIR"
            info "Copying extensions from VS Code to Cursor..."
            
            # Create a list of VS Code extensions to display
            echo "VS Code extensions being synced to Cursor:"
            ls -1 "$VSCODE_EXTS_DIR" | while read ext; do
                echo "  - $ext"
            done
            
            # Copy the extensions
            cp -R "$VSCODE_EXTS_DIR"/* "$CURSOR_EXTS_DIR"/ 2>/dev/null
            info "VS Code extensions copied to Cursor. You may need to restart Cursor."
        else
            warn "VS Code extensions directory not found."
        fi
    fi
else
    warn "Cursor CLI not found, skipping extension installation."
    info "Please install extensions manually after installing Cursor."
fi

# Setup Node.js environment
section "Setting up Node.js Environment"
if command -v npm &> /dev/null; then
    echo "Installing global npm packages..."
    npm install -g typescript @angular/cli @vue/cli create-react-app next gatsby-cli eslint prettier nodemon ts-node
    info "Node.js packages installed successfully!"
else
    warn "Node.js not found. Skipping npm packages installation."
fi

# Install NVM (Node Version Manager)
section "Installing NVM"
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    
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

# Setup shell environment
section "Setting up Shell Environment"
# Check if Oh My Zsh is installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    info "Oh My Zsh installed successfully!"
else
    info "Oh My Zsh already installed."
fi

# If .zshrc wasn't copied earlier, add custom configurations
if [ ! -f "~/.zshrc" ] && ! grep -q "# Custom aliases" ~/.zshrc; then
    echo "Adding custom configurations to .zshrc..."
    cat << EOF >> ~/.zshrc

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
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Docker aliases
alias dc="docker-compose"
alias dps="docker ps"
alias dex="docker exec -it"

# Oh My Posh setup
if command -v oh-my-posh &> /dev/null; then
    export POSH_THEME="$HOME/.config/ohmyposh/sprinks.omp.json"
    eval "$(oh-my-posh init zsh)"
fi
EOF
    info "Custom configurations added to .zshrc!"
else
    info "Custom configurations already exist in .zshrc."
fi

section "Setup Complete!"
echo "🎉 Your Full Stack Web Development environment has been set up! 🎉"
echo ""
echo "Your dotfiles have been copied to ~/dotfiles for backup"
echo "Your Oh My Posh theme has been set up at ~/.config/ohmyposh/sprinks.omp.json"
echo "LazyVim has been installed and configured for Neovim"
echo ""
echo "You may need to restart your terminal or run 'source ~/.zshrc' to apply all changes."
echo "Run 'nvim' to start LazyVim and 'cursor' to start Cursor IDE"
echo "Happy coding! 💻"