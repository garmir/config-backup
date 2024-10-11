#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Get the directory of the script
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG_BACKUP_REPO="$SCRIPT_DIR"
SCRIPT_NAME=$(basename "$0")

echo "Running $SCRIPT_NAME in $CONFIG_BACKUP_REPO"

# Define the dotfiles directory inside the config-backup repository
DOTFILES_DIR="$CONFIG_BACKUP_REPO/dotfiles"

# Ensure the dotfiles directory exists
mkdir -p "$DOTFILES_DIR"

# Define the list of dotfiles to back up
DOTFILES=(~/.zshrc ~/.bash_profile ~/.gitconfig ~/.hyper.js)

# Copy dotfiles to the dotfiles directory
echo "Copying dotfiles to $DOTFILES_DIR..."
for file in "${DOTFILES[@]}"; do
    file="${file/#\~/$HOME}"  # Expand any tildes or variables
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        # Sanitize files before copying
        case "$filename" in
            ".gitconfig")
                # Remove [user] section
                sed '/^\[user\]/,$d' "$file" > "$DOTFILES_DIR/$filename"
                ;;
            ".zshrc"|".bash_profile")
                # Remove lines containing sensitive patterns
                grep -v -E '(API_KEY|SECRET|TOKEN|PASSWORD)' "$file" > "$DOTFILES_DIR/$filename"
                ;;
            *)
                cp "$file" "$DOTFILES_DIR/"
                ;;
        esac
    else
        echo "Warning: $file does not exist and was not copied."
    fi
done

# Define the list of app-specific configurations to back up
CONFIG_DIRS=(nvim spotify-cli linearmouse)

echo "Copying app-specific configurations..."
for dir in "${CONFIG_DIRS[@]}"; do
    SRC_DIR="$HOME/.config/$dir"
    DEST_DIR="$DOTFILES_DIR/.config/$dir"
    if [ -d "$SRC_DIR" ]; then
        mkdir -p "$DEST_DIR"
        # Exclude files containing sensitive data
        rsync -av --exclude='**/*secret*' --exclude='**/*token*' --exclude='**/*password*' --exclude='**/*client*' "$SRC_DIR/" "$DEST_DIR/"
    else
        echo "Warning: $SRC_DIR does not exist and was not copied."
    fi
done

# Copy Obsidian configurations
OBSIDIAN_VAULT_PATH="${OBSIDIAN_VAULT_PATH:-$HOME/anathema}"  # Adjust this path if necessary

if [ -d "$OBSIDIAN_VAULT_PATH/.obsidian" ]; then
    OBSIDIAN_DEST="$DOTFILES_DIR/obsidian/.obsidian"
    mkdir -p "$OBSIDIAN_DEST"
    # Copy only configuration files, exclude personal notes
    rsync -av --exclude='**/workspace.json' "$OBSIDIAN_VAULT_PATH/.obsidian/" "$OBSIDIAN_DEST/"
    echo "Obsidian configurations copied."
else
    echo "Warning: Obsidian configuration not found at $OBSIDIAN_VAULT_PATH/.obsidian."
fi

# Generate Brewfile to reinstall Homebrew packages
echo "Generating Brewfile..."
if brew bundle dump --file="$CONFIG_BACKUP_REPO/Brewfile" --force; then
    echo "Brewfile generated successfully."
else
    echo "Failed to generate Brewfile. Please check for Homebrew issues."
    exit 1
fi

# Remove casks or formulae that might reveal sensitive tools
echo "Sanitizing Brewfile..."

if sed --version >/dev/null 2>&1; then
    # GNU sed
    SED_INPLACE=(-i)
else
    # BSD sed (macOS)
    SED_INPLACE=(-i '')
fi

sed "${SED_INPLACE[@]}" '/cask "privatevpn"/d' "$CONFIG_BACKUP_REPO/Brewfile"
sed "${SED_INPLACE[@]}" '/cask "1password"/d' "$CONFIG_BACKUP_REPO/Brewfile"

# Generate brew.sh script
echo "Generating brew.sh script..."
cat <<EOL > "$CONFIG_BACKUP_REPO/brew.sh"
#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

SCRIPT_DIR=\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)

# Install Homebrew if not installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found, installing..."

    if [[ "\$OSTYPE" == "darwin"* ]]; then
        # macOS-specific installation
        /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add Homebrew to PATH
        eval "\$("\$(brew --prefix)"/bin/brew shellenv)"
    elif [[ "\$OSTYPE" == "linux-gnu"* ]]; then
        # Linux-specific installation
        /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add Homebrew to PATH
        eval "\$("\$(brew --prefix)"/bin/brew shellenv)"
    else
        echo "Unsupported OS. Please install Homebrew manually."
        exit 1
    fi
