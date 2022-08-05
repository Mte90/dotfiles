-- Install vim-plug before running this script
-- https://github.com/gnituy18/config/blob/105a65084489720be58c44e479d20c30a4ea31e7/nvim/lua/plugins.lua

-- Check if WordPress mode
is_wp, message = pcall(function()
    return vim.api.nvim_get_var("wordpress_mode")
  end)

plugins = {
    "'lewis6991/impatient.nvim'",
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
    "'folke/lsp-colors.nvim'",
    "'onsails/lspkind-nvim'",
    "'https://git.sr.ht/~whynothugo/lsp_lines.nvim'",
    "'ray-x/lsp_signature.nvim'",
    "'williamboman/nvim-lsp-installer'",
    "'kosayoda/nvim-lightbulb'",
    "'RishabhRD/popfix'",
    "'hood/popui.nvim'",
    -- Tree-Sitter
    "'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}",
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
    "'kyazdani42/nvim-web-devicons'",
    -- Rainbow Parentheses
    "'p00f/nvim-ts-rainbow'",
    -- xDebug support
    "'mfussenegger/nvim-dap'",
    "'rcarriga/nvim-dap-ui'",
    "'theHamsta/nvim-dap-virtual-text'",
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
    "'Hrle97/nvim-cursorline', {'branch': 'feature/disable-conditionally'}",
    -- Emmett support
    "'mattn/emmet-vim'",
    -- Move code blocks
    "'fedepujol/move.nvim'",
    -- Autocomplete
    "'ms-jpq/coq_nvim', {'do': ':COQdeps'}",
    "'ms-jpq/coq.artifacts', {'branch': 'artifacts'}",
    "'mte90/coq_wordpress', {'do': './install.sh'}",
    -- highlights which characters to target
    "'unblevable/quick-scope'", -- VimL
    -- Search pulse
    "'inside/vim-search-pulse'", -- VimL
    -- Split one-liner into multiple
    "'AndrewRadev/splitjoin.vim', { 'branch': 'main' }", -- VimL
    -- chadtree
    "'ms-jpq/chadtree', {'branch': 'chad', 'do': ':CHADdeps'}",
    -- Status bar
    "'kdheepak/tabline.nvim'",
    "'moll/vim-bbye'", --Viml
    "'nvim-lualine/lualine.nvim'",
    "'arkav/lualine-lsp-progress'",
    -- fzf - poweful search
    "'vijaymarupudi/nvim-fzf'",
    "'ibhagwan/fzf-lua'",
    "'kevinhwang91/nvim-bqf'", -- quickfix
    -- Wrapper for sd
    "'SirJson/sd.vim'",
    -- display the hexadecimal colors - useful for css and color config
    "'norcalli/nvim-colorizer.lua'",
    -- Report lint errors
    "'mfussenegger/nvim-lint'",
    "'mhartington/formatter.nvim'",
    -- Wakatime
    "'wakatime/vim-wakatime'",
    -- Discord
    "'andweeb/presence.nvim'",
    -- EditorConfig support
    "'gpanders/editorconfig.nvim'",
    -- Comments
    "'terrortylor/nvim-comment'",
    "'folke/todo-comments.nvim'"
}

vim.cmd[[call plug#begin('~/.vim/plugged')]]
  for i, p in pairs(plugins) do
      vim.cmd(string.format("Plug %s", p))
  end

  if is_wp == false then
    -- alpha for a cool home page
    vim.cmd("Plug 'goolord/alpha-nvim'") -- VimL
    -- Syntax highlighting for webapi
    vim.cmd("Plug 'mattn/webapi-vim', { 'for' : ['javascript'] }") -- VimL
  end
vim.cmd[[call plug#end()]]

-- https://www.reddit.com/r/neovim/comments/opipij/guide_tips_and_tricks_to_reduce_startup_and/
local disabled_built_ins = {
    "netrw",
    "netrwPlugin",
    "netrwSettings",
    "netrwFileHandlers",
    "gzip",
    "zip",
    "zipPlugin",
    "tar",
    "tarPlugin",
    "getscript",
    "getscriptPlugin",
    "vimball",
    "vimballPlugin",
    "2html_plugin",
    "logipat",
    "rrhelper",
    "spellfile_plugin"
}

for _, plugin in pairs(disabled_built_ins) do
    vim.g["loaded_" .. plugin] = 1
end

require('plugin.autopairs')
require('plugin.blankline')
require('plugin.chadtree')
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


if is_wp == false then
    require('plugin.alpha')
end
