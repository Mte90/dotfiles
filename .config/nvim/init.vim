" Disable some plugin to have a wordpress core contributing experience
" nvim --cmd "let g:wordpress_mode=1"
" nvim-qt -- --cmd "let g:wordpress_mode=1"

set termguicolors

lua << EOF
    require('settings')
    require('plugins')
    require('mappings')
    require('misc')
EOF

source /home/mte90/.vim/custom/custom-fzf.vim
