# Settings Sync — Omarchy backup & restore plugin

Backs up your Omarchy setup to a git repo (GitHub) and restores it on a fresh
install: third-party shell plugins (with git URLs + commits + enabled state),
bar layout (`shell.json`), theme, font, Hyprland config, menu, hooks,
terminals, starship/git/btop/lazygit, custom themes, and package lists.

## Layout

```
manifest.json          Omarchy shell plugin manifest (id: settings-sync)
Widget.qml             bar widget + popup panel (calls bin/settings-sync-ctl)
Model.js               status parsing / labels (QML + node-testable)
bin/settings-sync-ctl  the real backup/restore CLI (also used by the widget)
install.sh             links CLI to ~/.local/bin + installs/enables the plugin
```

## First-time setup (on your main machine)

```bash
cd ~/Projects/omarchy-settings-sync
./install.sh
settings-sync-ctl set-repo git@github.com:you/omarchy-backup.git
settings-sync-ctl backup --push
```

Or in one step:

```bash
settings-sync-ctl init git@github.com:you/omarchy-backup.git
```

The bar widget shows backup status; its panel has **Back up now** /
**Restore** buttons and the repo field. Everything the widget does is just
calling `settings-sync-ctl`, so terminal and UI never drift.

## Fresh install recovery

```bash
# 1. Install this plugin (pick one):
omarchy plugin add https://github.com/isaactopo/omarchy-settings-sync.git --enable --yes
# ...or local/dev:
./install.sh

# 2. Restore everything from your backup repo:
settings-sync-ctl restore --repo git@github.com:you/omarchy-backup.git --yes

# 3. Optional: also reinstall the packages you had:
settings-sync-ctl restore --repo git@github.com:you/omarchy-backup.git --yes --with-packages
```

Restore snapshots whatever it is about to overwrite into
`~/.config/omarchy/settings-sync/backups/<timestamp>/`, reinstalls missing
third-party plugins via `omarchy plugin add <url> --enable`, re-applies
enabled/disabled states, pins plugins to the backed-up commit when possible,
sets theme/font, then rescans plugins and reloads the shell + Hyprland.

Useful flags:

```bash
settings-sync-ctl status              # human-readable
settings-sync-ctl status --json       # what the widget reads
settings-sync-ctl backup --push -m "before experimenting"
settings-sync-ctl restore --skip-plugins   # configs only
settings-sync-ctl restore --skip-config    # plugins only
settings-sync-ctl list-plugins
```

## What gets backed up

| File in backup repo | Source |
|---|---|
| `backup.json`, `theme.txt`, `font.txt` | `omarchy theme/font current`, version |
| `plugins.json` | third-party plugins: id, git URL, commit, enabled |
| `shell.json` | `~/.config/omarchy/shell.json` |
| `hypr/` | `~/.config/hypr/*.lua`, `*.conf` |
| `omarchy/menu.jsonc` | `extensions/omarchy-menu.jsonc` |
| `omarchy/workspace-layout.json`, `shell.toml`, `hooks/` | `~/.config/omarchy/` (skips `*.sample`) |
| `terminals/` | alacritty, kitty, ghostty, foot |
| `starship.toml`, `gitconfig`, `btop/`, `lazygit/` | `~/.config/` |
| `themes-custom/` | `~/.config/omarchy/themes/*` |
| `packages.explicit`, `packages.aur` | `pacman -Qqe` / `-Qqm` (reference; installed only with `--with-packages`) |

## Notes

- Backup commits locally; only `--push` uploads (the widget's button pushes).
- Plugin restores never overwrite an already-installed plugin directory —
  delete `~/.config/omarchy/plugins/<id>` first if you want a clean re-clone.
- Package install is opt-in (`--with-packages`) and only fills in missing
  packages via `omarchy pkg add`.
- Validate before publishing: `omarchy plugin validate ~/Projects/omarchy-settings-sync`
