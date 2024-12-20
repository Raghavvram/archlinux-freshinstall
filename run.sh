#!/bin/bash

# Clear the package cache
sudo pacman -Scc --noconfirm

# Initialize and populate the keyring
sudo pacman-key --init
sudo pacman-key --populate
sudo pacman -S archlinux-keyring --noconfirm
sudo pacman -Syyy

# Install essential packages
sudo pacman -S micro neovim htop neofetch git wget curl net-tools base-devel xfce4-terminal otf-codenewroman-nerd --needed --noconfirm

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
paru -S exa yazi fzf ripgrep

# Optional
# paru -S jdk-openjdk code gcc ttf-jetbrains-mono-nerd --noconfirm
