#!/bin/bash

set -e

echo "🚀 Starting setup..."

# -----------------------------------------
# Requesting sudo permissions
# -----------------------------------------
if ! sudo -v; then
    echo "❌ Failed to obtain sudo privileges. Exiting setup..."
    exit 1
fi

while true; do 
    sudo -v
    sleep 60
done 2>/dev/null &

SUDO_PID=$!

trap 'kill "$SUDO_PID" 2>/dev/null' EXIT

# ---------------------------------------------------------
# Xcode Command Line Tools
# ---------------------------------------------------------
if ! xcode-select -p &>/dev/null; then
    echo "📦 Installing Xcode Command Line Tools..."
    
    clt_placeholder="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    sudo touch "${clt_placeholder}"

    clt_label_command="/usr/sbin/softwareupdate -l |
                        grep -B 1 -E 'Command Line Tools' |
                        awk -F'*' '/^ *\\*/ {print \$2}' |
                        sed -e 's/^ *Label: //' -e 's/^ *//' |
                        sort -V |
                        tail -n1"
    
    clt_label=$(/bin/bash -c "${clt_label_command}")

    if [ -n "${clt_label}" ]; then
        echo "📥 Installing ${clt_label}..."
        sudo /usr/sbin/softwareupdate -i "${clt_label}"
        sudo /usr/bin/xcode-select --switch /Library/Developer/CommandLineTools
    else
        echo "⚠️  Headless installation failed. Falling back to manual prompt..."
        /usr/bin/xcode-select --install
        read -p "👉 Press [ENTER] here ONLY AFTER the popup window finishes installing... "
        sudo /usr/bin/xcode-select --switch /Library/Developer/CommandLineTools
    fi
    
    sudo /bin/rm -f "${clt_placeholder}"
    echo "✅ Xcode Command Line Tools verified!"
else
    echo "✅ Xcode Command Line Tools are already installed."
fi

# ---------------------------------------------------------
# Git Config
# ---------------------------------------------------------
git config --global user.name "Pushpinder Sidhu"
git config --global user.email "97248130+pushpindersidhu@users.noreply.github.com"

# ---------------------------------------------------------
# Clone Dotfiles
# ---------------------------------------------------------
if [ ! -d "$HOME/dotfiles" ]; then
    echo "📂 Cloning dotfiles repository to $HOME/dotfiles"
    git clone https://github.com/pushpindersidhu/dotfiles "$HOME/dotfiles"
else
    echo "📂 Dotfiles repository already exists at $HOME/dotfiles. Pulling latest changes..."
    git -C "$HOME/dotfiles" pull
fi

echo "✅ Dotfiles cloned successfully!"

cd "$HOME/dotfiles"

# ---------------------------------------------------------
# Homebrew Installation
# ---------------------------------------------------------
if ! command -v brew &>/dev/null; then
    echo "🍺 Installing Homebrew Package Manager..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    echo "🔧 Appending Homebrew environment paths to profile variables..."
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ Homebrew already installed."
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

# ---------------------------------------------------------
# Install Rust toolchain
# ---------------------------------------------------------
if ! command -v rustup &>/dev/null; then
    echo "🦀 Installing Rust toolchain..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    export PATH="$HOME/.cargo/bin:$PATH"
    echo "✅ Rust toolchain installed successfully!"
else
    echo "✅ Rust is already installed."
fi

# ---------------------------------------------------------
# Install Packages
# ---------------------------------------------------------
if [ -f "Brewfile" ]; then
    echo "📥 Installing packages from Brewfile..."

    if command -v brew &>/dev/null; then
        echo "🛡️  Trusting third-party developer tap: nikitabobko/tap..."
        brew trust nikitabobko/tap || true
    fi

    if ! command -v mas &>/dev/null; then
        brew install mas
    fi

    brew bundle --file=Brewfile
    echo "✅ Brewfile packages installed successfully!"
else
    echo "⚠️ Warning: No Brewfile target resolved in the active execution path."
fi

# ---------------------------------------------------------
# Install Oh My Zsh & Custom Plugins
# ---------------------------------------------------------
ZSH_DIR="$HOME/.oh-my-zsh"
CUSTOM_PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

if [ ! -d "$ZSH_DIR" ]; then
    echo "🐚 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    rm -f "$HOME/.zshrc"

    echo "✅ Oh My Zsh installed successfully!"
else
    echo "✅ Oh My Zsh already installed."
fi

echo "🔌 Installing plugins..."
if [ ! -d "$CUSTOM_PLUGIN_DIR/zsh-syntax-highlighting" ]; then
    echo "   -> Downloading: zsh-syntax-highlighting"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$CUSTOM_PLUGIN_DIR/zsh-syntax-highlighting"
    echo "✅ zsh-syntax-highlighting installed successfully!"
