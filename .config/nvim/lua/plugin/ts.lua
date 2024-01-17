require'nvim-treesitter.configs'.setup {
  ensure_installed = { "php", "javascript", "css", "python", "bash", "yaml", "json", "html", "htmldjango" },
  highlight = {
    enable = { "php", "javascript", "python", "bash", "css", "yaml", "json", "html", "htmldjango" },
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
require('ts_context_commentstring').setup()

require("debugprint").setup(
  {
    filetypes = {
      ['php'] = {
        left = 'error_log(print_r(',
        right = ', true));',
        mid_var = "$",
      }
    }
  }
)
