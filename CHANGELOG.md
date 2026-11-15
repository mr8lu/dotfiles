# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- **Bastion**: Added reproducible Ubuntu 24.04 Gemini agent-harness setup under `bastion/`, including `bastion/tmux/.tmux.conf` (`tmux-resurrect` and `tmux-continuum`), `tmux-harness-start.sh`, `gemini-harness.service` user unit, idle-aware nightly `reboot-if-needed` service/timer and `unattended-upgrades` overrides, `nez-registry-cleanup.sh` and `crontab.txt`, and an idempotent `bastion/install.sh` installer.
- **Zsh**: Added `gcli` and `gcli-safe` aliases for Gemini CLI in `.zshrc`.
- **Consolidation**: Added `starship.toml`, `~/.ssh/config`, global `~/.gitignore` exclusions, and local scripts (`notify-teams.sh`, `kill_netskope.sh`) into the repository. Updated `bootstrap.sh` to manage these new symlinks.
- **Automation**: Added `Brewfile` for dependency tracking, `bootstrap.sh` for automated symlinking, and `macos/defaults.sh` for declarative macOS system preferences.
- **Neovim**: Added modern IDE configuration using `lazy.nvim`, `nvim-lspconfig`, `nvim-cmp`, `telescope.nvim`, and `nvim-treesitter`.
- **Git**: Added GitHub credential helpers using `gh auth git-credential` to `.gitconfig`.
- **Tmux**: Configured keybinds in `.tmux.conf` to open new windows and split panes in the current working directory (`pane_current_path`).
