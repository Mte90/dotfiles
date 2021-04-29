" Note: Skip initialization for vim-tiny or vim-small.
if !1 | finish | endif

" Disable some plugin to have a wordpress core contributing experience
" vim --cmd "let wordpress_mode=1" 

lua << EOF
require('settings')
require('plugins')
require('mappings')
EOF

colorscheme valloric

if !exists('wordpress_mode')
    source /home/mte90/.vim/custom/custom-startify.vim
endif
source /home/mte90/.vim/custom/custom-lightline.vim
source /home/mte90/.vim/custom/custom-deoplete.vim
source /home/mte90/.vim/custom/custom-ale.vim
source /home/mte90/.vim/custom/custom-fzf.vim

lua << EOF
require('plugin.ts')
require('plugin.lsp')
require('plugin.dap')
require('plugin.gitsigns')
require('plugin.symbols-outline')
require('plugin.nvim-comment')
EOF

" https://www.reddit.com/r/neovim/comments/gofplz/neovim_has_added_the_ability_to_highlight_yanked/
augroup highlight_yank
    autocmd!
    autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank("IncSearch", 1000)
augroup END
augroup default
    autocmd!
    " Add support of stuff on different files
    autocmd BufReadPost * if line("'\"") && line("'\"") <= line("$") | exe "normal `\"" | endif
    autocmd BufRead,BufNewFile jquery.*.js set ft=javascript syntax=jquery
    autocmd FileType php set tabstop=4 
    autocmd FileType php.wordpress set tabstop=4
    autocmd FileType javascript set tabstop=2 shiftwidth=2
    autocmd FileType php let b:surround_45 = "<?php \r ?>"
augroup END 
augroup fmt
  autocmd!
  " Autoformat in tabs
  autocmd BufWritePre *.js :normal =G
  autocmd BufWritePre *.css :normal =G
  autocmd BufWritePre *.sass :normal =G
augroup END

au FileType qf call AdjustWindowHeight(3, 5)
function! AdjustWindowHeight(minheight, maxheight)
  exe max([min([line("$"), a:maxheight]), a:minheight]) . "wincmd _"
endfunction

" Enable Rainbow Parenthesis
let g:rainbow_active = 1
" Find root
let g:rooter_patterns = ['.git/', 'package.json', 'composer.json']
let g:rooter_resolve_links = 1
let g:rooter_silent_chdir  = 1
" Editorconfig
let g:EditorConfig_exclude_patterns = ['fugitive://.*']
" Ultisnip
let g:UltiSnipsEditSplit = 'vertical'
let g:UltiSnipsExpandTrigger='<tab>'
" Indent lines
let g:indent_guides_exclude_filetypes = ['help', 'chadtree', 'startify', 'fzf', 'tagbar', 'vista']
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_guide_size = 1
let g:indent_guides_color_change_percent = 3
" Nerdcommenter for... better comments
let g:NERDSpaceDelims = 1
let g:NERDCompactSexyComs = 1
let g:NERDCommentEmptyLines = 1
let g:NERDTrimTrailingWhitespace = 1
let g:NERDCreateDefaultMappings = 0
let g:NERDToggleCheckAllLines = 1
" Trigger a highlight only when pressing f and F.
let g:qs_highlight_on_keys = ['f']
let g:qs_max_chars=80
" Markdown
let g:vim_markdown_folding_disabled = 1
"Chadtree
lua vim.api.nvim_set_var("chadtree_ignores", { name = {".*", ".git", "vendor", "node_modules"} })
let g:chadtree_settings = {"keymap": { "tertiary": ["t"], 'trash': ['a'] }, "theme": {"text_colour_set": "solarized_dark"}}
let g:splitjoin_join_mapping = ''
