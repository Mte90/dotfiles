# https://github.com/junegunn/fzf
export FZF_DEFAULT_COMMAND='ag --ignore-dir .sass-cache --ignore-dir _output --ignore-dir node_modules --ignore-dir _generated --ignore _bootstrap.php --ignore-dir vendor -g "" -U --nogroup --column --nocolor --php --html --css --js'
export FZF_DEFAULT_OPTS='--exact --preview "bat --style=numbers --color=always {}"'
# Bind F1 to open file to Kate, Ctrl-Y to copy to the clipboard the path, Ctrl-N to enter the folder
alias fzf='fzf --bind "f1:execute(kate {}),ctrl-y:execute-silent(echo {} | pbcopy)+abort,ctrl-n:execute(cd {})"' 
