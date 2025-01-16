set termguicolors

lua << EOF
    vim.env.PATH = vim.env.HOME .. "/.local/bin:" .. vim.env.PATH
    require('utils')
    require('settings')
    require('plugins')
    require('mappings')
    require('misc')
EOF
