" Note: Skip initialization for vim-tiny or vim-small.
if !1 | finish | endif

filetype plugin on
filetype indent on
syntax on

set encoding=utf-8          " The encoding displayed
set fileencoding=utf-8      " The encoding written to file
set number          " Show line numbers
set textwidth=100   " Line wrap (number of cols)
set showmatch       " Highlight matching brace
set visualbell      " Use visual bell (no beeping)
set title           " change the terminal's title
set mouse=a         " enable mouse in all modes
set clipboard^=unnamedplus " Allow use of system clipboard
set guioptions+=a
set guioptions-=e  " Don't use GUI tabline
set ttyfast        " Faster redrawing
set lazyredraw     " Only redraw when necessary
" File type preferences
set fileformats=unix,dos
" New splits open to right and bottom
set splitbelow
set splitright
" Autofolding
set foldmethod=syntax " Fold by syntax highlighting
set foldnestmax=10
set nofoldenable      " Turn off folding by default
set foldcolumn=2
set report=0
" Search option
set hlsearch              " Search highlighting
set incsearch             " Search starts while entering string
set cursorline            " Color the cursorline
set undolevels=2000       " Number of undo levels
set backspace=indent,eol,start  " Intuitive backspacing in insert mode
set ignorecase      " Search ignore case
set smartcase       " Search ignore case unless search contains an uppercase
set infercase       " Adjust case in insert completion mode
set wrapscan        " Searches wrap around the end of the file
set showmatch       " Jump to matching bracket
" Switch off automatic creation of backup files
set nobackup
set nowritebackup
set noswapfile   " Turn off swap files
set hidden       " Buffer becomes hidden when abandoned to prevent need to save
set completeopt=menu,noinsert
set laststatus=2 " Always show the status line
" Tabbar
set showtabline=2  " Show tabline
" Frequency update
set updatetime=250
" Behaviour
set nostartofline               " Cursor in same column for few commands
set whichwrap+=h,l,<,>,[,],~    " Move to following line on certain keys
set showfulltag                 " Show tag and tidy search in completion
set noshowmode          " Don't show mode in cmd window
set shortmess=aoOTI     " Shorten messages and don't show intro
set scrolloff=2         " Keep at least 2 lines above/below
set sidescrolloff=5     " Keep at least 5 lines left/right
set noshowcmd           " Don't show command in status line
" Enable indent
set autoindent          " Uses indent from previous line
set smartindent         " Like cindent except lil' more clever
set copyindent          " Copy the structure of existing line's indent when autoin
set sw=4
set shiftwidth=4     " Number of auto-indent spaces
set smarttab         " Enable smart-tabs
set softtabstop=4    " Number of spaces per Tab
set expandtab        " Insert spaces when tab pressed
set pumheight=15
set ruler
set autochdir        " Set the file path as pwd
set gdefault         " Set searching to global by default
" Make every wrapped line visually indented.
set breakindent
set showbreak=\\\\\
" Display extra whitespace.
set list
set listchars=tab:»·,trail:·,nbsp:·
set wildmenu " Command line completion help
" Set color
set guifont=Droid\ Sans\ Mono\ Nerd\ Font:h10
colorscheme valloric
" exclusions from the autocomplete menu
set wildoptions=tagfile
if has('nvim-0.4')
    set pumblend=20
    set wildoptions+=pum
