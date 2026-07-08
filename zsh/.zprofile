
eval "$(/opt/homebrew/bin/brew shellenv)"

# added by Snowflake SnowSQL installer v1.2
export PATH=/Applications/SnowSQL.app/Contents/MacOS:$PATH
export PATH=$HOME/development/flutter/bin:$PATH
# Load local profile secrets if it exists
if [ -f ~/.zprofile.local ]; then
    source ~/.zprofile.local
fi


  [ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh


# Added by Antigravity CLI installer
export PATH="/Users/danipan/.local/bin:$PATH"