else
    echo "   -> ✅ zsh-syntax-highlighting already exists."
fi

if [ ! -d "$CUSTOM_PLUGIN_DIR/zsh-autosuggestions" ]; then
    echo "   -> Downloading: zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$CUSTOM_PLUGIN_DIR/zsh-autosuggestions"
    echo "✅ zsh-autosuggestions installed successfully!"
else
    echo "   -> ✅ zsh-autosuggestions already exists."
fi

# ---------------------------------------------------------
# Linking configs
# ---------------------------------------------------------
echo "🔗 Stowing..."

PACKAGES=(
    "aerospace"
    "ghostty"
    "nvim"
    "tmux"
    "zsh"
)

if ! command -v stow &>/dev/null; then
    echo "❌ stow not found."
    exit 1
fi

for PKG in "${PACKAGES[@]}"; do
    if [ -d "$PKG" ]; then
        echo "   -> Linking: $PKG"
        stow --adopt "$PKG"
    else
        echo "   ❌ Directory target missing for: $PKG"
    fi
done
echo "✅ All packages stowed successfully!"

# ---------------------------------------------------------
# macOS Dock, System & App Configurations
# ---------------------------------------------------------
echo "⚙️  Configuring macOS System & Dock Preferences..."

# --- KEYBOARD ---
echo "   [Keyboard]"
defaults write NSGlobalDomain KeyRepeat -int 2
echo "      > Key repeat rate set to 2"
defaults write NSGlobalDomain InitialKeyRepeat -int 15
echo "      > Initial key repeat delay set to 15"
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
echo "      > Press-and-hold disabled — key repeats instead of showing accent picker"
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
echo "      > Smart quotes disabled"
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
echo "      > Smart dashes disabled"
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
echo "      > Auto-capitalisation disabled"
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
echo "      > Auto-correct disabled"
 
# --- MOUSE ---
echo "   [Mouse]"
defaults write .GlobalPreferences com.apple.mouse.linear -bool true
echo "      > Mouse acceleration disabled — linear tracking"
 
# --- DOCK ---
echo "   [Dock]"
defaults write com.apple.dock persistent-apps -array
echo "      > Persistent apps cleared from Dock"
defaults write com.apple.dock tilesize -int 64 
echo "      > Icon size set to 64px"
defaults write com.apple.dock autohide -bool true
echo "      > Auto-hide enabled"
defaults write com.apple.dock autohide-delay -float 0
echo "      > Auto-hide delay set to 0 (instant)"
defaults write com.apple.dock autohide-time-modifier -float 0.2
echo "      > Auto-hide animation duration set to 0.2s"
 
# --- MISSION CONTROL ---
echo "   [Mission Control]"
defaults write com.apple.dock mru-spaces -bool false
echo "      > Spaces will not auto-rearrange based on recent use"
defaults write com.apple.dock expose-group-apps -bool true
echo "      > Windows grouped by app in Mission Control"
 
# --- FINDER ---
echo "   [Finder]"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
echo "      > All file extensions shown"
defaults write com.apple.finder AppleShowAllFiles -bool true
echo "      > Hidden files and dotfiles visible"
defaults write com.apple.finder _FXSortFoldersFirst -bool true
echo "      > Folders sorted to top in all views"
defaults write com.apple.finder FXPreferredViewStyle -string "icnv"
echo "      > Default view set to icon view"
defaults write com.apple.finder FXArrangeBy -string "name"
echo "      > Files auto-arranged by name"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
echo "      > Extension change warning disabled"
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
echo "      > Search defaults to current folder"
defaults write com.apple.finder ShowPathbar -bool true
echo "      > Path bar shown at bottom of window"
 
# --- SCREENSHOTS ---
echo "   [Screenshots]"
defaults write com.apple.screencapture location -string "$HOME/Desktop/"
echo "      > Screenshot save location set to ~/Desktop"
 
# --- NETWORK & STORAGE ---
echo "   [Network & Storage]"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
echo "      > .DS_Store files will not be created on network volumes"
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
echo "      > .DS_Store files will not be created on USB volumes"
 
# --- SECURITY ---
echo "   [Security]"
defaults write com.apple.LaunchServices LSQuarantine -bool false
echo "      > App quarantine warning disabled"

echo "🔄 Refreshing system processes..."
for app in "Dock" "Finder" "SystemUIServer"; do
    killall "$app" &>/dev/null || true
done
echo "✅ System preferences configured successfully!"

# ---------------------------------------------------------
# Cleanup & Exit
# ---------------------------------------------------------
echo "🔄 Resetting dotfiles repo to clean state..."
git reset --hard HEAD

echo "🎉 Setup completed successfully!"
