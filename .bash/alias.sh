alias ls='ls --color=auto -h'
alias grep='grep --color=auto --exclude-dir=\.git'
# https://github.com/sharkdp/bat
alias cat='bat'
# https://the.exa.website/
alias lx='exa'

# CD stuff
alias casa='cd /home/mte90/Desktop'
alias www='cd /var/www'
alias vvv='cd /var/www/VVV/www 2>/dev/null;cd /home/mte90/Desktop/VVV/www 2>/dev/null'
alias wpp='cd ./public_html/wp-content/plugins 2>/dev/null;cd ./public_html/build/wp-content/plugins 2>/dev/null;cd ./htdocs/wp-content/plugins 2>/dev/null;cd ./wp-content/plugins 2>/dev/null'
alias wpt='cd ./htdocs/wp-content/themes 2>/dev/null;cd ./wp-content/themes 2>/dev/null'
# Misc
alias biggest-10-files='BLOCKSIZE=1048576; du -x -h | sort -nr | head -10'
alias yt2mp3='youtube-dl -l --extract-audio --audio-format=mp3 -w -c'
alias kate='kate -b'
# dev
# https://github.com/gleitz/howdoi
alias howdoi='howdoi -c'
alias codeatcs='phpcs -p -s -d memory_limit=512M --ignore=*composer*,*.js,*.css,*vendor*,*/lib,index.php,*tests*,*config* --standard=/home/mte90/Desktop/Prog/CodeatCS/codeat.xml '
alias codeatcscbf='phpcbf -p -d memory_limit=512M --ignore=*composer*,*.js,*.css,*vendor*,*/lib,index.php,*tests*,*config* --standard=/home/mte90/Desktop/Prog/CodeatCS/codeat.xml '
alias dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME"
alias changedfiles="find . -type f -print0 | xargs -0 stat --format '%Z :%z %n' | sort -nr | cut -d: -f2- | head -n 20"

# Move to the # parent folder
up(){ DEEP=$1; [ -z "${DEEP}" ] && { DEEP=1; }; for i in $(seq 1 ${DEEP}); do cd ../; done; }

# Create folder and join it
function mkcd(){ mkdir -p $@ && cd $_; }
# Create all the parent directories with children
alias mkdir='mkdir -p'

# Download your fork and add the upstream
function git-fork() {
    url=$1
    url=${url%/}
    url=$(echo "$url" | sed 's/.git//g' | sed 's/git\@//g' | sed 's/github.com\://g')
    echo "$url download in progress"
    git clone "git@github.com:$url.git" &> /dev/null
    user=$(echo "$url" | awk -F/ '{print $1}')
    repo=$(echo "$url" | awk -F/ '{print $NF}')
    cd $repo
    remote=$(curl -s "https://api.github.com/repos/$user/$repo" | jq -r '.parent.clone_url' | tail -c +20)
    if [ "$remote" != "" ]; then
        echo "$remote download in progress"
        git remote add upstream "git@github.com:$remote" &> /dev/null
        git fetch --all &> /dev/null
    fi
}


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
function git-merge-last-commits() { git reset --soft HEAD~$1 && git commit; }
function commit() { commit=$(kdialog --title 'Commit message' --inputbox 'Insert the commit' '') && git commit -m "$commit" && echo "$commit"; }
function git-stat-months() { git diff --shortstat "@{$1 month ago}"; }
function gcm() { git commit -m "$@"; } 

# Open the debug of that website
function vvv-debug(){
    log="/var/www/VVV/www/$1/htdocs/wp-content/debug.log"
    if [ ! -f "$log" ]; then
        log="/var/www/VVV/www/$1/public_html/wp-content/debug.log"
    fi
    
    if [ -f "$log" ]; then
        actualsize=$(du -k "$log" | cut -f 1)
        if [ $actualsize -ge 300 ]; then
            rm "$log";
        fi
        echo "" > $log
        multitail -m 600 "$log";
    else
        echo "Log not found"
    fi
}

# https://github.com/junegunn/fzf
export FZF_DEFAULT_COMMAND='ag --ignore-dir .sass-cache --ignore-dir _output --ignore-dir node_modules --ignore-dir _generated --ignore _bootstrap.php --ignore-dir vendor -g "" -U --nogroup --column --nocolor --php --html --css --js'
export FZF_DEFAULT_OPTS='--exact --preview "bat --style=numbers --color=always {}"'
# Bind F1 to open file to Kate, Ctrl-Y to copy to the clipboard the path, Ctrl-N to enter the folder
alias fzf='fzf --bind "f1:execute(kate {}),ctrl-y:execute-silent(echo {} | pbcopy)+abort,ctrl-n:execute(cd {})"'

# https://github.com/cykerway/complete-alias
complete -F _complete_alias fzf
complete -F _complete_alias dotfiles
