-- Based on https://github.com/nimaipatel/dotfiles/blob/master/.config/nvim/lua/nimai/misc.lua

AddEventListener('ScrolloffFraction', { 'BufEnter,WinEnter,WinNew,VimResized *,*.*' }, function ()
	local vis_lines = vim.api.nvim_win_get_height(vim.fn.win_getid())
	vim.o.scrolloff = math.floor(vis_lines * 0.25)
end)

AddEventListener('LuaHighlight', { 'TextYankPost *' }, function()
	require'vim.highlight'.on_yank()
end)

AddEventListener('DisableHighLight', { 'InsertEnter *' }, function ()
	vim.o.hlsearch = false
end)

AddEventListener('EnableHighLight', { 'InsertLeave *' }, function ()
	vim.o.hlsearch = true
end) 

AddEventListener('TextYankPost', { 'BufEnter,WinEnter,WinNew,VimResized *,*.*' }, function ()
	local vis_lines = vim.api.nvim_win_get_height(vim.fn.win_getid())
	vim.o.scrolloff = math.floor(vis_lines * 0.25)
end)

-- Add support of stuff on different files   
local autocmds = {
  jquery = {
    { 'BufRead,BufNewFile', 'jquery.*.js', 'set ft=javascript syntax=jquery' };
  };
  php = {
    { 'FileType', 'php', 'set tabstop=4' };
  };
  php_wordpress = {
    { 'FileType', 'php.wordpress', 'set tabstop=4' };
  };
  js = {
    { 'FileType', 'javascript', 'set tabstop=2 shiftwidth=2' };
  };
  php_surround = {
    { 'FileType', 'php', 'let b:surround_45 = "<?php \r ?>"' };
  };
}

nvim_create_augroups(autocmds)
    
vim.api.nvim_exec([[
    augroup default
        autocmd!
        autocmd BufReadPost * if line("'\"") && line("'\"") <= line("$") | exe "normal `\"" | endif
    augroup END 

    au FileType qf call AdjustWindowHeight(3, 5)
    function! AdjustWindowHeight(minheight, maxheight)
    exe max([min([line("$"), a:maxheight]), a:minheight]) . "wincmd _"
    endfunction             
]],true)