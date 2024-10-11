#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

# Define the list of dotfiles to symlink
FILES_TO_SYMLINK=(.zshrc .bash_profile .gitconfig .hyper.js)

# Symlink dotfiles
echo "Creating symlinks for dotfiles..."
for file in "${FILES_TO_SYMLINK[@]}"; do
    TARGET="$HOME/$file"
    SOURCE="$DOTFILES_DIR/$file"
    if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
        mv "$TARGET" "${TARGET}.backup"
        echo "Backed up existing $file to ${file}.backup"
    fi
    ln -sf "$SOURCE" "$TARGET"
done

# Define the list of app-specific configurations to symlink
CONFIG_DIRS=(nvim spotify-cli linearmouse)

echo "Creating symlinks for app-specific configurations..."
mkdir -p "$HOME/.config"
for dir in "${CONFIG_DIRS[@]}"; do
    TARGET="$HOME/.config/$dir"
    SOURCE="$DOTFILES_DIR/.config/$dir"
    if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
        mv "$TARGET" "${TARGET}.backup"
        echo "Backed up existing $dir configuration to ${dir}.backup"
    fi
    ln -sf "$SOURCE" "$TARGET"
done

echo "Configuration setup complete!"
