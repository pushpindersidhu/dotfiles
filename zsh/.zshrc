export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

zstyle ':omz:update' mode disabled  

plugins=(
    git
    zsh-syntax-highlighting
    zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

eval "$(zoxide init zsh)"

alias ls='eza'
alias ll='eza -la'
alias cat='bat --paging=never --style=plain'
alias cd='z'
alias vi='nvim'