endif
" Ignore case when completing file names and directories.
set wildignorecase
" A list of file patterns to ignore when performing expansion and completion.
set wildignore+=*.so,/min/*
set wildignore+=.git,.hg,.svn,.stversions,*.pyc,*.spl,*.o,*.out,*~,%*
set wildignore+=*.jpg,*.jpeg,*.png,*.gif,*.log,**/tmp/**
set wildignore+=**/node_modules/**,**/bower_modules/**,*/.sass-cache/*
set wildignore+=__pycache__,*.egg-info
set wildignore+=*.out,*.obj,*.gem,*.pyc
set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz
set wildignore+=*.swp,*~,._*,*/vendor/cache/*,*/.sass-cache/*
set wildignore+=*/public/assets/*,*/tmp/cache/assets/*/sass/*
set wildignore+=*DS_Store*

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
    " Package manager
    Plugin 'VundleVim/Vundle.vim'
    " Show "Match 123 of 456 /search term/" in Vim searches
    Plugin 'henrik/vim-indexed-search'
    " wrapper for git and display git diff in the left gutter
    Plugin 'tpope/vim-fugitive'
    Plugin 'airblade/vim-gitgutter'
    " autoclose bracket and parenthesis when open
    Plugin 'Townk/vim-autoclose'
    " Always highlight enclosing tags
    Plugin 'andymass/vim-matchup'
    " close tags on </
    Plugin 'docunext/closetag.vim'
    if !exists('g:GuiLoaded')
        " Better terminal detection
        Plugin 'wincent/terminus'
    endif
    " Indentation is very helpful
    Plugin 'Yggdroot/indentLine'
    " Folding fast is important
    Plugin 'Konfekt/FastFold'
    " Remove trailing whitespaces
    Plugin 'vim-scripts/DeleteTrailingWhitespace'
    " Move block of code
    Plugin 'matze/vim-move'
    " Improve scrolloff area
    Plugin 'drzel/vim-scroll-off-fraction'
    " Underlines the words under your cursor
    Plugin 'itchyny/vim-cursorword'
    " Auto cwd
    Plugin 'airblade/vim-rooter'
    " startify for a cool home page
    Plugin 'mhinz/vim-startify'
    " session
    Plugin 'xolox/vim-misc'
    " check https://github.com/xolox/vim-session/pull/144
    Plugin 'xolox/vim-session'
    " Autocomplete system in real time
    if has('nvim')
        Plugin 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
    else
        Plugin 'roxma/vim-hug-neovim-rpc'
        Plugin 'roxma/nvim-yarp'
        Plugin 'Shougo/deoplete.nvim'
    endif
    " Snippets engine and... snippets!
    Plugin 'SirVer/ultisnips'
    Plugin 'honza/vim-snippets'
    Plugin 'sniphpets/sniphpets'
    Plugin 'sniphpets/sniphpets-common'
    " markdown
    Plugin 'plasticboy/vim-markdown'
    " php doc autocompletion
    Plugin 'tobyS/vmustache' | Plugin 'tobyS/pdv'
    " object view
    Plugin 'majutsushi/tagbar'
    Plugin 'lvht/tagbar-markdown'
    Plugin 'hushicai/tagbar-javascript.vim'
    Plugin 'mtscout6/vim-tagbar-css'
    " Nerdtree + modifications: git icons plugin, color filetype plugin
    Plugin 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeFind']}
    Plugin 'Xuyuanp/nerdtree-git-plugin'
    Plugin 'tiagofumo/vim-nerdtree-syntax-highlight'
    Plugin 'jistr/vim-nerdtree-tabs'
    " Status bar
    Plugin 'jacoborus/tender.vim'
    Plugin 'itchyny/lightline.vim'
    Plugin 'macthecadillac/lightline-gitdiff'
    " Tags are very important
    Plugin 'ludovicchabant/vim-gutentags'
    " https://github.com/vim-php/phpctags/pull/82/files
    Plugin 'vim-php/tagbar-phpctags.vim'
    " undo tree
    Plugin 'sjl/gundo.vim'
    " select text
    Plugin 'terryma/vim-expand-region'
    " fzf - poweful search
    Plugin 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
    Plugin 'junegunn/fzf.vim'
    " allow multisearch in current directory / multi replace as well
    Plugin 'wincent/ferret'
    " display the hexadecimal colors - useful for css and color config
    Plugin 'RRethy/vim-hexokinase'
    " Cool icons"
    Plugin 'ryanoasis/vim-devicons'
    " Report lint errors
    Plugin 'w0rp/ale'
    Plugin 'maximbaz/lightline-ale'
    " Wakatime
    Plugin 'wakatime/vim-wakatime'
    " Misc
    Plugin 'editorconfig/editorconfig-vim'
    Plugin 'tommcdo/vim-lion'
    " PHP syntax
    Plugin 'StanAngeloff/php.vim'
    Plugin 'arnaud-lb/vim-php-namespace'
    Plugin '2072/vim-syntax-for-PHP.git'
    Plugin 'nishigori/vim-php-dictionary'
    Plugin '2072/PHP-Indenting-for-VIm'
    Plugin 'captbaritone/better-indent-support-for-php-with-html'
    " Comments
    Plugin 'scrooloose/nerdcommenter'
    " highlights which characters to target
    Plugin 'unblevable/quick-scope'
    " WordPress
    Plugin 'salcode/vim-wordpress-dict'
    Plugin 'sudar/vim-wordpress-snippets'
    " Web
    Plugin 'othree/html5.vim'
    Plugin 'mattn/emmet-vim'
    Plugin 'hail2u/vim-css3-syntax'
    Plugin 'groenewege/vim-less'
    Plugin 'othree/csscomplete.vim'
    Plugin 'stephpy/vim-yaml'
    " Javascript
    Plugin 'moll/vim-node'
    Plugin 'pangloss/vim-javascript'
    Plugin 'othree/javascript-libraries-syntax.vim'
    Plugin '1995eaton/vim-better-javascript-completion'
    Plugin 'mklabs/grunt.vim'
    " Syntax highlighting for vue js framework
    Plugin 'posva/vim-vue'
    " Syntax highlighting for JSX
    Plugin 'mxw/vim-jsx'
    " Syntax highlighting for coffeescript
    Plugin 'kchmck/vim-coffee-script'
    Plugin 'lukaszkorecki/CoffeeTags'
    " Syntax highlighting for webapi
    Plugin 'mattn/webapi-vim'
    " Syntax highlighting for json
    Plugin 'elzr/vim-json'
    " Open docs on K
    Plugin 'rhysd/devdocs.vim'
call vundle#end()

source /home/mte90/.vim/custom/custom-nerdtree.vim
source /home/mte90/.vim/custom/custom-lightline.vim
source /home/mte90/.vim/custom/custom-deoplete.vim
source /home/mte90/.vim/custom/custom-ale.vim
source /home/mte90/.vim/custom/custom-gutentags.vim
source /home/mte90/.vim/custom/custom-startify.vim


let g:sessions_dir = '~/.vim/sessions'
let g:session_directory = '~/.vim/sessions'
let g:session_autoload = 'no'
let g:session_autosave = 'yes'
let g:session_autosave_periodic = 1
let g:session_silent = 1
augroup default
    autocmd!
    " Add support of stuff on different files
    autocmd BufReadPost * if line("'\"") && line("'\"") <= line("$") | exe "normal `\"" | endif
    autocmd BufRead,BufNewFile jquery.*.js set ft=javascript syntax=jquery
    autocmd FileType php setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab autoindent
    autocmd FileType php.wordpress setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab autoindent
    autocmd FileType javascript setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
    autocmd FileType php let b:surround_45 = "<?php \r ?>"
    " Autosave session
    autocmd BufRead,BufReadPost,BufNewFile,BufFilePost * :SaveSession
augroup END
function LoadNewPHPCS()
    " Wait Rooter that set the path
    sleep 100m
    if filereadable(getcwd() . '/phpcs.xml')
        let g:ale_php_phpcs_standard = getcwd() . '/phpcs.xml'
    endif
endfunction
augroup PHP
  autocmd!
  autocmd BufReadPost,BufNewFile *.php call LoadNewPHPCS()
augroup END
augroup fmt
  autocmd!
  " Autoformat in tabs
  autocmd BufWritePre *.php :normal =G
  autocmd BufWritePre *.js :normal =G
  autocmd BufWritePre *.css :normal =G
  autocmd BufWritePre *.sass :normal =G
augroup END

let g:fzf_action = {
  \ 'return': 'tab split',
\}
let $FZF_DEFAULT_COMMAND = 'ag --ignore-dir .sass-cache --ignore-dir _output --ignore-dir node_modules --ignore-dir vendor -g "" -U --nogroup --column --nocolor --php --html --css --js'
" Find root
let g:rooter_patterns = ['.git/']
let g:rooter_resolve_links = 1
let g:rooter_silent_chdir  = 1
" Emmett
let g:user_emmet_install_global = 1
" Editorconfig
let g:EditorConfig_exclude_patterns = ['fugitive://.*']
" PhpDoc
let g:pdv_template_dir = $HOME .'/.vim/bundle/pdv/templates_snip'
" Ultisnip
let g:UltiSnipsExpandTrigger='<tab>'
let g:UltiSnipsEditSplit = 'vertical'
" JS smart complete
let g:vimjs#smartcomplete = 1
" php
let g:PHP_autoformatcomment = 1
" Indent lines
let g:indentLine_fileTypeExclude = ['help', 'nerdtree', 'startify']
let g:indentLine_char = '┊'
" Nerdcommenter for... better comments
let g:NERDSpaceDelims = 1
let g:NERDCompactSexyComs = 1
let g:NERDCommentEmptyLines = 1
let g:NERDTrimTrailingWhitespace = 1
let g:NERDCreateDefaultMappings = 0
" Tagbar
let g:tagbar_width = 30
let g:tagbar_indent = 1
let g:tagbar_autoshowtag = 2
let g:tagbar_singleclick = 1
let g:tagbar_sort = 1
let g:tagbar_type_php  = {
    \ 'kinds'     : [
        \ 'i:interfaces',
        \ 'c:classes',
        \ 'd:constant definitions',
        \ 'f:functions',
        \ 'j:javascript functions:1',
        \ 'v:variables:1'
    \ ]
\ }
let g:devdocs_open_cmd = 'firefox'
" Trigger a highlight only when pressing f and F.
let g:qs_highlight_on_keys = ['f']
let g:qs_max_chars=80

" Hotkeys
" Insert blank lines above and bellow current line, respectively.
nnoremap [<Space> :<c-u>put! =repeat(nr2char(10), v:count1)<CR>
nnoremap ]<Space> :<c-u>put =repeat(nr2char(10), v:count1)<CR>
" Remove spaces at the end of lines
nnoremap <silent> ,<Space> :<C-u>silent! keeppatterns %substitute/\s\+$//e<CR>
" Save
nnoremap <leader>x :w<CR>
" Open Folder tab current directory
nmap <leader>n :call NERDTreeToggleInCurDir()<CR>
" Remove highlights
map <esc> :noh<cr>
" Fold code open/close with click
nmap <expr> <2-LeftMouse> 'za'
" Search in the project files
nmap <leader>f :Rg<space>
" Object view
nmap <C-t> :TagbarToggle<CR>
" Undo tree tab
nmap <leader>g :GundoToggle<CR>
nmap <leader>x :Files<CR>
map <silent> <C-w> <Plug>(expand_region_expand)
map <silent> <C-r> <Plug>(expand_region_shrink)
" Emmett
let g:user_emmet_leader_key=',' " ,,
" navigate between errors
nmap <silent> <C-k> <Plug>(ale_previous_wrap)
nmap <silent> <C-j> <Plug>(ale_next_wrap)
nmap <silent> <C-q> <Plug>(ale_fix)
" Toggle comments
nmap <C-d> <Plug>NERDCommenterToggle('n', 'Toggle')<Cr>
" Append ; to the end of the line -> Leader+B
map <leader>b :call setline('.', getline('.') . ';')<CR>
" Granular undo
inoremap <c-u> <c-g>u<c-u>
inoremap <c-w> <c-g>u<c-w>
imap <Space> <Space><C-G>u
" V-Block replace
vnoremap <leader>r :%s/\%V//g
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
nmap K <Plug>(devdocs-under-cursor)
" Align by cursor with plugin
nmap <leader>t glip=

" \\\\ correct :W to :w #typo
cnoreabbrev <expr> W ((getcmdtype() is# ':' && getcmdline() is# 'W')?('w'):('W'))
" \\\\ correct :Q to :q #typo
cnoreabbrev <expr> Q ((getcmdtype() is# ':' && getcmdline() is# 'Q')?('q'):('Q'))
