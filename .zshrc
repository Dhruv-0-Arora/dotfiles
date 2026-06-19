
# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

# bun completions
[ -s "/Users/dhruvarora/.bun/_bun" ] && source "/Users/dhruvarora/.bun/_bun"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gb="git branch"
alias gp="git push"
alias gpl="git pull"
alias gco="git checkout"
alias gmd="git merge origin/dev"
alias gl="git log --oneline --graph --decorate --all"
alias gbl="git blame -L"

alias e="nvim"
alias l="eza --icons --git --group-directories-first"
alias c="clear"
alias zshrc="e ~/.zshrc"
alias winter="cd /Volumes/wintermute/docs/ && l"

alias ..="cd .. && l"
alias ...="cd ../.."
alias ....="cd ../../.."

# home server
alias conn_server="ssh darora1@100.82.147.100"

# directories
alias docs="cd ~/Documents/"
alias config="cd ~/.config/"
alias vault="cd '/Users/dhruvarora/Library/Mobile Documents/iCloud~md~obsidian/Documents/Brain'"
alias wheel="cd ~/Documents/226_steeringwheel/"
alias sai="cd ~/Documents/sai-bots/"

# misc
alias espset="cd ~/esp/esp-idf/ && . ./export.sh && wheel"
alias flash="idf.py flash monitor"
alias rlocl="python3 -m uvicorn server:app --host 0.0.0.0 --port 8000"

export PATH="/Applications/Alacritty.app/Contents/MacOS:$PATH"
# export PATH="/opt/homebrew/opt/openjdk/bin:$PATH" # java version 25
export PATH="/usr/libexec/java_home -v 21.0.9:$PATH"
export GPG_TTY=$(tty)


# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
eval "$(zellij setup --generate-auto-start zsh)"
