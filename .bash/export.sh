# https://github.com/b3nj5m1n/xdg-ninja
export ANDROID_USER_HOME="$XDG_DATA_HOME"/android
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export CUDA_CACHE_PATH="$XDG_CACHE_HOME"/nv
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker
export GNUPGHOME="$XDG_DATA_HOME"/gnupg
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export GOPATH="$XDG_DATA_HOME"/go
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME"/npm/npmrc
export PARALLEL_HOME="$XDG_CONFIG_HOME"/parallel
export INPUTRC="$XDG_CONFIG_HOME"/readline/inputrc
export MYPY_CACHE_DIR="$XDG_CACHE_HOME"/mypy

# To use KDE file dialog with firefox https://daniele.tech/2019/02/how-to-execute-firefox-with-support-for-kde-filepicker/
export GTK_USE_PORTAL=1

export GEM_PATH=/usr/lib/ruby/vendor_ruby/:$GEM_PATH
export PATH=/usr/local/sbin:$PATH
export PATH=./vendor/bin:$PATH
export PATH=~/.local/share/npm/bin:$PATH
export PATH=./config/composer/bin:$PATH
export PATH=~/.cargo/bin:$PATH 
export PATH=/home/mte90/.config/composer/vendor/bin/:$PATH
export PATH=/home/mte90/.local/bin/:$PATH
export PATH=/home/mte90/.local/share/cargo/bin/:$PATH

FCEDIT=vim.tiny
export EDITOR="vim.tiny"
export DJANGO_DEBUG=True

# https://www.reddit.com/r/programming/comments/109rjuj/how_setting_the_tz_environment_variable_avoids/
export TZ=$(readlink -f /etc/localtime | cut -d/ -f 5-)
