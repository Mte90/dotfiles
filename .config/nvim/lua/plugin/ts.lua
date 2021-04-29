require'nvim-treesitter.configs'.setup {
  ensure_installed = { "php", "javascript", "css", "python", "bash", "yaml", "json", "html", "vue" },
  highlight = {
    enable = { "php", "javascript", "python", "bash", "yaml", "json", "html", "vue" },
  },
} 

local opts = {
    highlight_hovered_item = true,
    show_guides = true,
}

require('symbols-outline').setup(opts)
require('nvim-ts-autotag').setup()
