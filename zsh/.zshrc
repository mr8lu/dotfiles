  [ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

export PATH=/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home/bin:$PATH
export PATH=$HOME/go/bin:$PATH

alias python="python3"
alias vi="nvim"
alias vim="nvim"
alias ll="ls -lah"
export EDITOR="nvim"
export VISUAL="nvim"
alias /help="bash ~/.config/cheatsheet.sh | less -R"
alias /cheatsheet="bash ~/.config/cheatsheet.sh | less -R"

# Gemini CLI helper functions and aliases
_get_gcli_current_version() {
    local pkg_json="/opt/homebrew/lib/node_modules/@google/gemini-cli/package.json"
    if [ -f "$pkg_json" ]; then
        grep '"version":' "$pkg_json" 2>/dev/null | cut -d'"' -f4
    else
        gemini --version 2>/dev/null
    fi
}

_check_gcli_update() {
    local cache_file="$HOME/.gemini/tmp/gcli_update_status"
    local now=$(date +%s)
    local last_check=0
    
    if [ -f "$HOME/.gemini/tmp/gcli_last_update_check" ]; then
        last_check=$(cat "$HOME/.gemini/tmp/gcli_last_update_check" 2>/dev/null || echo 0)
    fi

    # 86400 seconds = 24 hours. Check once a day.
    if [ $((now - last_check)) -gt 86400 ]; then
        mkdir -p "$HOME/.gemini/tmp"
        echo "$now" > "$HOME/.gemini/tmp/gcli_last_update_check"
        (
            local latest current
            latest=$(npm show @google/gemini-cli version 2>/dev/null)
            current=$(_get_gcli_current_version)
            
            if [ -n "$latest" ] && [ -n "$current" ]; then
                echo "$current $latest" > "$cache_file"
            fi
        ) >/dev/null 2>&1 & disown
    fi
}

_show_gcli_update_warning() {
    local cache_file="$HOME/.gemini/tmp/gcli_update_status"
    if [ -s "$cache_file" ]; then
        local cached_current cached_latest
        read cached_current cached_latest < "$cache_file"
        
        if [ -n "$cached_latest" ] && [ -n "$cached_current" ] && [ "$cached_latest" != "$cached_current" ]; then
            # Double-check actual current version before showing stale warning
            local actual_current
            actual_current=$(_get_gcli_current_version)
            
            if [ "$actual_current" = "$cached_latest" ]; then
                # User has updated! Cache actual current as latest to stop warning
                echo "$actual_current $actual_current" > "$cache_file"
            else
                echo -e "\033[1;33m⚠️  A new version of gemini-cli is available: \033[1;32m$cached_latest\033[0m (current: $actual_current)" >&2
                echo -e "\033[1;33m👉 Run \033[1;36mnpm install -g @google/gemini-cli\033[1;33m to update.\033[0m\n" >&2
            fi
        fi
    fi
}

gcli() {
    _show_gcli_update_warning
    _check_gcli_update
    node "$HOME/.gemini/bin/patch-yolo.js" 2>/dev/null
    gemini --approval-mode=yolo --no-sandbox "$@"
}

gcli-safe() {
    _show_gcli_update_warning
    _check_gcli_update
    node "$HOME/.gemini/bin/patch-yolo.js" 2>/dev/null
    gemini --approval-mode=yolo "$@"
}

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

# pnpm
export PNPM_HOME="/Users/danipan/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# Force Emacs keybindings on the command line, even with EDITOR=nvim
bindkey -e

# OpenCode & Gemini CLI Vertex AI configuration
export GOOGLE_CLOUD_PROJECT="us-gcp-ame-con-e5556-npd-1"
export GOOGLE_PROJECT_ID="us-gcp-ame-con-e5556-npd-1"
export GOOGLE_LOCATION="us-central1"
export VERTEX_LOCATION="us-central1"
export USE_VERTEX_AI=true

# kimi-code
export PATH="/Users/danipan/.kimi-code/bin:$PATH"

ulimit -n 4096

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# GEMINI_BASTION_ENV
export PATH="$HOME/.local/bin:$PATH"
if [ -f "$HOME/.gemini/.env" ]; then
  set -a
  . "$HOME/.gemini/.env"
  set +a
fi
alias h='tmux new-session -A -s harness'
