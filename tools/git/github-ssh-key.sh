#!/bin/bash

echo "🔐 Setting up SSH key for GitHub..."

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
  echo "❌ GitHub CLI (gh) is not installed."
  echo ""
  echo "To install GitHub CLI:"
  echo "  - macOS (brew): brew install gh"
  echo "  - Linux (snap): sudo snap install gh"
  echo "  - Windows (choco): choco install gh"
  echo "  - Other options: https://github.com/cli/cli#installation"
  echo ""
  echo "After installation, run 'gh auth login' to authenticate before running this script again."
  exit 1
fi

# Check GitHub CLI authentication
if ! gh auth status &> /dev/null; then
  echo "❌ GitHub CLI is not authenticated."
  echo "Please run 'gh auth login' first."
  exit 1
fi

# Prompt for email (used in key comment)
read -p "📧 GitHub Email: " EMAIL

KEY_NAME="id_ed25519_github"
KEY_PATH="$HOME/.ssh/$KEY_NAME"
KEY_TITLE="GitHub SSH Key - $(hostname) - $(date +%Y-%m-%d)"

# Function to list existing SSH keys
list_existing_keys() {
  echo "🔍 Existing SSH keys in ~/.ssh/:"
  find ~/.ssh -type f -name '*.pub' -exec basename {} .pub \; 2>/dev/null | while read -r key; do
    echo "  - $key"
  done
}

# Function to fix permissions
fix_key_permissions() {
  chmod 600 "$1"
  chmod 644 "${1}.pub"
  echo "🔒 Fixed permissions for ${1}"
}

# Check if key already exists
if [ -f "$KEY_PATH" ]; then
  echo "⚠️  Default SSH key already exists at $KEY_PATH"
  echo ""
  list_existing_keys
  echo ""
  echo "What would you like to do?"
  echo "  1) Use existing key ($KEY_PATH)"
  echo "  2) Create new key"
  echo "  3) Select different existing key"
  echo "  4) Exit"
  read -p "Your choice (1-4): " CHOICE

  case $CHOICE in
    1)
      echo "✅ Using existing key: $KEY_PATH"
      fix_key_permissions "$KEY_PATH"
      ;;
    2)
      echo "🔧 Generating new SSH key..."
      rm -f "$KEY_PATH" "$KEY_PATH.pub"
      ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH" -N ""
      fix_key_permissions "$KEY_PATH"
      ;;
    3)
      list_existing_keys
      read -p "📝 Enter the name of existing key (without .pub): " EXISTING_KEY_NAME
      EXISTING_KEY_PATH="$HOME/.ssh/$EXISTING_KEY_NAME"
      if [ -f "$EXISTING_KEY_PATH" ]; then
        KEY_PATH="$EXISTING_KEY_PATH"
        echo "✅ Using selected key: $KEY_PATH"
        fix_key_permissions "$KEY_PATH"
      else
        echo "❌ Key not found: $EXISTING_KEY_PATH"
        exit 1
      fi
      ;;
    4)
      echo "❌ Aborting."
      exit 0
      ;;
    *)
      echo "❌ Invalid choice."
      exit 1
      ;;
  esac
else
  echo "🔧 Generating new SSH key..."
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH" -N ""
  fix_key_permissions "$KEY_PATH"
fi

# Start ssh-agent and add the key
eval "$(ssh-agent -s)"
ssh-add "$KEY_PATH"

# Verify public key exists
if [ ! -f "${KEY_PATH}.pub" ]; then
  echo "❌ Public key not found: ${KEY_PATH}.pub"
  exit 1
fi

# Use GitHub CLI to add key
echo "📡 Uploading public key to GitHub..."
if gh ssh-key add "${KEY_PATH}.pub" --title "$KEY_TITLE"; then
  echo ""
  echo "✅ SSH key setup complete!"
  echo "📂 Private Key: $KEY_PATH"
  echo "🔑 Public Key:  ${KEY_PATH}.pub"
  echo "🌐 GitHub Title: \"$KEY_TITLE\""
  echo ""
  echo "🧪 You can test it with: ssh -T git@github.com"
else
  echo "❌ Failed to upload SSH key to GitHub"
  echo "Possible reasons:"
  echo "1. Check file permissions:"
  echo "   - Run: ls -l ${KEY_PATH}.pub"
  echo "   - It should be readable (chmod 644)"
  echo "2. Verify GitHub CLI authentication:"
  echo "   - Run: gh auth status"
  echo "3. Check if key already exists on GitHub:"
  echo "   - Run: gh ssh-key list"
  exit 1
fi
