#!/bin/bash

# Fix corrupted APT package list
echo "Fixing corrupted package list..."

# Remove old package list
sudo rm -rf /var/lib/apt/lists/*
echo "Removed /var/lib/apt/lists/*"

# Recreate the partial directory
sudo mkdir -p /var/lib/apt/lists/partial
echo "Recreated /var/lib/apt/lists/partial"

# Update package list
echo "Updating package list..."
sudo apt-get update

echo "Done."
