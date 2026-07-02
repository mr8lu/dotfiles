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
