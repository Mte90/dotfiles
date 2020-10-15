# https://github.com/junegunn/fzf
export FZF_DEFAULT_COMMAND="rg --files --no-ignore --follow -g '!{.sass\-cache,node_modules,_generated,_bootstrap.php,vendor}/*' 2> /dev/null"
# https://medium.com/@vdeantoni/boost-your-command-line-productivity-with-fuzzy-finder-985aa162ba5d
export FZF_DEFAULT_OPTS='--exact --preview "([[ -f {} ]] && (batcat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200" --height=90%'
export FZF_DEFAULT_OPTS='--exact --preview "batcat --style=numbers --color=always {}"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
bind -x '"\C-p": nvim-qt $(fzf);'
# Bind F1 to open file to Kate, Ctrl-Y to copy to the clipboard the path, Ctrl-N to enter the folder
alias fzf='fzf --bind "f1:execute(kate {}),ctrl-y:execute-silent(echo {} | pbcopy)+abort,ctrl-n:execute(cd {})"' 

# find-in-file - usage: fif <SEARCH_TERM>
find-in-file() {
  if [ ! "$#" -gt 0 ]; then
    echo "Need a string to search for!";
    return 1;
  fi  
  rg --files-with-matches --no-messages "$1" | fzf $FZF_PREVIEW_WINDOW --preview "rg --ignore-case --pretty --context 10 '$1' {}"
}
