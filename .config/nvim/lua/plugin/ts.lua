require'nvim-treesitter.configs'.setup {
  ensure_installed = { "php", "javascript", "css", "python", "bash", "yaml", "json", "html", "vue" },
  highlight = {
    enable = { "php", "javascript", "python", "bash", "yaml", "json", "html", "vue" },
  },
  rainbow = {
    enable = true,
    extended_mode = true,
    max_file_lines = 1000,
  },
  context_commentstring = {
    enable = true
  },
  tree_docs = {enable = true},
  autopairs = {enable = true}
} 

local opts = {
    highlight_hovered_item = true,
    show_guides = true,
    auto_preview = true
}

require('symbols-outline').setup(opts)
require('nvim-ts-autotag').setup()
