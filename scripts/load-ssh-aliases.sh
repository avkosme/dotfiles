#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────
# 🔐 SOPS SSH Aliases Loader
# Usage: ./scripts/load-ssh-aliases.sh [--clean]
# ──────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
ENCRYPTED_FILE="$DOTFILES_ROOT/stow/ssh/.ssh_aliases.local.age"
DECRYPTED_DIR="$HOME/.config/sops/decrypted"
DECRYPTED_FILE="$DECRYPTED_DIR/ssh_aliases.local"
SYMLINK_TARGET="$HOME/.ssh_aliases.local"

# Export key for SOPS
export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"

# Parse flags
CLEAN=false
for arg in "$@"; do
  case $arg in
    --clean) CLEAN=true ;;
    -h|--help)
      echo "Usage: $0 [--clean]"
      echo "  Decrypts .ssh_aliases.local.age and symlinks to ~/.ssh_aliases.local"
      echo "  --clean  Removes decrypted file and symlink"
      exit 0
      ;;
  esac
done

# Cleanup mode
if [[ "$CLEAN" == true ]]; then
  echo "🧹 Cleaning up decrypted secrets..."
  rm -f "$DECRYPTED_FILE" "$SYMLINK_TARGET"
  echo "✅ Cleaned."
  exit 0
fi

# ──────────────────────────────────────────────────────────────
# Pre-flight checks
# ──────────────────────────────────────────────────────────────
if [[ ! -f "$AGE_KEY_FILE" ]]; then
  echo "❌ Age private key not found: $AGE_KEY_FILE"
  echo "💡 Generate one: age-keygen -o $AGE_KEY_FILE"
  exit 1
fi

if [[ ! -f "$ENCRYPTED_FILE" ]]; then
  echo "❌ Encrypted file not found: $ENCRYPTED_FILE"
  exit 1
fi

# ──────────────────────────────────────────────────────────────
# Decrypt & Secure
# ──────────────────────────────────────────────────────────────
mkdir -p "$DECRYPTED_DIR"
chmod 700 "$DECRYPTED_DIR"

echo "🔓 Decrypting SSH aliases..."
if ! sops -d "$ENCRYPTED_FILE" > "$DECRYPTED_FILE" 2>/tmp/sops_err.log; then
  echo "❌ Decryption failed:"
  cat /tmp/sops_err.log >&2
  rm -f /tmp/sops_err.log
  exit 1
fi
rm -f /tmp/sops_err.log

# Lock down permissions
chmod 600 "$DECRYPTED_FILE"

# ──────────────────────────────────────────────────────────────
# Symlink Management (Idempotent)
# ──────────────────────────────────────────────────────────────
if [[ -L "$SYMLINK_TARGET" ]]; then
  echo "🔄 Updating existing symlink..."
  unlink "$SYMLINK_TARGET"
elif [[ -e "$SYMLINK_TARGET" ]]; then
  echo "⚠️  Backing up existing file to .bak"
  mv "$SYMLINK_TARGET" "$SYMLINK_TARGET.bak.$(date +%s)"
fi

ln -s "$DECRYPTED_FILE" "$SYMLINK_TARGET"

echo "─────────────────────────────────────"
echo "✅ Ready! Aliases symlinked to $SYMLINK_TARGET"
echo "💡 Load them now: source $SYMLINK_TARGET"
echo "🧹 Clean up later: $0 --clean"