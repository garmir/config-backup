#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Install Homebrew if not installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found, installing..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS-specific installation
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add Homebrew to PATH
        eval "$("$(brew --prefix)"/bin/brew shellenv)"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux-specific installation
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add Homebrew to PATH
        eval "$("$(brew --prefix)"/bin/brew shellenv)"
    else
        echo "Unsupported OS. Please install Homebrew manually."
        exit 1
    fi
fi

# Install packages from Brewfile
brew bundle --file="$SCRIPT_DIR/Brewfile"
