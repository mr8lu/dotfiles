#!/usr/bin/env bash

# Get the directory where the script is located
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Setting up symlinks..."

# Symlink function
link_file() {
    local source_file=$1
    local target_file=$2

    if [ -L "$target_file" ]; then
        echo "Symlink already exists: $target_file"
    elif [ -e "$target_file" ]; then
        echo "File already exists, backing up: $target_file -> ${target_file}.backup"
        mv "$target_file" "${target_file}.backup"
        ln -s "$source_file" "$target_file"
        echo "Created symlink: $target_file"
    else
        ln -s "$source_file" "$target_file"
        echo "Created symlink: $target_file"
    fi
}

# Ensure .config exists
mkdir -p "$HOME/.config"

# Create symlinks for files
link_file "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"
link_file "$DOTFILES_DIR/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"
link_file "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"

# Create symlinks for directories
if [ -L "$HOME/.config/nvim" ]; then
    echo "Symlink already exists: $HOME/.config/nvim"
elif [ -d "$HOME/.config/nvim" ]; then
    echo "Directory already exists, backing up: $HOME/.config/nvim -> $HOME/.config/nvim.backup"
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup"
    ln -s "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    echo "Created symlink: $HOME/.config/nvim"
else
    ln -s "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    echo "Created symlink: $HOME/.config/nvim"
fi

echo "All symlinks have been set up successfully!"
