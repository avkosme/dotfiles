#!/usr/bin/env bash
# update-ai-coding-agent.sh (v3)
# Updates AI coding agents: opencode (curl installer), qwen, and others via brew/pip/npm/go.
set -uo pipefail

AGENTS=("opencode" "qwen")
DRY_RUN=false
VERBOSE=false

# ─────────────────────────────────────────────────────────────
# CLI Parsing
# ─────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    --add)     AGENTS+=("$2"); shift 2 ;;
    --help)
      cat << EOF
Usage: $0 [OPTIONS]

Options:
  --dry-run          Show what would be done, no changes made
  --verbose          Show detailed output
  --add <name>       Add an extra agent to update list
  --help             Show this help message

Examples:
  $0                         # Update default agents
  $0 --dry-run              # Preview actions
  $0 --add aider --add continue  # Add extra agents
EOF
      exit 0
      ;;
    *) echo "⚠️  Unknown flag: $1"; shift ;;
  esac
done

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
log() { echo -e "$1"; }
debug() { [[ "$VERBOSE" = true ]] && echo -e "  🔍 $1" || true; }

# ─────────────────────────────────────────────────────────────
# Agent Updaters
# ─────────────────────────────────────────────────────────────
update_opencode() {
  log "\n📦 Checking 'opencode'..."

  # Check if already installed
  if ! command -v opencode &>/dev/null; then
    log "  ⚠️  opencode not found in PATH. Installing via official installer..."
  else
    debug "Found: $(which opencode)"
    log "  ⬆️  Updating opencode via official installer..."
  fi

  local installer_url="https://opencode.ai/install"
  
  if [ "$DRY_RUN" = true ]; then
    log "  🧪 Would run: curl -fsSL $installer_url | bash"
    return 0
  fi

  # Run installer non-interactively
  if curl -fsSL "$installer_url" | bash; then
    log "  ✅ opencode updated successfully."
    # Refresh shell hash table in case binary location changed
    hash -r 2>/dev/null || true
    return 0
  else
    log "  ❌ Failed to update opencode."
    return 1
  fi
}

update_qwen() {
  log "\n📦 Checking 'qwen'..."

  # Try multiple possible package names
  local possible_names=("qwen" "qwen-cli" "qwen-agent" "dashscope")
  
  # 1️⃣ Homebrew
  if command -v brew &>/dev/null; then
    for name in "${possible_names[@]}"; do
      if brew list "$name" &>/dev/null 2>&1 || brew list --cask "$name" &>/dev/null 2>&1; then
        log "  ⬆️  Found in Homebrew as '$name'."
        [ "$DRY_RUN" = true ] && log "  🧪 Would run: brew upgrade $name" || brew upgrade "$name"
        return 0
      fi
    done
  fi

  # 2️⃣ pip
  if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
    local pip_cmd="pip3"; command -v pip3 &>/dev/null || pip_cmd="pip"
    for name in "${possible_names[@]}"; do
      if $pip_cmd show "$name" &>/dev/null 2>&1; then
        log "  ⬆️  Found via pip as '$name'."
        [ "$DRY_RUN" = true ] && log "  🧪 Would run: $pip_cmd install --upgrade $name" || $pip_cmd install --upgrade "$name"
        return 0
      fi
    done
  fi

  # 3️⃣ npm global
  if command -v npm &>/dev/null; then
    for name in "${possible_names[@]}"; do
      if npm ls -g --depth=0 2>/dev/null | grep -qw "$name"; then
        log "  ⬆️  Found via npm (global) as '$name'."
        [ "$DRY_RUN" = true ] && log "  🧪 Would run: npm update -g $name" || npm update -g "$name"
        return 0
      fi
    done
  fi

  log "  ❌ qwen not found in supported package managers."
  log "  💡 Try: pip install --upgrade qwen-agent  # or check https://github.com/QwenLM/Qwen-Agent"
  return 1
}

update_generic_agent() {
  local agent="$1"
  log "\n📦 Checking '${agent}'..."

  # Homebrew
  if command -v brew &>/dev/null; then
    if brew list "$agent" &>/dev/null 2>&1 || brew list --cask "$agent" &>/dev/null 2>&1; then
      log "  ⬆️  Found in Homebrew."
      [ "$DRY_RUN" = true ] && log "  🧪 Would run: brew upgrade $agent" || brew upgrade "$agent"
      return 0
    fi
  fi

  # Go
  if command -v go &>/dev/null; then
    local go_bin="${GOBIN:-$(go env GOPATH)/bin}/$agent"
    if [[ -f "$go_bin" ]] || { command -v "$agent" &>/dev/null && [[ "$(command -v "$agent")" == *"go/bin"* ]]; }; then
      log "  ⬆️  Found via Go."
      [ "$DRY_RUN" = true ] && log "  🧪 Would run: go install github.com/$agent/$agent@latest" || go install "github.com/$agent/$agent@latest"
      return 0
    fi
  fi

  # pip
  if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
    local pip_cmd="pip3"; command -v pip3 &>/dev/null || pip_cmd="pip"
    if $pip_cmd show "$agent" &>/dev/null 2>&1; then
      log "  ⬆️  Found via pip."
      [ "$DRY_RUN" = true ] && log "  🧪 Would run: $pip_cmd install --upgrade $agent" || $pip_cmd install --upgrade "$agent"
      return 0
    fi
  fi

  # npm
  if command -v npm &>/dev/null; then
    if npm ls -g --depth=0 2>/dev/null | grep -qw "$agent"; then
      log "  ⬆️  Found via npm (global)."
      [ "$DRY_RUN" = true ] && log "  🧪 Would run: npm update -g $agent" || npm update -g "$agent"
      return 0
    fi
  fi

  log "  ❌ '$agent' not found in standard package managers."
  return 1
}

# ─────────────────────────────────────────────────────────────
# Main Dispatcher
# ─────────────────────────────────────────────────────────────
update_agent() {
  local agent="$1"
  case "$agent" in
    opencode) update_opencode ;;
    qwen|qwen-cli|qwen-agent) update_qwen ;;
    *) update_generic_agent "$agent" ;;
  esac
}

# ─────────────────────────────────────────────────────────────
# Execution
# ─────────────────────────────────────────────────────────────
log "🔄 Starting AI Coding Agent Update..."
log "   Agents: ${AGENTS[*]}"
[ "$DRY_RUN" = true ] && log "🧪 DRY RUN MODE — no changes will be made."
[ "$VERBOSE" = true ] && log "🔍 VERBOSE output enabled."

exit_code=0
for agent in "${AGENTS[@]}"; do
  update_agent "$agent" || exit_code=1
done

if [ $exit_code -eq 0 ]; then
  log "\n✅ All updates completed successfully."
else
  log "\n⚠️  Some updates failed. Check output above."
fi

exit $exit_code