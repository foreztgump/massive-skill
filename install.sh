#!/usr/bin/env bash
# install.sh — Install massive-skill for various AI agent platforms
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_NAME="massive"

# Detect platform
detect_platform() {
  if [[ -d "${HOME}/.claude" ]]; then
    echo "claude-code"
  elif [[ -d "${HOME}/.cursor" ]]; then
    echo "cursor"
  elif [[ -d "${HOME}/.codex" ]]; then
    echo "codex"
  else
    echo "generic"
  fi
}

# Install for Claude Code
install_claude_code() {
  local target="${HOME}/.claude/skills/${SKILL_NAME}"
  mkdir -p "$(dirname "$target")"
  ln -sfn "$REPO_DIR" "$target"
  echo "Installed: Claude Code skill at ${target}"
  echo "  Skill file: ${target}/SKILL.md"
}

# Install for Cursor
install_cursor() {
  local target="${HOME}/.cursor/skills/${SKILL_NAME}"
  mkdir -p "$(dirname "$target")"
  ln -sfn "$REPO_DIR" "$target"
  echo "Installed: Cursor skill at ${target}"
}

# Install for Codex
install_codex() {
  local target="${HOME}/.codex/skills/${SKILL_NAME}"
  mkdir -p "$(dirname "$target")"
  ln -sfn "$REPO_DIR" "$target"
  echo "Installed: Codex skill at ${target}"
}

# Generic install (symlink scripts to PATH)
install_generic() {
  local target="${HOME}/.local/bin/massive-skill"
  mkdir -p "$target"
  for script in "$REPO_DIR"/scripts/*.sh; do
    ln -sfn "$script" "$target/$(basename "$script")"
  done
  chmod +x "$target"/*.sh
  echo "Installed: scripts symlinked to ${target}/"
  echo "  Add to PATH if needed: export PATH=\"${target}:\$PATH\""
}

# Check prerequisites
check_prereqs() {
  local missing=()
  command -v curl >/dev/null 2>&1 || missing+=("curl")
  command -v jq >/dev/null 2>&1 || missing+=("jq")

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing prerequisites: ${missing[*]}"
    echo "Install with: sudo apt install ${missing[*]}  (or brew install ${missing[*]})"
    exit 1
  fi

  if [[ -z "${MASSIVE_API_KEY:-}" ]]; then
    echo "Warning: MASSIVE_API_KEY is not set."
    echo "  Get your API key at https://massive.com/dashboard"
    echo "  Then: export MASSIVE_API_KEY=your_key_here"
  fi
}

main() {
  echo "Installing massive-skill..."
  check_prereqs

  local platform="${1:-$(detect_platform)}"

  case "$platform" in
    claude-code|claude) install_claude_code ;;
    cursor)             install_cursor ;;
    codex)              install_codex ;;
    generic|*)          install_generic ;;
  esac

  echo ""
  echo "Done. Make sure MASSIVE_API_KEY is set in your environment."
}

main "$@"
