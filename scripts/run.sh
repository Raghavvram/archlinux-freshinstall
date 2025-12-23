#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Clear the package cache
sudo pacman -Scc --noconfirm

# Initialize the pacman keyring.
sudo pacman-key --init

# Populate the pacman keyring with the default set of keys.
sudo pacman-key --populate

# Install the Arch Linux keyring package without asking for confirmation.
sudo pacman -S archlinux-keyring --noconfirm

# Refresh all package databases.
sudo pacman -Syyy


# Install essential packages
sudo pacman -S neovim htop neofetch git wget curl net-tools base-devel otf-codenewroman-nerd --needed --noconfirm

# Installing paru-bin
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si
cd ..

# Installing Colloid-gtk Theme and Icons
git clone https://github.com/vinceliuice/Colloid-gtk-theme.git
cd Colloid-gtk-theme
./install.sh -c dark --tweaks black
cd ..

git clone https://github.com/vinceliuice/Colloid-icon-theme.git
cd Colloid-icon-theme
./install.sh
cd ..

# Rust Tools
paru -S exa yazi fzf ripgrep lsd zoxide nushell 

# Optional
# paru -S jdk-openjdk code gcc ttf-jetbrains-mono-nerd --noconfirm
