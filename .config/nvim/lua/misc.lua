-- Based on https://github.com/nimaipatel/dotfiles/blob/master/.config/nvim/lua/nimai/misc.lua

vim.api.nvim_create_autocmd(
  'BufEnter,WinEnter,WinNew,VimResized *,*.*',
  {
    callback = function ()
      if (vim.bo.filetype ~= 'qf' or vim.bo.filetype ~= 'alpha') then
          local vis_lines = vim.api.nvim_win_get_height(vim.fn.win_getid())
          vim.o.scrolloff = math.floor(vis_lines * 0.25)
      end
    end
  }
)

vim.api.nvim_create_autocmd(
  'TextYankPost *',
  {
    callback = function()
      require'vim.highlight'.on_yank()
  end
  }
)

vim.api.nvim_create_autocmd(
  'InsertEnter *',
  {
    callback = function ()
      vim.o.hlsearch = false
  end
  }
)

vim.api.nvim_create_autocmd(
  'InsertLeave *',
  {
    callback = function ()
      vim.o.hlsearch = true
  end
  }
)

vim.api.nvim_create_autocmd(
  'BufEnter,WinEnter,WinNew,VimResized *,*.*',
  {
    callback = function ()
      local vis_lines = vim.api.nvim_win_get_height(vim.fn.win_getid())
      vim.o.scrolloff = math.floor(vis_lines * 0.25)
  end
  }
)

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

require'nvim-rooter'.setup { manual = true }

vim.api.nvim_exec([[
" Editorconfig
let g:EditorConfig_exclude_patterns = ['fugitive://.*']
" Trigger a highlight only when pressing f and F. - quickscope
let g:qs_highlight_on_keys = ['f']
let g:qs_max_chars=80
let g:splitjoin_join_mapping = '' 

let g:loaded_python_provider = 0
let g:loaded_node_provider = 0
let g:loaded_ruby_provider = 0
let g:loaded_perl_provider = 0
]],true)

local signs = {
    Error = " ",
    Warn = " ",
    Hint = " ",
    Info = " "
}

for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, {text = icon, texthl = hl, numhl = hl})
end

-- Do not source the default filetype.vim
vim.g.did_load_filetypes = 0
vim.g.do_filetype_lua = 1

require("cutlass").setup({
    cut_key = "c"
})
require("stickybuf").setup()

vim.g.cursorword_disabled_filetypes = {"dapui_breakpoints", "dapui_scopes", "dapui_stacks", "dapui_watches", "dapui-repl"}
