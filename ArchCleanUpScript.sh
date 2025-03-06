#!/bin/bash

echo "Updating system..."
if ! paru -Syu; then
    echo "System update failed. Please check your internet connection or package manager configuration."
    exit 1
fi

echo "Clearing pacman cache..."
pacman_cache_space_used="$(du -sh /var/cache/pacman/pkg/ 2>/dev/null | cut -f1)"
if sudo paccache -r; then
    echo "Pacman cache cleared. Space saved: $pacman_cache_space_used"
else
    echo "Failed to clear pacman cache. Check permissions or pacman configuration."
fi

echo "Removing orphan packages..."
orphans=$(paru -Qdtq)
if [ -n "$orphans" ]; then
    if ! paru -Rns --noconfirm $orphans; then
        echo "Failed to remove orphan packages. Check for dependency issues."
    else
        echo "Orphan packages removed."
    fi
else
    echo "No orphan packages found."
fi

echo "Clearing ~/.cache directory..."
home_cache_used="$(du -sh ~/.cache 2>/dev/null | cut -f1)"
if rm -rf ~/.cache/; then
    echo "Home cache cleared. Space saved: $home_cache_used"
else
    echo "Failed to clear ~/.cache directory. Check permissions or file locks."
fi

echo "Clearing system logs older than 7 days..."
if sudo journalctl --vacuum-time=7d; then
    echo "System logs older than 7 days have been cleared."
else
    echo "Failed to clear system logs. Check journalctl configuration."
fi

echo "System maintenance tasks completed successfully."
