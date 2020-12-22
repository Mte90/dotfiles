lua <<EOF
    vim.g.vista_default_executive = "ale"
    vim.g.vista_icon_indent = {"╰─▸ ", "├─▸ "}
    vim.g.vista_fold_toggle_icons = {"╰─▸ ", "├─▸ "}
    vim.cmd("let g:vista#renderer#enable_icon = 1")
    vim.cmd([[let g:vista#renderer#icons = {"function": "\uf794","variable": "\uf71b",}]])
EOF
let g:vista#executives = ['ale', 'nvim_lsp']
