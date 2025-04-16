# dev-toolkit

A modular command-line utility to manage Git, Docker, Kubernetes, and other developer tools.

---

## 📁 Project Structure

```
dev-toolkit/
├── dev-toolkit              # Main CLI entrypoint (add this to PATH or alias)
├── tools/
│   ├── git/
│   │   ├── switch-profile.sh
│   │   ├── init-config.sh
│   │   ├── generate-gpg-key.sh
│   │   └── setup-github-ssh.sh
│   ├── docker/
│   │   └── example-script.sh
│   └── kubernetes/
│       └── example-script.sh
```

---

## 💡 Philosophy

- **Modular**: Organize scripts by tool (`git`, `docker`, `kubernetes`, etc.).
- **Portable**: Simple Bash-based CLI that runs anywhere.
- **Extendable**: Just drop new scripts into the appropriate tool folder.

---

## 🛠️ Installation

1. Clone the repo:

```bash
git clone https://your-repo-url/dev-toolkit.git ~/projects/dev-toolkit
```

2. Add to your PATH (edit `~/.bashrc` or `~/.bash_profile`):

```bash
export PATH="$HOME/projects/dev-toolkit:$PATH"
```

3. Reload your shell:

```bash
source ~/.bashrc
```

4. Optional: Add an alias:

```bash
alias dt="dev-toolkit"
```

---

## 🚀 Usage

```bash
dev-toolkit git switch-profile
dev-toolkit docker example-script
dt git setup-github-ssh
```

---

## 🤝 Contributing

- Fork the repo and create a new branch.
- Add new scripts to the right tool folder under `tools/`.
- Name your scripts like `<command>.sh` and make sure they’re executable.
- Test it by running:

```bash
dev-toolkit <tool> <command>
```

Then make a pull request!

---

## 📦 Install Script

You can install `dev-toolkit` automatically using the provided install script.

1. Download the script:

```bash
curl -LO https://github.com/josimar-silva/dev-toolkit/releases/latest/download/install-dev-toolkit.sh
```

2. Make the script executable:

```bash
chmod +x install-dev-toolkit.sh
```

3. Run the script:

```bash
./install-dev-toolkit.sh
```

This will:
- Clone the repository into `~/projects/dev-toolkit`
- Add it to your `$PATH`
- Set up the `dt` alias for quick access

After installation, restart your terminal or run:

```bash
source ~/.bashrc
```

Then try using:

```bash
dt git switch-profile
```
