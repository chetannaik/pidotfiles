#          _
#  _______| |__  _ __ ___
# |_  / __| '_ \| '__/ __|
#  / /\__ \ | | | | | (__
# /___|___/_| |_|_|  \___|
#
export ZSH="$HOME/.oh-my-zsh"
export EDITOR=vim

plugins=(
   git
   brew
   colored-man-pages
   fasd
   vi-mode
   zsh-autosuggestions
   zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export PATH="$HOME/.local/bin:$PATH"

# Disable creation of __pycache__ directory
PYTHONDONTWRITEBYTECODE=1

###########
# ALIASES #
###########
alias l="ls -lh" /bin/ls
alias ll="ls -lah" /bin/ls
alias gti=git
alias r=ranger
alias vf="cd"
alias ta='tmux attach'

# git aliases
alias gs='git status'
alias gl='git log --graph --pretty=format:"%Cred%h%Creset %C(bold blue)%an%C(reset) - %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset" --abbrev-commit --date=relative'



########
# PURE #
########
fpath+=($HOME/.zsh/pure)
autoload -U promptinit; promptinit
prompt pure


#######
# FZF #
#######
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh