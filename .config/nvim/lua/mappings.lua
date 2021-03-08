package.path = package.path .. ";/home/mte90/.vim/plugged/astronauta.nvim/lua/astronauta/"
local k = require"astronauta.keymap"
local nnoremap = k.nnoremap
local inoremap = k.inoremap
local vnoremap = k.vnoremap
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
-- Move between panes/split with Ctrl
map { '<silent> <C-Up> ', ':wincmd k<CR>' }
map { '<silent> <C-Down>', ':wincmd j<CR>' }
map { '<silent> <C-Left>', ':wincmd h<CR>' }
map { '<silent> <C-Right>', ':wincmd l<CR>' }
nmap { '<silent> <C-Up>', ':wincmd k<CR>' }
nmap { '<silent> <C-Down>', ':wincmd j<CR>' }
nmap { '<silent> <C-Left>', ':wincmd h<CR>' }
nmap { '<silent> <C-Right>', ':wincmd l<CR>' }
-- Move between tabs with Alt
nmap { '<M-Right>', ':tabnext<CR>' }
nmap { '<M-Left>', ':tabprevious<CR>' }
-- correct :W to :w typo
vim.api.nvim_command("cnoreabbrev <expr> W ((getcmdtype() is# ':' && getcmdline() is# 'W')?('w'):('W'))")
-- correct :Q to :q typo
vim.api.nvim_command("cnoreabbrev <expr> Q ((getcmdtype() is# ':' && getcmdline() is# 'Q')?('q'):('Q'))")


-- Plugins custom mapping
-- Open Folder tab current directory
nmap { '<leader>n', ':CHADopen<CR>' }
-- Fold code open/close with click
nmap { '<expr> <2-LeftMouse>', 'za' }
-- Search in the project files
nmap { '<leader>f', ':Rg<space>' }
-- Object view
nmap { '<C-t>', ':Vista nvim_lsp<CR>' }
-- File list with fzf
nmap { '<leader>x', ':Files<CR>' }
-- navigate between errors
nmap { '<silent> <C-k>', '<Plug>(ale_previous_wrap)' }
nmap { '<silent> <C-j>', '<Plug>(ale_next_wrap)' }
nmap { '<silent> <C-q>', '<Plug>(ale_fix)' }
-- Toggle comments
nmap { '<C-d>', '<plug>NERDCommenterToggle<CR>' }
vmap { '<C-d>', '<plug>NERDCommenterToggle<CR>' }
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
nmap { '<Leader>s', ':SplitjoinSplit<cr>' }
