#
# ~/.bashrc
#

export BROWSER=google-chrome

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gs='git status'
alias gb='git branch'
alias gl='git log --oneline --decorate --graph'
alias gr='git reset --hard HEAD'
alias gd='git diff'
alias gco='git checkout'
alias gmd='git merge origin/dev'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../../'
alias l='ls -l'
alias c='clear'
alias e='nvim'
alias bashrc='nvim ~/.bashrc'
alias snip='scrot -s foo.png && xclip -se c -t image/png -i foo.png && rm foo.png &'

alias docs='cd /home/darora1/Documents/'
alias config='cd ~/.config/'
alias vault='cd ~/Documents/obsidian-vault/'
alias sai='cd ~/Documents/sai-bots/'

alias wheel="cd ~/Documents/226_steeringwheel/"
alias espset="cd ~/esp/esp-idf/ && . ./export.sh && wheel"
alias flash="idf.py flash monitor"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
. "$HOME/.cargo/env"
