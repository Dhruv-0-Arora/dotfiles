# git completions
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit

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

# --- git worktrees: work on multiple branches/projects at once ------------
# Worktrees live in a sibling dir: <repo>.worktrees/<branch>, so the parent
# stays clean. When inside zellij, each worktree opens in its own named tab.
alias gwl="git worktree list"
alias gwr="git worktree remove"       # gwr <branch-or-path>
alias gwp="git worktree prune"        # clean up stale worktree metadata

# gwa <branch> [base]: add a worktree for <branch> (creating it from [base],
# default current HEAD, when it doesn't exist yet) and open it in a new tab.
gwa() {
  local branch="$1" base="${2:-HEAD}"
  if [[ -z "$branch" ]]; then
    echo "usage: gwa <branch> [base-branch]" >&2
    return 1
  fi
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "gwa: not a git repo" >&2; return 1; }
  local wt_dir="${root:h}/${root:t}.worktrees/${branch}"
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git worktree add "$wt_dir" "$branch" || return 1
  else
    git worktree add -b "$branch" "$wt_dir" "$base" || return 1
  fi
  gwo "$wt_dir" "$branch"
}

# gwo <path> [name]: open an existing worktree path in a new zellij tab (or
# just cd into it when not running under zellij).
gwo() {
  local dir="$1" name="${2:-${1:t}}"
  [[ -z "$dir" ]] && { echo "usage: gwo <path> [tab-name]" >&2; return 1; }
  if [[ -n "$ZELLIJ" ]]; then
    zellij action new-tab -n "$name" -c "$dir" -- zsh
  else
    cd "$dir" && l
  fi
}

alias e="nvim"
# Tint eza directories forest green (#228B22) instead of the default blue,
# matching the zellij forest-green theme. `di` is the directory entry style.
export EZA_COLORS="di=38;2;34;139;34"
# `l` lists files; inside ~/Documents it uses dirtint (directories tinted by
# recency), everywhere else plain eza. Extend the guard with more paths as needed.
unalias l 2>/dev/null  # drop any pre-existing `l` alias so the function defines cleanly
l() {
  if [[ "$PWD" == "$HOME/Documents" ]]; then
    command dirtint "$@"
  else
    command eza --icons --git --group-directories-first "$@"
  fi
}
alias c="clear"
alias cc="claude"
alias zshrc="e ~/.zshrc"
alias winter="cd /Volumes/wintermute/docs/ && l"

alias ..="cd .. && l"
alias ...="cd ../.. && l"
alias ....="cd ../../.. && l"

# home server
alias conn_server="ssh darora1@100.82.147.100"

# directories
alias docs="cd ~/Documents/ && l"
alias config="cd ~/.config/"
alias vault="cd '/Users/dhruvarora/Library/Mobile Documents/iCloud~md~obsidian/Documents/Brain'"
alias wheel="cd ~/Documents/226_steeringwheel/"
alias sai="cd ~/Documents/sai-bots/"
alias fis="cd ~/Documents/synthesis/fission/"

# misc
alias espset="cd ~/esp/esp-idf/ && . ./export.sh && wheel"
alias flash="idf.py flash monitor"
alias rlocl="python3 -m uvicorn server:app --host 0.0.0.0 --port 8000"

export PATH="/Applications/Alacritty.app/Contents/MacOS:$PATH"
# export PATH="/opt/homebrew/opt/openjdk/bin:$PATH" # java version 25
export PATH="/usr/libexec/java_home -v 21.0.9:$PATH"
export GPG_TTY=$(tty)

if [ -z "$ZELLIJ" ]; then
    # Attach to 'default' or create it; then close the shell wrapper upon exit
    exec zellij attach -c default
fi
parse_git_branch() {
  git branch --show-current 2> /dev/null
}
setopt PROMPT_SUBST
export PROMPT='%F{cyan}%~ %F{green}[$(parse_git_branch)]%f $ '

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/dhruvarora/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/dhruvarora/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/dhruvarora/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/dhruvarora/google-cloud-sdk/completion.zsh.inc'; fi
