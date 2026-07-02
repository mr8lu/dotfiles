  [ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

export PATH=/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home/bin:$PATH

alias python="python3"
alias vim="/opt/homebrew/Cellar/vim/9.1.1450/bin/vim"
alias /help="bash ~/.config/cheatsheet.sh | less -R"
alias /cheatsheet="bash ~/.config/cheatsheet.sh | less -R"

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


