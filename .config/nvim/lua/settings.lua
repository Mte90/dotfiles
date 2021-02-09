local o = vim.o
local wo = vim.wo
local bo = vim.bo

vim.api.nvim_command('syntax on')
vim.api.nvim_command('filetype indent on')
vim.api.nvim_command('filetype plugin on')

-- global options
vim.api.nvim_set_option('clipboard', 'unnamedplus') -- Allow use of system clipboard
vim.api.nvim_command('set guioptions-=e')           -- Don't use GUI tabline
vim.api.nvim_command('set guioptions+=a')
vim.api.nvim_command('set completeopt-=preview')
vim.api.nvim_command('set completeopt+=longest,menuone,noselect')
o.pumheight = 15
o.pumblend  = 20
vim.api.nvim_command('set wildoptions+=pum')
o.whichwrap        = 'h,l,<,>,[,],~'
o.listchars        = 'tab:»·,trail:·,nbsp:·,precedes:«,extends:»'
o.backspace        = 'indent,eol,start'  -- Intuitive backspacing in insert mode
o.encoding         = 'utf-8'    -- The encoding displayed
o.fileencoding     = 'utf-8'    -- The encoding written to file
o.shortmess        = 'aoOTI'    -- Shorten messages and don't show intro
o.mouse            = 'a'        -- enable mouse in all modes
o.mousemodel       = 'popup'    -- set the behaviour of mouse
o.fileformats      = 'unix,dos' -- File type preferences
o.inccommand       = 'nosplit'  -- live preview the :substitute command
o.showbreak        = "\\\\"
o.report           = 0
o.undolevels       = 2000       -- Number of undo levels
o.laststatus       = 2          -- Always show the status line
o.showtabline      = 2          -- Show tabline
o.updatetime       = 250        -- Frequency update
o.scrolloff        = 2          -- Keep at least 2 lines above/below
o.sidescrolloff    = 5          -- Keep at least 5 lines left/right
o.showmatch        = true       -- Highlight matching brace
o.title            = true       -- change the terminal's title
o.lazyredraw       = true       -- Only redraw when necessary
o.splitbelow       = true       -- New splits open to right and bottom 
o.splitright       = true
o.hlsearch         = true       -- Search highlighting
o.incsearch        = true       -- Search starts while entering string
o.ignorecase       = true       -- Search ignore case
o.smartcase        = true       -- Search ignore case unless search contains an uppercase
o.infercase        = true       -- Adjust case in insert completion mode
o.wrapscan         = true       -- Searches wrap around the end of the file
o.showmatch        = true       -- Jump to matching bracket
o.cursorline       = true       -- Color the cursorline
o.backup           = false
o.writebackup      = false
o.swapfile         = false      -- Turn off swap files
o.hidden           = true       -- Buffer becomes hidden when abandoned to prevent need to save
o.autoread         = true       -- if a file is changed outside Vim, automatically re-read it
o.startofline      = false      -- Cursor in same column for few commands
o.showfulltag      = true       -- Show tag and tidy search in completion
o.showmode         = false      -- Don't show mode in cmd window
o.showcmd          = false      -- Don't show command in status line
o.shiftround       = true       -- align indent to next multiple value of shiftwidth
o.shiftwidth       = 4          -- Number of auto-indent spaces
o.softtabstop      = 4          -- Number of spaces per Tab
o.smarttab         = true       -- Enable smart-tabs
o.expandtab        = true       -- Insert spaces when tab pressed
o.ruler            = true
o.autochdir        = true       -- Set the file path as pwd
o.gdefault         = true       -- Set searching to global by default
o.wildmenu         = true       -- Command line completion help
o.wildignorecase   = true       -- Ignore case when completing file names and directories.
--   A list of file patterns to ignore when performing expansion and completion.
vim.api.nvim_command('set wildignore+=*.so,/min/*')
vim.api.nvim_command('set wildignore+=.git,.hg,.svn,.stversions,*.pyc,*.spl,*.o,*.out,*~,%*')
vim.api.nvim_command('set wildignore+=*.jpg,*.jpeg,*.png,*.gif,*.log,**/tmp/**')
vim.api.nvim_command('set wildignore+=**/node_modules/**,**/bower_modules/**,*/.sass-cache/*')
vim.api.nvim_command('set wildignore+=__pycache__,*.egg-info')
vim.api.nvim_command('set wildignore+=*.out,*.obj,*.gem,*.pyc,*DS_Store*')
vim.api.nvim_command('set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz')
vim.api.nvim_command('set wildignore+=*.swp,*~,._*,*/vendor/cache/*')
vim.api.nvim_command('set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz')

-- window-local options
wo.number          = true       -- Show line numbers
wo.foldmethod      = 'marker'   -- Autofolding
wo.foldmarker      = '/*,*/'
wo.foldnestmax     = 10
wo.breakindent     = true       -- Make every wrapped line visually indented.

-- buffer-local options
bo.omnifunc        = 'lsp#omnifunc' -- use omni completion provided by lsp
bo.textwidth       = 100         -- Line wrap (number of cols)
bo.autoindent      = true        -- Uses indent from previous line
bo.smartindent     = true        -- Like cindent except lil' more clever
bo.copyindent      = true        -- Copy the structure of existing line's indent when autoin
