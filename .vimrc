" Note: Skip initialization for vim-tiny or vim-small.
if !1 | finish | endif

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
source /home/mte90/.vim/custom/custom-deoplete.vim
source /home/mte90/.vim/custom/custom-ale.vim
source /home/mte90/.vim/custom/custom-fzf.vim

lua << EOF
require('plugin.ts')
require('plugin.lsp')
require('plugin.dap')
require('plugin.gitsigns')
require('plugin.nvim-comment')
require('plugin.lualine')
EOF

" Find root
let g:rooter_patterns = ['.git/', 'package.json', 'composer.json']
let g:rooter_resolve_links = 1
let g:rooter_silent_chdir  = 1
" Editorconfig
let g:EditorConfig_exclude_patterns = ['fugitive://.*']
" Ultisnip
let g:UltiSnipsEditSplit = 'vertical'
let g:UltiSnipsExpandTrigger='<tab>'
" Trigger a highlight only when pressing f and F. - quickscope
let g:qs_highlight_on_keys = ['f']
let g:qs_max_chars=80
" Markdown
let g:vim_markdown_folding_disabled = 1
"Chadtree
lua vim.api.nvim_set_var("chadtree_ignores", { name = {".*", ".git", "vendor", "node_modules"} })
let g:chadtree_settings = {"keymap": { "tertiary": ["t"], 'trash': ['a'] }, "theme": {"text_colour_set": "solarized_dark"}}
let g:splitjoin_join_mapping = ''
