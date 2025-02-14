-- Internals mapping

-- Insert blank lines above and bellow current line, respectively.
vim.keymap.set('n', '[<Space>', ":<c-u>put! =repeat(nr2char(10), v:count1)")
vim.keymap.set('n', ']<Space>', ":<c-u>put =repeat(nr2char(10), v:count1)")
vim.keymap.set('n', '{<Space>', ":<c-u>put! =repeat(nr2char(10), v:count1)")
vim.keymap.set('n', '}<Space>', ":<c-u>put =repeat(nr2char(10), v:count1)")
-- Reselect text after indent/unindent.
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')
-- Remove spaces at the end of lines
vim.keymap.set('n', '<silent> ,<Space>', ":<C-u>silent! keeppatterns %substitute/\\s\\+$//e<CR>")
-- Remove highlights
vim.keymap.set('n', '<esc>', ':noh<cr>')
-- Granular undo
vim.keymap.set('i', '<Space>', '<Space><C-G>u')
-- No yank on delete
vim.keymap.set('n', 'd', '"_d')
vim.keymap.set('n', 'D', '"_D')
vim.keymap.set('v', 'd', '"_d')
vim.keymap.set('n', '<del>', '<C-G>"_x')
vim.keymap.set('x', 'p', 'pgvy')
-- Move between panes/split with Ctrl
vim.keymap.set('n', '<silent> <C-Up> ', ':wincmd k<CR>')
vim.keymap.set('n', '<silent> <C-Down>', ':wincmd j<CR>')
vim.keymap.set('n', '<silent> <C-Left>', ':BufferLineCyclePrev<CR>')
vim.keymap.set('n', '<silent> <C-Right>', ':BufferLineCycleNext<CR>')
vim.keymap.set('n', '<silent> <C-Up>', ':wincmd k<CR>')
vim.keymap.set('n', '<silent> <C-Down>', ':wincmd j<CR>')
vim.keymap.set('n', '<silent> <C-Left>', ':BufferLineCyclePrev<CR>')
vim.keymap.set('n', '<silent> <C-Right>', ':BufferLineCycleNext<CR>')
-- Move between tabs with Alt
vim.keymap.set('n', '<M-Right>', ':tabnext<CR>')
vim.keymap.set('n', '<M-Left>', ':tabprevious<CR>')
-- Move code blocks
vim.api.nvim_set_keymap('v', '<A-j>', ":MoveBlock(1)<CR>", { noremap = true, silent = true})
vim.api.nvim_set_keymap('v', '<A-k>', ":MoveBlock(-1)<CR>", { noremap = true, silent = true})
-- correct :W to :w typo
vim.api.nvim_command("cnoreabbrev <expr> W ((getcmdtype() is# ':' && getcmdline() is# 'W')?('w'):('W'))")
-- correct :Q to :q typo
vim.api.nvim_command("cnoreabbrev <expr> Q ((getcmdtype() is# ':' && getcmdline() is# 'Q')?('q'):('Q'))")
vim.keymap.set('n', '<C-q>', function()
  -- close current win if there are more than 1 win
  -- else close current tab if there are more than 1 tab
  -- else close current vim
  if #vim.api.nvim_tabpage_list_wins(0) > 1 then
    vim.cmd([[close]])
  elseif #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd([[tabclose]])
  else
    vim.cmd([[qa]])
  end
end, { desc = 'Super <C-q>' })
-- save buffer with control + w
vim.keymap.set('n', '<c-s>', ':w<cr>')
vim.keymap.set('x', '<C-S-X>', '"+d')
vim.keymap.set('v', '<C-S-c>', '"+y')         -- Copy
vim.keymap.set('n', '<C-S-v>', '"+P')         -- Paste normal mode
vim.keymap.set('v', '<C-S-v>', '"+P')         -- Paste visual mode
vim.keymap.set('c', '<C-S-v>', '<C-R>+')      -- Paste command mode
vim.keymap.set('i', '<C-S-v>', '<C-R><C-O>+') -- Paste insert mode

-- Plugins custom mapping
-- Open Folder tab current directory
vim.keymap.set('n', '<leader>n', function()
		pcall(vim.cmd.Neotree, "toggle")
	end)
-- Fold code open/close with click
vim.keymap.set('n', '<expr> <2-LeftMouse>', 'za')
-- Object view
vim.keymap.set('n', '<C-t>', ':AerialToggle right<CR>')
-- Search in the project files
vim.keymap.set('n', '<leader>f', ':FzfLua live_grep lsp_finder<CR>')
-- File list with fzf
vim.keymap.set('n', '<leader>x', ':FzfLua files<CR>')
-- Search in file with fzf
vim.keymap.set('n', '<leader>g', ':FzfLua lines<CR>')
-- Jump to definition under cursor
vim.keymap.set('n', '<leader>j', '<cmd>lua vim.lsp.buf.definition()<cr>')
-- Append ; to the end of the line
vim.keymap.set("i", ";;", "<C-O>A;")
-- DAP
vim.keymap.set('n', '<F1>', ":lua require'dap'clear_breakpoints()<CR>")
vim.keymap.set('n', '<F2>', ":lua require'dapui'.float_element('scopes', {position = 'center',  enter = true })<CR>")
vim.keymap.set('n', '<F3>', ":lua require'dapui'.float_element('console', {position = 'center'})<CR>")
vim.keymap.set('n', '<F4>', ":lua require'dapui'.toggle()<CR>")
vim.keymap.set('n', '<F5>', ":lua require'dap'.toggle_breakpoint()<CR>")
vim.keymap.set('n', '<F6>', ":lua require'dap'.continue()<CR>")
vim.keymap.set('n', '<F7>', ":lua require'dap'.restart()<CR>")
vim.keymap.set('n', '<F8>', ":lua require'dap'.step_over()<CR>")
vim.keymap.set('n', '<F9>', ":lua require'dap'.step_into()<CR>")
vim.keymap.set('n', '<F10>', ":lua require'dap'.step_out()<CR>")

-- Split code in line to different lines
vim.keymap.set('n', '<leader>s', ':SplitjoinSplit<cr>')
vim.keymap.set("n", "<Leader>p", function()
    return require('debugprint').debugprint( { above = true, variable = true } )
end, {
    expr = true,
})
vim.keymap.set('v', '<C-r>', ':SearchReplaceSingleBufferOpen<cr>')
-- https://www.cyberciti.biz/faq/how-to-reload-vimrc-file-without-restarting-vim-on-linux-unix/
-- Edit vimrc configuration file
vim.keymap.set('n', 'confe', ':e $MYVIMRC<CR>')
-- Reload vims configuration file
vim.keymap.set('n', 'confr', ':source $MYVIMRC<CR>')
