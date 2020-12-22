lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "php", "javascript", "css", "python", "bash", "yaml", "json", "html", "vue" },
  highlight = {
    enable = { "php", "javascript", "python", "bash", "yaml", "json", "html", "vue" },
  },
}
EOF
