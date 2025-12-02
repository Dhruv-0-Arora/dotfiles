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
alias l="ls -la"
alias c="clear"
alias zshrc="e ~/.zshrc"

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

alias docs="cd ~/Documents/"
alias config="cd ~/.config/"
alias vault="cd '/Users/dhruvarora/Library/Mobile Documents/iCloud~md~obsidian/Documents/Brain'"
alias wheel="cd ~/Documents/226_steeringwheel/"
alias espset="cd ~/esp/esp-idf/ && . ./export.sh && wheel"
alias flash="idf.py flash monitor"
alias sai="cd ~/Documents/sai-bots/"

export PATH="/Applications/Alacritty.app/Contents/MacOS:$PATH"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
