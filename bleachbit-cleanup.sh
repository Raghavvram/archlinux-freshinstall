#!/bin/bash

# Run BleachBit cleanup for each specified item
sudo bleachbit --clean bash.history \
    deepscan.backup \
    deepscan.ds_store \
    deepscan.thumbs_db \
    deepscan.tmp \
    deepscan.vim_swap_root \
    deepscan.vim_swap_user \
    filezilla.mru \
    google_chrome.cache \
    google_chrome.dom \
    google_chrome.form_history \
    google_chrome.history \
    google_chrome.vacuum \
    journald.clean \
    libreoffice.history \
    system.cache \
    system.custom \
    system.desktop_entry \
    system.localizations \
    system.memory \
    system.recent_documents \
    system.rotated_logs \
    system.tmp \
    system.trash \
    thumbnails.cache \
    thunderbird.cache \
    thunderbird.cookies \
    thunderbird.index \
    thunderbird.passwords \
    thunderbird.sessionjson \
    thunderbird.vacuum \
    vim.history \
    vlc.memory_dump \
    vlc.mru \
    x11.debug_logs

echo "Cleanup completed successfully!"

