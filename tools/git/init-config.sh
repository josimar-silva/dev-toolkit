#!/bin/bash

# Setup Git on new machines

echo "🛠️  Starting interactive Git configuration..."

read -p "👤 Name: " GIT_NAME
read -p "📧 Email: " GIT_EMAIL
read -p "🔐 GPG Signing Key (leave blank to skip): " GIT_SIGNINGKEY
read -p "🗂️  Credential store path [default: ~/.gitcred]: " GIT_CRED_STORE

# Set default if empty
GIT_CRED_STORE=${GIT_CRED_STORE:-"$HOME/.gitcred"}

# Output file
GITCONFIG_PATH="$HOME/.gitconfig"

echo "⚙️  Writing configuration to $GITCONFIG_PATH..."

cat > "$GITCONFIG_PATH" <<EOF
[credential]
	helper = store --file $GIT_CRED_STORE
[user]
	email = $GIT_EMAIL
	name = $GIT_NAME
EOF

# Only add signingkey if provided
if [ -n "$GIT_SIGNINGKEY" ]; then
  echo "	signingkey = $GIT_SIGNINGKEY" >> "$GITCONFIG_PATH"
fi

cat >> "$GITCONFIG_PATH" <<EOF
[core]
	editor = vim
	longpaths = true
[color]
	diff = auto
	status = auto
[alias]
	afs = !git add \$1 && git status
	aafs = !git add . && git status
	lc = log -2
	pls = !git pull && git status
	pss = !git push -u origin HEAD && git status
	cs = !git commit -v && git status
	rhh = !git reset --hard HEAD
	st = !git status
	mr = !sh -c 'git fetch \$1 merge-requests/\$2/head:mr-\$1-\$2 && git checkout mr-\$1-\$2' -
	rbm = !git checkout master && git pull && git checkout - && git rebase -i master
	undo = reset --soft HEAD^
	stash-please = !git add . && git stash save * && git status
	unstash = !git stash pop && git reset && git status
[commit]
	gpgsign = true
EOF

# Initialize credential store file
if [ ! -f "$GIT_CRED_STORE" ]; then
  touch "$GIT_CRED_STORE"
  echo "✅ Initialized credential store at $GIT_CRED_STORE"
else
  echo "ℹ️  Credential store already exists at $GIT_CRED_STORE"
fi

echo "🎉 Git configuration complete!"
