" Disable some plugin to have a wordpress core contributing experience
" vim --cmd "let wordpress_mode=1" 

lua << EOF
require('settings')
require('plugins')
require('mappings')
require('misc')
EOF

source /home/mte90/.vim/custom/custom-ale.vim
source /home/mte90/.vim/custom/custom-fzf.vim
