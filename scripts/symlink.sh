#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────
# Usage: ./scripts/symlink.sh [-d|--dry-run] [-f|--force] <package>
# ──────────────────────────────────────────────────────────────

PACKAGE=""
DRY_RUN=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--dry-run) DRY_RUN=true; shift ;;
    -f|--force)   FORCE=true; shift ;;
    *)            PACKAGE="$1"; shift ;;
  esac
done

if [[ -z "$PACKAGE" ]]; then
  echo "❌ Usage: $0 [-d|--dry-run] [-f|--force] <package-name>"
  exit 1
fi

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"
STOW_DIR="$DOTFILES_ROOT/stow"
PACKAGE_DIR="$STOW_DIR/$PACKAGE"
HOME_DIR="$HOME"

if [[ ! -d "$PACKAGE_DIR" ]]; then
  echo "❌ Package '$PACKAGE' not found in $STOW_DIR"
  exit 1
fi

echo "📦 Symlinking package: $PACKAGE"
[[ "$DRY_RUN" == true ]] && echo "🔍 Mode: DRY RUN"
[[ "$FORCE" == true ]] && echo "⚠️  Mode: FORCE"
echo "─────────────────────────────────────"

cd "$PACKAGE_DIR"

# Process all files/dirs deterministically
find . -mindepth 1 | sort | while IFS= read -r item; do
  rel="${item#./}"
  target="$HOME_DIR/$rel"
  source="$PACKAGE_DIR/$rel"

  # Skip if already correctly linked
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    echo "✅ $rel"
    continue
  fi

  # Handle existing targets
  if [[ -e "$target" ]]; then
    if [[ "$FORCE" == true ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        echo "🔄 Would overwrite: $rel"
        continue
      fi
      rm -rf "$target"
      echo "🗑️  Removed: $rel"
    else
      echo "⏭️  Skip (exists): $rel"
      continue
    fi
  fi

  # Dry-run exit
  if [[ "$DRY_RUN" == true ]]; then
    echo "🔗 Would link: $rel"
    continue
  fi

  # Create symlink
  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
  echo "🔗 $rel"
done

echo "─────────────────────────────────────"
echo "✅ Done."