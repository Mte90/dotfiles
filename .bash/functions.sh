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

# cd back up to the top-level git/hg repo dir
function cdreporoot () {
    ORIGINAL_PWD=$(pwd)
    while [ ! -d ".git" -a ! -d ".hg" -a $ORIGINAL_PWD != "/" ]
    do
        cd ..
    done
    if [  -d ".git" ] ; then
        :
    elif [ -d ".hg" ] ; then
        :
    else
        cd $ORIGINAL_PWD
    fi
}

# https://blog.jez.io/bash-debugger/
debugger() {
  echo "Stopped in REPL. Press ^D to resume, or ^C to abort."
  local line
  while read -r -p "> " line; do
    eval "$line"
  done
  echo
}

codecoverage() {
    codecept run wpunit --coverage-html 
    
    rsync --exclude={.sass-cache*,*.map,node_modules,.php_cs,.git*,*.lock,*.yml,*lock.json} --progress -avz ./tests/_output/coverage -e ssh dev.codeat.it:/var/www/plugin/$1/coverage > /dev/null
    
    /home/mte90/ffnightly/firefox https://dev.codeat.it/plugin/$1
}
