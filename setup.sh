#!/bin/bash
set -e

echo "Installing official packages..."
sudo pacman -S --needed - < <(grep -v '^#' packages.txt | sed '/^$/d')

echo "Installing paru (AUR helper)..."
if ! command -v paru &> /dev/null; then
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd ..
fi

echo "Installing AUR packages..."
paru -S --needed - < <(grep -v '^#' aur-packages.txt | sed '/^$/d')

echo "Enabling services..."
sudo systemctl enable sddm
sudo systemctl enable NetworkManager
sudo systemctl enable docker

echo "Adding user to docker group..."
sudo usermod -aG docker $USER

echo "Setting zsh as default shell..."
chsh -s /bin/zsh

echo "Setting up Flatpak (Flathub)..."
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "Done. Reboot recommended."
