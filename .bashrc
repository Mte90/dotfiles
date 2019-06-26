# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
export HISTCONTROL="erasedups:ignoreboth:ignorespace"
export HISTFILESIZE=2000        # increase history file size (default is 500)
# Show datetime on every command
export HISTTIMEFORMAT="%h %d %H:%M:%S "

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTSIZE=1000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Auto fix filenames with spell checker
shopt -s dirspell
shopt -s cdspell

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto -h'
    
    alias grep='grep --color=auto --exclude-dir=\.git'
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# if the command-not-found package is installed, use it
if [ -x /usr/lib/command-not-found -o -x /usr/share/command-not-found/command-not-found ]; then
	function command_not_found_handle {
	        # check because c-n-f could've been removed in the meantime
                if [ -x /usr/lib/command-not-found ]; then
		   /usr/lib/command-not-found -- "$1"
                   return $?
                elif [ -x /usr/share/command-not-found/command-not-found ]; then
		   /usr/share/command-not-found/command-not-found -- "$1"
                   return $?
		else
		   printf "%s: command not found\n" "$1" >&2
		   return 127
		fi
	}
fi

# Autocompletion ignore case for filenames
bind "set completion-ignore-case on"

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

# https://github.com/sharkdp/bat
alias cat='bat'
# https://the.exa.website/
alias lx='exa'

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
    url=$(echo $url | sed 's/.git//g' | sed 's/git\@//g' | sed 's/github.com\://g')
    echo "$url download in progress"
    git clone git@github.com:$url.git &> /dev/null
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

# Commit easily
function gcm() {
    git commit -m "$@"
}

# https://github.com/github/hub
if [ -f /usr/share/bash-completion/completions/hub ]; then
    . /usr/share/bash-completion/completions/hub
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

# https://github.com/petobens/trueline
TRUELINE_GIT_MODIFIED_COLOR='red'
. ~/.bash_powerline

# https://github.com/dvorka/hstr
export HH_CONFIG=hicolor         # get more colors
export PROMPT_COMMAND="history -a; history -n; ${PROMPT_COMMAND}"   # mem/file sync
# if this is interactive shell, then bind hh to Ctrl-r (for Vi mode check doc)
if [[ $- =~ .*i.* ]]; then bind '"\C-r": "\C-a hh -- \C-j"'; fi

# For VVV development
export WP_TESTS_DB_HOST=localhost
export WP_TESTS_DB_USER=root
export WP_TESTS_DB_PASSWORD='test'

# Open the debug of that website
function vvv-debug(){
    log="/var/www/VVV/www/$1/htdocs/wp-content/debug.log"
    if [ ! -f $log ]; then
        log="/var/www/VVV/www/$1/public_html/wp-content/debug.log"
    fi
    
    if [ -f $log ]; then
        actualsize=$(du -k $log | cut -f 1)
        if [ $actualsize -ge 300 ]; then
            rm $log;
        fi
        echo "" > $log
        multitail -cS php -m 600 $log;
    else
        echo "Log not found"
    fi
}

# https://github.com/wting/autojump
source /usr/share/autojump/autojump.sh

# https://github.com/junegunn/fzf
export FZF_DEFAULT_COMMAND='ag --ignore-dir .sass-cache --ignore-dir _output --ignore-dir node_modules --ignore-dir _generated --ignore _bootstrap.php --ignore-dir vendor -g "" -U --nogroup --column --nocolor --php --html --css --js'
export FZF_DEFAULT_OPTS='--exact --preview "bat --style=numbers --color=always {}"'
# Bind F1 to open file to Kate, Ctrl-Y to copy to the clipboard the path, Ctrl-N to enter the folder
alias fzf='fzf --bind "f1:execute(kate {}),ctrl-y:execute-silent(echo {} | pbcopy)+abort,ctrl-n:execute(cd {})"'

# https://github.com/cykerway/complete-alias
if [ -f ~/.bash_completion ]; then
    . ~/.bash_completion
fi
complete -F _complete_alias fzf
complete -F _complete_alias dotfiles

# To use KDE file dialog with firefox https://daniele.tech/2019/02/how-to-execute-firefox-with-support-for-kde-filepicker/
export GTK_USE_PORTAL=1

# Fix issues with pulse on my system
PULSE_DIR="/tmp/$( whoami )-pulse"
mkdir -p $PULSE_DIR && chmod 777 $PULSE_DIR && chown mte90:mte90 $PULSE_DIR
export PULSE_CONFIG_PATH=$PULSE_DIR
export PULSE_STATE_PATH=$PULSE_DIR
export PULSE_RUNTIME_PATH=$PULSE_DIR

# Fix issues with permissions on my system
export XDG_RUNTIME_DIR="/run/user/1000"

export PATH=$PATH:/usr/local/sbin
export PATH=./vendor/bin:$PATH
export PATH=./composer/bin:$PATH
export PATH=~/.composer/vendor/bin:$PATH
