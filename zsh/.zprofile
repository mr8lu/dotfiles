
eval "$(/opt/homebrew/bin/brew shellenv)"

# added by Snowflake SnowSQL installer v1.2
export PATH=/Applications/SnowSQL.app/Contents/MacOS:$PATH
export PATH=$HOME/development/flutter/bin:$PATH
export HF_TOKEN="your_huggingface_token_here"
# Add your SSH keys here, e.g.:
# ssh-add --apple-load-keychain $HOME/.ssh/your_key


  [ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh
