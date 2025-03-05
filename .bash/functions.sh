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
