#!/bin/zsh
# This script runs once when chezmoi apply is executed

set -e  # Exit on any error

# =============================================================================
# VERSION CONFIGURATION - Managed via .tool-versions file
# =============================================================================

echo "🚀 Setting up macOS development environment..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[CHEZMOI]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    error "This script is for macOS only"
    exit 1
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    log "Homebrew already installed"
fi

# Update Homebrew
log "Updating Homebrew..."
brew update

# Install GUI applications
log "Installing GUI applications..."
GUI_APPS=(
    "iterm2"        # Terminal emulator
)

for app in "${GUI_APPS[@]}"; do
    if brew list --cask "$app" &>/dev/null; then
        log "$app already installed"
    else
        log "Installing $app..."
        brew install --cask "$app"
    fi
done

# Install fonts
log "Installing fonts..."
brew tap homebrew/cask-fonts
brew install --cask font-fira-code
brew install --cask font-fira-code-nerd-font

# Install CLI tools via Homebrew
log "Installing CLI tools..."
BREW_PACKAGES=(
    "fzf"           # Fuzzy finder
    "eza"           # Modern replacement for ls
    "bat"           # Cat with syntax highlighting
    "broot"         # Tree navigation
    "git-delta"     # Git diff viewer
    "asdf"          # Version manager
    "ripgrep"       # Fast text search
    "tree"          # Directory tree viewer
    "watchman"      # File watching service
    "gpg"           # GNU Privacy Guard
    "1password-cli" # 1Password CLI
)

for package in "${BREW_PACKAGES[@]}"; do
    if brew list "$package" &>/dev/null; then
        log "$package already installed"
    else
        log "Installing $package..."
        brew install "$package"
    fi
done

# Install xcodes (Xcode version manager)
log "Installing xcodes..."
if ! brew list "xcodesorg/made/xcodes" &>/dev/null; then
    brew install xcodesorg/made/xcodes
else
    log "xcodes already installed"
fi

# Install Starship prompt
log "Installing Starship prompt..."
if ! command -v starship &> /dev/null; then
    curl -fsSL https://starship.rs/install.sh | sh
else
    log "Starship already installed"
fi

# Install iTerm2 shell integration
log "Installing iTerm2 shell integration..."
curl -L https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash

# Configure fzf
log "Configuring fzf..."
if ! grep -q "fzf" ~/.zshrc 2>/dev/null; then
    log "Setting up fzf shell integration..."
    $(brew --prefix)/opt/fzf/install --all
else
    log "fzf shell integration already configured"
fi

# Install Oh My Zsh
log "Installing Oh My Zsh..."
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "Installing Oh My Zsh..."
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    log "Oh My Zsh already installed"
fi

# Configure broot
log "Configuring broot..."
if ! grep -q "br" ~/.zshrc 2>/dev/null; then
    log "Running broot --install to set up shell integration..."
    broot --install
else
    log "broot shell integration already configured"
fi

# Setup asdf
log "Setting up asdf..."

# Source asdf for current session (needed for plugin installation)
if [[ -f $(brew --prefix asdf)/libexec/asdf.sh ]]; then
    source $(brew --prefix asdf)/libexec/asdf.sh
else
    warn "asdf not found, skipping version management setup"
    exit 0
fi

# Install asdf plugins
log "Installing asdf plugins..."
ASDF_PLUGINS=(
    "nodejs https://github.com/asdf-vm/asdf-nodejs.git"
    "cocoapods"
    "python"
    "swift"
    "swiftlint"
    "yarn"
)

for plugin_info in "${ASDF_PLUGINS[@]}"; do
    plugin_name=$(echo "$plugin_info" | cut -d' ' -f1)
    plugin_repo=$(echo "$plugin_info" | cut -d' ' -f2-)

    if asdf plugin list | grep -q "^$plugin_name$"; then
        log "asdf plugin $plugin_name already installed"
    else
        log "Installing asdf plugin: $plugin_name..."
        if [[ "$plugin_repo" != "$plugin_name" ]]; then
            asdf plugin add "$plugin_name" "$plugin_repo"
        else
            asdf plugin add "$plugin_name"
        fi
    fi
done

# Install versions from .tool-versions
log "Installing language versions from .tool-versions..."
if [[ -f "$HOME/.tool-versions" ]]; then
    log "Found .tool-versions file, installing all specified versions..."
    asdf install
else
    warn ".tool-versions file not found, skipping version installation"
fi

log "✅ macOS development environment setup complete!"
echo
log "Installed packages will be configured by your chezmoi-managed dotfiles."
log "Restart your terminal after chezmoi apply completes to load the new configuration."
