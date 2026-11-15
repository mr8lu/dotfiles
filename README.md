# 🎨 Bauhaus Terminal Dotfiles

My personal dotfiles repository configured with an earthy, muted, Bauhaus-inspired aesthetic. This repository manages configurations for my development environment on macOS.

## 📁 Repository Structure

```text
~/.dotfiles/
├── git/
│   ├── .gitconfig            # Global Git configurations
│   └── .gitignore_global     # Global Git ignores
├── tmux/
│   └── .tmux.conf            # Tmux window and pane settings
├── vim/
│   └── .vimrc                # Vim editing environment
├── wezterm/
│   ├── .config/
│   │   └── cheatsheet.sh     # Interactive Tmux/Wezterm cheatsheet
│   └── .wezterm.lua          # Core WezTerm configuration and keybindings
└── zsh/
    ├── .zprofile             # Zsh profile settings
    └── .zshrc                # Zsh interactive shell configurations
```

## ✨ Highlights

*   **WezTerm:** Configured with an Earthy Bauhaus Color Palette, native macOS blur, and explicit keyboard overrides (e.g., `Command + Left/Right` for line navigation, `Command + Shift + R` for reloading).
*   **Cheatsheet:** A custom terminal cheatsheet mapped to `Control + Shift + C` in WezTerm, featuring fully spelled-out key labels and ANSI C color codes.
*   **Symlink Driven:** All dotfiles are symlinked to their native locations, ensuring any edits immediately apply to the environment while being tracked by Git.

## 🚀 Installation (New Machine Setup)

To replicate this environment on a new macOS machine:

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
    ```

2.  **Create Symbolic Links:**
    Link the files from the repository to your home directory:
    ```bash
    ln -sf ~/.dotfiles/zsh/.zshrc ~/.zshrc
    ln -sf ~/.dotfiles/zsh/.zprofile ~/.zprofile
    
    ln -sf ~/.dotfiles/wezterm/.wezterm.lua ~/.wezterm.lua
    mkdir -p ~/.config
    ln -sf ~/.dotfiles/wezterm/.config/cheatsheet.sh ~/.config/cheatsheet.sh
    
    ln -sf ~/.dotfiles/tmux/.tmux.conf ~/.tmux.conf
    ln -sf ~/.dotfiles/vim/.vimrc ~/.vimrc
    
    ln -sf ~/.dotfiles/git/.gitconfig ~/.gitconfig
    ln -sf ~/.dotfiles/git/.gitignore_global ~/.gitignore_global
    ```

3.  **Permissions:**
    Ensure scripts are executable:
    ```bash
    chmod +x ~/.config/cheatsheet.sh
    ```

## 📝 Workflow
Since the files in `~/` are symlinked to `~/.dotfiles/`, you can edit your config files normally (e.g., `vim ~/.zshrc`). The changes will automatically be reflected in the `~/.dotfiles` directory, ready to be committed and pushed.

## 🖥️ Bastion Server Setup (Ubuntu 24.04)

The `bastion/` directory captures the 24/7 Gemini agent-harness and automated maintenance configuration for an Ubuntu 24.04 bastion server without modifying the macOS setup:

```text
bastion/
├── .config/systemd/user/
│   └── gemini-harness.service                 # User service maintaining the "harness" tmux session
├── bin/
│   ├── nez-registry-cleanup.sh                # DOCR tag pruning & garbage collection script
│   └── tmux-harness-start.sh                  # Restores resurrect state & missing windows on boot
├── crontab.txt                                # 15-min tmux-resurrect save & daily registry cleanup
├── etc/
│   ├── apt/apt.conf.d/
│   │   └── 52unattended-upgrades-local        # Disables immediate auto-reboot; removes unused kernels
│   └── systemd/system/
│       ├── apt-daily.timer.d/override.conf    # Schedules apt-daily at 02:30 America/New_York
│       ├── apt-daily-upgrade.timer.d/override.conf # Schedules upgrades at 03:00 America/New_York
│       ├── reboot-if-needed.service           # Runs safe idle-aware reboot check
│       └── reboot-if-needed.timer             # Triggers at 03:30 America/New_York
├── install.sh                                 # Idempotent installer (uses $USER / $HOME)
├── tmux/
│   └── .tmux.conf                             # Bastion-specific tmux configuration
└── usr/local/sbin/
    └── reboot-if-needed.sh                    # Waits for Gemini panes to be idle (until 06:30 ET), snapshots, then reboots
```

### Reproducing on a Fresh Ubuntu Server

```bash
./bastion/install.sh
```

### Tmux Configuration Differences (`tmux/.tmux.conf` vs `bastion/tmux/.tmux.conf`)

*   **macOS (`tmux/.tmux.conf`):** Tailored for local desktop usage with WezTerm. Uses the Earthy Bauhaus theme (`#1E1B18` / `#C05C46`), macOS `pbcopy` mouse clipboard bindings, CSI-u extended keys (`extkeys`), hyperlinks, and a live git-status bar script (`tmux-git-status.sh`).
*   **Bastion (`bastion/tmux/.tmux.conf`):** Tailored for headless 24/7 agent persistence on Linux. Uses a slate/blue `GEMINI-BASTION` status bar (`#1e293b` / `#2563eb`) with UTC clock, 100,000-line scrollback history, `detach-on-destroy off`, 1-based window/pane indexing, and loads `tmux-resurrect` + `tmux-continuum` (saving every 15 minutes, capturing pane contents, and restoring `gemini` processes with `gemini --resume latest --approval-mode=yolo --no-sandbox -m gemini-4-argon`).

