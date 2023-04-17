# For VVV development
export WP_TESTS_DB_HOST='localhost'
export WP_TESTS_DB_USER='root'
export WP_TESTS_DB_PASSWORD='test'

# To use KDE file dialog with firefox https://daniele.tech/2019/02/how-to-execute-firefox-with-support-for-kde-filepicker/
export GTK_USE_PORTAL=1

# Fix issues with permissions on my system
export XDG_RUNTIME_DIR="/run/user/1000"

export PATH=/usr/local/sbin:$PATH
export PATH=./vendor/bin:$PATH
export PATH=./composer/bin:$PATH
export PATH=~/.config/vendor/bin:$PATH
export PATH=~/.cargo/bin:$PATH 
export PATH=/home/mte90/.composer/vendor/bin/:$PATH
export GEM_PATH=/usr/lib/ruby/vendor_ruby/:$GEM_PATH
export PATH=/home/mte90/.local/bin/:$PATH

FCEDIT=vim
export DJANGO_DEBUG=True

# https://www.reddit.com/r/programming/comments/109rjuj/how_setting_the_tz_environment_variable_avoids/
export TZ=$(readlink -f /etc/localtime | cut -d/ -f 5-)

# https://github.com/dvorka/hstr
export HH_CONFIG=hicolor         # get more colors
export PROMPT_COMMAND="history -a; history -n; ${PROMPT_COMMAND}"   # mem/file sync
# if this is interactive shell, then bind hh to Ctrl-r (for Vi mode check doc)
if [[ $- =~ .*i.* ]]; then bind '"\C-r": "\C-a hstr -- \C-j"'; fi
