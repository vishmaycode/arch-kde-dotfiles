#!/bin/bash
set -e

# -------------------------------------------------
# PACKAGES INSTALLATION
# -------------------------------------------------
echo "Installing official packages..."
sudo pacman -S --needed --noconfirm - < <(grep -v '^#' packages.txt | sed '/^$/d')

echo "Installing paru (AUR helper)..."
if ! command -v paru &> /dev/null; then
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd ..
fi

echo "Installing AUR packages..."
paru -S --needed --noconfirm - < <(grep -v '^#' aur-packages.txt | sed '/^$/d')

if ! command -v google-chrome-stable &> /dev/null; then
    git clone https://aur.archlinux.org/google-chrome.git
    cd google-chrome
    makepkg -si --noconfirm
    cd ..
else
    echo "google-chrome already installed, skipping."
fi

# -------------------------------------------------
# ENABLE SERVICES
# -------------------------------------------------

echo "Enabling services..."
sudo systemctl enable sddm
sudo systemctl enable NetworkManager
sudo systemctl enable docker

echo "Adding user to docker group..."
sudo usermod -aG docker $USER

# -------------------------------------------------
# ZSH
# -------------------------------------------------
echo "Ensuring Oh My Zsh is installed..."

if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh already installed. Skipping."
else
    echo "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "Ensuring Powerlevel10k theme is installed..."

P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

if [ -d "$P10K_DIR" ]; then
    echo "Powerlevel10k already installed. Skipping."
else
    echo "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

if [ "$SHELL" != "/bin/zsh" ]; then
    chsh -s "$(command -v zsh)"
else
    echo "zsh is already the default shell. Skipping."
fi

# -------------------------------------------------
# FLATPAK
# -------------------------------------------------
echo "Setting up Flatpak (Flathub)..."
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# -------------------------------------------------
# DOTFILES SETUP (BASH + ZSH)
# -------------------------------------------------
echo "Setting up shell configuration files..."

DOTFILES_REPO="https://raw.githubusercontent.com/vishmaycode/zsh-and-bash/master"

# Backup existing configs
[ -f ~/.bashrc ] && mv ~/.bashrc ~/.bashrc.backup.$(date +%s)
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup.$(date +%s)
[ -f ~/.aliases ] && mv ~/.aliases ~/.aliases.backup.$(date +%s)

# Download new configs
curl -fsSL "$DOTFILES_REPO/.bashrc" -o ~/.bashrc
curl -fsSL "$DOTFILES_REPO/.zshrc" -o ~/.zshrc
curl -fsSL "$DOTFILES_REPO/.aliases" -o ~/.aliases

# -------------------------------------------------
# BLE.SH INSTALL (for bash)
# -------------------------------------------------
if [ -d "$HOME/.local/share/blesh" ]; then
    echo "ble.sh already installed. Skipping."
else
    echo "Installing ble.sh..."
    git clone --recursive --depth 1 https://github.com/akinomyoga/ble.sh.git ~/.local/share/blesh
    make -C ~/.local/share/blesh install PREFIX=~/.local
fi

# -------------------------------------------------
# ATUIN INSTALL
# -------------------------------------------------
if [ -x "$HOME/.atuin/bin/atuin" ]; then
    echo "Atuin already installed. Skipping."
else
    echo "Installing Atuin..."
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi

# -------------------------------------------------
# ENSURE NVM + PYENV INSTALLED (CONFIG ALREADY IN DOTFILES)
# -------------------------------------------------

# Install pyenv if missing
if [ ! -d "$HOME/.pyenv" ]; then
    echo "Installing pyenv..."
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
fi

# Install NVM if missing
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

echo "Shell configuration complete."

# -------------------------------------------------
# NEOVIM CONFIG (LazyVim)
# -------------------------------------------------
echo "Setting up Neovim configuration..."

NVIM_CONFIG_DIR="$HOME/.config/nvim"

if [ -d "$NVIM_CONFIG_DIR" ]; then
    echo "Neovim config already exists. Skipping clone."
else
    echo "Cloning Neovim LazyVim config..."
    git clone https://github.com/vishmaycode/neovim-lazyvim.git "$NVIM_CONFIG_DIR"
fi

# -------------------------------------------------
# TMUX CONFIG
# -------------------------------------------------
echo "Setting up tmux configuration..."

TMUX_CONF="$HOME/.tmux.conf"

if [ -f "$TMUX_CONF" ]; then
    echo "tmux config already exists. Skipping."
else
    echo "Downloading tmux config..."
    curl -fsSL https://raw.githubusercontent.com/vishmaycode/tmux-config/main/.tmux.conf -o "$TMUX_CONF"
fi

# -------------------------------------------------
# PERSONAL LOCAL BINARIES
# -------------------------------------------------
echo "Setting up personal local binaries..."

LOCAL_BIN_DIR="$HOME/.local/bin"

mkdir -p "$LOCAL_BIN_DIR"

if [ -d "$LOCAL_BIN_DIR/.git" ]; then
    echo "local-bin repo already exists. Pulling latest changes..."
    git -C "$LOCAL_BIN_DIR" pull --ff-only || true
else
    echo "Cloning local-bin repository..."
    rm -rf "$LOCAL_BIN_DIR"
    git clone https://github.com/vishmaycode/local-bin.git "$LOCAL_BIN_DIR"
fi

# Ensure PATH contains ~/.local/bin (for current session)
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

echo "Done. Reboot recommended."
