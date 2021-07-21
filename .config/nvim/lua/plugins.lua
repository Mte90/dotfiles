-- Install vim-plug before running this script
-- https://github.com/gnituy18/config/blob/105a65084489720be58c44e479d20c30a4ea31e7/nvim/lua/plugins.lua

plugins = {
    -- KDE style theme
    "'fneu/breezy'", -- not yet ready
    -- LSP 
    "'neovim/nvim-lspconfig'",
    "'folke/lsp-colors.nvim'",
    "'folke/lsp-trouble.nvim'",
    "'onsails/lspkind-nvim'",
    "'ray-x/lsp_signature.nvim'",
    -- Tree-Sitter
    "'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}",
    "'haringsrob/nvim_context_vt'", 
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
    -- Snippets engine and... snippets!
    "'SirVer/ultisnips'", -- VimL
    "'honza/vim-snippets'", -- VimL
    "'sniphpets/sniphpets', { 'for' : ['php'] }", -- VimL
    "'sniphpets/sniphpets-phpunit', { 'for' : ['php'] }", -- VimL
    "'sniphpets/sniphpets-common', { 'for' : ['php'] }", -- VimL
    -- Emmett support
    "'mattn/emmet-vim'",
    -- Autocomplete 
    "'hrsh7th/nvim-compe'",
    "'FateXii/emmet-compe'",
--     "'tzachar/compe-tabnine', { 'do': './install.sh' }",
    -- highlights which characters to target
    "'unblevable/quick-scope'", -- VimL
    -- Search pulse
    "'inside/vim-search-pulse'", -- VimL
    -- Split one-liner into multiple
    "'AndrewRadev/splitjoin.vim', { 'branch': 'main' }", -- VimL
    -- chadtree
    "'ms-jpq/chadtree', {'branch': 'chad', 'do': ':CHADdeps'}",
    -- Status bar
    "'hoob3rt/lualine.nvim', { 'commit': '5c20f5f4b8b3318913ed5a9b00cd5610b7295bd4'}",
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
