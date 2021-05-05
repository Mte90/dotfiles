require('lualine').setup{
    options = {
        theme = 'papercolor_light',
        icons_enabled = true,
        condition = exclude_statusline,
        disabled_filetypes = {'startify', 'Outline', 'plugins'},
    },
    sections = {
        lualine_a = { { 'mode', upper = true } },
        lualine_b = { { 'branch', icon = '' } },
        lualine_c = { { 'diff', icon = ''}, {'filename'} },
        lualine_x = { { 'filetype', 'fileformat'} },
        lualine_y = { { 'nofixme#amount'} },
        lualine_z = { { 'diagnostics', sources = {'nvim_lsp', 'ale'}, sections = {'error', 'warn', 'info'}, symbols = {error = 'E:', warn = 'W:', info = 'I:'} } }
    },
    extensions = { 'fzf', 'chadtree', 'fugitive' }
} 

require'bufferline'.setup{
    diagnostics = "nvim_lsp",
    close_icon = 'x',
}
