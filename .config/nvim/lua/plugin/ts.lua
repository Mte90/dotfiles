require'nvim-treesitter.configs'.setup {
  ensure_installed = { "php", "javascript", "css", "python", "bash", "yaml", "json", "html", "vue" },
  highlight = {
    enable = { "php", "javascript", "python", "bash", "yaml", "json", "html", "vue" },
  },
  rainbow = {
    enable = true,
    extended_mode = true, -- Highlight also non-parentheses delimiters, boolean or table: lang -> boolean
    max_file_lines = 1000, -- Do not enable for files with more than 1000 lines, int
  },
  tree_docs = {enable = true}
} 

local opts = {
    highlight_hovered_item = true,
    show_guides = true,
    auto_preview = true
}

require('symbols-outline').setup(opts)
require('nvim-ts-autotag').setup()
