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
    close_on_select = true
}

require("aerial").setup(opts)
require('nvim-ts-autotag').setup()
require('hlargs').setup()
