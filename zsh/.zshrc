  [ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

export PATH=/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home/bin:$PATH

alias python="python3"
alias vi="nvim"
alias vim="nvim"
export EDITOR="nvim"
export VISUAL="nvim"
alias /help="bash ~/.config/cheatsheet.sh | less -R"
alias /cheatsheet="bash ~/.config/cheatsheet.sh | less -R"

# Gemini CLI aliases
alias gcli="gemini -y --no-sandbox"
alias gcli-safe="gemini -y"

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
# Load local configuration (API keys, secrets, etc.) if it exists
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi

# Initialize Starship prompt
eval "$(starship init zsh)"

# Allow Shift+Enter to insert a new line in Zsh without executing
function insert-newline() {
    LBUFFER+=$'\n'
}
zle -N insert-newline
bindkey '^[[13;2u' insert-newline

# Force terminal hyperlink support (OSC 8) in CLI tools (like gemini-cli) inside tmux
export FORCE_HYPERLINK=1

# Terminal Markdown & Mermaid Rendering Helpers
alias markdown="glow"
alias markdown-image="mdcat"
alias markdown-mermaid="glowm"

# Render and display standalone .mmd or .mermaid files directly in WezTerm
function mrender() {
    if [ -z "$1" ]; then
        echo "Usage: mrender <diagram.mmd>"
        return 1
    fi
    local tmp=$(mktemp).png
    # Use mermaid-cli to render to a PNG and display it inside WezTerm
    if mmdc -i "$1" -o "$tmp" -b transparent -t dark &>/dev/null; then
        wezterm imgcat "$tmp"
    else
        echo "Error: Failed to compile Mermaid diagram. Ensure @mermaid-js/mermaid-cli is installed."
    fi
    rm -f "$tmp"
}


# Added by Antigravity CLI installer
export PATH="/Users/danipan/.local/bin:$PATH"
