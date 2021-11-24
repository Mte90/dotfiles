alias grep='rg'
alias hh='hstr'
# https://altbox.dev/
# https://github.com/sharkdp/bat
alias cat='batcat --paging=never'
# https://the.exa.website/
alias ls='exa --group-directories-first --git-ignore --git -abghlS'
alias ln='ln -sf'
# Create all the parent directories with children
alias mkdir='mkdir -p'
alias diff='colordiff'
alias fd='fdfind'
# Create folder and join it
function mkcd(){ mkdir -p $@ && cd $_; }
alias jpeg-to-webp='fd "./*\.jpg$" -x cwebp -q 95 {} -o {.}.jpg.webp'

# CD stuff
alias casa='cd /home/mte90/Desktop'
alias www='cd /var/www'
alias vvv='cd /var/www/VVV/www 2>/dev/null;cd /home/mte90/Desktop/VVV/www 2>/dev/null'
alias wpp='cd ./public_html/wp-content/plugins 2>/dev/null;cd ./public_html/build/wp-content/plugins 2>/dev/null;cd ./wp-content/plugins 2>/dev/null'
alias wpt='cd ./public_html/wp-content/themes 2>/dev/null;cd ./public_html/build/wp-content/themes 2>/dev/null;cd ./wp-content/themes 2>/dev/null'
# Misc
alias biggest-10-files='BLOCKSIZE=1048576; du -x -h | sort -nr | head -10'
#youtube-dl as mp3
alias yt2mp3='youtube-dl -x --audio-format=mp3 -w -c -o "%(title)s-%(id)s.%(ext)s"'
alias changedfiles="find . -type f -print0 | xargs -0 stat --format '%Z :%z %n' | sort -nr | cut -d: -f2- | head -n 20"
alias kate='kate -b'

# For Git
alias git='/home/mte90/Desktop/Prog/gitapper/gitapper.sh'
#  To remember the SSH password for 36000 minutes
alias git-pass='ssh-add -t 36000'
alias gpm="git push origin $(git rev-parse --abbrev-ref HEAD)"
alias git-remove-deleted-branch-remotely="git remote prune origin"
#  Add and remove new/deleted files from git index automatically
alias git-remove-file-not-exist-anymore-history="git ls-files -d -m -o -z --exclude-standard | xargs -0 git update-index --add --remove"
alias dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME"
function git-stat-months() { git diff --shortstat "@{$1 month ago}"; }

alias nvim-qt="/home/mte90/Desktop/Prog/My-Scripts/misc/nvim-qt.py"
alias vim.tiny="nvim -u NONE"
alias nvim.tiny="nvim -u NONE"

# https://github.com/cykerway/complete-alias
complete -F _complete_alias fzf
complete -F _complete_alias dotfiles
complete -F _complete_alias git

# WordPress vim mode
alias nvim-wp="nvim-qt /var/www/VVV/www/wordpress-develop/public_html -- --cmd 'let wordpress_mode=1' "
