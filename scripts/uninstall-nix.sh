#!/bin/bash

# Nix Uninstallation Script for macOS
# This script removes Nix package manager completely from your system

echo "🗑️  Nix Uninstallation Script"
echo "=============================="
echo ""
echo "⚠️  Warning: This will completely remove Nix from your system."
echo "This includes:"
echo "  - Nix package manager"
echo "  - All Nix-installed packages (including the current Homebrew)"
echo "  - Nix daemon services"
echo "  - Nix user accounts"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Step 1: Stopping and removing Nix daemon services..."
sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null && echo "  ✅ Unloaded nix-daemon" || echo "  ℹ️  nix-daemon not found"
sudo rm /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null && echo "  ✅ Removed nix-daemon.plist" || echo "  ℹ️  nix-daemon.plist not found"
sudo launchctl unload /Library/LaunchDaemons/org.nixos.darwin-store.plist 2>/dev/null && echo "  ✅ Unloaded darwin-store" || echo "  ℹ️  darwin-store not found"
sudo rm /Library/LaunchDaemons/org.nixos.darwin-store.plist 2>/dev/null && echo "  ✅ Removed darwin-store.plist" || echo "  ℹ️  darwin-store.plist not found"

echo ""
echo "Step 2: Removing Nix store and directories..."
if [ -d "/nix" ]; then
    echo "  Removing /nix directory (this may take a while)..."
    sudo rm -rf /nix
    echo "  ✅ Removed /nix"
else
    echo "  ℹ️  /nix directory not found"
fi

echo ""
echo "Step 3: Removing Nix configuration files from home directory..."
rm -rf ~/.nix-profile && echo "  ✅ Removed ~/.nix-profile" || echo "  ℹ️  ~/.nix-profile not found"
rm -rf ~/.nix-defexpr && echo "  ✅ Removed ~/.nix-defexpr" || echo "  ℹ️  ~/.nix-defexpr not found"
rm -rf ~/.nix-channels && echo "  ✅ Removed ~/.nix-channels" || echo "  ℹ️  ~/.nix-channels not found"
rm -rf ~/.config/nix && echo "  ✅ Removed ~/.config/nix" || echo "  ℹ️  ~/.config/nix not found"
rm -rf ~/.cache/nix && echo "  ✅ Removed ~/.cache/nix" || echo "  ℹ️  ~/.cache/nix not found"

echo ""
echo "Step 4: Removing Nix users and groups..."
sudo dscl . -delete /Groups/nixbld 2>/dev/null && echo "  ✅ Removed nixbld group" || echo "  ℹ️  nixbld group not found"

nix_users=$(sudo dscl . -list /Users | grep nixbld 2>/dev/null)
if [ -n "$nix_users" ]; then
    for u in $nix_users; do
        sudo dscl . -delete /Users/$u && echo "  ✅ Removed user $u"
    done
else
    echo "  ℹ️  No nixbld users found"
fi

echo ""
echo "Step 5: Removing synthetic.conf entry..."
if [ -f "/etc/synthetic.conf" ]; then
    # Check if it only contains nix entry
    if grep -q "^nix" /etc/synthetic.conf 2>/dev/null; then
        sudo rm /etc/synthetic.conf && echo "  ✅ Removed /etc/synthetic.conf"
    else
        echo "  ⚠️  /etc/synthetic.conf exists but contains other entries"
        echo "  Please manually remove the 'nix' line from /etc/synthetic.conf"
    fi
else
    echo "  ℹ️  /etc/synthetic.conf not found"
fi

echo ""
echo "Step 6: Cleaning up shell profile files..."
echo "  Checking for Nix entries in shell profiles..."

shell_files=(
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.bash_profile"
    "$HOME/.bashrc"
)

for file in "${shell_files[@]}"; do
    if [ -f "$file" ] && grep -q "nix" "$file" 2>/dev/null; then
        echo "  ⚠️  Found Nix references in $file"
        echo "     Creating backup at ${file}.backup"
        cp "$file" "${file}.backup"
        
        # Remove common Nix lines
        sed -i.tmp '/nix-daemon/d' "$file"
        sed -i.tmp '/nix\/var\/nix\/profiles/d' "$file"
        sed -i.tmp '/\.nix-profile/d' "$file"
        rm -f "${file}.tmp"
        
        echo "     ✅ Cleaned Nix references from $file"
    fi
done

echo ""
echo "✅ Nix uninstallation complete!"
echo ""
echo "⚠️  Important: You must REBOOT your Mac for all changes to take effect."
echo ""
echo "After rebooting:"
echo "  1. Verify /nix is gone: ls -la /nix"
echo "  2. Install official Homebrew:"
echo "     /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
echo "  3. Re-run your setup script"
echo ""
read -p "Would you like to reboot now? (yes/no): " reboot_confirm

if [ "$reboot_confirm" = "yes" ]; then
    echo "Rebooting in 5 seconds... (Press Ctrl+C to cancel)"
    sleep 5
    sudo reboot
else
    echo "Please remember to reboot manually before proceeding."
fi


