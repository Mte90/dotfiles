-- Install vim-plug before running this script
-- https://github.com/gnituy18/config/blob/105a65084489720be58c44e479d20c30a4ea31e7/nvim/lua/plugins.lua

plugins = {
    -- KDE style theme
    "'fneu/breezy'", -- not yet ready
    -- LSP 
    "'neovim/nvim-lspconfig'",
    "'halkn/lightline-lsp'",
    "'alexaandru/nvim-lspupdate'",
    -- Tree-Sitter
    "'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}",
    "'nvim-lua/completion-nvim'",
    "'nvim-treesitter/completion-treesitter'",
    "'romgrk/nvim-treesitter-context'", 
    -- xDebug support
    "'mfussenegger/nvim-dap'",
    "'theHamsta/nvim-dap-virtual-text'",
    -- https://github.com/neovim/neovim/pull/13823
    "'tjdevries/astronauta.nvim'",
    -- Auto cwd
    "'airblade/vim-rooter'",
    -- Show --Match 123 of 456 /search term/-- in Vim searches
    "'henrik/vim-indexed-search'",
    -- wrapper for git
    "'tpope/vim-fugitive'",
    "'f-person/git-blame.nvim'",
    -- display git diff in the left gutter
    "'airblade/vim-gitgutter'",
    -- Always highlight enclosing tags
    "'andymass/vim-matchup'",
    -- close tags on </
    "'docunext/closetag.vim'",
    -- jump to definition
    "'pechorin/any-jump.vim'",
    -- Indentation is very helpful
    "'nathanaelkane/vim-indent-guides'",
    -- Rainbow Parentheses Improved
    "'luochen1990/rainbow'",
    -- Folding fast is important
    "'Konfekt/FastFold'",
    -- Move block of code
    "'matze/vim-move'",
    -- Improve scrolloff area
    "'drzel/vim-scroll-off-fraction'",
    -- Underlines the words under your cursor
    "'itchyny/vim-cursorword'",
    -- Snippets engine and... snippets!
    "'SirVer/ultisnips'",
    "'honza/vim-snippets'",
    "'sniphpets/sniphpets', { 'for' : ['php'] }",
    "'sniphpets/sniphpets-phpunit', { 'for' : ['php'] }",
    "'sniphpets/sniphpets-common', { 'for' : ['php'] }",
    -- Autocomplete system in real time
    "'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }",
    "'Shougo/deoplete-lsp'",
    "'mte90/deoplete-wp-hooks'",
    -- highlights which characters to target
    "'unblevable/quick-scope'",
    -- Search pulse
    "'inside/vim-search-pulse'",
    -- Split one-liner into multiple
    "'AndrewRadev/splitjoin.vim', { 'branch': 'main' }",
    -- chadtree
    "'ms-jpq/chadtree', {'branch': 'chad', 'do': ':UpdateRemotePlugins'}",
    -- Status bar
    "'itchyny/lightline.vim'",
    "'macthecadillac/lightline-gitdiff'",
    "'itchyny/vim-gitbranch'",
    "'mte90/vim-no-fixme', {'branch': 'patch-1'}",
    -- object view
    "'liuchengxu/vista.vim'",
    -- fzf - poweful search
    "'junegunn/fzf'",
    "'junegunn/fzf.vim'", 
    -- Wrapper for sd
    "'SirJson/sd.vim'",
    -- display the hexadecimal colors - useful for css and color config
    "'RRethy/vim-hexokinase'",
    -- Cool icons
    "'kyazdani42/nvim-web-devicons'",
    -- Report lint errors
    "'dense-analysis/ale'",
    "'maximbaz/lightline-ale'",
    "'nathunsmitty/nvim-ale-diagnostic'",
    -- Wakatime
    "'wakatime/vim-wakatime'",
    -- Discord
    "'andweeb/presence.nvim'",
    -- EditorConfig support
    "'editorconfig/editorconfig-vim'",
    -- Comments
    "'scrooloose/nerdcommenter'",
    -- Web
    "'mklabs/grunt.vim', { 'for' : ['javascript'] }"
    --Plug 'brooth/far.vim'
}


vim.cmd[[call plug#begin('~/.vim/plugged')]]
  for i, p in pairs(plugins) do
      vim.cmd(string.format("Plug %s", p))
  end

  if vim.fn.exists("wordpress_mode") == 0 then
    -- startify for a cool home page
    vim.cmd("Plug 'mhinz/vim-startify'")
  end
  if vim.fn.exists("g:GuiLoaded") == 0 then
    -- Better terminal detection
    vim.cmd("Plug 'wincent/terminus'")
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

