#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export HISTCONTROL=ignoredups:erasedups # no duplicate entries
export HISTSIZE=1000                   
export HISTFILESIZE=750               
shopt -s histappend                     # append to history, don't overwrite it

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

# VI mode in bash + mode in prompt
set -o vi
bind 'set show-mode-in-prompt on'
