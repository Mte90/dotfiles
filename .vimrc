" Note: Skip initialization for vim-tiny or vim-small.
if !1 | finish | endif

" Disable some plugin to have a wordpress core contributing experience
" vim --cmd "let wordpress_mode=1" 

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
set mousemodel=popup  " set the behaviour of mouse
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
set foldmethod=marker
set foldmarker=/*,*/
set foldnestmax=10
set foldcolumn=2
set report=0
" Search option
set hlsearch              " Search highlighting
set incsearch             " Search starts while entering string
set inccommand=nosplit    " live preview the :substitute command
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
set completeopt-=preview
set completeopt+=longest,menuone,noselect
" use omni completion provided by lsp
set omnifunc=lsp#omnifunc
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
set shiftround       " align indent to next multiple value of shiftwidth
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
set listchars=tab:»·,trail:·,nbsp:·,precedes:«,extends:»
set wildmenu " Command line completion help
" Set color
set guifont=Droid\ Sans\ Mono\ Nerd\ Font:h10
set background=light
" exclusions from the autocomplete menu
set wildoptions=tagfile
set pumblend=20
set wildoptions+=pum
set inccommand=nosplit
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
" Tags folder
set tags+=/home/mte90/.vim/tags
" if a file is changed outside Vim, automatically re-read it
set autoread

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
    " Package manager
    Plugin 'VundleVim/Vundle.vim'
    " KDE style theme
    Plugin 'fneu/breezy'
    " LSP 
    Plugin 'neovim/nvim-lspconfig'
    Plugin 'halkn/lightline-lsp'
    " Tree-Sitter
    Plugin 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
    Plugin 'nvim-lua/completion-nvim'
    Plugin 'nvim-treesitter/completion-treesitter'
    " Auto cwd
    Plugin 'airblade/vim-rooter'
    if !exists('wordpress_mode')
        " startify for a cool home page
        Plugin 'mhinz/vim-startify'
    endif
    " Show "Match 123 of 456 /search term/" in Vim searches
    Plugin 'henrik/vim-indexed-search'
    " wrapper for git
    Plugin 'tpope/vim-fugitive'
    Plugin 'f-person/git-blame.nvim'
    " display git diff in the left gutter
    Plugin 'airblade/vim-gitgutter'
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
    " Rainbow Parentheses Improved
    Plugin 'luochen1990/rainbow'
    " Folding fast is important
    Plugin 'Konfekt/FastFold'
    " Move block of code
    Plugin 'matze/vim-move'
    " Improve scrolloff area
    Plugin 'drzel/vim-scroll-off-fraction'
    " Underlines the words under your cursor
    Plugin 'itchyny/vim-cursorword'
    " Snippets engine and... snippets!
    Plugin 'SirVer/ultisnips'
    Plugin 'honza/vim-snippets'
    Plugin 'sniphpets/sniphpets'
    Plugin 'sniphpets/sniphpets-phpunit'
    Plugin 'sniphpets/sniphpets-common'
    Plugin 'sudar/vim-wordpress-snippets'
    " Autocomplete system in real time
    Plugin 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
    Plugin 'Shougo/deoplete-lsp'
    Plugin 'mte90/deoplete-wp-hooks'
    if !exists('wordpress_mode')
        " markdown
        Plugin 'godlygeek/tabular'
        Plugin 'plasticboy/vim-markdown'
    endif
    " highlights which characters to target
    Plugin 'unblevable/quick-scope'
    " Search pulse
    Plugin 'inside/vim-search-pulse'
    " Split one-liner into multiple
    Plugin 'AndrewRadev/splitjoin.vim'
    " chadtree
    Plugin 'ms-jpq/chadtree', {'branch': 'chad', 'do': ':UpdateRemotePlugins'}
    " Status bar
    Plugin 'itchyny/lightline.vim'
    Plugin 'macthecadillac/lightline-gitdiff'
    Plugin 'itchyny/vim-gitbranch'
    Plugin 'fisle/vim-no-fixme'
    " object view
    Plugin 'liuchengxu/vista.vim'
    " fzf - poweful search
    Plugin 'junegunn/fzf'
    Plugin 'junegunn/fzf.vim' 
    " Wrapper for sd
    Plugin 'SirJson/sd.vim'
    " display the hexadecimal colors - useful for css and color config
    Plugin 'RRethy/vim-hexokinase'
    " Cool icons
    if !has('nvim')
        Plugin 'ryanoasis/vim-devicons'
    else
        Plugin 'kyazdani42/nvim-web-devicons'
    endif
    " Report lint errors
    Plugin 'dense-analysis/ale'
    Plugin 'maximbaz/lightline-ale'
    " Wakatime
    Plugin 'wakatime/vim-wakatime'
    " EditorConfig support
    Plugin 'editorconfig/editorconfig-vim'
    " xDebug support
    Plugin 'vim-vdebug/vdebug'
    " Comments
    Plugin 'scrooloose/nerdcommenter'
    " Web
    Plugin 'mattn/emmet-vim'
    Plugin 'mklabs/grunt.vim'
    if !exists('wordpress_mode')
        Plugin 'moll/vim-node'
        " Syntax highlighting for webapi
        Plugin 'mattn/webapi-vim'
    endif
    " Open docs on K
    Plugin 'rhysd/devdocs.vim'
call vundle#end()

colorscheme breezy

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
" Emmett
let g:user_emmet_install_global = 1
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

" Browser to open the devdocs
let g:devdocs_open_cmd = 'firefox'
" Trigger a highlight only when pressing f and F.
let g:qs_highlight_on_keys = ['f']
let g:qs_max_chars=80
" Markdown
let g:vim_markdown_folding_disabled = 1

let g:vdebug_options = {
    \    'break_on_open' : 0,
    \    'ide_key' : 'VVVDEBUG'
    \}
let g:vdebug_options.path_maps = {"/srv/www/": "/var/www/VVV/www/"}

lua vim.api.nvim_set_var("chadtree_ignores", { name = {".*", ".git", "vendor", "node_modules"} })
let g:chadtree_settings = {"keymap": { "tertiary": ["t"], 'trash': ['a'] }}
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

" Replace all
nnoremap <leader>r :exec "Rgi ".expand("<cword>")<cr>
" Plugins custom mapping
nmap K <Plug>(devdocs-under-cursor)
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
" Emmett
let g:user_emmet_leader_key=',' " ,,
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
