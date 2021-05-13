-- Install vim-plug before running this script
-- https://github.com/gnituy18/config/blob/105a65084489720be58c44e479d20c30a4ea31e7/nvim/lua/plugins.lua

plugins = {
    -- KDE style theme
    "'fneu/breezy'", -- not yet ready
    -- LSP 
    "'neovim/nvim-lspconfig'",
    "'kabouzeid/nvim-lspinstall'",
    "'folke/lsp-colors.nvim'",
    "'folke/lsp-trouble.nvim'",
    "'onsails/lspkind-nvim'",
    "'ray-x/lsp_signature.nvim'",
    -- Tree-Sitter
    "'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}",
    "'nvim-lua/completion-nvim'",
    "'nvim-treesitter/completion-treesitter'",
    "'haringsrob/nvim_context_vt'", 
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
    "'airblade/vim-rooter'", -- VimL
    "'nvim-lua/plenary.nvim'",
    -- wrapper for git
    "'tpope/vim-fugitive'", -- VimL
    "'f-person/git-blame.nvim'",
    -- display git diff in the left gutter
    "'lewis6991/gitsigns.nvim'",
    -- close html tags
    "'windwp/nvim-ts-autotag'",
    -- Indentation is very helpful
    "'lukas-reineke/indent-blankline.nvim', { 'branch': 'lua' }",
    -- Folding fast is important
    "'Konfekt/FastFold'", -- VimL
    -- Move block of code
    "'matze/vim-move'", -- VimL
    -- Underlines the words under your cursor
    "'RRethy/vim-illuminate'",
    -- Snippets engine and... snippets!
    "'SirVer/ultisnips'", -- VimL
    "'honza/vim-snippets'", -- VimL
    "'sniphpets/sniphpets', { 'for' : ['php'] }", -- VimL
    "'sniphpets/sniphpets-phpunit', { 'for' : ['php'] }", -- VimL
    "'sniphpets/sniphpets-common', { 'for' : ['php'] }", -- VimL
    -- Autocomplete system in real time
    "'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }",
    "'Shougo/deoplete-lsp'",
    "'mte90/deoplete-wp-hooks'",
    -- highlights which characters to target
    "'unblevable/quick-scope'", -- VimL
    -- Search pulse
    "'inside/vim-search-pulse'", -- VimL
    -- Split one-liner into multiple
    "'AndrewRadev/splitjoin.vim', { 'branch': 'main' }", -- VimL
    -- chadtree
    "'ms-jpq/chadtree', {'branch': 'chad', 'do': ':UpdateRemotePlugins'}", -- VimL
    -- Status bar
    "'hoob3rt/lualine.nvim'",
    "'akinsho/nvim-bufferline.lua'",
    "'mte90/vim-no-fixme', {'branch': 'patch-1'}", -- VimL
    "'folke/todo-comments.nvim'",
    -- fzf - poweful search
    "'junegunn/fzf'",
    "'junegunn/fzf.vim'",  -- VimL
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
    vim.cmd("Plug 'mhinz/vim-startify'")
  end
  if vim.fn.exists("wordpress_mode") == 0 then
    -- markdown
    vim.cmd("Plug 'godlygeek/tabular', { 'for' : ['markdown'] }")
    vim.cmd("Plug 'plasticboy/vim-markdown', { 'for' : ['markdown'] }")
    vim.cmd("Plug 'moll/vim-node', { 'for' : ['javascript'] }")
    -- Syntax highlighting for webapi
    vim.cmd("Plug 'mattn/webapi-vim', { 'for' : ['javascript'] }")
  end
vim.cmd[[call plug#end()]]

