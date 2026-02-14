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
# DOTFILES
# -------------------------------------------------
echo "Installing user dotfiles..."

# Copy home files
rsync -a dotfiles/home/ "$HOME/"

# -------------------------------------------------
# KDE APPLY WHITESUR THEME
# -------------------------------------------------

echo "Applying WhiteSur KDE theme..."

chown -R "$USER:$USER" "$HOME"

# Apply Global Theme
if command -v plasma-apply-lookandfeel &> /dev/null; then
    plasma-apply-lookandfeel -a com.github.vinceliuice.WhiteSur
fi

# Icon Theme
kwriteconfig6 --file kdeglobals --group Icons --key Theme WhiteSur-dark

# Cursor Theme
kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme WhiteSur-cursors

# Enable Kvantum
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum

if command -v kvantummanager &> /dev/null; then
    kvantummanager --set WhiteSur
fi

# Window Decoration (Aurorae)
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme WhiteSur-dark

echo "WhiteSur theme configured."

echo "==================================================="
echo "POST INSTALL PRECAUSIONS"
echo "please logout and login and set proper height for panel"
echo "and adjust themes in settings manually if needed"
echo "==================================================="

echo "Done. Reboot recommended."
