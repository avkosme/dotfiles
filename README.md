# dotfiles

> 🎯 Personal development environment configuration — managed with a lightweight, Stow-inspired symlink system.

```
~/.dotfiles/
├── scripts/
│   ├── symlink.sh              # Custom symlink manager (no external deps)
│   └── load-ssh-aliases.sh     # SOPS decrypt + symlink helper
├── stow/
│   ├── ghostty/                # Terminal emulator config
│   ├── git/                    # Git global config & ignores
│   ├── ssh/                    # SSH configs + encrypted aliases
│   │   ├── .ssh_aliases.local.age  # 🔐 Encrypted private aliases
│   │   └── .ssh/
│   │       └── config          # Public SSH config with Include
│   ├── zsh/                    # Shell configuration
│   └── ...                     # Add more packages as needed
├── .sops.yaml                  # SOPS encryption config
├── README.md
└── .gitignore
```

---

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/avkosme/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 2. (Optional) Preview what will be linked
./scripts/symlink.sh -d ghostty

# 3. Apply configuration for a package
./scripts/symlink.sh ghostty

# 4. Verify
ls -la ~/.config/ghostty/config  # Should show a symlink → ~/.dotfiles/stow/ghostty/...
```

---

## 📦 Available Packages

| Package   | Description                          | Target Path                     |
|-----------|--------------------------------------|---------------------------------|
| `ghostty` | [Ghostty](https://ghostty.org) terminal config | `~/.config/ghostty/config`      |
| `git`     | Global Git config & ignore rules     | `~/.gitconfig`, `~/.gitignore_global` |
| `ssh`     | SSH configs + 🔐 encrypted aliases   | `~/.ssh/config`, `~/.ssh_aliases.local` |
| `zsh`     | Zsh shell config + aliases           | `~/.zshrc`, `~/.zshenv`         |
| `nvim`    | Neovim configuration                 | `~/.config/nvim/`               |
| `tmux`    | Terminal multiplexer settings        | `~/.tmux.conf`                  |

> 💡 Add new packages by creating `stow/<package-name>/.<path>/` mirroring your `$HOME` structure.

---

## ⚙️ `symlink.sh` Usage

```bash
./scripts/symlink.sh [OPTIONS] <package>

Options:
  -d, --dry-run   Show what would be linked (no changes)
  -f, --force     Overwrite existing files/dirs at target
  -h, --help      Show this help message

Examples:
  ./scripts/symlink.sh ghostty           # Normal apply
  ./scripts/symlink.sh -d git            # Preview git links
  ./scripts/symlink.sh -f -d nvim        # Force + dry-run (preview overwrites)
```

### How It Works
```
stow/ghostty/.config/ghostty/config
          ↓
~/.config/ghostty/config → ~/.dotfiles/stow/ghostty/.config/ghostty/config
```

---

## 🔐 Encrypted Secrets with SOPS + Age

Store private SSH aliases, API keys, or credentials securely in your dotfiles using **[SOPS](https://github.com/getsops/sops)** + **[age](https://age-encryption.org)**.

### 📦 Install Dependencies

```bash
# macOS (Homebrew)
brew install age sops

# Linux (Debian/Ubuntu)
sudo apt install age sops

# Linux (Arch)
sudo pacman -S age sops
```

### 🔑 Generate Your Age Key Pair (One-Time Setup)

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# Extract your public key
AGE_PUB=$(grep "public key:" ~/.config/sops/age/keys.txt | awk '{print $3}')
echo "✅ Public key: $AGE_PUB"
```

### ⚙️ Configure SOPS (Optional but Recommended)

Create `.sops.yaml` in your repo root to avoid repeating `--age` flags:

```yaml
# ~/.dotfiles/.sops.yaml
creation_rules:
  - path_regex: \.(yaml|yml|json|env|local)$
    age: <YOUR_PUBLIC_KEY_HERE>  # Replace with output from above
```

### 🔒 Encrypt Your Private Aliases

