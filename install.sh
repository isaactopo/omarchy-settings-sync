#!/bin/bash
# Install the settings-sync plugin into Omarchy.
# Usage: ./install.sh [--enable] [--cli-only]
set -euo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$HOME/.config/omarchy/plugins"
BIN_DIR="$HOME/.local/bin"
ID="settings-sync"

ENABLE=true
for a in "$@"; do
  case "$a" in
    --no-enable) ENABLE=false;;
    --cli-only) CLI_ONLY=true;;
    -h|--help) echo "usage: ./install.sh [--no-enable] [--cli-only]"; exit 0;;
  esac
done

mkdir -p "$BIN_DIR"
ln -sf "$HERE/bin/settings-sync-ctl" "$BIN_DIR/settings-sync-ctl"
echo "linked CLI: $BIN_DIR/settings-sync-ctl"

if [[ "${CLI_ONLY:-false}" == "true" ]]; then
  echo "CLI only — skipping shell plugin install."
  exit 0
fi

if [[ -d "$PLUGINS_DIR/$ID" && ! -L "$PLUGINS_DIR/$ID" ]]; then
  echo "plugin $ID already installed at $PLUGINS_DIR/$ID"
  echo "update it with: omarchy plugin update $ID"
else
  rm -f "$PLUGINS_DIR/$ID"
  if command -v omarchy >/dev/null 2>&1 && git -C "$HERE" rev-parse --git-dir >/dev/null 2>&1; then
    url="$(git -C "$HERE" remote get-url origin 2>/dev/null || true)"
    if [[ -n "$url" ]]; then
      omarchy plugin add "$url" --yes || true
    fi
  fi
  if [[ ! -e "$PLUGINS_DIR/$ID" ]]; then
    # Dev / local install: symlink the working copy.
    ln -sfn "$HERE" "$PLUGINS_DIR/$ID"
    echo "symlinked $HERE -> $PLUGINS_DIR/$ID (dev install)"
    omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  fi
fi

if $ENABLE; then
  omarchy plugin enable "$ID" --section right 2>/dev/null || omarchy plugin enable "$ID" 2>/dev/null || true
  echo "enabled $ID (if the shell is running it appears in the bar)"
fi

echo "done. Next: settings-sync-ctl set-repo <github-url> && settings-sync-ctl backup --push"
