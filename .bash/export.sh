# To use KDE file dialog with firefox https://daniele.tech/2019/02/how-to-execute-firefox-with-support-for-kde-filepicker/
export GTK_USE_PORTAL=1

export PATH=/usr/local/sbin:$PATH
export PATH=./vendor/bin:$PATH
export PATH=./composer/bin:$PATH
export PATH=~/.config/vendor/bin:$PATH
export PATH=~/.cargo/bin:$PATH 
export PATH=/home/mte90/.composer/vendor/bin/:$PATH
export GEM_PATH=/usr/lib/ruby/vendor_ruby/:$GEM_PATH
export PATH=/home/mte90/.local/bin/:$PATH

FCEDIT=vim
export EDITOR="vim.tiny"
export DJANGO_DEBUG=True

# https://www.reddit.com/r/programming/comments/109rjuj/how_setting_the_tz_environment_variable_avoids/
export TZ=$(readlink -f /etc/localtime | cut -d/ -f 5-)
