#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────
# 🚀 Dotfiles Bootstrap Script
# Usage: ./scripts/install.sh [--skip-omz] [--skip-symlink]
# ──────────────────────────────────────────────────────────────

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
SKIP_OMZ=false
SKIP_SYMLINK=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-omz) SKIP_OMZ=true; shift ;;
    --skip-symlink) SKIP_SYMLINK=true; shift ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  --skip-omz        Skip Oh My Zsh installation"
      echo "  --skip-symlink    Skip applying dotfiles symlinks"
      echo "  -h, --help        Show this help"
      exit 0
      ;;
    *) echo "❌ Unknown option: $1"; exit 1 ;;
  esac
done

# Helper functions
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[⚠]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1" >&2; }

# ──────────────────────────────────────────────────────────────
# 1. Install Oh My Zsh (via Git — more reliable than curl installer)
# ──────────────────────────────────────────────────────────────
install_oh_my_zsh() {
  if [[ "$SKIP_OMZ" == true ]]; then
    log_warn "Skipping Oh My Zsh installation (--skip-omz)"
    return 0
  fi

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log_success "Oh My Zsh already installed at ~/.oh-my-zsh"
    return 0
  fi

  log_info "Installing Oh My Zsh via git clone..."
  
  if git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" 2>&1; then
    log_success "Oh My Zsh installed successfully"
  else
    log_error "Failed to clone Oh My Zsh. Check your network/connection."
    log_info "Tip: Try manually: git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh"
    return 1
  fi
}

# ──────────────────────────────────────────────────────────────
# 2. Apply dotfiles symlinks using our custom symlink.sh
# ──────────────────────────────────────────────────────────────
apply_dotfiles() {
  if [[ "$SKIP_SYMLINK" == true ]]; then
    log_warn "Skipping symlink application (--skip-symlink)"
    return 0
  fi

  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local dotfiles_root="$(dirname "$script_dir")"
  
  log_info "Applying dotfiles symlinks..."
  
  # Symlink all packages in stow/ directory
  if [[ -d "$dotfiles_root/stow" ]]; then
    for pkg_dir in "$dotfiles_root/stow"/*/; do
      [[ -d "$pkg_dir" ]] || continue
      local pkg_name="$(basename "$pkg_dir")"
      log_info "  → Symlinking package: $pkg_name"
      "$script_dir/symlink.sh" "$pkg_name" || log_warn "Failed to symlink $pkg_name"
    done
    log_success "Dotfiles symlinks applied"
  else
    log_warn "No 'stow/' directory found — skipping symlink step"
  fi
}

# ──────────────────────────────────────────────────────────────
# 3. Install essential CLI tools (macOS/Linux)
# ──────────────────────────────────────────────────────────────
install_cli_tools() {
  log_info "Checking for essential CLI tools..."
  
  # macOS: Homebrew
  if [[ "$(uname)" == "Darwin" ]] && ! command -v brew &>/dev/null; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  
  # Install common tools via Homebrew (if available)
  if command -v brew &>/dev/null; then
    log_info "Installing common tools via Homebrew..."
    brew install --quiet \
      git \
      zsh \
      neovim \
      ripgrep \
      fd \
      fzf \
      stow \
      || log_warn "Some Homebrew packages failed to install"
  fi
  
  # Linux: apt/dnf fallback (optional)
  if command -v apt &>/dev/null && ! command -v git &>/dev/null; then
    log_info "Installing basics via apt..."
    sudo apt update && sudo apt install -y git zsh neovim curl wget
  fi
}

# ──────────────────────────────────────────────────────────────
# 4. Set Zsh as default shell (if not already)
# ──────────────────────────────────────────────────────────────
setup_default_shell() {
  local zsh_path="$(command -v zsh)"
  
  if [[ "$SHELL" != "$zsh_path" ]]; then
    log_info "Setting Zsh as default shell..."
    
    # Add zsh to allowed shells if needed (macOS)
    if [[ "$(uname)" == "Darwin" ]] && ! grep -q "$zsh_path" /etc/shells; then
      sudo sh -c "echo '$zsh_path' >> /etc/shells"
    fi
    
    # Change default shell
    chsh -s "$zsh_path"
    log_success "Zsh set as default shell. Restart terminal to apply."
  else
    log_success "Zsh is already your default shell"
  fi
}


# ──────────────────────────────────────────────────────────────
# 5. Setup scripts directory and symlinks
# ──────────────────────────────────────────────────────────────
setup_scripts_symlinks() {
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local dotfiles_root="$(dirname "$script_dir")"
  local scripts_src="$dotfiles_root/scripts"
  local scripts_dest="$HOME/.local/bin"

  log_info "Setting up scripts directory and symlinks..."

  # Create destination directory
  mkdir -p "$scripts_dest"
  if [[ $? -eq 0 ]]; then
    log_success "Created directory: $scripts_dest"
  else
    log_error "Failed to create directory: $scripts_dest"
    return 1
  fi

  # Check if source scripts directory exists
  if [[ ! -d "$scripts_src" ]]; then
    log_warn "Source scripts directory not found: $scripts_src — skipping symlink creation"
    return 0
  fi

  # Find all executable files in the source scripts directory
  local found_scripts=false
  for src_script in "$scripts_src"/*; do
    # Skip if no files match the pattern
    [[ -e "$src_script" ]] || continue

    # Only process files (not directories) that are executable
    if [[ -f "$src_script" && -x "$src_script" ]]; then
      found_scripts=true
      local script_name="$(basename "$src_script")"
      local dest_link="$scripts_dest/$script_name"

      # Remove existing symlink or file if it exists
      if [[ -e "$dest_link" ]] || [[ -L "$dest_link" ]]; then
        rm -f "$dest_link"
        log_info "Removed existing symlink/file: $dest_link"
      fi

      # Create new symlink
      ln -sf "$src_script" "$dest_link"
      if [[ $? -eq 0 ]]; then
        log_success "Symlink created: $script_name -> $dest_link"
      else
        log_error "Failed to create symlink for $script_name"
      fi
    fi
  done

  # Inform if no executable scripts were found
  if [[ "$found_scripts" == false ]]; then
    log_warn "No executable scripts found in $scripts_src — nothing to symlink"
  fi

  log_success "Scripts symlinks setup completed"
}



# ──────────────────────────────────────────────────────────────
# Main execution
# ──────────────────────────────────────────────────────────────
main() {
  echo -e "${BLUE}🚀 Starting dotfiles bootstrap...${NC}\n"
  
  install_cli_tools
  install_oh_my_zsh
  apply_dotfiles
  setup_default_shell
  setup_scripts_symlinks
  
  echo -e "\n${GREEN}✅ Bootstrap complete!${NC}"
  echo -e "💡 Next steps:"
  echo -e "   1. Restart your terminal or run: ${YELLOW}exec zsh${NC}"
  echo -e "   2. Customize: ${YELLOW}nvim ~/.dotfiles/stow/zshrc/.zshrc${NC}"
  echo -e "   3. Add machine-specific overrides: ${YELLOW}~/.zshrc.local${NC}"
}

# Run main
main "$@"