-- package.path = package.path .. ";/home/mte90/.vim/plugged/astronauta.nvim/lua/astronauta/"
local k = require"astronauta.keymap"
local nnoremap = k.nnoremap
local inoremap = k.inoremap
local vnoremap = k.vnoremap
local xnoremap = k.xnoremap
local map      = k.map
local nmap     = k.nmap
local vmap     = k.vmap

-- Internals mapping

-- Insert blank lines above and bellow current line, respectively.
nnoremap { '[<Space>', ":<c-u>put! =repeat(nr2char(10), v:count1)" } 
nnoremap { ']<Space>', ":<c-u>put =repeat(nr2char(10), v:count1)" } 
nnoremap { '{<Space>', ":<c-u>put! =repeat(nr2char(10), v:count1)" } 
nnoremap { '}<Space>', ":<c-u>put =repeat(nr2char(10), v:count1)" } 
-- Reselect text after indent/unindent.
vnoremap { '<', '<gv' }
vnoremap { '>', '>gv' }
-- Remove spaces at the end of lines
nnoremap { '<silent> ,<Space>', ":<C-u>silent! keeppatterns %substitute/\\s\\+$//e<CR>" }
-- Remove highlights
map { '<esc>', ':noh<cr>' }
-- Granular undo
inoremap { '<Space>', '<Space><C-G>u' }
-- No yank on delete
nnoremap { 'd', '"_d' }
nnoremap { 'D', '"_D' }
vnoremap { 'd', '"_d' }
nnoremap { '<del>', '<C-G>"_x' }
xnoremap { 'p', 'pgvy' }
-- Move between panes/split with Ctrl
map { '<silent> <C-Up> ', ':wincmd k<CR>' }
map { '<silent> <C-Down>', ':wincmd j<CR>' }
map { '<silent> <C-Left>', ':BufferLineCyclePrev<CR>' }
map { '<silent> <C-Right>', ':BufferLineCycleNext<CR>' }
nmap { '<silent> <C-Up>', ':wincmd k<CR>' }
nmap { '<silent> <C-Down>', ':wincmd j<CR>' }
map { '<silent> <C-Left>', ':BufferLineCyclePrev<CR>' }
map { '<silent> <C-Right>', ':BufferLineCycleNext<CR>' }
-- Move between tabs with Alt
nmap { '<M-Right>', ':tabnext<CR>' }
nmap { '<M-Left>', ':tabprevious<CR>' }
-- Move code blocks
vim.api.nvim_set_keymap('n', '<A-j>', ":MoveLine(1)<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<A-k>', ":MoveLine(-1)<CR>", { noremap = true, silent = true })
-- correct :W to :w typo
vim.api.nvim_command("cnoreabbrev <expr> W ((getcmdtype() is# ':' && getcmdline() is# 'W')?('w'):('W'))")
-- correct :Q to :q typo
vim.api.nvim_command("cnoreabbrev <expr> Q ((getcmdtype() is# ':' && getcmdline() is# 'Q')?('q'):('Q'))")
-- save buffer with control + w
nnoremap { '<c-s>', ':w<cr>' }


-- Plugins custom mapping
-- Open Folder tab current directory
nmap { '<leader>n', ':CHADopen<CR>' }
-- Fold code open/close with click
nmap { '<expr> <2-LeftMouse>', 'za' }
-- Object view
nmap { '<C-t>', ':SymbolsOutline<CR>' }
-- Search in the project files
nmap { '<leader>f', ':Rg<space>' }
-- File list with fzf
nmap { '<leader>x', ':FzfLua files<CR>' }
-- Search on file with fzf
nmap { '<leader>g', ':FzfLua lines<CR>' }
-- Jump to definition under cursor
nmap { '<leader>j', '<cmd>lua vim.lsp.buf.definition()<cr>' }
-- navigate between errors
nmap { '<C-k>', ':ALEPreviousWrap<CR>' }
nmap { '<C-j>', ':ALENextWrap<CR>' }
nmap { '<C-q>', ':ALEFix<CR>' }
-- Append ; to the end of the line -> Leader+B
map { '<leader>b', ":call setline('.', getline('.') . ';')<CR>" }
-- DAP
nnoremap { '<F5>', ":lua require'dap'.toggle_breakpoint()<CR>" }
nnoremap { '<F6>', ":lua require'dap'.continue()<CR>" }
nnoremap { '<F10>', ":lua require'dap'.step_over()<CR>" }
nnoremap { '<F11>', ":lua require'dap'.step_into()<CR>" }
nnoremap { '<F12>', ":lua require'dap'.step_out()<CR>" }
-- https://www.cyberciti.biz/faq/how-to-reload-vimrc-file-without-restarting-vim-on-linux-unix/
-- Edit vimrc configuration file
nnoremap { 'confe', ':e $MYVIMRC<CR>' }
-- Reload vims configuration file
nnoremap { 'confr', ':source $MYVIMRC<CR>' }
-- Split code in line to different lines
nmap { '<leader>s', ':SplitjoinSplit<cr>' }
nmap { '<leader>q', ':TroubleToggle<cr>' }
