alias grep='rg'
# https://altbox.dev/
# https://github.com/sharkdp/bat
alias cat='bat --paging=never'
# https://the.exa.website/
alias ls='exa --group-directories-first --git-ignore --git -abghlS'
alias ln='ln -sf'
# Create all the parent directories with children
alias mkdir='mkdir -p'
alias diff='colordiff'
alias fd='fdfind'
# Create folder and join it
function mkcd(){ mkdir -p $@ && cd $_; }

# CD stuff
alias casa='cd /home/mte90/Desktop'
alias www='cd /var/www'
alias vvv='cd /var/www/VVV/www 2>/dev/null;cd /home/mte90/Desktop/VVV/www 2>/dev/null'
alias wpp='cd ./public_html/wp-content/plugins 2>/dev/null;cd ./public_html/build/wp-content/plugins 2>/dev/null;cd ./htdocs/wp-content/plugins 2>/dev/null;cd ./wp-content/plugins 2>/dev/null'
alias wpt='cd ./htdocs/wp-content/themes 2>/dev/null;cd ./wp-content/themes 2>/dev/null'
# Misc
alias biggest-10-files='BLOCKSIZE=1048576; du -x -h | sort -nr | head -10'
alias yt2mp3='youtube-dl -l -x --audio-format=mp3 -w -c'
alias changedfiles="find . -type f -print0 | xargs -0 stat --format '%Z :%z %n' | sort -nr | cut -d: -f2- | head -n 20"
alias kate='kate -b'

# dev
# https://github.com/gleitz/howdoi
alias howdoi='howdoi -c'

alias codeatcs='phpcs -p -s -d memory_limit=512M --ignore=*composer*,*.js,*.css,*vendor*,*/lib,index.php,*tests*,*config* --standard=/home/mte90/Desktop/Prog/CodeatCS/codeat.xml '
alias codeatcscbf='phpcbf -p -d memory_limit=512M --ignore=*composer*,*.js,*.css,*vendor*,*/lib,index.php,*tests*,*config* --standard=/home/mte90/Desktop/Prog/CodeatCS/codeat.xml '

# https://github.com/github/hub
if [ -f /usr/share/bash-completion/completions/hub ]; then
    source /usr/share/bash-completion/completions/hub
fi
eval "$(hub alias -s)"

# For Git
alias git-commit-rename='git commit --amend'
alias git-remove-last-commit='git reset --soft HEAD~1'
#  To remember the SSH password for 36000 minutes
alias git-pass='ssh-add -t 36000'
alias gpm="git push origin master"
alias git-restage="git update-index --again"
alias git-rename-branch="git rename-branch"
alias git-remove-deleted-branch-remotely="git remote prune origin"
#  Add and remove new/deleted files from git index automatically
alias git-remove-file-not-exist-anymore-history="git ls-files -d -m -o -z --exclude-standard | xargs -0 git update-index --add --remove"
alias dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME"
function git-merge-last-commits() { git reset --soft HEAD~$1 && git commit; }
alias commit="/home/mte90/Desktop/Prog/My-Scripts/dev/validate-commit.py"
function git-stat-months() { git diff --shortstat "@{$1 month ago}"; }
function gcm() { git commit -m "$@"; } 

# https://github.com/cykerway/complete-alias
complete -F _complete_alias fzf
complete -F _complete_alias dotfiles
