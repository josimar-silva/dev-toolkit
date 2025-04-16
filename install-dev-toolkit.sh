#!/bin/bash

set -e

REPO_URL="https://github.com/josimar-silva/dev-toolkit.git"
INSTALL_DIR="$HOME/projects/dev-toolkit"
BASHRC="$HOME/.bashrc"

echo "📦 Installing dev-toolkit..."

# Clone the repo
if [ -d "$INSTALL_DIR" ]; then
  echo "⚠️  $INSTALL_DIR already exists."
  read -p "Do you want to overwrite it? (y/N): " OVERWRITE
  if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
    echo "❌ Aborting."
    exit 1
  fi
  rm -rf "$INSTALL_DIR"
fi

echo "🔽 Cloning dev-toolkit into $INSTALL_DIR..."
git clone "$REPO_URL" "$INSTALL_DIR"

# Make main script executable
chmod +x "$INSTALL_DIR/dev-toolkit"

# Add to PATH if not already added
if ! grep -q "$INSTALL_DIR" "$BASHRC"; then
  echo "🔧 Adding dev-toolkit to PATH in $BASHRC"
  echo "" >> "$BASHRC"
  echo "# Dev Toolkit" >> "$BASHRC"
  echo "export PATH="$INSTALL_DIR:\$PATH"" >> "$BASHRC"
fi

# Add alias for convenience
if ! grep -q "alias dt=" "$BASHRC"; then
  echo "🔧 Adding alias 'dt' to $BASHRC"
  echo "alias dt="dev-toolkit"" >> "$BASHRC"
fi

echo "🔁 Reloading shell config..."
source "$BASHRC"

echo "✅ dev-toolkit installed!"
echo ""
echo "Try: dt git init-config"
