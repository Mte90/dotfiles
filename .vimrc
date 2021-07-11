" Disable some plugin to have a wordpress core contributing experience
" vim --cmd "let wordpress_mode=1" 

lua << EOF
require('settings')
require('plugins')
require('mappings')
require('misc')
EOF

if !exists('wordpress_mode')
    source /home/mte90/.vim/custom/custom-startify.vim
endif
source /home/mte90/.vim/custom/custom-ale.vim
source /home/mte90/.vim/custom/custom-fzf.vim
