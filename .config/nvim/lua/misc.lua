vim.cmd.colorscheme("synthweave")
vim.ui.select = require"popui.ui-overrider"

require("cutlass").setup({
    cut_key = "c"
})
require("stickybuf").setup()

-- Based on https://github.com/nimaipatel/dotfiles/blob/master/.config/nvim/lua/nimai/misc.lua

vim.api.nvim_create_autocmd(
  {'BufEnter','WinEnter','WinNew','VimResized'},
  {
    pattern = ' *,*.*',
    callback = function ()
      if (vim.bo.filetype ~= 'qf' or vim.bo.filetype ~= 'alpha') then
          local vis_lines = vim.api.nvim_win_get_height(vim.fn.win_getid())
          vim.o.scrolloff = math.floor(vis_lines * 0.25)
      end
    end
  }
)

-- https://www.reddit.com/r/neovim/comments/1abd2cq/comment/kjnmjca/?utm_source=reddit&utm_medium=web2x&context=3

vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(0) then
            vim.api.nvim_win_set_cursor(0, mark)
        end
    end,
})

vim.api.nvim_create_autocmd(
  'InsertEnter',
  {
    pattern = '*',
    callback = function ()
      vim.o.hlsearch = false
  end
  }
)

vim.api.nvim_create_autocmd(
  'InsertLeave',
  {
    pattern = '*',
    callback = function ()
      vim.o.hlsearch = true
  end
  }
)

vim.api.nvim_create_autocmd(
  {'FileType'},
  {
    pattern = 'php',
    callback = function ()
      vim.o.tabstop = 4
    end
  }
)

vim.api.nvim_create_autocmd(
  {'FileType'},
  {
    pattern = 'php.wordpress',
    callback = function ()
      vim.o.tabstop = 4
    end
  }
)

vim.api.nvim_create_autocmd(
  {'FileType'},
  {
    pattern = 'javascript',
    callback = function ()
      vim.o.tabstop = 2
      vim.o.shiftwidth = 2
    end
  }
)

vim.api.nvim_exec([[
    au FileType qf call AdjustWindowHeight(3, 5)
    function! AdjustWindowHeight(minheight, maxheight)
    exe max([min([line("$"), a:maxheight]), a:minheight]) . "wincmd _"
    endfunction
]],true)

require("project_nvim").setup {
  patterns = { ".git", "README.txt", "node_modules", "composer.json", "vendor", "package.json", "manage.py" },
  exclude_dirs = {'~/.cache/*'},
  silent_chdir = false,
}

vim.g.splitjoin_join_mapping = ''

local signs = {
    Error = "",
    Warn = " ",
    Hint = "",
    Info = " "
}

for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, {text = icon, texthl = hl, numhl = hl})
end

vim.g.cursorword_disabled_filetypes = {"dapui_breakpoints", "dapui_scopes", "dapui_stacks", "dapui_watches", "dapui-repl"}

-- https://github.com/kevinhwang91/nvim-ufo custom fold text
local handler = function(virtText, lnum, endLnum, width, truncate)
    local newVirtText = {}
    local suffix = ('  %d '):format(endLnum - lnum)
    local sufWidth = vim.fn.strdisplaywidth(suffix)
    local targetWidth = width - sufWidth
    local curWidth = 0
    for _, chunk in ipairs(virtText) do
        local chunkText = chunk[1]
        local chunkWidth = vim.fn.strdisplaywidth(chunkText)
        if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
        else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, {chunkText, hlGroup})
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
                suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
            end
            break
        end
        curWidth = curWidth + chunkWidth
    end
    table.insert(newVirtText, {suffix, 'MoreMsg'})
    return newVirtText
end

-- global handler
require('ufo').setup({
    fold_virt_text_handler = handler
})

local bufnr = vim.api.nvim_get_current_buf()
require('ufo').setFoldVirtTextHandler(bufnr, handler)

require("search-replace").setup()
require('beacon').setup()
require("hardtime").setup({
  disable_mouse = false,
  disabled_keys = {
   ["<Up>"] = {},
   ["<Down>"] = {},
   ["<Left>"] = {},
   ["<Right>"] = {},
  },
})

require('nvim-cursorline').setup {
  cursorline = {
    enable = true,
    timeout = 1000,
    number = false,
    disable_filetypes = {
      'neo-tree'
    },
  },
  cursorword = {
    enable = true,
    min_length = 3,
    hl = { underline = true },
  }
}
require("precognition").toggle()

vim.diagnostic.config({virtual_lines=true})
