-- Install vim-plug before running this script

plugins = {
    "'rcarriga/nvim-notify'",
    "'petertriho/nvim-scrollbar'",
    -- Wildmenu superpower
    "'gelguy/wilder.nvim', {'do': ':UpdateRemotePlugins'}",
    "'romgrk/fzy-lua-native'",
    -- Just delete no yank too
    "'gbprod/cutlass.nvim'",
    -- UI improvements
    "'stevearc/dressing.nvim'",
    "'rainbowhxch/beacon.nvim'",
    -- LSP 
    "'neovim/nvim-lspconfig'",
    "'onsails/lspkind-nvim'",
    "'ErichDonGubler/lsp_lines.nvim'",
    "'ray-x/lsp_signature.nvim'",
    "'kosayoda/nvim-lightbulb'",
    "'HallerPatrick/py_lsp.nvim'",
    -- Popup
    "'RishabhRD/popfix'",
    "'hood/popui.nvim'",
    -- Tree-Sitter
    "'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}",
    "'gbprod/php-enhanced-treesitter.nvim'",
    "'tweekmonster/django-plus.vim'",
    "'haringsrob/nvim_context_vt'", 
    "'JoosepAlviste/nvim-ts-context-commentstring'",
    "'nvim-treesitter/nvim-tree-docs'",
    "'m-demare/hlargs.nvim'",
    -- close html tags
    "'windwp/nvim-ts-autotag'",
    -- Autopair added
    "'windwp/nvim-autopairs'",
    -- Autorename closing HTML tags
    "'AndrewRadev/tagalong.vim'", -- Viml
    -- object view
    "'stevearc/aerial.nvim'",
    "'stevearc/stickybuf.nvim'",
    -- Cool icons
    "'nvim-tree/nvim-web-devicons'",
    -- Rainbow Parentheses
    "'HiPhish/rainbow-delimiters.nvim'",
    -- Search Replace
    "'roobert/search-replace.nvim'",
    -- xDebug support
    "'mfussenegger/nvim-dap'",
    "'rcarriga/nvim-dap-ui'",
    "'theHamsta/nvim-dap-virtual-text'",
    "'andrewferrier/debugprint.nvim'",
    "'mfussenegger/nvim-dap-python'",
    -- Auto cwd
    "'ahmedkhalf/project.nvim'",
    "'nvim-lua/plenary.nvim'",
    -- wrapper for git
    "'tpope/vim-fugitive'", -- VimL
    "'f-person/git-blame.nvim'",
    -- display git diff in the left gutter
    "'lewis6991/gitsigns.nvim'",
    -- Indentation is very helpful
    "'lukas-reineke/indent-blankline.nvim'",
    -- Folding fast is important
    "'kevinhwang91/promise-async'",
    "'kevinhwang91/nvim-ufo'",
    -- Underlines the words under your cursor
    "'bennypowers/nvim-cursorline', {'branch': 'feat/disable-filetype'}",
    -- Emmett support
    "'mattn/emmet-vim'",
    -- Move code blocks
    "'hinell/move.nvim'",
    -- Autocomplete
    "'ms-jpq/coq_nvim', {'do': ':COQdeps'}",
    "'ms-jpq/coq.artifacts', {'branch': 'artifacts'}",
    "'Mte90/coq_wordpress', {'do': './install.sh'}",
    -- highlights which characters to target with F/f
    "'jinh0/eyeliner.nvim'",
    -- Split one-liner into multiple
    "'AndrewRadev/splitjoin.vim', { 'branch': 'main' }", -- VimL
    -- neo-tree
    "'MunifTanjim/nui.nvim'",
    "'nvim-neo-tree/neo-tree.nvim'",
    -- Status bar
    "'moll/vim-bbye'", --Viml
    "'nvim-lualine/lualine.nvim'",
    "'arkav/lualine-lsp-progress'",
    -- fzf - poweful search
    "'vijaymarupudi/nvim-fzf'",
    "'ibhagwan/fzf-lua'",
    "'kevinhwang91/nvim-bqf'", -- quickfix
    -- display the hexadecimal colors - useful for css and color config
    "'NvChad/nvim-colorizer.lua'",
    -- Report lint errors
    "'mfussenegger/nvim-lint'",
    "'mhartington/formatter.nvim'",
    -- Comments
    "'terrortylor/nvim-comment'",
    "'folke/todo-comments.nvim'"
}

vim.cmd[[call plug#begin('~/.vim/plugged')]]
  for i, p in pairs(plugins) do
      vim.cmd(string.format("Plug %s", p))
  end

  -- alpha for a cool home page
  vim.cmd("Plug 'goolord/alpha-nvim'") -- VimL
  -- Syntax highlighting for webapi
  vim.cmd("Plug 'mattn/webapi-vim', { 'for' : ['javascript'] }") -- VimL
vim.cmd[[call plug#end()]]

require('plugin.autopairs')
require('plugin.blankline')
require('plugin.neotree')
require('plugin.coq')
require('plugin.dap')
require('plugin.dressing')
require('plugin.gitsigns')
require('plugin.lint')
require('plugin.lsp')
require('plugin.lualine')
require('plugin.nvim-comment')
require('plugin.ts')
require('plugin.wilder')
require('plugin.alpha')
