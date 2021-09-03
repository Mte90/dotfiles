-- Install vim-plug before running this script
-- https://github.com/gnituy18/config/blob/105a65084489720be58c44e479d20c30a4ea31e7/nvim/lua/plugins.lua

plugins = {
    -- KDE style theme
    "'fneu/breezy'", -- not yet ready
    "'lewis6991/impatient.nvim'",
    -- LSP 
    "'neovim/nvim-lspconfig'",
    "'folke/lsp-colors.nvim'",
    "'folke/lsp-trouble.nvim'",
    "'onsails/lspkind-nvim'",
    "'ray-x/lsp_signature.nvim'",
    "'kabouzeid/nvim-lspinstall'",
    -- Tree-Sitter
    "'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}",
    "'haringsrob/nvim_context_vt'", 
    "'JoosepAlviste/nvim-ts-context-commentstring'",
    "'Olical/aniseed', { 'tag': 'v3.19.0' }",
    "'nvim-treesitter/nvim-tree-docs'",
    -- close html tags
    "'windwp/nvim-ts-autotag'",
    -- object view
    "'simrat39/symbols-outline.nvim'",
    -- Cool icons
    "'kyazdani42/nvim-web-devicons'",
    -- Rainbow Parentheses
    "'p00f/nvim-ts-rainbow'",
    -- xDebug support
    "'mfussenegger/nvim-dap'",
    "'rcarriga/nvim-dap-ui'",
    "'theHamsta/nvim-dap-virtual-text'",
    -- https://github.com/neovim/neovim/pull/13823
    "'tjdevries/astronauta.nvim'",
    -- Auto cwd
    "'ygm2/rooter.nvim'",
    "'nvim-lua/plenary.nvim'",
    -- wrapper for git
    "'tpope/vim-fugitive'", -- VimL
    "'f-person/git-blame.nvim'",
    -- display git diff in the left gutter
    "'lewis6991/gitsigns.nvim'",
    -- Indentation is very helpful
    "'lukas-reineke/indent-blankline.nvim'",
    -- Folding fast is important
    "'Konfekt/FastFold'", -- VimL
    -- Underlines the words under your cursor
    "'yamatsum/nvim-cursorline'",
    -- Autopair added
    "'windwp/nvim-autopairs'",
    -- Snippets engine and... snippets!
    "'SirVer/ultisnips'", -- VimL
    -- Emmett support
    "'mattn/emmet-vim'",
    -- Autocomplete 
    "'ms-jpq/coq_nvim', {'do': ':COQdeps'}",
    "'ms-jpq/coq.artifacts', {'branch': 'artifacts'}",
    -- highlights which characters to target
    "'unblevable/quick-scope'", -- VimL
    -- Search pulse
    "'inside/vim-search-pulse'", -- VimL
    -- Split one-liner into multiple
    "'AndrewRadev/splitjoin.vim', { 'branch': 'main' }", -- VimL
    -- chadtree
    "'ms-jpq/chadtree', {'branch': 'chad', 'do': ':CHADdeps'}",
    -- Status bar
    "'shadmansaleh/lualine.nvim'", -- This fork is updated!
    "'akinsho/nvim-bufferline.lua'",
    "'mte90/vim-no-fixme', {'branch': 'patch-1'}", -- VimL
    "'folke/todo-comments.nvim'",
    -- fzf - poweful search
    "'junegunn/fzf'",
    "'junegunn/fzf.vim'",  -- VimL
    "'kevinhwang91/nvim-bqf'", -- quickfix
    -- Wrapper for sd
    "'SirJson/sd.vim'",
    -- display the hexadecimal colors - useful for css and color config
    "'norcalli/nvim-colorizer.lua'",
    -- Report lint errors
    "'dense-analysis/ale'",
    "'nathunsmitty/nvim-ale-diagnostic'",
    -- Wakatime
    "'wakatime/vim-wakatime'",
    -- Discord
    "'andweeb/presence.nvim'",
    -- EditorConfig support
    "'editorconfig/editorconfig-vim'",
    -- Comments
    "'terrortylor/nvim-comment'"
}

vim.cmd[[call plug#begin('~/.vim/plugged')]]
  for i, p in pairs(plugins) do
      vim.cmd(string.format("Plug %s", p))
  end

  if vim.fn.exists("wordpress_mode") == 0 then
    -- startify for a cool home page
    vim.cmd("Plug 'mhinz/vim-startify'") -- VimL
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

require('plugin.blankline')
require('plugin.chadtree')
require('plugin.dap')
require('plugin.gitsigns')
require('plugin.lsp')
require('plugin.lualine')
require('plugin.nvim-comment')
require('plugin.ts')
require('plugin.coq')
require('plugin.autopairs')
