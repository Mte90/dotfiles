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