```bash
# 1. Create your plaintext aliases file (NEVER commit this)
cat > stow/ssh/.ssh_aliases.local << 'EOF'
# Private SSH aliases — DO NOT COMMIT
alias deploy-prod='ssh admin@prod.example.com -i ~/.ssh/id_prod'
alias db-tunnel='ssh -L 5432:localhost:5432 db-admin@prod-db'
EOF

# 2. Encrypt with SOPS + Age
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
sops -e stow/ssh/.ssh_aliases.local > stow/ssh/.ssh_aliases.local.age

# 3. Remove plaintext immediately
rm stow/ssh/.ssh_aliases.local

# 4. Commit ONLY the encrypted file
git add stow/ssh/.ssh_aliases.local.age .sops.yaml
git commit -m "feat(ssh): add encrypted private aliases"
```

### 🔓 Decrypt & Load Aliases

```bash
# Option A: One-time decrypt + symlink (using helper script)
./scripts/load-ssh-aliases.sh
source ~/.ssh_aliases.local

# Option B: Decrypt to memory only (more secure)
SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" \
  sops -d stow/ssh/.ssh_aliases.local.age | source /dev/stdin

# Option C: Add alias to ~/.zshrc for easy loading
echo 'alias load-ssh="SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d ~/.dotfiles/stow/ssh/.ssh_aliases.local.age | source /dev/stdin"' >> ~/.dotfiles/stow/zshrc/.zshrc
```

### 🧹 Clean Up Decrypted Secrets

```bash
# Remove decrypted file and symlink
./scripts/load-ssh-aliases.sh --clean

# Or manually
rm -f ~/.ssh_aliases.local ~/.config/sops/decrypted/ssh_aliases.local
```

---

## 🛠️ Adding a New Package

1. **Create the package directory**  
   ```bash
   mkdir -p ~/.dotfiles/stow/mytool/.config/mytool
   ```

2. **Add your config file(s)**  
   ```bash
   cp ~/.config/mytool/settings.toml ~/.dotfiles/stow/mytool/.config/mytool/
   ```

3. **Apply with the script**  
   ```bash
   ./scripts/symlink.sh mytool
   ```

4. **Commit & push**  
   ```bash
   git add stow/mytool
   git commit -m "feat: add mytool config"
   git push
   ```

---

## 🔒 Security & Best Practices

### General
- ✅ **Never commit secrets**: Use `.env.example`, `git-crypt`, or SOPS+age
- ✅ **Test in dry-run mode first**: `./scripts/symlink.sh -d <pkg>`
- ✅ **Backup before force**: `mv ~/.config/ghostty/config ~/.config/ghostty/config.bak`
- ✅ **Use global `.gitignore`**:  
  ```bash
  git config --global core.excludesfile ~/.dotfiles/.gitignore_global
  ```

### Encrypted Secrets (SOPS+Age)
| ✅ Do | ❌ Don't |
|-------|----------|
| Store `keys.txt` in a password manager or encrypted backup | Commit `keys.txt` or `AGE-SECRET-KEY-...` to git |
| Use `chmod 600` on key files | Share your private Age key |
| Decrypt to memory when possible (`source /dev/stdin`) | Leave decrypted files on disk longer than needed |
| Add `*.age` to `.gitignore` only if unencrypted | Commit plaintext `.local` files alongside `.age` |

### Recommended `.gitignore`
```gitignore
# ~/.dotfiles/.gitignore
# Decrypted secrets
.config/sops/decrypted/
.ssh_aliases.local
*.local

# Age/SOPS keys
.config/sops/age/keys.txt
*.age.bak

# OS/IDE noise
.DS_Store
Thumbs.db
*.swp
.vscode/
.idea/
```

---

## 🔄 Maintenance

```bash
# Check for broken symlinks
find ~/.dotfiles/stow -type l -exec test ! -e {} \; -print

# Update all packages (if you manage multiple machines)
git -C ~/.dotfiles pull --rebase

# Remove a package's symlinks manually
unlink ~/.config/ghostty/config  # Then optionally: rm -rf ~/.dotfiles/stow/ghostty

# Rotate Age keys (if compromised)
age-keygen -o ~/.config/sops/age/keys-new.txt
# Re-encrypt all .age files with new key
find . -name "*.age" -exec sops --rotate --update-mac {} \;
```

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/add-kitty-config`
3. Follow the `stow/` structure convention
4. Test with `--dry-run` on a clean VM/container
5. Submit a PR with a description of what's added/changed

> 🔐 For encrypted files: Document the public key used in the PR description so reviewers can verify decryption.

---

## 📄 License

MIT © [Andrei Kostiuchenko](https://github.com/avkosme)  
*Free to use, modify, and share — but please credit the source.*
