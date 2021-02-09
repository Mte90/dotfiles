" Note: Skip initialization for vim-tiny or vim-small.
if !1 | finish | endif

" Disable some plugin to have a wordpress core contributing experience
" vim --cmd "let wordpress_mode=1" 

lua << EOF
require('settings')
require('plugins')
EOF

colorscheme valloric

if !exists('wordpress_mode')
    source /home/mte90/.vim/custom/custom-startify.vim
endif
source /home/mte90/.vim/custom/custom-lightline.vim
source /home/mte90/.vim/custom/custom-deoplete.vim
source /home/mte90/.vim/custom/custom-ale.vim
source /home/mte90/.vim/custom/custom-fzf.vim
source /home/mte90/.vim/custom/custom-lsp.vim
source /home/mte90/.vim/custom/custom-ts.vim
source /home/mte90/.vim/custom/custom-vista.vim

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
let g:indentLine_fileTypeExclude = ['help', 'chadtree', 'startify', 'fzf', 'tagbar']
let g:indentLine_char = '┊'
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
" Vdebug
let g:vdebug_options = {
    \    'break_on_open' : 0,
    \    'ide_key' : 'VVVDEBUG'
    \}
let g:vdebug_options.path_maps = {"/srv/www/": "/var/www/VVV/www/"}
"Chadtree
lua vim.api.nvim_set_var("chadtree_ignores", { name = {".*", ".git", "vendor", "node_modules"} })
let g:chadtree_settings = {"keymap": { "tertiary": ["t"], 'trash': ['a'] }, "theme": {"text_colour_set": "solarized_dark"}}
let g:splitjoin_join_mapping = ''

" Internals mapping
" Insert blank lines above and bellow current line, respectively.
nnoremap [<Space> :<c-u>put! =repeat(nr2char(10), v:count1)<CR>
nnoremap ]<Space> :<c-u>put =repeat(nr2char(10), v:count1)<CR>
nnoremap {<Space> :<c-u>put! =repeat(nr2char(10), v:count1)<CR>
nnoremap }<Space> :<c-u>put =repeat(nr2char(10), v:count1)<CR>
" Reselect text after indent/unindent.
vnoremap < <gv
vnoremap > >gv
" Remove spaces at the end of lines
nnoremap <silent> ,<Space> :<C-u>silent! keeppatterns %substitute/\s\+$//e<CR>
" Remove highlights
map <esc> :noh<cr>
" Granular undo
inoremap <Space> <Space><C-G>u
" No yank on delete
nnoremap d "_d
nnoremap D "_D
vnoremap d "_d
nnoremap <del> <C-G>"_x
" Move between panes/split with Ctrl
map <silent> <C-Up> :wincmd k<CR>
map <silent> <C-Down> :wincmd j<CR>
map <silent> <C-Left> :wincmd h<CR>
map <silent> <C-Right> :wincmd l<CR>
nmap <silent> <C-Up> :wincmd k<CR>
nmap <silent> <C-Down> :wincmd j<CR>
nmap <silent> <C-Left> :wincmd h<CR>
nmap <silent> <C-Right> :wincmd l<CR>
" Move between tabs with Alt
nmap <M-Right> :tabnext<CR>
nmap <M-Left> :tabprevious<CR>
" correct :W to :w typo
cnoreabbrev <expr> W ((getcmdtype() is# ':' && getcmdline() is# 'W')?('w'):('W'))
" correct :Q to :q typo
cnoreabbrev <expr> Q ((getcmdtype() is# ':' && getcmdline() is# 'Q')?('q'):('Q'))

" Plugins custom mapping
" Open Folder tab current directory
nmap <leader>n <cmd>CHADopen<cr>
" Fold code open/close with click
nmap <expr> <2-LeftMouse> 'za'
" Search in the project files
nmap <leader>f :Rg<space>
" Object view
nmap <C-t> :Vista nvim_lsp<CR>
" File list with fzf
nmap <leader>x :Files<CR>
" navigate between errors
nmap <silent> <C-k> <Plug>(ale_previous_wrap)
nmap <silent> <C-j> <Plug>(ale_next_wrap)
nmap <silent> <C-q> <Plug>(ale_fix)
" Toggle comments
nmap <C-d> <plug>NERDCommenterToggle<CR>
vmap <C-d> <plug>NERDCommenterToggle<CR>
" Append ; to the end of the line -> Leader+B
map <leader>b :call setline('.', getline('.') . ';')<CR>
" https://www.cyberciti.biz/faq/how-to-reload-vimrc-file-without-restarting-vim-on-linux-unix/
" Edit vimrc configuration file
nnoremap confe :e $MYVIMRC<CR>
" Reload vims configuration file
nnoremap confr :source $MYVIMRC<CR>
nmap <Leader>s :SplitjoinSplit<cr>
