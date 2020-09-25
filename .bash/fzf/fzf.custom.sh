# https://github.com/junegunn/fzf
export FZF_DEFAULT_COMMAND="rg --files --no-ignore --follow -g '!{.sass\-cache,node_modules,_generated,_bootstrap.php,vendor}/*' 2> /dev/null"
export FZF_DEFAULT_OPTS='--exact --preview "batcat --style=numbers --color=always {}"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
bind -x '"\C-p": nvim-qt $(fzf);'
# Bind F1 to open file to Kate, Ctrl-Y to copy to the clipboard the path, Ctrl-N to enter the folder
alias fzf='fzf --bind "f1:execute(kate {}),ctrl-y:execute-silent(echo {} | pbcopy)+abort,ctrl-n:execute(cd {})"' 

# Based on https://revelry.co/terminal-workflow-fzf/
function git-checkout() {
    result=$(git branch --color=always | grep -v '/HEAD\s' | sort |
    fzf --height 50% --border --ansi --tac --preview-window right:70% \
      --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) | head -'$LINES |
    sed 's/^..//' | cut -d' ' -f1)

  if [[ $result != "" ]]; then
    if [[ $result == remotes/* ]]; then
      git checkout --track $(echo $result | sed 's#remotes/##')
    else
      git checkout "$result"
    fi
  fi
}