fi

# Install packages from Brewfile
brew bundle --file="\$SCRIPT_DIR/Brewfile"
EOL

chmod +x "$CONFIG_BACKUP_REPO/brew.sh"

# Create setup.sh script to symlink dotfiles
echo "Generating setup.sh script..."
cat <<EOL > "$CONFIG_BACKUP_REPO/setup.sh"
#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

SCRIPT_DIR=\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)
DOTFILES_DIR="\$SCRIPT_DIR/dotfiles"

# Define the list of dotfiles to symlink
FILES_TO_SYMLINK=(.zshrc .bash_profile .gitconfig .hyper.js)

# Symlink dotfiles
echo "Creating symlinks for dotfiles..."
for file in "\${FILES_TO_SYMLINK[@]}"; do
    TARGET="\$HOME/\$file"
    SOURCE="\$DOTFILES_DIR/\$file"
    if [ -e "\$TARGET" ] && [ ! -L "\$TARGET" ]; then
        mv "\$TARGET" "\${TARGET}.backup"
        echo "Backed up existing \$file to \${file}.backup"
    fi
    ln -sf "\$SOURCE" "\$TARGET"
done

# Define the list of app-specific configurations to symlink
CONFIG_DIRS=(nvim spotify-cli linearmouse)

echo "Creating symlinks for app-specific configurations..."
mkdir -p "\$HOME/.config"
for dir in "\${CONFIG_DIRS[@]}"; do
    TARGET="\$HOME/.config/\$dir"
    SOURCE="\$DOTFILES_DIR/.config/\$dir"
    if [ -e "\$TARGET" ] && [ ! -L "\$TARGET" ]; then
        mv "\$TARGET" "\${TARGET}.backup"
        echo "Backed up existing \$dir configuration to \${dir}.backup"
    fi
    ln -sf "\$SOURCE" "\$TARGET"
done

echo "Configuration setup complete!"
EOL

chmod +x "$CONFIG_BACKUP_REPO/setup.sh"

# Create .gitignore file to exclude any unintended files
echo "Creating .gitignore..."
cat <<EOL > "$CONFIG_BACKUP_REPO/.gitignore"
# Ignore macOS system files
.DS_Store

# Ignore backup files
*.backup

# Ignore sensitive directories (just in case)
dotfiles/config/gh/
dotfiles/config/aws/
dotfiles/config/ssh/
EOL

# Create README.md file if it doesn't exist
echo "Creating README.md..."
if [ -f "$CONFIG_BACKUP_REPO/README.md" ]; then
    echo "README.md already exists. Skipping."
else
    if [ -z "$GITHUB_USERNAME" ]; then
        read -r -p "Enter your GitHub username: " GITHUB_USERNAME
    fi
    cat <<EOL > "$CONFIG_BACKUP_REPO/README.md"
# Configuration Backup

## Setup Instructions

1. Clone the repository:

   \`\`\`bash
   git clone https://github.com/${GITHUB_USERNAME}/config-backup.git
   cd config-backup
   \`\`\`

2. Run the \`brew.sh\` script to reinstall Homebrew packages:

   \`\`\`bash
   ./brew.sh
   \`\`\`

3. Run the \`setup.sh\` script to create symlinks:

   \`\`\`bash
   ./setup.sh
   \`\`\`

4. Open your terminal and you're good to go!

**Note:** Ensure that any sensitive information has been removed from the configuration files before pushing to a public repository.
EOL
fi

# Review and confirm before pushing to GitHub
echo "Review the files before pushing to GitHub to ensure no sensitive data is included."
AUTO_CONFIRM=false

while getopts "y" opt; do
  case $opt in
    y)
      AUTO_CONFIRM=true
      ;;
    *)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [ "$AUTO_CONFIRM" = true ]; then
    confirm_push="y"
else
    read -r -p "Have you reviewed the files and are ready to push to GitHub? (y/n): " confirm_push
fi

if [ "$confirm_push" = "y" ]; then
    echo "Pushing config-backup to GitHub..."
    cd "$CONFIG_BACKUP_REPO" || exit 1
    git add .

    # Detect default Git branch
    DEFAULT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}

    git commit -m "Automated backup of configurations (PII sanitized)"

    if git push origin "$DEFAULT_BRANCH"; then
        echo "Backup complete! Everything has been pushed to GitHub."
    else
        echo "Failed to push to GitHub. Please check your Git settings."
    fi
else
    echo "Please review the files and rerun the script when you're ready."
fi