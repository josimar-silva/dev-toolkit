#!/bin/bash

# git-profile-manager - A tool to manage multiple Git profiles

CONFIG_FILE="$HOME/.gitprofiles"
EDITOR="${EDITOR:-nano}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if config file exists, create if not
if [ ! -f "$CONFIG_FILE" ]; then
  echo -e "${YELLOW}Creating new configuration file at $CONFIG_FILE${NC}"
  touch "$CONFIG_FILE"
  echo "# Git Profiles Configuration" >> "$CONFIG_FILE"
  echo "# Format:" >> "$CONFIG_FILE"
  echo "# [profile-name]" >> "$CONFIG_FILE"
  echo "# email = your.email@example.com" >> "$CONFIG_FILE"
  echo "# name = Your Name" >> "$CONFIG_FILE"
  echo "# signingkey = your_signing_key (optional)" >> "$CONFIG_FILE"
  echo "" >> "$CONFIG_FILE"
fi

# Function to get config value from profile section
get_profile_value() {
  local section="$1"
  local key="$2"
  sed -n "/^\[$section\]/,/^\[/p" "$CONFIG_FILE" | grep "^$key =" | cut -d '=' -f 2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Function to list all profiles
list_profiles() {
  echo -e "${BLUE}Available Git profiles:${NC}"
  grep -oP '^\[\K[^\]]+' "$CONFIG_FILE" | while read -r profile; do
    echo -e "  ${GREEN}$profile${NC}"
    echo "    Email: $(get_profile_value "$profile" "email")"
    echo "    Name: $(get_profile_value "$profile" "name")"
    signingkey=$(get_profile_value "$profile" "signingkey")
    if [ -n "$signingkey" ]; then
      echo "    Signing Key: $signingkey"
    fi
    echo ""
  done
}

# Function to add/edit a profile
edit_profile() {
  local profile="$1"
  
  # Get current values if profile exists
  if grep -q "^\[$profile\]" "$CONFIG_FILE"; then
    current_email=$(get_profile_value "$profile" "email")
    current_name=$(get_profile_value "$profile" "name")
    current_signingkey=$(get_profile_value "$profile" "signingkey")
    echo -e "${YELLOW}Editing existing profile: $profile${NC}"
  else
    current_email=""
    current_name=""
    current_signingkey=""
    echo -e "${GREEN}Creating new profile: $profile${NC}"
  fi

  # Prompt for values
  read -p "Email [$current_email]: " email
  email="${email:-$current_email}"
  
  read -p "Name [$current_name]: " name
  name="${name:-$current_name}"
  
  read -p "Signing Key (optional) [$current_signingkey]: " signingkey
  signingkey="${signingkey:-$current_signingkey}"

  # Validate required fields
  if [ -z "$email" ] || [ -z "$name" ]; then
    echo -e "${RED}Error: Email and Name are required fields${NC}"
    exit 1
  fi

  # Create temporary file for new profile section
  tmpfile=$(mktemp)
  
  # Copy all content except the profile we're editing
  sed "/^\[$profile\]/,/^$/d" "$CONFIG_FILE" > "$tmpfile"
  
  # Add the new/updated profile
  echo "" >> "$tmpfile"
  echo "[$profile]" >> "$tmpfile"
  echo "email = $email" >> "$tmpfile"
  echo "name = $name" >> "$tmpfile"
  if [ -n "$signingkey" ]; then
    echo "signingkey = $signingkey" >> "$tmpfile"
  fi
  echo "" >> "$tmpfile"

  # Replace original file with the updated one
  mv "$tmpfile" "$CONFIG_FILE"
  
  echo -e "${GREEN}Profile '$profile' saved successfully!${NC}"
}

# Function to switch to a profile
switch_profile() {
  local profile="$1"
  
  if ! grep -q "^\[$profile\]" "$CONFIG_FILE"; then
    echo -e "${RED}Error: Profile '$profile' not found${NC}"
    exit 1
  fi

  # Get profile values
  email=$(get_profile_value "$profile" "email")
  name=$(get_profile_value "$profile" "name")
  signingkey=$(get_profile_value "$profile" "signingkey")

  # Set git config
  git config --global user.email "$email"
  git config --global user.name "$name"

  # Set signingkey only if it exists in the profile
  if [ -n "$signingkey" ]; then
    git config --global user.signingkey "$signingkey"
    echo -e "${GREEN}Switched to $profile Git profile: $name <$email> (with signing key)${NC}"
  else
    git config --global --unset user.signingkey
    echo -e "${GREEN}Switched to $profile Git profile: $name <$email>${NC}"
  fi
}

# Function to delete a profile
delete_profile() {
  local profile="$1"
  
  if ! grep -q "^\[$profile\]" "$CONFIG_FILE"; then
    echo -e "${RED}Error: Profile '$profile' not found${NC}"
    exit 1
  fi

  read -p "Are you sure you want to delete profile '$profile'? [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    # Create temporary file without the profile
    tmpfile=$(mktemp)
    sed "/^\[$profile\]/,/^$/d" "$CONFIG_FILE" > "$tmpfile"
    mv "$tmpfile" "$CONFIG_FILE"
    echo -e "${GREEN}Profile '$profile' deleted successfully!${NC}"
  else
    echo -e "${YELLOW}Deletion canceled${NC}"
  fi
}

# Function to show current profile
show_current() {
  current_email=$(git config --global user.email)
  current_name=$(git config --global user.name)
  current_signingkey=$(git config --global user.signingkey || echo "none")
  
  echo -e "${BLUE}Current Git configuration:${NC}"
  echo "  Email: $current_email"
  echo "  Name: $current_name"
  echo "  Signing Key: $current_signingkey"
  
  # Try to find which profile matches current config
  matching_profile=""
  grep -oP '^\[\K[^\]]+' "$CONFIG_FILE" | while read -r profile; do
    profile_email=$(get_profile_value "$profile" "email")
    profile_name=$(get_profile_value "$profile" "name")
    if [ "$profile_email" = "$current_email" ] && [ "$profile_name" = "$current_name" ]; then
      echo -e "\n${GREEN}This matches your '$profile' profile${NC}"
    fi
  done
}

# Main command handling
case "$1" in
  list)
    list_profiles
    ;;
  add)
    if [ -z "$2" ]; then
      echo -e "${RED}Error: Please specify a profile name${NC}"
      echo "Usage: $0 add <profile-name>"
      exit 1
    fi
    edit_profile "$2"
    ;;
  edit)
    if [ -z "$2" ]; then
      echo -e "${RED}Error: Please specify a profile name${NC}"
      echo "Usage: $0 edit <profile-name>"
      exit 1
    fi
    edit_profile "$2"
    ;;
  use|switch)
    if [ -z "$2" ]; then
      echo -e "${RED}Error: Please specify a profile name${NC}"
      echo "Usage: $0 use <profile-name>"
      exit 1
    fi
    switch_profile "$2"
    ;;
  delete|remove)
    if [ -z "$2" ]; then
      echo -e "${RED}Error: Please specify a profile name${NC}"
      echo "Usage: $0 delete <profile-name>"
      exit 1
    fi
    delete_profile "$2"
    ;;
  current|show)
    show_current
    ;;
  *)
    echo -e "${BLUE}Git Profile Manager${NC}"
    echo "Usage: $0 [command] [profile-name]"
    echo ""
    echo "Commands:"
    echo "  list                   - List all available profiles"
    echo "  add <profile-name>     - Add a new profile"
    echo "  edit <profile-name>    - Edit an existing profile"
    echo "  use|switch <profile>   - Switch to a profile"
    echo "  delete|remove <profile> - Delete a profile"
    echo "  current|show           - Show current Git configuration"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 add work"
    echo "  $0 switch personal"
    echo "  $0 delete old-profile"
    echo "  $0 current"
    exit 1
    ;;
esac
