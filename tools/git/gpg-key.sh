#!/bin/bash

echo "🔐 GPG Key Generator for Git Signing"
echo "------------------------------------"

# Prompt for identity
read -p "👤 Full Name (for GPG key): " FULL_NAME
read -p "📧 Email (for GPG key): " EMAIL

echo "📄 Generating GPG key for: $FULL_NAME <$EMAIL>"
echo "You'll be prompted by GPG to confirm details..."

# Launch GPG key creation
gpg --full-generate-key

# Wait for key generation
echo "⏳ Waiting for GPG key to be available..."

# Extract key ID (assumes latest created key matches email)
GPG_KEY=$(gpg --list-secret-keys --keyid-format LONG "$EMAIL" | awk '/^sec/ { print $2 }' | awk -F'/' '{print $2}')

if [ -z "$GPG_KEY" ]; then
  echo "❌ Failed to find generated GPG key. Please check manually with: gpg --list-secret-keys"
  exit 1
fi

echo ""
echo "✅ GPG key generated successfully!"
echo "🆔 Your GPG key ID: $GPG_KEY"
echo ""
echo "📋 You can now add this to your Git config:"
echo "    git config --global user.signingkey $GPG_KEY"
echo "    git config --global commit.gpgsign true"
echo ""
echo "💡 You might also want to export your public key if pushing to GitHub/GitLab:"
echo "    gpg --armor --export $GPG_KEY"
