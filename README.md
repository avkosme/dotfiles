# dotfiles

> 🎯 Personal development environment configuration — managed with a lightweight, Stow-inspired symlink system.

```
~/.dotfiles/
├── scripts/
│   └── symlink.sh    # Custom symlink manager (no external deps)
├── stow/
│   ├── ghostty/      # Terminal emulator config
│   ├── git/          # Git global config & ignores
│   ├── zsh/          # Shell configuration
│   └── ...           # Add more packages as needed
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

- ✅ **Never commit secrets**: Use `.env.example`, `git-crypt`, or a secrets manager
- ✅ **Test in dry-run mode first**: `./scripts/symlink.sh -d <pkg>`
- ✅ **Backup before force**: `mv ~/.config/ghostty/config ~/.config/ghostty/config.bak`
- ✅ **Use global `.gitignore`**:  
  ```bash
  git config --global core.excludesfile ~/.dotfiles/.gitignore_global
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
```

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/add-kitty-config`
3. Follow the `stow/` structure convention
4. Test with `--dry-run` on a clean VM/container
5. Submit a PR with a description of what's added/changed

---

## 📄 License

MIT © [Andrei Kostiuchenko](https://github.com/avkosme)  
*Free to use, modify, and share — but please credit the source.*
