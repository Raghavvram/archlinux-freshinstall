#!/bin/bash

# Clear the package cache
sudo pacman -Scc --noconfirm

# Initialize and populate the keyring
sudo pacman-key --init
sudo pacman-key --populate
sudo pacman -S archlinux-keyring --noconfirm
sudo pacman -Syyy
